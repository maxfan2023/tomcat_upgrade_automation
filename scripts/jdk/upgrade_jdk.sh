#!/usr/bin/env bash

# JDK upgrade automation for Ab Initio application hosts.
#
# The script is intended to run on the target application server. It upgrades
# the local JDK symlinks, verifies the active java version, archives the old JDK
# directory, and optionally calls the PostgreSQL-side JDK update script over SSH.
#
# Design goals:
#   - Keep environment-specific settings in configs/jdk/jdk_upgrade_<env>.conf.
#   - Keep --java-version as the semantic Java version, for example 11.0.31.
#   - Keep archive name and extracted directory configurable because Zulu build
#     labels cannot be safely inferred from the Java version alone.
#   - Be idempotent: a repeated run should skip already-completed work.
#   - Never delete the target JDK directory while archiving the old JDK.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PROGRAM_NAME="$(basename "$0")"

ENV_NAME=""
CONFIG_FILE=""
CLI_JAVA_VERSION=""
CLI_JDK_ARCHIVE=""
CLI_JDK_DIR=""
CLI_OLD_JDK_BASENAME=""
FROM_STEP_RAW="1"
START_STEP=1
DRY_RUN=0
DEBUG=0
AUTO_CONTINUE=0
LIST_STEPS=0

LOG_READY=0
LOG_FILE=""
ERROR_LOG_FILE=""
LOCK_DIR=""

JAVA_VERSION=""
JDK_ARCHIVE=""
JDK_DIR=""
JDK_ARCHIVE_PATH=""
TARGET_JDK_PATH=""
RUN_DATE_YYYYMMDD="$(date +%Y%m%d)"
OLD_JDK_STATE_FILE=""
OLD_JDK_BASENAME=""
LAST_CAPTURED_OUTPUT=""

DEFAULT_STEPS=(1 2 3 4 5 6 7 8 9)

usage() {
  cat <<'EOF'
Usage:
  ./scripts/jdk/upgrade_jdk.sh --env ENV [options]

Summary:
  Upgrade the JDK used by Ab Initio on the current application host.
  The script reads environment-specific paths and commands from a config file,
  prints commands before execution, supports dry-run mode, and can resume from a
  specific step.

Options:
  -e, --env ENV             One of dev, uat, prod, prod-cont
  -c, --config FILE         Path to env config file.
                            Defaults to configs/jdk/jdk_upgrade_<env>.conf
  -j, --java-version VER    Target Java version, for example 11.0.31
      --jdk-archive FILE    Target JDK archive file name, for example
                            zulu11.88.18-sa-jdk11.0.31-linux_x64.tar.gz
      --jdk-dir DIR         Extracted target JDK directory name, for example
                            zulu11.88.18-sa-jdk11.0.31-linux_x64
      --old-jdk-basename DIR_NAME
                            Override the old JDK directory basename to archive.
                            Default is auto-detected from the pre-upgrade jdk11
                            symlink target.
  -s, --from-step STEP      Start from a step number or label, for example 5
                            or step_5
      --dry-run             Print commands only, do not execute commands
      --debug               Enable shell tracing after logging starts
      --auto-continue       Do not pause between steps
      --list-steps          Print supported steps and exit
  -h, --help                Show this help text

Examples:
  ./scripts/jdk/upgrade_jdk.sh --env dev --dry-run
  ./scripts/jdk/upgrade_jdk.sh --env uat --java-version 11.0.31 --auto-continue
  ./scripts/jdk/upgrade_jdk.sh --env prod --from-step step_8
  ./scripts/jdk/upgrade_jdk.sh --env prod-cont \
    --jdk-archive zulu11.88.18-sa-jdk11.0.31-linux_x64.tar.gz \
    --jdk-dir zulu11.88.18-sa-jdk11.0.31-linux_x64
  ./scripts/jdk/upgrade_jdk.sh --env prod --from-step step_7 \
    --old-jdk-basename zulu11.86.20-sa-jdk11.0.30-linux_x64
EOF
}

print_steps() {
  cat <<'EOF'
step_1  Verify the target JDK installation archive exists
step_2  Check current /FCR_APP/abinitio/java/jdk11/bin/java --version
step_3  Stop Ab Initio application services when configured
step_4  Extract/install the target JDK
step_5  Record old jdk11 target and update JDK symlinks
step_6  Verify the active java version after symlink update
step_7  Archive the old JDK directory and optionally delete it
step_8  Update JDK on PostgreSQL database server hosts
step_9  Start Ab Initio application services when configured
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

step_label_for_number() {
  printf 'step_%s\n' "$1"
}

step_title() {
  case "$1" in
    1) printf '%s\n' "Verify target JDK archive" ;;
    2) printf '%s\n' "Check current Java version" ;;
    3) printf '%s\n' "Stop Ab Initio services" ;;
    4) printf '%s\n' "Install target JDK" ;;
    5) printf '%s\n' "Update JDK symlinks" ;;
    6) printf '%s\n' "Verify target Java version" ;;
    7) printf '%s\n' "Archive old JDK" ;;
    8) printf '%s\n' "Update PostgreSQL database server JDK" ;;
    9) printf '%s\n' "Start Ab Initio services" ;;
    *) printf '%s\n' "Unknown step" ;;
  esac
}

emit_plain_line() {
  local text="${1:-}"
  if [[ "${LOG_READY}" -eq 1 ]]; then
    printf '%s\n' "${text}" | tee -a "${LOG_FILE}"
  else
    printf '%s\n' "${text}"
  fi
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
log_cmd() { log CMD "$*"; }
log_skip() { log SKIP "$*"; }
log_dryrun() { log DRYRUN "$*"; }

log_error() {
  local message="$*"
  log ERROR "${message}"
  if [[ -n "${ERROR_LOG_FILE}" ]]; then
    printf '%s %s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "❌" "ERROR" "${message}" >> "${ERROR_LOG_FILE}"
  fi
}

die() {
  local message="${1:-Unknown error}"
  if [[ "${LOG_READY}" -eq 1 ]]; then
    log_error "${message}"
    log_info "Log file: ${LOG_FILE}"
    log_info "Error file: ${ERROR_LOG_FILE}"
  else
    printf 'ERROR: %s\n' "${message}" >&2
  fi
  exit 1
}

log_step_banner() {
  local text="$1"
  emit_plain_line ""
  emit_plain_line "############################################################"
  emit_plain_line "### ${text}"
  emit_plain_line "############################################################"
  emit_plain_line ""
}

log_step() {
  log_step_banner "$*"
  log STEP "$*"
}

single_quote_for_display() {
  local remaining="$1"
  local sq="'"

  printf "'"
  while [[ "${remaining}" == *"${sq}"* ]]; do
    printf '%s' "${remaining%%"${sq}"*}"
    printf "'\\''"
    remaining="${remaining#*"${sq}"}"
  done
  printf '%s' "${remaining}"
  printf "'"
}

format_display_arg() {
  local arg="$1"

  if [[ -n "${arg}" && "${arg}" =~ ^[A-Za-z0-9_./:@%+=,-]+$ ]]; then
    printf '%s' "${arg}"
  else
    single_quote_for_display "${arg}"
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
  printf 'bash -lc %s' "$(single_quote_for_display "${shell_cmd}")"
}

run_logged_cmd() {
  local display=""
  local cmd_rc=0

  display="$(display_cmd "$@")"
  log_cmd "${display}"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_dryrun "${display}"
    return 0
  fi

  set +e
  "$@" 2>&1 | tee -a "${LOG_FILE}"
  cmd_rc="${PIPESTATUS[0]}"
  set -e

  if [[ "${cmd_rc}" -ne 0 ]]; then
    die "Command failed with exit code ${cmd_rc}: ${display}"
  fi
}

run_logged_shell() {
  local shell_cmd="$1"
  local display=""
  local cmd_rc=0

  [[ -n "${shell_cmd}" ]] || return 0
  display="$(display_shell_cmd "${shell_cmd}")"
  log_cmd "${display}"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_dryrun "${display}"
    return 0
  fi

  set +e
  bash -lc "${shell_cmd}" 2>&1 | tee -a "${LOG_FILE}"
  cmd_rc="${PIPESTATUS[0]}"
  set -e

  if [[ "${cmd_rc}" -ne 0 ]]; then
    die "Command failed with exit code ${cmd_rc}: ${display}"
  fi
}

capture_java_version() {
  local java_bin="${JAVA_BASE_DIR}/jdk11/bin/java"
  local output=""
  local cmd_rc=0
  local display=""

  LAST_CAPTURED_OUTPUT=""
  display="$(display_cmd "${java_bin}" --version)"
  log_cmd "${display}"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_dryrun "${display}"
    return 0
  fi

  if [[ ! -x "${java_bin}" ]]; then
    log_warn "Java binary is not executable or does not exist: ${java_bin}"
    return 1
  fi

  set +e
  output="$("${java_bin}" --version 2>&1)"
  cmd_rc="$?"
  set -e

  if [[ -n "${output}" ]]; then
    emit_plain_line "${output}"
  fi
  LAST_CAPTURED_OUTPUT="${output}"
  return "${cmd_rc}"
}

parse_args() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -e|--env)
        [[ "$#" -ge 2 ]] || die "--env requires a value"
        ENV_NAME="$2"
        shift 2
        ;;
      -c|--config)
        [[ "$#" -ge 2 ]] || die "--config requires a value"
        CONFIG_FILE="$2"
        shift 2
        ;;
      -j|--java-version)
        [[ "$#" -ge 2 ]] || die "--java-version requires a value"
        CLI_JAVA_VERSION="$2"
        shift 2
        ;;
      --jdk-archive)
        [[ "$#" -ge 2 ]] || die "--jdk-archive requires a value"
        CLI_JDK_ARCHIVE="$2"
        shift 2
        ;;
      --jdk-dir)
        [[ "$#" -ge 2 ]] || die "--jdk-dir requires a value"
        CLI_JDK_DIR="$2"
        shift 2
        ;;
      --old-jdk-basename)
        [[ "$#" -ge 2 ]] || die "--old-jdk-basename requires a value"
        CLI_OLD_JDK_BASENAME="$2"
        shift 2
        ;;
      -s|--from-step)
        [[ "$#" -ge 2 ]] || die "--from-step requires a value"
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
      --auto-continue)
        AUTO_CONTINUE=1
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
        die "Unknown argument: $1"
        ;;
    esac
  done
}

default_config_file_for_env() {
  local env_name="$1"
  printf '%s/configs/jdk/jdk_upgrade_%s.conf\n' "${REPO_ROOT}" "${env_name}"
}

ensure_supported_env() {
  case "${ENV_NAME}" in
    dev|uat|prod|prod-cont) return 0 ;;
    *) die "--env must be one of dev, uat, prod, prod-cont" ;;
  esac
}

ensure_array_defined() {
  local name="$1"
  if ! declare -p "${name}" >/dev/null 2>&1; then
    eval "${name}=()"
  fi
}

load_config() {
  ensure_supported_env
  if [[ -z "${CONFIG_FILE}" ]]; then
    CONFIG_FILE="$(default_config_file_for_env "${ENV_NAME}")"
  fi

  [[ -f "${CONFIG_FILE}" ]] || die "Config file not found: ${CONFIG_FILE}"
  # shellcheck source=/dev/null
  source "${CONFIG_FILE}"

  : "${JAVA_BASE_DIR:?JAVA_BASE_DIR must be set in the config file}"
  : "${JDK_SOFTWARE_DIR:?JDK_SOFTWARE_DIR must be set in the config file}"
  : "${DEFAULT_JAVA_VERSION:?DEFAULT_JAVA_VERSION must be set in the config file}"
  : "${DEFAULT_JDK_ARCHIVE:?DEFAULT_JDK_ARCHIVE must be set in the config file}"
  : "${DEFAULT_JDK_DIR:?DEFAULT_JDK_DIR must be set in the config file}"

  ensure_array_defined JDK_SYMLINKS
  ensure_array_defined STOP_COMMANDS
  ensure_array_defined START_COMMANDS
  ensure_array_defined DB_UPDATE_HOSTS

  if [[ "${#JDK_SYMLINKS[@]}" -eq 0 ]]; then
    JDK_SYMLINKS=(jdk11 jdk1.8.0_191)
  fi

  JAVA_VERSION="${CLI_JAVA_VERSION:-${DEFAULT_JAVA_VERSION}}"
  JDK_ARCHIVE="${CLI_JDK_ARCHIVE:-${DEFAULT_JDK_ARCHIVE}}"
  JDK_DIR="${CLI_JDK_DIR:-${DEFAULT_JDK_DIR}}"

  [[ -n "${JAVA_VERSION}" ]] || die "Target Java version is empty"
  [[ -n "${JDK_ARCHIVE}" ]] || die "Target JDK archive name is empty"
  [[ -n "${JDK_DIR}" ]] || die "Target JDK directory name is empty"
  [[ "${JAVA_VERSION}" =~ ^[0-9]+(\.[0-9]+)+$ ]] || die "--java-version must be a semantic Java version like 11.0.31"
  if [[ -n "${CLI_OLD_JDK_BASENAME}" ]]; then
    ensure_target_is_not_old_delete_target "${CLI_OLD_JDK_BASENAME}"
  fi

  JDK_ARCHIVE_PATH="${JDK_SOFTWARE_DIR}/${JDK_ARCHIVE}"
  TARGET_JDK_PATH="${JAVA_BASE_DIR}/${JDK_DIR}"
  TARGET_JDK_CHMOD_MODE="${TARGET_JDK_CHMOD_MODE:-2755}"
  LOG_DIR="${LOG_DIR:-${REPO_ROOT}/logs}"
  STATE_DIR="${STATE_DIR:-${REPO_ROOT}/.state}"
  LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-90}"
  DELETE_OLD_JDK_AFTER_ARCHIVE="${DELETE_OLD_JDK_AFTER_ARCHIVE:-yes}"
  DB_UPDATE_COMMAND="${DB_UPDATE_COMMAND:-/bin/bash /opt/clouseau/upgrade_jdk_on_db.sh}"
  POST_STOP_CHECK_CMD="${POST_STOP_CHECK_CMD:-}"
  POST_START_CHECK_CMD="${POST_START_CHECK_CMD:-}"
}

setup_logging() {
  mkdir -p "${LOG_DIR}" "${STATE_DIR}"
  LOG_FILE="${LOG_DIR}/jdk_${JAVA_VERSION}_update_${RUN_DATE_YYYYMMDD}.log"
  ERROR_LOG_FILE="${LOG_FILE%.log}.err"
  OLD_JDK_STATE_FILE="${STATE_DIR}/jdk_${ENV_NAME}_${JAVA_VERSION}_old_jdk.env"
  : >> "${LOG_FILE}"
  : >> "${ERROR_LOG_FILE}"
  LOG_READY=1

  if [[ "${DEBUG}" -eq 1 ]]; then
    exec 2> >(tee -a "${LOG_FILE}" >&2)
    set -x
  fi
}

cleanup_old_logs() {
  local display=""

  display="$(display_cmd find "${LOG_DIR}" -type f "(" -name "*.log" -o -name "*.err" ")" -mtime "+${LOG_RETENTION_DAYS}" -print -delete)"
  log_cmd "${display}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_dryrun "${display}"
    return 0
  fi

  find "${LOG_DIR}" -type f \( -name '*.log' -o -name '*.err' \) -mtime +"${LOG_RETENTION_DAYS}" -print -delete | tee -a "${LOG_FILE}" || true
}

acquire_lock() {
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_info "dry-run mode skips lock creation"
    return 0
  fi

  LOCK_DIR="${STATE_DIR}/.jdk_${ENV_NAME}_${JAVA_VERSION}.lock"
  if ! mkdir "${LOCK_DIR}" 2>/dev/null; then
    die "Another JDK upgrade appears to be running. Lock exists: ${LOCK_DIR}"
  fi
}

release_lock() {
  if [[ -n "${LOCK_DIR}" && -d "${LOCK_DIR}" ]]; then
    rmdir "${LOCK_DIR}" 2>/dev/null || true
  fi
}

compute_execution_steps() {
  local step=""

  START_STEP="$(normalize_step "${FROM_STEP_RAW}")" || die "Invalid --from-step value: ${FROM_STEP_RAW}"
  [[ "${START_STEP}" -ge 1 && "${START_STEP}" -le 9 ]] || die "--from-step must be between step_1 and step_9"

  EXECUTION_STEPS=()
  for step in "${DEFAULT_STEPS[@]}"; do
    if [[ "${step}" -ge "${START_STEP}" ]]; then
      EXECUTION_STEPS+=("${step}")
    fi
  done
}

wait_for_step_confirmation() {
  local completed_label="$1"
  local next_label="$2"
  local answer=""

  if [[ "${AUTO_CONTINUE}" -eq 1 || -z "${next_label}" ]]; then
    return 0
  fi

  emit_plain_line ""
  emit_plain_line "Completed ${completed_label}."
  emit_plain_line "Type yes to continue to ${next_label}, or anything else to stop."
  printf '> ' | tee -a "${LOG_FILE}"
  if ! IFS= read -r answer; then
    die "Failed to read confirmation after ${completed_label}. Re-run with --auto-continue to avoid interactive pauses."
  fi
  printf '%s\n' "${answer}" >> "${LOG_FILE}"
  [[ "${answer}" == "yes" ]] || die "Execution stopped by user after ${completed_label}"
}

path_is_safe_basename() {
  local value="$1"
  [[ -n "${value}" && "${value}" != "." && "${value}" != ".." && "${value}" != */* ]]
}

resolve_link_target_path() {
  local link_name="$1"
  local link_path="${JAVA_BASE_DIR}/${link_name}"
  local target=""

  if [[ ! -L "${link_path}" ]]; then
    return 1
  fi

  target="$(readlink "${link_path}")"
  if [[ "${target}" == /* ]]; then
    printf '%s\n' "${target}"
  else
    printf '%s/%s\n' "${JAVA_BASE_DIR}" "${target}"
  fi
}

read_saved_old_jdk_basename() {
  OLD_JDK_BASENAME=""
  if [[ -n "${CLI_OLD_JDK_BASENAME}" ]]; then
    OLD_JDK_BASENAME="${CLI_OLD_JDK_BASENAME}"
    ensure_target_is_not_old_delete_target "${OLD_JDK_BASENAME}"
    return 0
  fi

  if [[ -f "${OLD_JDK_STATE_FILE}" ]]; then
    # shellcheck source=/dev/null
    source "${OLD_JDK_STATE_FILE}"
  fi
  OLD_JDK_BASENAME="${OLD_JDK_BASENAME:-}"
  if [[ -n "${OLD_JDK_BASENAME}" ]]; then
    ensure_target_is_not_old_delete_target "${OLD_JDK_BASENAME}"
  fi
}

save_old_jdk_basename() {
  local old_basename="$1"

  OLD_JDK_BASENAME="${old_basename}"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log_dryrun "Would save OLD_JDK_BASENAME=${OLD_JDK_BASENAME} to ${OLD_JDK_STATE_FILE}"
    return 0
  fi

  printf 'OLD_JDK_BASENAME=%q\n' "${OLD_JDK_BASENAME}" > "${OLD_JDK_STATE_FILE}"
}

record_old_jdk_target_if_needed() {
  local old_target_path=""
  local old_basename=""

  if [[ -n "${CLI_OLD_JDK_BASENAME}" ]]; then
    ensure_target_is_not_old_delete_target "${CLI_OLD_JDK_BASENAME}"
    save_old_jdk_basename "${CLI_OLD_JDK_BASENAME}"
    log_info "Using operator-provided old JDK directory: ${CLI_OLD_JDK_BASENAME}"
    return 0
  fi

  if ! old_target_path="$(resolve_link_target_path jdk11)"; then
    log_warn "Cannot record old JDK because ${JAVA_BASE_DIR}/jdk11 is not a symlink"
    save_old_jdk_basename ""
    return 0
  fi

  old_basename="$(basename "${old_target_path}")"
  if [[ "${old_basename}" == "${JDK_DIR}" ]]; then
    log_info "jdk11 already points to target JDK ${JDK_DIR}; no old JDK directory to archive"
    save_old_jdk_basename ""
    return 0
  fi

  save_old_jdk_basename "${old_basename}"
  log_info "Recorded old JDK directory: ${old_basename}"
}

ensure_target_is_not_old_delete_target() {
  local old_basename="$1"

  path_is_safe_basename "${old_basename}" || die "Refusing unsafe old JDK directory name: ${old_basename}"
  [[ "${old_basename}" != "${JDK_DIR}" ]] || die "Refusing to archive/delete target JDK directory as old JDK: ${old_basename}"
}

step_1_verify_archive() {
  log_step "step_1 Verify target JDK archive"
  run_logged_cmd test -f "${JDK_ARCHIVE_PATH}"
}

step_2_check_current_java() {
  log_step "step_2 Check current Java version"

  if capture_java_version; then
    if [[ "${LAST_CAPTURED_OUTPUT}" == *"${JAVA_VERSION}"* ]]; then
      if [[ "${START_STEP}" -eq 1 ]]; then
        log_ok "JDK version is already up to date: ${JAVA_VERSION}"
        log_info "Log file: ${LOG_FILE}"
        exit 0
      fi
      log_ok "Current JDK version already matches target ${JAVA_VERSION}; continuing because run starts from ${START_STEP}"
      return 0
    fi
    log_info "Current JDK version does not match target ${JAVA_VERSION}; continuing upgrade"
    return 0
  fi

  log_warn "Unable to read current Java version; continuing upgrade because target archive was verified"
}

step_3_stop_services() {
  local command=""

  log_step "step_3 Stop Ab Initio services"
  if [[ "${#STOP_COMMANDS[@]}" -eq 0 ]]; then
    log_skip "No stop commands configured for ${ENV_NAME}"
  else
    for command in "${STOP_COMMANDS[@]}"; do
      run_logged_shell "${command}"
    done
  fi

  if [[ -n "${POST_STOP_CHECK_CMD}" ]]; then
    run_logged_shell "${POST_STOP_CHECK_CMD}"
  fi
}

step_4_install_target_jdk() {
  log_step "step_4 Install target JDK"
  run_logged_cmd ls -lrth "${JDK_SOFTWARE_DIR}"

  if [[ -d "${TARGET_JDK_PATH}" ]]; then
    log_skip "Target JDK directory already exists: ${TARGET_JDK_PATH}"
  else
    run_logged_cmd tar -xzf "${JDK_ARCHIVE_PATH}" -C "${JAVA_BASE_DIR}"
  fi

  run_logged_cmd test -d "${TARGET_JDK_PATH}"
  run_logged_cmd ls -lrth "${JAVA_BASE_DIR}"
}

step_5_update_symlinks() {
  local link_name=""
  local link_path=""

  log_step "step_5 Record old JDK and update symlinks"
  record_old_jdk_target_if_needed

  run_logged_cmd test -d "${TARGET_JDK_PATH}"
  for link_name in "${JDK_SYMLINKS[@]}"; do
    link_path="${JAVA_BASE_DIR}/${link_name}"
    if [[ -e "${link_path}" && ! -L "${link_path}" ]]; then
      die "Refusing to replace non-symlink path: ${link_path}"
    fi
    run_logged_cmd ln -sfn "${JDK_DIR}" "${link_path}"
  done

  run_logged_cmd chmod -R "${TARGET_JDK_CHMOD_MODE}" "${TARGET_JDK_PATH}"
  run_logged_cmd ls -lrth "${JAVA_BASE_DIR}"
}

step_6_verify_target_java() {
  log_step "step_6 Verify target Java version"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    capture_java_version
    log_dryrun "Would verify active Java version contains ${JAVA_VERSION}"
    return 0
  fi

  if ! capture_java_version; then
    die "Failed to run java --version after JDK symlink update"
  fi

  if [[ "${LAST_CAPTURED_OUTPUT}" != *"${JAVA_VERSION}"* ]]; then
    die "JDK upgrade verification failed. Expected java version ${JAVA_VERSION}, got: ${LAST_CAPTURED_OUTPUT}"
  fi

  log_ok "Verified active Java version: ${JAVA_VERSION}"
}

step_7_archive_old_jdk() {
  local old_path=""
  local archive_file=""

  log_step "step_7 Archive old JDK"
  read_saved_old_jdk_basename

  if [[ -z "${OLD_JDK_BASENAME}" ]]; then
    log_skip "No old JDK directory recorded; nothing to archive"
    return 0
  fi

  ensure_target_is_not_old_delete_target "${OLD_JDK_BASENAME}"
  old_path="${JAVA_BASE_DIR}/${OLD_JDK_BASENAME}"
  archive_file="${JAVA_BASE_DIR}/${OLD_JDK_BASENAME}_${RUN_DATE_YYYYMMDD}.tar.gz"

  if [[ -f "${archive_file}" ]]; then
    log_skip "Old JDK archive already exists: ${archive_file}"
  elif [[ -d "${old_path}" ]]; then
    run_logged_cmd tar -czf "${archive_file}" -C "${JAVA_BASE_DIR}" "${OLD_JDK_BASENAME}"
  else
    log_warn "Old JDK directory is missing and no archive exists: ${old_path}"
    return 0
  fi

  if [[ "${DELETE_OLD_JDK_AFTER_ARCHIVE}" == "yes" ]]; then
    ensure_target_is_not_old_delete_target "${OLD_JDK_BASENAME}"
    if [[ -d "${old_path}" ]]; then
      run_logged_cmd rm -rf "${old_path}"
    else
      log_skip "Old JDK directory already removed: ${old_path}"
    fi
  else
    log_skip "DELETE_OLD_JDK_AFTER_ARCHIVE=${DELETE_OLD_JDK_AFTER_ARCHIVE}; keeping ${old_path}"
  fi

  run_logged_cmd ls -lrth "${JAVA_BASE_DIR}"
}

step_8_update_database_hosts() {
  local host=""

  log_step "step_8 Update PostgreSQL database server JDK"
  if [[ "${#DB_UPDATE_HOSTS[@]}" -eq 0 ]]; then
    log_skip "No DB update hosts configured for ${ENV_NAME}"
    return 0
  fi

  for host in "${DB_UPDATE_HOSTS[@]}"; do
    run_logged_cmd ssh -q "${host}" -C "${DB_UPDATE_COMMAND}"
  done
}

step_9_start_services() {
  local command=""

  log_step "step_9 Start Ab Initio services"
  if [[ "${#START_COMMANDS[@]}" -eq 0 ]]; then
    log_skip "No start commands configured for ${ENV_NAME}"
  else
    for command in "${START_COMMANDS[@]}"; do
      run_logged_shell "${command}"
    done
  fi

  if [[ -n "${POST_START_CHECK_CMD}" ]]; then
    run_logged_shell "${POST_START_CHECK_CMD}"
  fi
}

execute_step() {
  case "$1" in
    1) step_1_verify_archive ;;
    2) step_2_check_current_java ;;
    3) step_3_stop_services ;;
    4) step_4_install_target_jdk ;;
    5) step_5_update_symlinks ;;
    6) step_6_verify_target_java ;;
    7) step_7_archive_old_jdk ;;
    8) step_8_update_database_hosts ;;
    9) step_9_start_services ;;
    *) die "Unsupported step: $1" ;;
  esac
}

print_runtime_summary() {
  log_info "env: ${ENV_NAME}"
  log_info "config file: ${CONFIG_FILE}"
  log_info "target java version: ${JAVA_VERSION}"
  log_info "target JDK archive: ${JDK_ARCHIVE_PATH}"
  log_info "target JDK directory: ${TARGET_JDK_PATH}"
  log_info "target JDK chmod mode: ${TARGET_JDK_CHMOD_MODE}"
  log_info "delete old JDK after archive: ${DELETE_OLD_JDK_AFTER_ARCHIVE}"
  log_info "dry-run: ${DRY_RUN}"
  log_info "from-step: $(step_label_for_number "${START_STEP}")"
  log_info "log file: ${LOG_FILE}"
}

main() {
  local index=0
  local step=""
  local next_step=""

  parse_args "$@"

  if [[ "${LIST_STEPS}" -eq 1 ]]; then
    print_steps
    exit 0
  fi

  [[ -n "${ENV_NAME}" ]] || die "--env is required for execution"
  load_config
  setup_logging
  cleanup_old_logs
  compute_execution_steps
  acquire_lock
  trap 'release_lock' EXIT

  print_runtime_summary

  for index in "${!EXECUTION_STEPS[@]}"; do
    step="${EXECUTION_STEPS[${index}]}"
    next_step=""
    if [[ "$((index + 1))" -lt "${#EXECUTION_STEPS[@]}" ]]; then
      next_step="$(step_label_for_number "${EXECUTION_STEPS[$((index + 1))]}")"
    fi

    execute_step "${step}"
    log_ok "$(step_label_for_number "${step}") completed: $(step_title "${step}")"
    wait_for_step_confirmation "$(step_label_for_number "${step}")" "${next_step}"
  done

  log_ok "JDK upgrade workflow completed for ${ENV_NAME}"
  log_info "Log file: ${LOG_FILE}"
  log_info "Error file: ${ERROR_LOG_FILE}"
}

main "$@"
