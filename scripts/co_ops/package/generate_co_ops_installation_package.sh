#!/usr/bin/env bash

# Build and deliver a customized Ab Initio co-Operating System installation
# package for one target host.
#
# The workflow in this script follows the runbook in
# docs/runbooks/co_ops/CO_OPS_RUNBOOK.md and keeps the
# environment-specific values in separate config files:
#   - configs/co_ops/package/co_ops_denv.conf
#   - configs/co_ops/package/co_ops_benv.conf
#   - configs/co_ops/package/co_ops_penv.conf
#
# Design goals:
#   - Validate that the script is executed on the correct build host.
#   - Keep target host input as a full FQDN only.
#   - Support dry-run, debug, log rotation, and restart-from-step.
#   - Stop on failures and pause between steps unless --auto-continue is used.
#   - Stay re-runnable by using mkdir -p, overwrite-safe scp, and a
#     version-specific remote directory.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PROGRAM_NAME="$(basename "$0")"
CONFIG_DIR="${REPO_ROOT}/configs/co_ops/package"

LOG_READY=0
LOCK_DIR=""
ERROR_LOG_FILE=""

TARGET_HOST=""
TARGET_HOST_SHORT=""
CO_OPS_VERSION=""
VERSION_TOKEN=""
ENV_NAME_INPUT=""
ENV_NAME=""
CONFIG_FILE=""
CURRENT_HOST=""
CURRENT_HOST_ENV=""
SKIP_BUILD_HOST_VALIDATION=0

FROM_STEP_RAW="1"
START_STEP=1
DRY_RUN=0
DEBUG=0
AUTO_CONTINUE=0

LOG_DIR="${REPO_ROOT}/logs"
STATE_DIR="${REPO_ROOT}/.state"
LOG_RETENTION_DAYS=90

EXPECTED_CURRENT_HOST=""
TARGET_HOST_SUFFIX=""
BUILD_BASE_DIR=""
BUILD_SCRIPT_RELATIVE_PATH=""
BUILD_REFERENCE_XREF=""
REMOTE_USER=""
REMOTE_PACKAGE_ROOT=""
UPGRADE_SCRIPT_SOURCE=""
SSH_AUTH_MODE="key"
PACKAGE_ENV_LABEL=""
SSH_DESTINATION=""
REMOTE_VERSION_DIR=""
PACKAGE_FILE=""
PACKAGE_FILE_NAME=""
BUILD_TARGET_FQDN=""

EXECUTION_STEPS=()

usage() {
  cat <<'EOF'
Usage:
  ./scripts/co_ops/package/generate_co_ops_installation_package.sh --env <denv|benv|penv> <target_host_fqdn> <co_ops_version> [options]

Summary:
  Build a customized co-ops installation package on the correct build host,
  copy it to the target host, unzip it, then copy upgrade_co_ops_automation.sh.
  Examples below assume the current working directory is the repository root.

Required positional arguments:
  <target_host_fqdn>       Full target host name.
                           denv example: gbl25149199.hk.hsbc
                           benv example: gbl25183799.systems.uk.hsbc
                           penv example: gbl25185999.systems.uk.hsbc
  <co_ops_version>         Target co-ops version, for example 4.4.3.3

Options:
  -c, --config FILE       Optional. Path to the config file.
                          Default: configs/co_ops/package/co_ops_<env>.conf
  -e, --env ENV           Required. One of denv, benv, penv
  -s, --from-step STEP     Start from a specific step, for example 4 or step_4
      --auto-continue      Continue automatically after each step
      --dry-run            Print commands only, do not execute them
      --debug              Enable shell tracing and imply --dry-run
      --list-steps         Print the supported steps and exit
  -h, --help               Show this help text

Step list:
  step_1  Detect env from the current build host and validate the target host
  step_2  Validate local prerequisites and derive runtime paths
  step_3  Build the customized installation package
  step_4  Verify the generated package exists
  step_5  Create the remote version directory
  step_6  Transfer the package to the target host
  step_7  Unzip the package on the target host
  step_8  Transfer upgrade_co_ops_automation.sh to the target host
  step_9  chmod the remote script and verify the remote directory

Examples:
  ./scripts/co_ops/package/generate_co_ops_installation_package.sh --env denv gbl25149199.hk.hsbc 4.4.3.3 --dry-run
  ./scripts/co_ops/package/generate_co_ops_installation_package.sh --env benv gbl25183799.systems.uk.hsbc 4.4.3.3 --auto-continue
  ./scripts/co_ops/package/generate_co_ops_installation_package.sh --env penv gbl25185999.systems.uk.hsbc 4.4.3.3 --from-step step_6
  ./scripts/co_ops/package/generate_co_ops_installation_package.sh --env denv --config configs/co_ops/package/co_ops_denv.conf gbl25149199.hk.hsbc 4.4.3.3 --dry-run
EOF
}

print_steps() {
  usage | sed -n '/^Step list:/,$p'
}

# Normalize a step selector such as "step_6" or "6" so resume logic stays
# friendly for operators and easy for the script to compare numerically.
normalize_step() {
  local raw="${1:-}"
  raw="${raw#step_}"
  if [[ ! "${raw}" =~ ^[0-9]+$ ]]; then
    printf '%s\n' ""
    return 1
  fi
  printf '%s\n' "${raw}"
}

step_label_for_number() {
  printf 'step_%s\n' "$1"
}

step_title() {
  case "$1" in
    1) printf '%s\n' "Validate requested env, build host, and target host" ;;
    2) printf '%s\n' "Validate local prerequisites" ;;
    3) printf '%s\n' "Build customized installation package" ;;
    4) printf '%s\n' "Verify generated package" ;;
    5) printf '%s\n' "Create remote version directory" ;;
    6) printf '%s\n' "Transfer package to target host" ;;
    7) printf '%s\n' "Unzip package on target host" ;;
    8) printf '%s\n' "Transfer upgrade script to target host" ;;
    9) printf '%s\n' "chmod and verify remote script" ;;
    *) printf '%s\n' "Unknown step" ;;
  esac
}

die() {
  local message="${1:-Unknown error}"
  if [[ "${LOG_READY}" -eq 1 ]]; then
    log_error "${message}"
  else
    printf 'ERROR: %s\n' "${message}" >&2
  fi
  exit 1
}

user_stop() {
  log WARN "script stopped by user"
  log INFO "Log file: ${LOG_FILE}"
  log INFO "Error file: ${ERROR_LOG_FILE}"
  exit 0
}

log() {
  local level="$1"
  shift
  local emoji=""
  local line=""

  case "${level}" in
    STEP) emoji="🚀" ;;
    INFO) emoji="ℹ️ " ;;
    OK) emoji="✅" ;;
    WARN) emoji="⚠️ " ;;
    ERROR) emoji="❌" ;;
    CMD) emoji="💻" ;;
    DRYRUN) emoji="🧪" ;;
    *) emoji="•" ;;
  esac

  line="$(printf '%s %s [%s] %s' "$(date '+%Y-%m-%d %H:%M:%S')" "${emoji}" "${level}" "$*")"
  if [[ "${LOG_READY}" -eq 1 ]]; then
    printf '%s\n' "${line}" | tee -a "${LOG_FILE}"
  else
    printf '%s\n' "${line}"
  fi
}

log_error() {
  local message="$*"
  log ERROR "${message}"
  printf '%s %s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "❌" "ERROR" "${message}" >> "${ERROR_LOG_FILE}"
}

log_step_banner() {
  local text="$1"
  if [[ "${LOG_READY}" -eq 1 ]]; then
    {
      printf '\n'
      printf '############################################################\n'
      printf '### %s\n' "${text}"
      printf '############################################################\n'
      printf '\n'
    } | tee -a "${LOG_FILE}"
  else
    printf '\n############################################################\n### %s\n############################################################\n\n' "${text}"
  fi
}

# Build a human-readable command string for logs. This is intentionally for
# display only, so it prefers readable double quotes over shell-style %q output.
format_display_arg() {
  local arg="$1"
  if [[ "${arg}" =~ ^[A-Za-z0-9_./:@%+=,-]+$ ]]; then
    printf '%s' "${arg}"
    return 0
  fi
  arg="${arg//\\/\\\\}"
  arg="${arg//\"/\\\"}"
  arg="${arg//\$/\\$}"
  arg="${arg//\`/\\\`}"
  printf '"%s"' "${arg}"
}

display_cmd() {
  local rendered=()
  local arg=""
  for arg in "$@"; do
    rendered+=("$(format_display_arg "${arg}")")
  done
  printf '%s' "${rendered[*]}"
}

display_shell_cmd() {
  local shell_cmd="$1"
  printf 'bash -lc %s' "$(format_display_arg "${shell_cmd}")"
}

# Every workflow command goes through this helper.
# In --dry-run mode the command is only logged and the function returns before
# any process is started, which keeps step actions side-effect free.
run_logged_cmd() {
  local display
  local cmd_rc=0
  local tee_rc=0
  local err_trap_state=""
  display="$(display_cmd "$@")"
  log CMD "${display}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log DRYRUN "command not executed because --dry-run is enabled"
    return 0
  fi
  err_trap_state="$(trap -p ERR || true)"
  trap - ERR
  set +e
  "$@" 2>&1 | tee -a "${LOG_FILE}"
  cmd_rc=${PIPESTATUS[0]}
  tee_rc=${PIPESTATUS[1]:-0}
  set -e
  if [[ -n "${err_trap_state}" ]]; then
    eval "${err_trap_state}"
  fi
  if [[ "${tee_rc}" -ne 0 ]]; then
    die "failed to write command output to log while running: ${display}"
  fi
  if [[ "${cmd_rc}" -ne 0 ]]; then
    die "command failed with exit code ${cmd_rc}: ${display}"
  fi
}

# Same contract as run_logged_cmd, but for one composed shell command string.
# This is used for the build-package call where keeping the original command
# shape from the runbook makes operator review easier.
run_shell_cmd() {
  local shell_cmd="$1"
  local cmd_rc=0
  local tee_rc=0
  local err_trap_state=""
  local display=""
  display="$(display_shell_cmd "${shell_cmd}")"
  log CMD "${display}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log DRYRUN "command not executed because --dry-run is enabled"
    return 0
  fi
  err_trap_state="$(trap -p ERR || true)"
  trap - ERR
  set +e
  bash -lc "${shell_cmd}" 2>&1 | tee -a "${LOG_FILE}"
  cmd_rc=${PIPESTATUS[0]}
  tee_rc=${PIPESTATUS[1]:-0}
  set -e
  if [[ -n "${err_trap_state}" ]]; then
    eval "${err_trap_state}"
  fi
  if [[ "${tee_rc}" -ne 0 ]]; then
    die "failed to write command output to log while running: ${display}"
  fi
  if [[ "${cmd_rc}" -ne 0 ]]; then
    die "command failed with exit code ${cmd_rc}: ${display}"
  fi
}

run_ssh_remote_cmd() {
  local destination="$1"
  local remote_cmd="$2"
  local display=""
  local cmd_rc=0
  local tee_rc=0
  local err_trap_state=""

  # Follow the runbook's visual order in logs and dry-run output, while keeping
  # the actual ssh invocation in the client-supported option order.
  display="ssh -q ${destination} -C $(format_display_arg "${remote_cmd}")"
  log CMD "${display}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log DRYRUN "command not executed because --dry-run is enabled"
    return 0
  fi

  err_trap_state="$(trap -p ERR || true)"
  trap - ERR
  set +e
  ssh -q -C "${destination}" "${remote_cmd}" 2>&1 | tee -a "${LOG_FILE}"
  cmd_rc=${PIPESTATUS[0]}
  tee_rc=${PIPESTATUS[1]:-0}
  set -e
  if [[ -n "${err_trap_state}" ]]; then
    eval "${err_trap_state}"
  fi
  if [[ "${tee_rc}" -ne 0 ]]; then
    die "failed to write command output to log while running: ${display}"
  fi
  if [[ "${cmd_rc}" -ne 0 ]]; then
    die "command failed with exit code ${cmd_rc}: ${display}"
  fi
}

rotate_logs() {
  local display=""
  display="$(display_cmd find "${LOG_DIR}" -type f \( -name '*.log' -o -name '*.err' \) -mtime "+${LOG_RETENTION_DAYS}" -print -delete)"
  log CMD "${display}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    return 0
  fi
  find "${LOG_DIR}" -type f \( -name '*.log' -o -name '*.err' \) -mtime +"${LOG_RETENTION_DAYS}" -print -delete || true
}

acquire_lock() {
  # A dry-run never performs the real workflow steps, so it does not need to
  # block another operator with a runtime lock.
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log INFO "dry-run mode skips lock creation"
    return 0
  fi
  LOCK_DIR="${STATE_DIR}/.${ENV_NAME}_${TARGET_HOST_SHORT}_${VERSION_TOKEN}.lock"
  if ! mkdir "${LOCK_DIR}" 2>/dev/null; then
    die "another run is already active for ${ENV_NAME}/${TARGET_HOST_SHORT}/${CO_OPS_VERSION}: ${LOCK_DIR}"
  fi
}

release_lock() {
  if [[ -n "${LOCK_DIR}" && -d "${LOCK_DIR}" ]]; then
    rm -rf "${LOCK_DIR}"
  fi
}

on_error() {
  local rc="$1"
  local line="$2"
  local command="$3"
  if [[ "${LOG_READY}" -eq 1 ]]; then
    log_error "command failed at line ${line} with exit code ${rc}: ${command}"
    log INFO "Log file: ${LOG_FILE}"
    log INFO "Error file: ${ERROR_LOG_FILE}"
  else
    printf 'ERROR: command failed at line %s with exit code %s: %s\n' "${line}" "${rc}" "${command}" >&2
  fi
  exit "${rc}"
}

ensure_required_commands() {
  local commands=(bash date find hostname mkdir scp sed ssh tee)
  local cmd=""
  for cmd in "${commands[@]}"; do
    command -v "${cmd}" >/dev/null 2>&1 || die "required command not found: ${cmd}"
  done
}

parse_args() {
  local positional=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c|--config)
        [[ $# -ge 2 ]] || die "missing value for $1"
        CONFIG_FILE="$2"
        shift 2
        ;;
      -e|--env)
        [[ $# -ge 2 ]] || die "missing value for $1"
        ENV_NAME_INPUT="$2"
        shift 2
        ;;
      -s|--from-step)
        [[ $# -ge 2 ]] || die "missing value for $1"
        FROM_STEP_RAW="$2"
        shift 2
        ;;
      --auto-continue)
        AUTO_CONTINUE=1
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --debug)
        DEBUG=1
        DRY_RUN=1
        shift
        ;;
      --list-steps)
        print_steps
        exit 0
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --)
        shift
        while [[ $# -gt 0 ]]; do
          positional+=("$1")
          shift
        done
        ;;
      -*)
        die "unknown option: $1"
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done

  if [[ "${#positional[@]}" -ne 2 ]]; then
    usage
    exit 1
  fi

  TARGET_HOST="${positional[0]}"
  CO_OPS_VERSION="${positional[1]}"
}

default_config_file_for_env() {
  local env_name="$1"
  printf '%s/co_ops_%s.conf\n' "${CONFIG_DIR}" "${env_name}"
}

detect_current_host() {
  if [[ -n "${CURRENT_HOST_OVERRIDE:-}" ]]; then
    printf '%s\n' "${CURRENT_HOST_OVERRIDE}"
    return 0
  fi

  if hostname -f >/dev/null 2>&1; then
    hostname -f
    return 0
  fi

  hostname
}

# Keep the target host contract strict: the caller must pass a full FQDN, and
# the version must stay in dotted numeric format because later path generation
# depends on it.
validate_inputs() {
  [[ -n "${ENV_NAME_INPUT}" ]] || die "--env is required and must be one of denv, benv, penv"
  case "${ENV_NAME_INPUT}" in
    denv|benv|penv) ;;
    *) die "--env must be one of denv, benv, penv" ;;
  esac
  [[ "${TARGET_HOST}" =~ ^[[:alnum:]-]+(\.[[:alnum:]-]+)+$ ]] || die "target host must be a full FQDN: ${TARGET_HOST}"
  [[ "${CO_OPS_VERSION}" =~ ^[0-9]+(\.[0-9]+)+$ ]] || die "invalid co-ops version: ${CO_OPS_VERSION}"

  TARGET_HOST_SHORT="${TARGET_HOST%%.*}"
  VERSION_TOKEN="${CO_OPS_VERSION//./}"
  START_STEP="$(normalize_step "${FROM_STEP_RAW}")" || die "invalid step value: ${FROM_STEP_RAW}"
  [[ "${START_STEP}" -ge 1 && "${START_STEP}" -le 9 ]] || die "--from-step must be between step_1 and step_9"
}

# Real execution must run on an approved build host. Dry-run is different: it is
# allowed to run on any machine because it only prints the workflow commands and
# never executes step commands.
resolve_environment_from_current_host() {
  CURRENT_HOST="$(detect_current_host)"
  ENV_NAME="${ENV_NAME_INPUT}"

  case "${CURRENT_HOST}" in
    gbl25149108.hc.cloud.uk.hsbc)
      CURRENT_HOST_ENV="denv"
      ;;
    gbl25183782.systems.uk.hsbc)
      CURRENT_HOST_ENV="benv"
      ;;
    gbl25185915.systems.uk.hsbc)
      CURRENT_HOST_ENV="penv"
      ;;
    *)
      CURRENT_HOST_ENV=""
      ;;
  esac

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    SKIP_BUILD_HOST_VALIDATION=1
    if [[ -z "${CONFIG_FILE}" ]]; then
      CONFIG_FILE="$(default_config_file_for_env "${ENV_NAME}")"
    fi
    return 0
  fi

  [[ -n "${CURRENT_HOST_ENV}" ]] || die "unsupported current host: ${CURRENT_HOST}. This script must run on one of the approved build hosts."

  if [[ "${ENV_NAME_INPUT}" != "${CURRENT_HOST_ENV}" ]]; then
    die "requested env ${ENV_NAME_INPUT} does not match current build host ${CURRENT_HOST} which belongs to ${CURRENT_HOST_ENV}"
  fi

  if [[ -z "${CONFIG_FILE}" ]]; then
    CONFIG_FILE="$(default_config_file_for_env "${ENV_NAME}")"
  fi
}

# Load the env-specific knobs from a shell config file so future path, account,
# or xref changes do not require editing the main script.
load_config() {
  [[ -f "${CONFIG_FILE}" ]] || die "config file not found: ${CONFIG_FILE}"

  # shellcheck disable=SC1090
  source "${CONFIG_FILE}"

  : "${EXPECTED_CURRENT_HOST:?EXPECTED_CURRENT_HOST must be set in ${CONFIG_FILE}}"
  : "${TARGET_HOST_SUFFIX:?TARGET_HOST_SUFFIX must be set in ${CONFIG_FILE}}"
  : "${BUILD_BASE_DIR:?BUILD_BASE_DIR must be set in ${CONFIG_FILE}}"
  : "${BUILD_SCRIPT_RELATIVE_PATH:?BUILD_SCRIPT_RELATIVE_PATH must be set in ${CONFIG_FILE}}"
  : "${REMOTE_USER:?REMOTE_USER must be set in ${CONFIG_FILE}}"
  : "${REMOTE_PACKAGE_ROOT:?REMOTE_PACKAGE_ROOT must be set in ${CONFIG_FILE}}"
  : "${UPGRADE_SCRIPT_SOURCE:?UPGRADE_SCRIPT_SOURCE must be set in ${CONFIG_FILE}}"
  : "${PACKAGE_ENV_LABEL:?PACKAGE_ENV_LABEL must be set in ${CONFIG_FILE}}"
  declare -p TARGET_HOST_ALLOWLIST >/dev/null 2>&1 || die "TARGET_HOST_ALLOWLIST must be defined in ${CONFIG_FILE}"
  [[ "${#TARGET_HOST_ALLOWLIST[@]}" -gt 0 ]] || die "TARGET_HOST_ALLOWLIST must not be empty in ${CONFIG_FILE}"

  if [[ "${SKIP_BUILD_HOST_VALIDATION}" -eq 0 ]]; then
    [[ "${CURRENT_HOST}" == "${EXPECTED_CURRENT_HOST}" ]] || die "current host mismatch. Expected ${EXPECTED_CURRENT_HOST}, got ${CURRENT_HOST}"
  fi
  [[ "${TARGET_HOST}" == *"${TARGET_HOST_SUFFIX}" ]] || die "target host ${TARGET_HOST} does not match env ${ENV_NAME} suffix ${TARGET_HOST_SUFFIX}"
  if ! target_host_is_allowed "${TARGET_HOST}"; then
    die "target host ${TARGET_HOST} is not in the allowlist for env ${ENV_NAME}"
  fi

  SSH_DESTINATION="${REMOTE_USER}@${TARGET_HOST}"
  REMOTE_VERSION_DIR="${REMOTE_PACKAGE_ROOT}/co_ops_${VERSION_TOKEN}"
  BUILD_TARGET_FQDN="${TARGET_HOST_SHORT}${TARGET_HOST_SUFFIX}"
  PACKAGE_FILE="${BUILD_BASE_DIR}/ai_build/tmp/ai_build_package_${TARGET_HOST_SHORT}_${PACKAGE_ENV_LABEL}.tgz"
  PACKAGE_FILE_NAME="$(basename "${PACKAGE_FILE}")"

  LOG_DIR="${LOG_DIR:-${REPO_ROOT}/logs}"
  STATE_DIR="${STATE_DIR:-${REPO_ROOT}/.state}"
  LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-90}"
}

target_host_is_allowed() {
  local candidate="$1"
  local allowed_host=""
  for allowed_host in "${TARGET_HOST_ALLOWLIST[@]}"; do
    if [[ "${allowed_host}" == "${candidate}" ]]; then
      return 0
    fi
  done
  return 1
}

init_logging() {
  mkdir -p "${LOG_DIR}" "${STATE_DIR}"
  LOG_FILE="${LOG_DIR}/co_ops_installation_package_${ENV_NAME}_${TARGET_HOST_SHORT}_${VERSION_TOKEN}_$(date +%Y%m%d).log"
  ERROR_LOG_FILE="${LOG_FILE%.log}.err"
  : >> "${LOG_FILE}"
  : >> "${ERROR_LOG_FILE}"
  LOG_READY=1

  if [[ "${DEBUG}" -eq 1 ]]; then
    export PS4='+ ${BASH_SOURCE##*/}:${LINENO}: '
    set -x
  fi
}

# Build the ordered step list once so --from-step behaves predictably and the
# user confirmation prompt always knows the next logical step.
build_execution_steps() {
  local step=""
  EXECUTION_STEPS=()
  for step in 1 2 3 4 5 6 7 8 9; do
    if [[ "${step}" -ge "${START_STEP}" ]]; then
      EXECUTION_STEPS+=("${step}")
    fi
  done
}

wait_for_step_confirmation() {
  local completed_label="$1"
  local next_label="$2"
  local answer=""

  if [[ -z "${next_label}" ]]; then
    return 0
  fi

  if [[ "${AUTO_CONTINUE}" -eq 1 ]]; then
    log INFO "auto continue to the next step"
    return 0
  fi

  if [[ "${LOG_READY}" -eq 1 ]]; then
    {
      printf '\nCompleted %s.\n' "${completed_label}"
      printf 'Type yes to continue to %s, or anything else to stop.\n' "${next_label}"
      printf '> '
    } | tee -a "${LOG_FILE}"
  else
    printf '\nCompleted %s.\nType yes to continue to %s, or anything else to stop.\n> ' "${completed_label}" "${next_label}"
  fi

  if ! IFS= read -r answer; then
    die "failed to read user confirmation after ${completed_label}"
  fi

  if [[ "${LOG_READY}" -eq 1 ]]; then
    printf '%s\n' "${answer}" >> "${LOG_FILE}"
  fi

  [[ "${answer}" == "yes" ]] || user_stop
}

log_runtime_context() {
  log INFO "program: ${PROGRAM_NAME}"
  log INFO "config file: ${CONFIG_FILE}"
  log INFO "current host: ${CURRENT_HOST}"
  log INFO "requested env: ${ENV_NAME_INPUT}"
  if [[ -n "${CURRENT_HOST_ENV}" ]]; then
    log INFO "current host env: ${CURRENT_HOST_ENV}"
  else
    log WARN "current host is not one of the approved build hosts"
  fi
  log INFO "environment: ${ENV_NAME}"
  log INFO "target host: ${TARGET_HOST}"
  log INFO "co-ops version: ${CO_OPS_VERSION}"
  log INFO "remote version directory: ${REMOTE_VERSION_DIR}"
  log INFO "allowlist entries in ${ENV_NAME}: ${#TARGET_HOST_ALLOWLIST[@]}"
  if [[ "${SKIP_BUILD_HOST_VALIDATION}" -eq 1 ]]; then
    log WARN "dry-run mode skips current build host validation"
  fi
  if [[ "${SSH_AUTH_MODE}" == "password" ]]; then
    log WARN "ssh/scp in ${ENV_NAME} may prompt for a password"
  else
    log INFO "ssh/scp in ${ENV_NAME} uses key-based authentication"
  fi
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log DRYRUN "dry-run mode is enabled. Commands will be printed only."
  fi
}

step_1_detect_env() {
  if [[ "${SKIP_BUILD_HOST_VALIDATION}" -eq 1 ]]; then
    log WARN "dry-run preview uses requested env ${ENV_NAME_INPUT} without enforcing current build host checks"
  else
    log INFO "requested env ${ENV_NAME_INPUT} matches current build host ${CURRENT_HOST}"
  fi
  log INFO "target host ${TARGET_HOST} passed suffix validation for env ${ENV_NAME}"
  log INFO "target host ${TARGET_HOST} is present in the ${ENV_NAME} allowlist"
}

# Validate the local files up front so the script fails early before any remote
# work starts. This makes troubleshooting much cheaper in production runs.
step_2_validate_local_prerequisites() {
  run_logged_cmd test -d "${BUILD_BASE_DIR}"
  run_logged_cmd test -f "${BUILD_BASE_DIR}/${BUILD_SCRIPT_RELATIVE_PATH}"
  if [[ -n "${BUILD_REFERENCE_XREF}" ]]; then
    run_logged_cmd test -f "${BUILD_BASE_DIR}/${BUILD_REFERENCE_XREF}"
  fi
  run_logged_cmd test -f "${UPGRADE_SCRIPT_SOURCE}"
}

# Build the package exactly in the runbook style so operators can compare the
# printed command with the manual procedure line by line.
step_3_build_package() {
  local shell_cmd=""

  if [[ -n "${BUILD_REFERENCE_XREF}" ]]; then
    printf -v shell_cmd \
      'cd %q && export BUILDHOST=%q && %q -x %q -t %q -e %q -b %q' \
      "${BUILD_BASE_DIR}" \
      "${TARGET_HOST_SHORT}" \
      "${BUILD_SCRIPT_RELATIVE_PATH}" \
      "${BUILD_REFERENCE_XREF}" \
      "${BUILD_TARGET_FQDN}" \
      "${ENV_NAME}" \
      "${CO_OPS_VERSION}"
  else
    printf -v shell_cmd \
      'cd %q && export BUILDHOST=%q && %q -t %q -e %q -b %q' \
      "${BUILD_BASE_DIR}" \
      "${TARGET_HOST_SHORT}" \
      "${BUILD_SCRIPT_RELATIVE_PATH}" \
      "${BUILD_TARGET_FQDN}" \
      "${ENV_NAME}" \
      "${CO_OPS_VERSION}"
  fi

  run_shell_cmd "${shell_cmd}"
}

step_4_verify_package() {
  run_logged_cmd test -f "${PACKAGE_FILE}"
}

# The version directory keeps repeated runs scoped to one co-ops version and
# makes the target path obvious during review.
step_5_create_remote_dir() {
  run_ssh_remote_cmd "${SSH_DESTINATION}" "mkdir -p ${REMOTE_VERSION_DIR}"
}

step_6_transfer_package() {
  run_logged_cmd scp -q "${PACKAGE_FILE}" "${SSH_DESTINATION}:${REMOTE_VERSION_DIR}/"
}

step_7_unzip_package() {
  local remote_cmd=""
  printf -v remote_cmd 'cd %q && tar -xzf %q && ls -lrth %q' \
    "${REMOTE_VERSION_DIR}" "${PACKAGE_FILE_NAME}" "${REMOTE_VERSION_DIR}"
  run_ssh_remote_cmd "${SSH_DESTINATION}" "${remote_cmd}"
}

step_8_transfer_upgrade_script() {
  run_logged_cmd scp -q "${UPGRADE_SCRIPT_SOURCE}" "${SSH_DESTINATION}:${REMOTE_VERSION_DIR}/"
}

step_9_chmod_and_verify() {
  local remote_cmd=""
  printf -v remote_cmd 'ls -lrth %q && chmod +x %q && ls -lrth %q' \
    "${REMOTE_VERSION_DIR}" \
    "${REMOTE_VERSION_DIR}/upgrade_co_ops_automation.sh" \
    "${REMOTE_VERSION_DIR}"
  run_ssh_remote_cmd "${SSH_DESTINATION}" "${remote_cmd}"
}

run_step() {
  case "$1" in
    1) step_1_detect_env ;;
    2) step_2_validate_local_prerequisites ;;
    3) step_3_build_package ;;
    4) step_4_verify_package ;;
    5) step_5_create_remote_dir ;;
    6) step_6_transfer_package ;;
    7) step_7_unzip_package ;;
    8) step_8_transfer_upgrade_script ;;
    9) step_9_chmod_and_verify ;;
    *) die "unknown step: $1" ;;
  esac
}

# With set -eE -o pipefail and the ERR trap in main(), any failing command
# inside a step stops the script immediately. The loop therefore only reaches
# the next step when the current one completed successfully.
execute_selected_steps() {
  local index=0
  local current_step=""
  local completed_label=""
  local next_label=""

  for index in "${!EXECUTION_STEPS[@]}"; do
    current_step="${EXECUTION_STEPS[${index}]}"
    completed_label="$(step_label_for_number "${current_step}")"

    log_step_banner "${completed_label} - $(step_title "${current_step}")"
    log STEP "${completed_label} - $(step_title "${current_step}")"
    run_step "${current_step}"
    log OK "${completed_label} completed"

    next_label=""
    if [[ $((index + 1)) -lt "${#EXECUTION_STEPS[@]}" ]]; then
      next_label="$(step_label_for_number "${EXECUTION_STEPS[$((index + 1))]}")"
    fi
    wait_for_step_confirmation "${completed_label}" "${next_label}"
  done
}

main() {
  ensure_required_commands
  parse_args "$@"
  validate_inputs
  resolve_environment_from_current_host
  load_config
  init_logging
  rotate_logs
  acquire_lock
  trap 'release_lock' EXIT
  trap 'on_error $? $LINENO "$BASH_COMMAND"' ERR
  build_execution_steps
  log_runtime_context
  execute_selected_steps
  log OK "all selected steps completed successfully"
  printf '%s\n' "Log file: ${LOG_FILE}"
  printf '%s\n' "Error file: ${ERROR_LOG_FILE}"
}

main "$@"
