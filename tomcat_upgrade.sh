#!/usr/bin/env bash

# Tomcat upgrade automation for the Ab Initio application hub.
#
# What this script does:
#   1. Verifies the Tomcat installer archive.
#   2. Optionally takes a full backup of abinitio-app-hub/apps.
#   3. Backs up the Tomcat 9 directories called out in the runbook.
#   4. Stops services, renames the active Tomcat directories, installs a new version,
#      restores selected content from *_org, validates the result, and starts services.
#
# Design goals:
#   - Keep environment-specific values in a separate config file.
#   - Support dry-run and restart-from-step usage.
#   - Prefer safe defaults: cleanup is opt-in, and risky operations are logged clearly.
#   - Be re-runnable where possible without clobbering successful prior backups.
#
# Common examples:
#   ./tomcat_upgrade.sh --dry-run
#   ./tomcat_upgrade.sh --env ienv --backup-flag yes --dry-run
#   ./tomcat_upgrade.sh --env ienv --version 9.0.117
#   ./tomcat_upgrade.sh --env ienv --from-step step_9
#   ./tomcat_upgrade.sh --env ienv --backup-flag yes --cleanup
#
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROGRAM_NAME="$(basename "$0")"
LOG_READY=0
LOCK_DIR=""
LAST_CAPTURED_OUTPUT=""

DEFAULT_CONFIG_FILE="${SCRIPT_DIR}/configs/default.conf"
DEFAULT_STEPS=(1 2 3 4 5 6 7 8 9 10 11)
CLEANUP_STEPS=(13 14)
RUNTIME_SUBDIRS=(conf logs temp webapps work)
RESTORE_COMPARE_DIRS=(logs temp work)
FULL_APPS_BACKUP_PREFIX="apps_full_backup"
MANAGED_HOME_FILES=(catalina.bat catalina.sh)
MANAGED_BASE_CONF_FILES=(logging.properties web.xml server.xml)
MANAGED_TMPLT_CONF_FILES=(logging.properties web.xml server.xml)
MANAGED_TOMCAT_DIR_NAMES=()

CONFIG_FILE="${DEFAULT_CONFIG_FILE}"
SELECTED_ENVS_CSV=""
CLI_TARGET_VERSION=""
FROM_STEP_RAW="1"
DRY_RUN=0
DEBUG=0
DO_CLEANUP=0
LIST_STEPS=0
BACKUP_FLAG="no"

SELECTED_ENVS=()
FILESYSTEM_ENVS=()
EXECUTION_STEPS=()
RUN_DATE_DDMMYYYY="$(date +%d%m%Y)"
RUN_DATE_YYYYMMDD="$(date +%Y%m%d)"
START_STEP=1

usage() {
  cat <<'EOF'
Usage:
  ./tomcat_upgrade.sh [options]

Summary:
  This script automates a configurable Tomcat upgrade workflow.
  It reads environment-specific values from a shell config file, prints every
  command before it runs, and can restart from a later step when needed.

Options:
  -c, --config FILE        Path to the config file. Defaults to configs/default.conf
  -e, --env LIST           Comma-separated logical env list, for example ienv,denv
  -v, --version VERSION    Target Tomcat version, for example 9.0.116
  -s, --from-step STEP     Start from a specific step, for example 9 or step_9
      --dry-run            Print what would run, but do not execute commands
      --debug              Enable shell tracing after logging starts
      --backup-flag FLAG   yes|no. When yes, back up the whole apps directory before step 2
      --cleanup            Also execute step 13 and step 14
      --list-steps         Print the supported steps and exit
  -h, --help               Show this help text

Notes:
  - By default the script runs step 1 through step 11.
  - When --backup-flag yes is used, an extra full apps backup runs between step 1 and step 2.
  - Cleanup is opt-in because deleting *_org and backup archives removes rollback assets.
  - The config file is a shell file and is sourced directly by this script.
  - penv-cont reuses penv filesystem paths by default, but skips service stop/start.
  - The script uses the current date in DDMMYYYY format when naming backup directories.

Typical commands:
  1. Safest first pass in a dev environment
     ./tomcat_upgrade.sh --env ienv --backup-flag yes --dry-run

  2. Real run for one environment with the extra full apps backup
     ./tomcat_upgrade.sh --env ienv --backup-flag yes

  3. Resume from a later step after manual review
     ./tomcat_upgrade.sh --env ienv --from-step step_9

  4. Upgrade to a different Tomcat version
     ./tomcat_upgrade.sh --env ienv --version 9.0.117 --backup-flag yes

  5. Explicit cleanup after validation
     ./tomcat_upgrade.sh --env ienv --cleanup
EOF
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

print_steps() {
  cat <<'EOF'
step_1   Verify the Tomcat installer archive exists
step_1.5 Optional full backup of abinitio-app-hub/apps when --backup-flag yes
step_2   Back up current Tomcat directories and create tar.gz archives
step_3   Stop managed application services
step_4   Rename current Tomcat directories to *_org
step_5   Install the target Tomcat version with ab-app
step_6   Verify the installed version and required Tomcat directories
step_7   Restore managed files in catalina-home-9.0/bin
step_8   Restore managed files in catalina-base-9.0
step_9   Restore managed files in catalina-base-9.0-tmplt
step_10  Compare managed restored content against *_org
step_11  Purge runtime folders under app instances and start services
step_13  Remove *_org Tomcat directories (only with --cleanup)
step_14  Remove dated backup archives (only with --cleanup)
EOF
}

die() {
  local message="${1:-Unknown error}"
  if [[ "${LOG_READY}" -eq 1 ]]; then
    log ERROR "${message}"
  else
    printf 'ERROR: %s\n' "${message}" >&2
  fi
  exit 1
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
    SKIP) emoji="⏭️ " ;;
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

log_info() { log INFO "$*"; }
log_ok() { log OK "$*"; }
log_warn() { log WARN "$*"; }
log_error() { log ERROR "$*"; }
log_cmd() { log CMD "$*"; }
log_skip() { log SKIP "$*"; }
log_dryrun() { log DRYRUN "$*"; }

emit_plain_line() {
  local text="${1:-}"
  if [[ "${LOG_READY}" -eq 1 ]]; then
    printf '%s\n' "${text}" | tee -a "${LOG_FILE}"
  else
    printf '%s\n' "${text}"
  fi
}

log_step_banner() {
  local message="$1"
  emit_plain_line ""
  emit_plain_line "############################################################"
  emit_plain_line "### ${message}"
  emit_plain_line "############################################################"
  emit_plain_line ""
}

log_step() {
  log_step_banner "$*"
  log STEP "$*"
}

log_step_done() {
  log OK "$*"
  log_step_banner "$*"
}

quote_cmd() {
  local quoted=()
  local arg=""
  for arg in "$@"; do
    printf -v arg '%q' "${arg}"
    quoted+=("${arg}")
  done
  printf '%s' "${quoted[*]}"
}

run_logged_cmd() {
  local display
  display="$(quote_cmd "$@")"
  log_cmd "${display}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    return 0
  fi
  if [[ "${LOG_READY}" -eq 1 ]]; then
    "$@" 2>&1 | tee -a "${LOG_FILE}"
  else
    "$@"
  fi
}

run_shell_cmd() {
  local shell_cmd="$1"
  local display
  printf -v display 'bash -lc %q' "${shell_cmd}"
  log_cmd "${display}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    return 0
  fi
  if [[ "${LOG_READY}" -eq 1 ]]; then
    bash -lc "${shell_cmd}" 2>&1 | tee -a "${LOG_FILE}"
  else
    bash -lc "${shell_cmd}"
  fi
}

run_cmd_capture() {
  local display="$1"
  shift
  local output=""
  local rc=0
  log_cmd "${display}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    LAST_CAPTURED_OUTPUT=""
    return 0
  fi

  set +e
  output="$("$@" 2>&1)"
  rc=$?
  set -e

  LAST_CAPTURED_OUTPUT="${output}"
  if [[ -n "${output}" ]]; then
    if [[ "${LOG_READY}" -eq 1 ]]; then
      printf '%s\n' "${output}" | tee -a "${LOG_FILE}"
    else
      printf '%s\n' "${output}"
    fi
  fi
  return "${rc}"
}

safe_env_name() {
  local env_name="$1"
  env_name="${env_name//-/_}"
  printf '%s\n' "${env_name}"
}

config_get() {
  local prefix="$1"
  local env_name="$2"
  local safe_name
  local var_name
  safe_name="$(safe_env_name "${env_name}")"
  var_name="${prefix}__${safe_name}"
  printf '%s' "${!var_name:-}"
}

config_has() {
  local prefix="$1"
  local env_name="$2"
  [[ -n "$(config_get "${prefix}" "${env_name}")" ]]
}

contains_value() {
  local needle="$1"
  shift || true
  local item=""
  for item in "$@"; do
    if [[ "${item}" == "${needle}" ]]; then
      return 0
    fi
  done
  return 1
}

append_unique() {
  local value="$1"
  shift
  local -a current=("$@")
  if contains_value "${value}" "${current[@]}"; then
    printf '%s\n' "${current[*]}"
    return 0
  fi
  current+=("${value}")
  printf '%s\n' "${current[*]}"
}

join_by() {
  local delimiter="$1"
  shift || true
  local result=""
  local item=""
  for item in "$@"; do
    if [[ -z "${result}" ]]; then
      result="${item}"
    else
      result="${result}${delimiter}${item}"
    fi
  done
  printf '%s\n' "${result}"
}

trim_trailing_slash() {
  local path="$1"
  while [[ "${path}" != "/" && "${path}" == */ ]]; do
    path="${path%/}"
  done
  printf '%s\n' "${path}"
}

assert_safe_path() {
  local path
  local root
  path="$(trim_trailing_slash "$1")"
  root="$(trim_trailing_slash "$2")"
  [[ -n "${path}" ]] || die "Refusing to operate on an empty path"
  [[ -n "${root}" ]] || die "Refusing to use an empty safety root"
  [[ "${path}" != "/" ]] || die "Refusing to operate on /"
  case "${path}" in
    "${root}"/*) ;;
    *) die "Refusing to operate on '${path}' because it is outside '${root}'" ;;
  esac
}

require_command() {
  local cmd="$1"
  command -v "${cmd}" >/dev/null 2>&1 || die "Required command not found: ${cmd}"
}

ensure_required_commands() {
  local commands=(bash cp mv tar diff cmp find date mkdir rm tee)
  local cmd=""
  for cmd in "${commands[@]}"; do
    require_command "${cmd}"
  done
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c|--config)
        [[ $# -ge 2 ]] || die "Missing value for $1"
        CONFIG_FILE="$2"
        shift 2
        ;;
      -e|--env)
        [[ $# -ge 2 ]] || die "Missing value for $1"
        SELECTED_ENVS_CSV="$2"
        shift 2
        ;;
      -v|--version)
        [[ $# -ge 2 ]] || die "Missing value for $1"
        CLI_TARGET_VERSION="$2"
        shift 2
        ;;
      -s|--from-step)
        [[ $# -ge 2 ]] || die "Missing value for $1"
        FROM_STEP_RAW="$2"
        shift 2
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --debug)
        DEBUG=1
        shift
        ;;
      --backup-flag)
        [[ $# -ge 2 ]] || die "Missing value for $1"
        BACKUP_FLAG="$2"
        shift 2
        ;;
      --cleanup)
        DO_CLEANUP=1
        shift
        ;;
      --list-steps)
        LIST_STEPS=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
  done
}

# Load and validate the shell-style config file. The config is sourced directly
# so that arrays and path expressions can stay simple for operators to maintain.
load_config() {
  [[ -f "${CONFIG_FILE}" ]] || die "Config file not found: ${CONFIG_FILE}"
  # shellcheck disable=SC1090
  source "${CONFIG_FILE}"

  : "${DEFAULT_TOMCAT_VERSION:?DEFAULT_TOMCAT_VERSION must be set in the config file}"
  : "${SOFTWARE_TOMCAT_ROOT:?SOFTWARE_TOMCAT_ROOT must be set in the config file}"
  : "${ABINITIO_TMP_DIR:?ABINITIO_TMP_DIR must be set in the config file}"
  : "${APPS_SUBDIR:?APPS_SUBDIR must be set in the config file}"
  : "${LOG_DIR:?LOG_DIR must be set in the config file}"
  : "${STATE_DIR:?STATE_DIR must be set in the config file}"
  : "${CATA_HOME_DIR_NAME:?CATA_HOME_DIR_NAME must be set in the config file}"
  : "${CATA_BASE_DIR_NAME:?CATA_BASE_DIR_NAME must be set in the config file}"
  : "${CATA_BASE_TMPLT_DIR_NAME:?CATA_BASE_TMPLT_DIR_NAME must be set in the config file}"
  : "${ENVIRONMENTS:?ENVIRONMENTS must be set in the config file}"

  LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-90}"
  SHELL_EXECUTABLE="${SHELL_EXECUTABLE:-bash}"
  CLI_TARGET_VERSION="${CLI_TARGET_VERSION:-}"
  TARGET_VERSION="${CLI_TARGET_VERSION:-${DEFAULT_TOMCAT_VERSION}}"
  MANAGED_TOMCAT_DIR_NAMES=("${CATA_HOME_DIR_NAME}" "${CATA_BASE_TMPLT_DIR_NAME}" "${CATA_BASE_DIR_NAME}")
  BACKUP_FLAG="$(printf '%s' "${BACKUP_FLAG}" | tr '[:upper:]' '[:lower:]')"
  case "${BACKUP_FLAG}" in
    yes|no) ;;
    *) die "--backup-flag must be either yes or no" ;;
  esac
}

init_logging() {
  mkdir -p "${LOG_DIR}" "${STATE_DIR}"
  LOG_FILE="${LOG_DIR}/tomcat_upgrade_${TARGET_VERSION}_${RUN_DATE_YYYYMMDD}.log"
  : >> "${LOG_FILE}"
  LOG_READY=1

  if [[ "${DEBUG}" -eq 1 ]]; then
    export PS4='+ ${BASH_SOURCE##*/}:${LINENO}: '
    set -x
  fi
}

rotate_logs() {
  local cmd_display=""
  printf -v cmd_display 'find %q -type f -name %q -mtime +%q -print -delete' \
    "${LOG_DIR}" "*.log" "${LOG_RETENTION_DAYS}"
  log_cmd "${cmd_display}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    return 0
  fi
  find "${LOG_DIR}" -type f -name '*.log' -mtime +"${LOG_RETENTION_DAYS}" -print -delete || true
}

acquire_lock() {
  local config_name
  config_name="$(basename "${CONFIG_FILE}")"
  LOCK_DIR="${STATE_DIR}/.${config_name}.lock"
  if ! mkdir "${LOCK_DIR}" 2>/dev/null; then
    die "Another run appears to be active. Lock directory exists: ${LOCK_DIR}"
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
    log_error "Command failed at line ${line} with exit code ${rc}: ${command}"
  else
    printf 'ERROR: Command failed at line %s with exit code %s: %s\n' "${line}" "${rc}" "${command}" >&2
  fi
  exit "${rc}"
}

# Resolve logical envs to the filesystem targets we will actually touch.
# This matters for penv-cont because it intentionally points at the same
# filesystem layout as penv while keeping different service-control behavior.
validate_envs() {
  local env_name=""
  local file_env=""

  if [[ -n "${SELECTED_ENVS_CSV}" ]]; then
    IFS=',' read -r -a SELECTED_ENVS <<< "${SELECTED_ENVS_CSV}"
  else
    SELECTED_ENVS=("${ENVIRONMENTS[@]}")
  fi

  [[ "${#SELECTED_ENVS[@]}" -gt 0 ]] || die "No environments selected"

  for env_name in "${SELECTED_ENVS[@]}"; do
    contains_value "${env_name}" "${ENVIRONMENTS[@]}" || die "Unknown env in selection: ${env_name}"

    [[ -n "$(config_get ENV_BASE_DIR "${env_name}")" ]] || die "ENV_BASE_DIR is missing for ${env_name}"
    [[ -n "$(config_get ENV_PROFILE "${env_name}")" ]] || die "ENV_PROFILE is missing for ${env_name}"
    if [[ -z "$(config_get ENV_SHOULD_CONTROL_SERVICE "${env_name}")" ]]; then
      die "ENV_SHOULD_CONTROL_SERVICE is missing for ${env_name}"
    fi

    file_env="$(config_get ENV_FILESYSTEM_KEY "${env_name}")"
    file_env="${file_env:-${env_name}}"

    [[ -n "$(config_get ENV_BASE_DIR "${file_env}")" ]] || die "ENV_BASE_DIR is missing for filesystem target ${file_env}"
    [[ -n "$(config_get ENV_PROFILE "${file_env}")" ]] || die "ENV_PROFILE is missing for filesystem target ${file_env}"

    if [[ "${#FILESYSTEM_ENVS[@]}" -eq 0 ]] || ! contains_value "${file_env}" "${FILESYSTEM_ENVS[@]:-}"; then
      FILESYSTEM_ENVS+=("${file_env}")
    fi
  done
}

# Build the ordered list of steps for this run. We keep the original step
# numbers from the runbook so that --from-step remains intuitive for operators.
build_execution_steps() {
  local base_steps=("${DEFAULT_STEPS[@]}")
  local cleanup_step=""
  START_STEP="$(normalize_step "${FROM_STEP_RAW}")" || die "Invalid step value: ${FROM_STEP_RAW}"

  if [[ "${DO_CLEANUP}" -eq 1 ]]; then
    for cleanup_step in "${CLEANUP_STEPS[@]}"; do
      base_steps+=("${cleanup_step}")
    done
  fi

  if [[ "${START_STEP}" -ge 13 && "${DO_CLEANUP}" -ne 1 ]]; then
    die "Starting from step ${START_STEP} requires --cleanup"
  fi

  EXECUTION_STEPS=()
  for cleanup_step in "${base_steps[@]}"; do
    if [[ "${cleanup_step}" -ge "${START_STEP}" ]]; then
      EXECUTION_STEPS+=("${cleanup_step}")
    fi
  done

  [[ "${#EXECUTION_STEPS[@]}" -gt 0 ]] || die "No steps selected for execution"
}

installer_tarball_path() {
  printf '%s/%s/apache-tomcat-%s.tar.gz\n' "${SOFTWARE_TOMCAT_ROOT}" "${TARGET_VERSION}" "${TARGET_VERSION}"
}

apps_dir_for_env() {
  local env_name="$1"
  local base_dir
  base_dir="$(config_get ENV_BASE_DIR "${env_name}")"
  printf '%s/%s\n' "${base_dir}" "${APPS_SUBDIR}"
}

apps_hub_dir_for_env() {
  dirname "$(apps_dir_for_env "$1")"
}

full_apps_backup_dir_for_env() {
  local env_name="$1"
  local hub_dir
  hub_dir="$(apps_hub_dir_for_env "${env_name}")"
  printf '%s/%s_%s\n' "${hub_dir}" "${FULL_APPS_BACKUP_PREFIX}" "${RUN_DATE_DDMMYYYY}"
}

managed_tomcat_dir_path_for_env() {
  local env_name="$1"
  local dir_name="$2"
  printf '%s/%s\n' "$(apps_dir_for_env "${env_name}")" "${dir_name}"
}

managed_tomcat_org_dir_path_for_env() {
  local env_name="$1"
  local dir_name="$2"
  org_dir_path "$(managed_tomcat_dir_path_for_env "${env_name}" "${dir_name}")"
}

managed_tomcat_backup_dir_path_for_env() {
  local env_name="$1"
  local dir_name="$2"
  dated_backup_path "$(managed_tomcat_dir_path_for_env "${env_name}" "${dir_name}")"
}

profile_for_env() {
  config_get ENV_PROFILE "$1"
}

runner_for_env() {
  config_get ENV_RUNNER "$1"
}

service_control_enabled() {
  [[ "$(config_get ENV_SHOULD_CONTROL_SERVICE "$1")" == "yes" ]]
}

purge_targets_for_env() {
  printf '%s\n' "$(config_get ENV_APP_PURGE_TARGETS "$1")"
}

optional_hook_for_env() {
  config_get "$1" "$2"
}

org_dir_path() {
  printf '%s_org\n' "$1"
}

dated_backup_path() {
  printf '%s_%s\n' "$1" "${RUN_DATE_DDMMYYYY}"
}

ensure_dir_exists() {
  local dir_path="$1"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_cmd "$(quote_cmd test -d "${dir_path}")"
    return 0
  fi
  [[ -d "${dir_path}" ]] || die "Expected directory is missing: ${dir_path}"
}

ensure_file_exists() {
  local file_path="$1"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_cmd "$(quote_cmd test -f "${file_path}")"
    return 0
  fi
  [[ -f "${file_path}" ]] || die "Expected file is missing: ${file_path}"
}

ensure_any_dir_exists() {
  local primary="$1"
  local secondary="$2"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_cmd "test -d $(quote_cmd "${primary}") || test -d $(quote_cmd "${secondary}")"
    return 0
  fi
  if [[ ! -d "${primary}" && ! -d "${secondary}" ]]; then
    die "Neither '${primary}' nor '${secondary}' exists"
  fi
}

current_version_matches() {
  local env_name="$1"
  local version_script
  version_script="$(apps_dir_for_env "${env_name}")/${CATA_HOME_DIR_NAME}/bin/version.sh"
  if [[ ! -x "${version_script}" ]]; then
    return 1
  fi
  run_cmd_capture "$(quote_cmd "${version_script}")" "${version_script}" || return 1
  [[ "${LAST_CAPTURED_OUTPUT}" == *"${TARGET_VERSION}"* ]]
}

verify_version_for_env() {
  local env_name="$1"
  local version_script
  version_script="$(apps_dir_for_env "${env_name}")/${CATA_HOME_DIR_NAME}/bin/version.sh"
  log_info "Verifying Tomcat version for filesystem target '${env_name}'"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_cmd "$(quote_cmd "${version_script}")"
    return 0
  fi

  ensure_file_exists "${version_script}"
  run_cmd_capture "$(quote_cmd "${version_script}")" "${version_script}" || die "Failed to execute ${version_script}"
  [[ "${LAST_CAPTURED_OUTPUT}" == *"${TARGET_VERSION}"* ]] || die "Tomcat version check failed for ${env_name}. Output did not contain ${TARGET_VERSION}"
}

verify_required_dirs_for_env() {
  local env_name="$1"
  local dir_name=""

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    for dir_name in "${MANAGED_TOMCAT_DIR_NAMES[@]}"; do
      log_cmd "$(quote_cmd test -d "$(managed_tomcat_dir_path_for_env "${env_name}" "${dir_name}")")"
    done
    return 0
  fi

  for dir_name in "${MANAGED_TOMCAT_DIR_NAMES[@]}"; do
    ensure_dir_exists "$(managed_tomcat_dir_path_for_env "${env_name}" "${dir_name}")"
  done
}

backup_directory_if_needed() {
  local source_dir="$1"
  local backup_dir="$2"
  local fallback_source
  fallback_source="$(org_dir_path "${source_dir}")"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_cmd "cp -a $(quote_cmd "${source_dir}") $(quote_cmd "${backup_dir}") # falls back to $(quote_cmd "${fallback_source}") if needed at runtime"
    return 0
  fi

  if [[ -d "${backup_dir}" ]]; then
    log_skip "Backup already exists, skipping: ${backup_dir}"
    return 0
  fi

  if [[ -d "${source_dir}" ]]; then
    run_logged_cmd cp -a "${source_dir}" "${backup_dir}"
    return 0
  fi

  if [[ -d "${fallback_source}" ]]; then
    log_warn "Primary source ${source_dir} is missing; backing up from ${fallback_source}"
    run_logged_cmd cp -a "${fallback_source}" "${backup_dir}"
    return 0
  fi

  die "Cannot back up ${source_dir}; neither the original nor ${fallback_source} exists"
}

archive_directory_if_needed() {
  local backup_dir="$1"
  local archive_file="${backup_dir}.tar.gz"
  local parent_dir=""
  local base_name=""

  if [[ -f "${archive_file}" ]]; then
    log_skip "Archive already exists, skipping: ${archive_file}"
    return 0
  fi

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    parent_dir="$(dirname "${backup_dir}")"
    base_name="$(basename "${backup_dir}")"
    log_cmd "$(quote_cmd tar -czf "${archive_file}" -C "${parent_dir}" "${base_name}")"
    return 0
  fi

  ensure_dir_exists "${backup_dir}"
  parent_dir="$(dirname "${backup_dir}")"
  base_name="$(basename "${backup_dir}")"
  run_logged_cmd tar -czf "${archive_file}" -C "${parent_dir}" "${base_name}"
}

# Optional safety net backup for the whole apps directory. This is intended for
# cautious testing in shared environments where a broader rollback point helps.
backup_full_apps_dir_if_needed() {
  local env_name="$1"
  local apps_dir=""
  local backup_dir=""

  apps_dir="$(apps_dir_for_env "${env_name}")"
  backup_dir="$(full_apps_backup_dir_for_env "${env_name}")"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_cmd "$(quote_cmd cp -a "${apps_dir}" "${backup_dir}")"
    return 0
  fi

  if [[ -d "${backup_dir}" ]]; then
    log_skip "Full apps backup already exists, skipping: ${backup_dir}"
  else
    ensure_dir_exists "${apps_dir}"
    run_logged_cmd cp -a "${apps_dir}" "${backup_dir}"
  fi
}

rename_to_org_if_needed() {
  local current_dir="$1"
  local org_dir
  org_dir="$(org_dir_path "${current_dir}")"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_cmd "$(quote_cmd mv "${current_dir}" "${org_dir}")"
    return 0
  fi

  if [[ -d "${current_dir}" && ! -e "${org_dir}" ]]; then
    run_logged_cmd mv "${current_dir}" "${org_dir}"
    return 0
  fi

  if [[ -d "${org_dir}" && ! -e "${current_dir}" ]]; then
    log_skip "Rename already completed, skipping: ${current_dir} -> ${org_dir}"
    return 0
  fi

  if [[ -d "${org_dir}" && -e "${current_dir}" ]]; then
    log_skip "Both current and _org directories exist. Assuming the rename step already ran: ${current_dir}"
    return 0
  fi

  die "Cannot rename ${current_dir}; neither the current nor the _org directory exists"
}

backup_managed_tomcat_dirs_for_env() {
  local env_name="$1"
  local dir_name=""
  local source_dir=""
  local backup_dir=""

  for dir_name in "${MANAGED_TOMCAT_DIR_NAMES[@]}"; do
    source_dir="$(managed_tomcat_dir_path_for_env "${env_name}" "${dir_name}")"
    backup_dir="$(managed_tomcat_backup_dir_path_for_env "${env_name}" "${dir_name}")"
    backup_directory_if_needed "${source_dir}" "${backup_dir}"
    archive_directory_if_needed "${backup_dir}"
  done
}

rename_managed_tomcat_dirs_for_env() {
  local env_name="$1"
  local dir_name=""

  for dir_name in "${MANAGED_TOMCAT_DIR_NAMES[@]}"; do
    rename_to_org_if_needed "$(managed_tomcat_dir_path_for_env "${env_name}" "${dir_name}")"
  done
}

required_dir_state() {
  local env_name="$1"
  local apps_dir
  local home_dir
  local base_dir
  local tmplt_dir
  apps_dir="$(apps_dir_for_env "${env_name}")"
  home_dir="${apps_dir}/${CATA_HOME_DIR_NAME}"
  base_dir="${apps_dir}/${CATA_BASE_DIR_NAME}"
  tmplt_dir="${apps_dir}/${CATA_BASE_TMPLT_DIR_NAME}"

  if [[ -d "${home_dir}" && -d "${base_dir}" && -d "${tmplt_dir}" ]]; then
    printf '%s\n' "all"
    return 0
  fi

  if [[ ! -e "${home_dir}" && ! -e "${base_dir}" && ! -e "${tmplt_dir}" ]]; then
    printf '%s\n' "none"
    return 0
  fi

  printf '%s\n' "partial"
}

run_profile_command() {
  local env_name="$1"
  local cwd="$2"
  shift 2
  local command_string="$*"
  local profile
  local shell_cmd
  profile="$(profile_for_env "${env_name}")"
  printf -v shell_cmd 'source %q && cd %q && %s' "${profile}" "${cwd}" "${command_string}"
  run_shell_cmd "${shell_cmd}"
}

run_optional_hook() {
  local hook_prefix="$1"
  local env_name="$2"
  local hook_cmd=""
  hook_cmd="$(optional_hook_for_env "${hook_prefix}" "${env_name}")"
  if [[ -z "${hook_cmd}" ]]; then
    return 0
  fi
  log_info "Running optional hook ${hook_prefix} for ${env_name}"
  run_shell_cmd "${hook_cmd}"
}

sync_file_if_needed() {
  local source_file="$1"
  local target_file="$2"
  local label="$3"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_cmd "cmp -s $(quote_cmd "${source_file}") $(quote_cmd "${target_file}") || cp -p $(quote_cmd "${source_file}") $(quote_cmd "${target_file}")"
    return 0
  fi

  ensure_file_exists "${source_file}"

  if [[ -f "${target_file}" ]] && cmp -s "${source_file}" "${target_file}"; then
    log_skip "${label} is already synchronized"
    return 0
  fi

  run_logged_cmd cp -p "${source_file}" "${target_file}"
}

sync_conf_file_set_if_needed() {
  local source_conf_dir="$1"
  local target_conf_dir="$2"
  local label_prefix="$3"
  shift 3
  local file_name=""

  for file_name in "$@"; do
    sync_file_if_needed \
      "${source_conf_dir}/${file_name}" \
      "${target_conf_dir}/${file_name}" \
      "${label_prefix}/conf/${file_name}"
  done
}

# Synchronize a managed directory by replacing the target tree when differences
# are detected. We do a full tree replace instead of copying only changed files
# so that step 10 directory comparisons can converge to a clean match.
sync_directory_tree_if_needed() {
  local source_dir="$1"
  local target_dir="$2"
  local label="$3"
  local safety_root="$4"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_cmd "diff -qr $(quote_cmd "${source_dir}") $(quote_cmd "${target_dir}") >/dev/null || { rm -rf $(quote_cmd "${target_dir}") && cp -a $(quote_cmd "${source_dir}") $(quote_cmd "${target_dir}"); }"
    return 0
  fi

  if [[ ! -d "${source_dir}" ]]; then
    die "Expected source directory for ${label} is missing: ${source_dir}"
  fi

  if [[ -d "${target_dir}" ]] && diff -qr "${source_dir}" "${target_dir}" >/dev/null 2>&1; then
    log_skip "${label} is already synchronized"
    return 0
  fi

  assert_safe_path "${target_dir}" "${safety_root}"
  if [[ -e "${target_dir}" || -L "${target_dir}" ]]; then
    run_logged_cmd rm -rf "${target_dir}"
  fi
  run_logged_cmd cp -a "${source_dir}" "${target_dir}"
}

sync_runtime_dirs_if_needed() {
  local apps_dir="$1"
  local target_root="$2"
  local source_root="$3"
  local label_prefix="$4"
  local runtime_dir=""

  for runtime_dir in "${RESTORE_COMPARE_DIRS[@]}"; do
    sync_directory_tree_if_needed \
      "${source_root}/${runtime_dir}" \
      "${target_root}/${runtime_dir}" \
      "${label_prefix}/${runtime_dir}" \
      "${apps_dir}"
  done
}

assert_files_identical() {
  local left="$1"
  local right="$2"
  local label="$3"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_cmd "$(quote_cmd cmp -s "${left}" "${right}")"
    return 0
  fi

  ensure_file_exists "${left}"
  ensure_file_exists "${right}"
  cmp -s "${left}" "${right}" || die "Verification failed for ${label}: ${left} differs from ${right}"
  log_ok "${label} matches"
}

assert_directories_identical() {
  local left="$1"
  local right="$2"
  local label="$3"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_cmd "$(quote_cmd diff -qr "${left}" "${right}")"
    return 0
  fi

  if [[ ! -d "${left}" || ! -d "${right}" ]]; then
    die "Verification failed for ${label}: directory missing between ${left} and ${right}"
  fi

  diff -qr "${left}" "${right}" >/dev/null 2>&1 || die "Verification failed for ${label}: ${left} differs from ${right}"
  log_ok "${label} matches"
}

assert_conf_file_set_identical() {
  local source_conf_dir="$1"
  local target_conf_dir="$2"
  local label_prefix="$3"
  shift 3
  local file_name=""

  for file_name in "$@"; do
    assert_files_identical \
      "${source_conf_dir}/${file_name}" \
      "${target_conf_dir}/${file_name}" \
      "${label_prefix}/conf/${file_name}"
  done
}

assert_runtime_dirs_identical() {
  local source_root="$1"
  local target_root="$2"
  local label_prefix="$3"
  local runtime_dir=""

  for runtime_dir in "${RESTORE_COMPARE_DIRS[@]}"; do
    assert_directories_identical \
      "${source_root}/${runtime_dir}" \
      "${target_root}/${runtime_dir}" \
      "${label_prefix}/${runtime_dir}"
  done
}

restore_managed_tree_for_env() {
  local env_name="$1"
  local dir_name="$2"
  local include_catalina="$3"
  shift 3
  local conf_files=("$@")
  local apps_dir=""
  local current_root=""
  local org_root=""
  local current_conf=""
  local org_conf=""
  local label_prefix=""

  apps_dir="$(apps_dir_for_env "${env_name}")"
  current_root="$(managed_tomcat_dir_path_for_env "${env_name}" "${dir_name}")"
  org_root="$(managed_tomcat_org_dir_path_for_env "${env_name}" "${dir_name}")"
  current_conf="${current_root}/conf"
  org_conf="${org_root}/conf"
  label_prefix="${env_name}:${dir_name}"

  sync_conf_file_set_if_needed "${org_conf}" "${current_conf}" "${label_prefix}" "${conf_files[@]}"

  if [[ "${include_catalina}" == "yes" ]]; then
    sync_directory_tree_if_needed "${org_conf}/Catalina" "${current_conf}/Catalina" "${label_prefix}/conf/Catalina" "${apps_dir}"
  fi

  sync_directory_tree_if_needed "${org_root}/webapps" "${current_root}/webapps" "${label_prefix}/webapps" "${apps_dir}"
  sync_runtime_dirs_if_needed "${apps_dir}" "${current_root}" "${org_root}" "${label_prefix}"
}

verify_managed_tree_for_env() {
  local env_name="$1"
  local dir_name="$2"
  local include_catalina="$3"
  shift 3
  local conf_files=("$@")
  local current_root=""
  local org_root=""
  local current_conf=""
  local org_conf=""
  local label_prefix=""

  current_root="$(managed_tomcat_dir_path_for_env "${env_name}" "${dir_name}")"
  org_root="$(managed_tomcat_org_dir_path_for_env "${env_name}" "${dir_name}")"
  current_conf="${current_root}/conf"
  org_conf="${org_root}/conf"
  label_prefix="${env_name}:${dir_name}"

  assert_conf_file_set_identical "${org_conf}" "${current_conf}" "${label_prefix}" "${conf_files[@]}"

  if [[ "${include_catalina}" == "yes" ]]; then
    if [[ "${DRY_RUN}" -eq 1 || -d "${org_conf}/Catalina" || -d "${current_conf}/Catalina" ]]; then
      assert_directories_identical "${org_conf}/Catalina" "${current_conf}/Catalina" "${label_prefix}/conf/Catalina"
    fi
  fi

  assert_directories_identical "${org_root}/webapps" "${current_root}/webapps" "${label_prefix}/webapps"
  assert_runtime_dirs_identical "${org_root}" "${current_root}" "${label_prefix}"
}

cleanup_org_dirs_for_env() {
  local env_name="$1"
  local apps_dir
  local dir_name=""

  apps_dir="$(apps_dir_for_env "${env_name}")"
  for dir_name in "${MANAGED_TOMCAT_DIR_NAMES[@]}"; do
    remove_path_if_exists "$(managed_tomcat_org_dir_path_for_env "${env_name}" "${dir_name}")" "${apps_dir}"
  done
}

cleanup_archive_files_for_env() {
  local env_name="$1"
  local apps_dir
  local dir_name=""
  local archive_path=""

  apps_dir="$(apps_dir_for_env "${env_name}")"
  for dir_name in "${MANAGED_TOMCAT_DIR_NAMES[@]}"; do
    archive_path="$(managed_tomcat_backup_dir_path_for_env "${env_name}" "${dir_name}").tar.gz"
    remove_path_if_exists "${archive_path}" "${apps_dir}"
  done
}

remove_path_if_exists() {
  local path="$1"
  local safety_root="$2"

  assert_safe_path "${path}" "${safety_root}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_cmd "$(quote_cmd rm -rf "${path}")"
    return 0
  fi
  if [[ ! -e "${path}" && ! -L "${path}" ]]; then
    log_skip "Path already absent, skipping delete: ${path}"
    return 0
  fi
  run_logged_cmd rm -rf "${path}"
}

# Step 1 stays lightweight on purpose: it checks only whether the installer
# archive is present before any backup or service action happens.
step_1() {
  local installer_path
  local env_name=""
  installer_path="$(installer_tarball_path)"

  log_step "Step 1 - Verify the Tomcat installer archive"
  for env_name in "${FILESYSTEM_ENVS[@]}"; do
    log_info "Checking installer for filesystem target '${env_name}': ${installer_path}"
    ensure_file_exists "${installer_path}"
  done
  log_step_done "End of Step 1 - Installer archive check completed"
}

# Step 2 follows the original runbook backup for the Tomcat 9 directories that
# the upgrade manipulates directly, and also produces tar.gz archives for them.
step_2() {
  local env_name=""

  log_step "Step 2 - Back up the current Tomcat directories"
  for env_name in "${FILESYSTEM_ENVS[@]}"; do
    backup_managed_tomcat_dirs_for_env "${env_name}"
  done
  log_step_done "End of Step 2 - Backup step completed"
}

# This optional step is injected between step 1 and step 2 when backup_flag=yes.
# It does not change step numbering in the main flow, so operators can keep
# using the documented step numbers from the runbook.
step_1_5_full_apps_backup() {
  local env_name=""

  if [[ "${BACKUP_FLAG}" != "yes" ]]; then
    return 0
  fi

  log_step "Step 1.5 - Back up the full abinitio-app-hub/apps directory"
  for env_name in "${FILESYSTEM_ENVS[@]}"; do
    backup_full_apps_dir_if_needed "${env_name}"
  done
  log_step_done "End of Step 1.5 - Full apps backup completed"
}

step_3() {
  local env_name=""
  local runner=""
  log_step "Step 3 - Stop managed application services"

  for env_name in "${SELECTED_ENVS[@]}"; do
    if ! service_control_enabled "${env_name}"; then
      log_skip "Service stop is disabled for ${env_name}"
      continue
    fi
    runner="$(runner_for_env "${env_name}")"
    [[ -n "${runner}" ]] || die "ENV_RUNNER is missing for ${env_name}"
    run_profile_command "${env_name}" "${ABINITIO_TMP_DIR}" "$(quote_cmd "${runner}" stop application)"
    run_optional_hook "ENV_POST_STOP_CHECK_CMD" "${env_name}"
  done
  log_step_done "End of Step 3 - Stop step completed"
}

step_4() {
  local env_name=""

  log_step "Step 4 - Rename current Tomcat directories to *_org"
  for env_name in "${FILESYSTEM_ENVS[@]}"; do
    rename_managed_tomcat_dirs_for_env "${env_name}"
  done
  log_step_done "End of Step 4 - Rename step completed"
}

step_5() {
  local env_name=""
  local apps_dir=""
  local state=""
  local installer_path
  installer_path="$(installer_tarball_path)"

  log_step "Step 5 - Install the target Tomcat version"
  for env_name in "${FILESYSTEM_ENVS[@]}"; do
    apps_dir="$(apps_dir_for_env "${env_name}")"
    state="$(required_dir_state "${env_name}")"

    case "${state}" in
      all)
        if current_version_matches "${env_name}"; then
          log_skip "Target Tomcat version already installed for ${env_name}"
          continue
        fi
        die "Tomcat directories already exist for ${env_name}, but they do not match target version ${TARGET_VERSION}"
        ;;
      partial)
        die "Partial Tomcat installation detected for ${env_name}; please repair the filesystem state before retrying"
        ;;
      none)
        run_profile_command "${env_name}" "${apps_dir}" "ab-app install $(quote_cmd "${installer_path}")"
        ;;
      *)
        die "Unknown installation state '${state}' for ${env_name}"
        ;;
    esac
  done
  log_step_done "End of Step 5 - Install step completed"
}

step_6() {
  local env_name=""
  log_step "Step 6 - Verify the installed Tomcat version and required directories"

  for env_name in "${FILESYSTEM_ENVS[@]}"; do
    verify_version_for_env "${env_name}"
    verify_required_dirs_for_env "${env_name}"
  done
  log_step_done "End of Step 6 - Post-install verification completed"
}

step_7() {
  local env_name=""
  local apps_dir=""
  local current_bin=""
  local org_bin=""
  local file_name=""

  log_step "Step 7 - Restore managed files under catalina-home-9.0/bin"
  for env_name in "${FILESYSTEM_ENVS[@]}"; do
    apps_dir="$(apps_dir_for_env "${env_name}")"
    current_bin="${apps_dir}/${CATA_HOME_DIR_NAME}/bin"
    org_bin="$(org_dir_path "${apps_dir}/${CATA_HOME_DIR_NAME}")/bin"
    ensure_any_dir_exists "${org_bin}" "${current_bin}"

    for file_name in "${MANAGED_HOME_FILES[@]}"; do
      sync_file_if_needed "${org_bin}/${file_name}" "${current_bin}/${file_name}" "${env_name}:${file_name}"
    done
  done
  log_step_done "End of Step 7 - Home file restore completed"
}

# Step 8 restores the managed content for catalina-base-9.0. The current
# requirement is to restore webapps plus the runtime directories logs/temp/work
# whenever differences are detected against the *_org copy.
step_8() {
  local env_name=""

  log_step "Step 8 - Restore managed content under catalina-base-9.0"
  for env_name in "${FILESYSTEM_ENVS[@]}"; do
    restore_managed_tree_for_env "${env_name}" "${CATA_BASE_DIR_NAME}" "no" "${MANAGED_BASE_CONF_FILES[@]}"
  done
  log_step_done "End of Step 8 - Base restore completed"
}

# Step 9 mirrors step 8 for catalina-base-9.0-tmplt, including Catalina,
# webapps, and the runtime directories that now participate in restore logic.
step_9() {
  local env_name=""

  log_step "Step 9 - Restore managed content under catalina-base-9.0-tmplt"
  for env_name in "${FILESYSTEM_ENVS[@]}"; do
    restore_managed_tree_for_env "${env_name}" "${CATA_BASE_TMPLT_DIR_NAME}" "yes" "${MANAGED_TMPLT_CONF_FILES[@]}"
  done
  log_step_done "End of Step 9 - Template restore completed"
}

# Step 10 is the post-restore convergence check. It verifies that the managed
# files and directories we intentionally restored now match the *_org source.
step_10() {
  local env_name=""

  log_step "Step 10 - Verify managed restored content matches *_org"
  for env_name in "${FILESYSTEM_ENVS[@]}"; do
    assert_conf_file_set_identical \
      "$(managed_tomcat_org_dir_path_for_env "${env_name}" "${CATA_HOME_DIR_NAME}")/bin" \
      "$(managed_tomcat_dir_path_for_env "${env_name}" "${CATA_HOME_DIR_NAME}")/bin" \
      "${env_name}:${CATA_HOME_DIR_NAME}/bin" \
      "${MANAGED_HOME_FILES[@]}"
    verify_managed_tree_for_env "${env_name}" "${CATA_BASE_DIR_NAME}" "no" "${MANAGED_BASE_CONF_FILES[@]}"
    verify_managed_tree_for_env "${env_name}" "${CATA_BASE_TMPLT_DIR_NAME}" "yes" "${MANAGED_TMPLT_CONF_FILES[@]}"
  done
  log_step_done "End of Step 10 - Managed diff verification completed"
}

# Step 11 purges runtime folders under the configured app instances and then
# starts services for envs that are marked as service-controlled.
step_11() {
  local env_name=""
  local apps_dir=""
  local purge_targets=""
  local target=""
  local runtime_dir=""
  local runner=""

  log_step "Step 11 - Purge runtime folders and start services"
  for env_name in "${FILESYSTEM_ENVS[@]}"; do
    apps_dir="$(apps_dir_for_env "${env_name}")"
    purge_targets="$(purge_targets_for_env "${env_name}")"
    if [[ -z "${purge_targets}" ]]; then
      log_warn "No purge targets configured for ${env_name}; skipping runtime purge"
      continue
    fi

    for target in ${purge_targets}; do
      for runtime_dir in "${RUNTIME_SUBDIRS[@]}"; do
        remove_path_if_exists "${apps_dir}/${target}/${runtime_dir}" "${apps_dir}"
      done
    done
  done

  for env_name in "${SELECTED_ENVS[@]}"; do
    if ! service_control_enabled "${env_name}"; then
      log_skip "Service start is disabled for ${env_name}"
      continue
    fi
    runner="$(runner_for_env "${env_name}")"
    [[ -n "${runner}" ]] || die "ENV_RUNNER is missing for ${env_name}"
    run_profile_command "${env_name}" "${ABINITIO_TMP_DIR}" "$(quote_cmd "${runner}" start application)"
    run_optional_hook "ENV_POST_START_CHECK_CMD" "${env_name}"
  done
  log_step_done "End of Step 11 - Purge and start step completed"
}

step_13() {
  local env_name=""

  log_step "Step 13 - Remove *_org Tomcat directories"
  for env_name in "${FILESYSTEM_ENVS[@]}"; do
    cleanup_org_dirs_for_env "${env_name}"
  done
  log_step_done "End of Step 13 - Cleanup of *_org directories completed"
}

step_14() {
  local env_name=""

  log_step "Step 14 - Remove dated backup archives"
  for env_name in "${FILESYSTEM_ENVS[@]}"; do
    cleanup_archive_files_for_env "${env_name}"
  done
  log_step_done "End of Step 14 - Cleanup of dated backup archives completed"
}

# Dispatch the selected steps in order. Step 1.5 is intentionally injected
# inside step 2 handling so we do not introduce a new public step number.
execute_steps() {
  local step_number=""
  for step_number in "${EXECUTION_STEPS[@]}"; do
    case "${step_number}" in
      1) step_1 ;;
      2)
        step_1_5_full_apps_backup
        step_2
        ;;
      3) step_3 ;;
      4) step_4 ;;
      5) step_5 ;;
      6) step_6 ;;
      7) step_7 ;;
      8) step_8 ;;
      9) step_9 ;;
      10) step_10 ;;
      11) step_11 ;;
      13) step_13 ;;
      14) step_14 ;;
      *) die "Unsupported step requested: ${step_number}" ;;
    esac
  done
}

# Main bootstrap sequence:
#   - parse CLI options
#   - load config and compute the concrete env/step plan
#   - set up logging and locking
#   - execute the requested workflow
main() {
  parse_args "$@"
  if [[ "${LIST_STEPS}" -eq 1 ]]; then
    print_steps
    exit 0
  fi

  ensure_required_commands
  load_config
  validate_envs
  build_execution_steps
  init_logging
  rotate_logs
  acquire_lock

  trap 'release_lock' EXIT
  trap 'on_error $? $LINENO "$BASH_COMMAND"' ERR

  log_info "Using config file: ${CONFIG_FILE}"
  log_info "Selected logical envs: $(join_by ', ' "${SELECTED_ENVS[@]}")"
  log_info "Selected filesystem targets: $(join_by ', ' "${FILESYSTEM_ENVS[@]}")"
  log_info "Target Tomcat version: ${TARGET_VERSION}"
  log_info "backup_flag: ${BACKUP_FLAG}"
  log_info "Execution steps: $(join_by ', ' "${EXECUTION_STEPS[@]}")"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_dryrun "Dry-run mode is enabled. Commands will be printed but not executed."
  fi
  if [[ "${DO_CLEANUP}" -ne 1 ]]; then
    log_info "Cleanup is disabled. Step 13 and step 14 are intentionally skipped."
  fi

  execute_steps
  log_ok "Tomcat upgrade workflow finished successfully"
}

main "$@"
