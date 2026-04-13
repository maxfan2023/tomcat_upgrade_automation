#!/usr/bin/env bash

# Automate the target-host Ab Initio co-ops upgrade workflow after the
# installation package has already been copied and unpacked to the host.
#
# This script intentionally mirrors the operator experience of
# generate_co_ops_installation_package.sh:
#   - env-specific settings live in separate config files
#   - steps are resumable with --from-step
#   - commands are printed before execution
#   - logs rotate daily and old files are removed automatically
#   - each step pauses for confirmation unless --auto-continue is used
#
# Notes:
#   - The script is expected to run on the target host itself.
#   - The co-ops version positional argument is optional and defaults to 4.4.3.3.
#   - --debug implies --dry-run to match the prompt requirement that debug mode
#     prints commands without executing them.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." 2>/dev/null && pwd || true)"
REPO_ROOT="${REPO_ROOT:-$(pwd)}"
PROGRAM_NAME="$(basename "$0")"
CONFIG_DIR="${REPO_ROOT}/configs/co_ops/upgrade"

LOG_READY=0
LOCK_DIR=""
ERROR_LOG_FILE=""

CO_OPS_VERSION="4.4.3.3"
CO_OPS_VERSION_DASHED=""
VERSION_TOKEN=""
VERSION_LABEL=""
ENV_NAME_INPUT=""
ENV_NAME=""
CONFIG_FILE=""
CURRENT_HOST=""
CURRENT_HOST_SHORT=""
CURRENT_USER=""

FROM_STEP_RAW="1"
START_STEP=1
DRY_RUN=0
DEBUG=0
AUTO_CONTINUE=0

LOG_DIR="${REPO_ROOT}/logs"
STATE_DIR="${REPO_ROOT}/.state"
LOG_RETENTION_DAYS=90

HOST_SUFFIX=""
ABINITIO_BASE_DIR=""
PROFILE_PREFIX=""
PACKAGE_ENV_LABEL=""
ADMIN_USER=""
BATCH_USER=""
PACKAGE_ROOT=""
MANAGEMENT_PROFILE_DIR=""
JAVA_HOME_TARGET=""
PROFILE_SOURCE_VERSION=""
CO_OPS_UPGRADE_RUNNER_RELATIVE="ai_build_package/scripts/coop-upgrade.ksh"

REMOTE_VERSION_DIR=""
PACKAGE_FILE=""
UPGRADE_RUNNER=""
TARGET_AB_HOME=""
TARGET_PROFILE=""
SOURCE_PROFILE=""
ABINITIORC_FILE=""
ABINITIORC_BACKUP=""
ENV_ROOT=""
TOMCAT_APPS_DIR=""

EXECUTION_STEPS=()

usage() {
  cat <<'EOF'
Usage:
  ./scripts/co_ops/upgrade/upgrade_co_ops_automation.sh [<co_ops_version>] [options]

Summary:
  Run the co-ops upgrade workflow on the target host after the package has been
  copied to /opt/abinitio/tmp/co_ops_<version_without_dots>.
  Examples below assume the current working directory is the repository root.

Positional arguments:
  <co_ops_version>         Optional. Target co-ops version, for example 4.4.3.3
                           or 4-4-3-3
                           Default: 4.4.3.3

Options:
  -c, --config FILE       Optional. Path to the config file.
                          Default: configs/co_ops/upgrade/co_ops_upgrade_<env>.conf
  -e, --env ENV            Optional. One of denv, benv, penv
                           Useful for dry-run preview when env auto-detection is
                           not possible from the current host.
  -s, --from-step STEP     Start from a specific step, for example 4 or step_4
      --auto-continue      Continue automatically after each step
      --dry-run            Print commands only, do not execute them
      --debug              Enable shell tracing and imply --dry-run
      --list-steps         Print the supported steps and exit
  -h, --help               Show this help text

Step list:
  step_1  Detect env and validate runtime paths
  step_2  Verify package and upgrade runner on the target host
  step_3  Run coop-upgrade.ksh -c
  step_4  Validate the upgraded co-ops with admin profile
  step_5  Create the target source profile if needed
  step_6  Update export AB_HOME in the target source profile
  step_7  Backup abinitiorc with the current date suffix
  step_8  Update all AB_JAVA_HOME entries in abinitiorc
  step_9  Validate the upgraded co-ops with the batch profile
  step_10 Archive tomcat 10 directories

Examples:
  ./scripts/co_ops/upgrade/upgrade_co_ops_automation.sh 4.4.3.3 --dry-run
  ./scripts/co_ops/upgrade/upgrade_co_ops_automation.sh --env benv 4.4.3.3 --auto-continue
  ./scripts/co_ops/upgrade/upgrade_co_ops_automation.sh 4-4-3-3 --from-step step_6
  ./scripts/co_ops/upgrade/upgrade_co_ops_automation.sh --env denv --config configs/co_ops/upgrade/co_ops_upgrade_denv.conf 4.4.3.3 --dry-run
EOF
}

print_steps() {
  usage | sed -n '/^Step list:/,$p'
}

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
    1) printf '%s\n' "Detect env and validate runtime paths" ;;
    2) printf '%s\n' "Verify package and upgrade runner" ;;
    3) printf '%s\n' "Run coop-upgrade.ksh -c" ;;
    4) printf '%s\n' "Validate upgraded co-ops with admin profile" ;;
    5) printf '%s\n' "Create the target source profile if needed" ;;
    6) printf '%s\n' "Update export AB_HOME in the target source profile" ;;
    7) printf '%s\n' "Backup abinitiorc" ;;
    8) printf '%s\n' "Update AB_JAVA_HOME in abinitiorc" ;;
    9) printf '%s\n' "Validate upgraded co-ops with batch profile" ;;
    10) printf '%s\n' "Archive tomcat 10 directories" ;;
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

format_display_arg() {
  local arg="$1"
  if printf '%s\n' "${arg}" | LC_ALL=C grep -Eq '^[A-Za-z0-9_./:@%+=, -]+$'; then
    printf '%s' "${arg}"
  else
    printf '"%s"' "${arg}"
  fi
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
  local q=""

  if [[ "${shell_cmd}" == *$'\n'* ]]; then
    printf '%s\n' "${shell_cmd}"
    return 0
  fi

  q="${shell_cmd//\'/\'\\\'\'}"
  printf "bash -lc '%s'" "${q}"
}

run_logged_cmd() {
  local display=""
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

run_shell_cmd() {
  local shell_cmd="$1"
  local display=""
  local cmd_rc=0
  local tee_rc=0
  local err_trap_state=""

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

run_expected_diff_cmd() {
  local left_file="$1"
  local right_file="$2"
  local display=""
  local diff_rc=0
  local tee_rc=0
  local err_trap_state=""

  display="$(display_cmd diff -u "${left_file}" "${right_file}")"
  log CMD "${display}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log DRYRUN "command not executed because --dry-run is enabled"
    return 0
  fi

  err_trap_state="$(trap -p ERR || true)"
  trap - ERR
  set +e
  diff -u "${left_file}" "${right_file}" 2>&1 | tee -a "${LOG_FILE}"
  diff_rc=${PIPESTATUS[0]}
  tee_rc=${PIPESTATUS[1]:-0}
  set -e
  if [[ -n "${err_trap_state}" ]]; then
    eval "${err_trap_state}"
  fi
  if [[ "${tee_rc}" -ne 0 ]]; then
    die "failed to write command output to log while running: ${display}"
  fi
  case "${diff_rc}" in
    1) ;;
    0) die "no change detected between ${left_file} and ${right_file}" ;;
    *) die "diff failed with exit code ${diff_rc}: ${display}" ;;
  esac
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
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log INFO "dry-run mode skips lock creation"
    return 0
  fi
  LOCK_DIR="${STATE_DIR}/.${ENV_NAME}_${CURRENT_HOST_SHORT}_${VERSION_TOKEN}.lock"
  if ! mkdir "${LOCK_DIR}" 2>/dev/null; then
    die "another run is already active for ${ENV_NAME}/${CURRENT_HOST_SHORT}/${CO_OPS_VERSION}: ${LOCK_DIR}"
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
  local commands=(awk bash chmod cmp cp date diff find grep hostname id mkdir mktemp mv rm sed tar tee test)
  local cmd=""

  if [[ "${DRY_RUN}" -eq 0 ]]; then
    commands+=(dzdo)
  fi

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

  if [[ "${#positional[@]}" -gt 1 ]]; then
    usage
    exit 1
  fi

  if [[ "${#positional[@]}" -eq 1 ]]; then
    CO_OPS_VERSION="${positional[0]}"
  fi
}

default_config_file_for_env() {
  local env_name="$1"
  local local_copy="${REPO_ROOT}/co_ops_upgrade_${env_name}.conf"
  local repo_copy="${CONFIG_DIR}/co_ops_upgrade_${env_name}.conf"
  local script_copy="${SCRIPT_DIR}/co_ops_upgrade_${env_name}.conf"
  local derived_repo_copy="${SCRIPT_REPO_ROOT}/configs/co_ops/upgrade/co_ops_upgrade_${env_name}.conf"

  if [[ -f "${local_copy}" ]]; then
    printf '%s\n' "${local_copy}"
    return 0
  fi
  if [[ -f "${repo_copy}" ]]; then
    printf '%s\n' "${repo_copy}"
    return 0
  fi
  if [[ -f "${script_copy}" ]]; then
    printf '%s\n' "${script_copy}"
    return 0
  fi
  printf '%s\n' "${derived_repo_copy}"
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

detect_current_user() {
  id -un
}

validate_inputs() {
  if [[ -n "${ENV_NAME_INPUT}" ]]; then
    case "${ENV_NAME_INPUT}" in
      denv|benv|penv) ;;
      *) die "--env must be one of denv, benv, penv" ;;
    esac
  fi

  [[ "${CO_OPS_VERSION}" =~ ^[0-9]+([.-][0-9]+)+$ ]] || die "invalid co-ops version: ${CO_OPS_VERSION}"
  CO_OPS_VERSION="${CO_OPS_VERSION//-/.}"
  CO_OPS_VERSION_DASHED="${CO_OPS_VERSION//./-}"
  VERSION_TOKEN="${CO_OPS_VERSION//./}"
  VERSION_LABEL="V${CO_OPS_VERSION_DASHED}"
  START_STEP="$(normalize_step "${FROM_STEP_RAW}")" || die "invalid step value: ${FROM_STEP_RAW}"
  [[ "${START_STEP}" -ge 1 && "${START_STEP}" -le 10 ]] || die "--from-step must be between step_1 and step_10"
}

detect_env_from_current_host() {
  CURRENT_HOST="$(detect_current_host)"
  CURRENT_HOST_SHORT="${CURRENT_HOST%%.*}"
  CURRENT_USER="$(detect_current_user)"

  if [[ -n "${ENV_NAME_INPUT}" ]]; then
    ENV_NAME="${ENV_NAME_INPUT}"
    return 0
  fi

  if [[ "${CURRENT_HOST}" == *.hk.hsbc ]]; then
    ENV_NAME="denv"
    return 0
  fi

  if [[ -d "/opt/abinitio/benv/abinitio" && ! -d "/opt/abinitio/penv/abinitio" ]]; then
    ENV_NAME="benv"
    return 0
  fi

  if [[ -d "/opt/abinitio/penv/abinitio" && ! -d "/opt/abinitio/benv/abinitio" ]]; then
    ENV_NAME="penv"
    return 0
  fi

  if [[ -f "/opt/abinitio/tmp/co_ops_${VERSION_TOKEN}/ai_build_package_${CURRENT_HOST_SHORT}_benv.tgz" \
        && ! -f "/opt/abinitio/tmp/co_ops_${VERSION_TOKEN}/ai_build_package_${CURRENT_HOST_SHORT}_penv.tgz" ]]; then
    ENV_NAME="benv"
    return 0
  fi

  if [[ -f "/opt/abinitio/tmp/co_ops_${VERSION_TOKEN}/ai_build_package_${CURRENT_HOST_SHORT}_penv.tgz" \
        && ! -f "/opt/abinitio/tmp/co_ops_${VERSION_TOKEN}/ai_build_package_${CURRENT_HOST_SHORT}_benv.tgz" ]]; then
    ENV_NAME="penv"
    return 0
  fi

  die "unable to detect env from current host ${CURRENT_HOST}. Please pass --env denv|benv|penv."
}

load_config() {
  if [[ -z "${CONFIG_FILE}" ]]; then
    CONFIG_FILE="$(default_config_file_for_env "${ENV_NAME}")"
  fi
  [[ -f "${CONFIG_FILE}" ]] || die "config file not found: ${CONFIG_FILE}"

  # shellcheck disable=SC1090
  source "${CONFIG_FILE}"

  : "${HOST_SUFFIX:?HOST_SUFFIX must be set in ${CONFIG_FILE}}"
  : "${ABINITIO_BASE_DIR:?ABINITIO_BASE_DIR must be set in ${CONFIG_FILE}}"
  : "${PROFILE_PREFIX:?PROFILE_PREFIX must be set in ${CONFIG_FILE}}"
  : "${PACKAGE_ENV_LABEL:?PACKAGE_ENV_LABEL must be set in ${CONFIG_FILE}}"
  : "${ADMIN_USER:?ADMIN_USER must be set in ${CONFIG_FILE}}"
  : "${BATCH_USER:?BATCH_USER must be set in ${CONFIG_FILE}}"
  : "${PACKAGE_ROOT:?PACKAGE_ROOT must be set in ${CONFIG_FILE}}"
  : "${MANAGEMENT_PROFILE_DIR:?MANAGEMENT_PROFILE_DIR must be set in ${CONFIG_FILE}}"
  : "${JAVA_HOME_TARGET:?JAVA_HOME_TARGET must be set in ${CONFIG_FILE}}"
  : "${PROFILE_SOURCE_VERSION:?PROFILE_SOURCE_VERSION must be set in ${CONFIG_FILE}}"

  LOG_DIR="${LOG_DIR:-${REPO_ROOT}/logs}"
  STATE_DIR="${STATE_DIR:-${REPO_ROOT}/.state}"
  LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-90}"
}

derive_runtime_paths() {
  local source_version_label=""

  source_version_label="V${PROFILE_SOURCE_VERSION//./-}"
  REMOTE_VERSION_DIR="${PACKAGE_ROOT}/co_ops_${VERSION_TOKEN}"
  PACKAGE_FILE="${REMOTE_VERSION_DIR}/ai_build_package_${CURRENT_HOST_SHORT}_${PACKAGE_ENV_LABEL}.tgz"
  UPGRADE_RUNNER="${REMOTE_VERSION_DIR}/${CO_OPS_UPGRADE_RUNNER_RELATIVE}"
  TARGET_AB_HOME="${ABINITIO_BASE_DIR}/abinitio-${VERSION_LABEL}"
  TARGET_PROFILE="${MANAGEMENT_PROFILE_DIR}/${PROFILE_PREFIX}-${VERSION_LABEL}"
  SOURCE_PROFILE="${MANAGEMENT_PROFILE_DIR}/${PROFILE_PREFIX}-${source_version_label}"
  ABINITIORC_FILE="${TARGET_AB_HOME}/config/abinitiorc"
  ABINITIORC_BACKUP="${ABINITIORC_FILE}_bkp_$(date +%d%m%Y)"
  ENV_ROOT="${ABINITIO_BASE_DIR%/abinitio}"
  TOMCAT_APPS_DIR="${ENV_ROOT}/abinitio-app-hub/apps"
}

init_logging() {
  mkdir -p "${LOG_DIR}" "${STATE_DIR}"
  LOG_FILE="${LOG_DIR}/co_ops_upgrade_${ENV_NAME}_${CURRENT_HOST_SHORT}_${VERSION_TOKEN}_$(date +%Y%m%d).log"
  ERROR_LOG_FILE="${LOG_FILE%.log}.err"
  : >> "${LOG_FILE}"
  : >> "${ERROR_LOG_FILE}"
  LOG_READY=1

  if [[ "${DEBUG}" -eq 1 ]]; then
    export PS4='+ ${BASH_SOURCE##*/}:${LINENO}: '
    set -x
  fi
}

build_execution_steps() {
  local step=""
  EXECUTION_STEPS=()
  for step in 1 2 3 4 5 6 7 8 9 10; do
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
  log INFO "current user: ${CURRENT_USER}"
  log INFO "environment: ${ENV_NAME}"
  log INFO "co-ops version: ${CO_OPS_VERSION}"
  log INFO "co-ops version label: ${CO_OPS_VERSION_DASHED}"
  log INFO "package directory: ${REMOTE_VERSION_DIR}"
  log INFO "package file: ${PACKAGE_FILE}"
  log INFO "upgrade runner: ${UPGRADE_RUNNER}"
  log INFO "target AB_HOME: ${TARGET_AB_HOME}"
  log INFO "target profile: ${TARGET_PROFILE}"
  log INFO "source profile: ${SOURCE_PROFILE}"
  log INFO "target abinitiorc: ${ABINITIORC_FILE}"
  log INFO "batch user: ${BATCH_USER}"
  if [[ -n "${ENV_NAME_INPUT}" ]]; then
    log INFO "requested env: ${ENV_NAME_INPUT}"
  fi
  if [[ "${DEBUG}" -eq 1 ]]; then
    log WARN "debug mode implies dry-run; commands will not be executed"
  elif [[ "${DRY_RUN}" -eq 1 ]]; then
    log DRYRUN "dry-run mode is enabled. Commands will be printed only."
  fi
}

admin_validation_ready() {
  local shell_cmd=""

  [[ -d "${TARGET_AB_HOME}" ]] || return 1
  printf -v shell_cmd \
    'export AB_HOME=%q && export PATH=%q:$PATH && installation-test >/dev/null 2>&1 && ab-key show >/dev/null 2>&1' \
    "${TARGET_AB_HOME}" \
    "${TARGET_AB_HOME}/bin"
  bash -lc "${shell_cmd}" >/dev/null 2>&1
}

step_1_detect_env_and_validate_runtime() {
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    if [[ "${CURRENT_HOST}" != *"${HOST_SUFFIX}" ]]; then
      log WARN "dry-run mode skips current host suffix enforcement for ${CURRENT_HOST}"
    fi
    if [[ "${CURRENT_USER}" != "${ADMIN_USER}" ]]; then
      log WARN "dry-run mode skips current user enforcement for ${CURRENT_USER}"
    fi
    log INFO "dry-run mode skips filesystem existence checks for target-host runtime paths"
    return 0
  fi

  [[ "${CURRENT_HOST}" == *"${HOST_SUFFIX}" ]] || die "current host ${CURRENT_HOST} does not match env ${ENV_NAME} suffix ${HOST_SUFFIX}"
  [[ "${CURRENT_USER}" == "${ADMIN_USER}" ]] || die "current user must be ${ADMIN_USER} for env ${ENV_NAME}, got ${CURRENT_USER}"
  [[ -d "${ABINITIO_BASE_DIR}" ]] || die "ab initio base directory not found: ${ABINITIO_BASE_DIR}"
  [[ -d "${REMOTE_VERSION_DIR}" ]] || die "package directory not found: ${REMOTE_VERSION_DIR}"
  [[ -d "${MANAGEMENT_PROFILE_DIR}" ]] || die "management profile directory not found: ${MANAGEMENT_PROFILE_DIR}"
  log INFO "runtime validation passed for env ${ENV_NAME}"
}

step_2_verify_package_and_runner() {
  run_logged_cmd test -f "${PACKAGE_FILE}"
  run_logged_cmd test -x "${UPGRADE_RUNNER}"
}

step_3_run_upgrade() {
  local shell_cmd=""

  if [[ "${DRY_RUN}" -eq 0 ]] && admin_validation_ready; then
    log INFO "target version ${CO_OPS_VERSION} already validates under the admin profile; skipping coop-upgrade.ksh for idempotence"
    return 0
  fi

  printf -v shell_cmd 'cd %q && ./ai_build_package/scripts/coop-upgrade.ksh -c' "${REMOTE_VERSION_DIR}"
  run_shell_cmd "${shell_cmd}"
}

step_4_validate_admin_profile() {
  local shell_cmd=""

  printf -v shell_cmd \
    'export AB_HOME=%q && export PATH=%q:$PATH && echo "$PATH" && installation-test && ab-key show' \
    "${TARGET_AB_HOME}" \
    "${TARGET_AB_HOME}/bin"
  run_shell_cmd "${shell_cmd}"
}

step_5_create_target_profile() {
  if [[ -f "${TARGET_PROFILE}" ]]; then
    log INFO "target profile already exists: ${TARGET_PROFILE}"
    return 0
  fi
  run_logged_cmd test -f "${SOURCE_PROFILE}"
  run_logged_cmd cp -p "${SOURCE_PROFILE}" "${TARGET_PROFILE}"
}

step_6_update_target_profile_ab_home() {
  run_logged_cmd \
    grep -Eq '^[[:space:]]*export[[:space:]]+AB_HOME=' "${TARGET_PROFILE}"
  run_logged_cmd \
    sed -E -i "s|^([[:space:]]*export[[:space:]]+AB_HOME=).*$|\1${TARGET_AB_HOME}|" "${TARGET_PROFILE}"
  run_expected_diff_cmd "${SOURCE_PROFILE}" "${TARGET_PROFILE}"
}

step_7_backup_abinitiorc() {
  run_logged_cmd test -f "${ABINITIORC_FILE}"
  if [[ -f "${ABINITIORC_BACKUP}" ]]; then
    log INFO "abinitiorc backup already exists: ${ABINITIORC_BACKUP}"
    return 0
  fi
  run_logged_cmd cp -p "${ABINITIORC_FILE}" "${ABINITIORC_BACKUP}"
}

step_8_update_abinitiorc_java_home() {
  run_logged_cmd \
    grep -Eq '^[[:space:]]*AB_JAVA_HOME([[:space:]]|$)' "${ABINITIORC_FILE}"
  run_logged_cmd \
    sed -E -i "s|^([[:space:]]*AB_JAVA_HOME([[:space:]]*@[^:]+)?[[:space:]]*:[[:space:]]*).*$|\1${JAVA_HOME_TARGET}|" "${ABINITIORC_FILE}"
  run_expected_diff_cmd "${ABINITIORC_FILE}" "${ABINITIORC_BACKUP}"
}

step_9_validate_batch_profile() {
  local shell_cmd=""

  shell_cmd="dzdo /bin/su - ${BATCH_USER} <<'AB_BATCH_VALIDATE'
source ${TARGET_PROFILE}
installation-test
ab-key show
AB_BATCH_VALIDATE"
  run_shell_cmd "${shell_cmd}"
}

archive_tomcat_dir() {
  local source_dir="$1"
  local archive_file="$2"

  if [[ -f "${archive_file}" && ! -d "${source_dir}" ]]; then
    log INFO "archive already exists and source directory is gone: ${archive_file}"
    return 0
  fi

  run_logged_cmd test -d "${source_dir}"
  run_logged_cmd tar -czf "${archive_file}" "${source_dir}"
  run_logged_cmd rm -rf "${source_dir}"
}

step_10_archive_tomcat_10_directories() {
  run_logged_cmd mkdir -p "${TOMCAT_APPS_DIR}"
  archive_tomcat_dir \
    "${TOMCAT_APPS_DIR}/catalina-base-10.1" \
    "${TOMCAT_APPS_DIR}/catalina-base-10.1.tgz"
  archive_tomcat_dir \
    "${TOMCAT_APPS_DIR}/catalina-base-10.1-tmplt" \
    "${TOMCAT_APPS_DIR}/catalina-base-10.1-tmplt.tgz"
  archive_tomcat_dir \
    "${TOMCAT_APPS_DIR}/catalina-home-10.1" \
    "${TOMCAT_APPS_DIR}/catalina-home-10.1.tgz"
  run_logged_cmd ls -lrth "${TOMCAT_APPS_DIR}/"
}

run_step() {
  case "$1" in
    1) step_1_detect_env_and_validate_runtime ;;
    2) step_2_verify_package_and_runner ;;
    3) step_3_run_upgrade ;;
    4) step_4_validate_admin_profile ;;
    5) step_5_create_target_profile ;;
    6) step_6_update_target_profile_ab_home ;;
    7) step_7_backup_abinitiorc ;;
    8) step_8_update_abinitiorc_java_home ;;
    9) step_9_validate_batch_profile ;;
    10) step_10_archive_tomcat_10_directories ;;
    *) die "unknown step: $1" ;;
  esac
}

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
  parse_args "$@"
  ensure_required_commands
  validate_inputs
  detect_env_from_current_host
  load_config
  derive_runtime_paths
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
