#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT_DIR}/scripts/jdk/upgrade_jdk.sh"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_exists() {
  [[ -e "$1" ]] || fail "expected path to exist: $1"
}

assert_not_exists() {
  [[ ! -e "$1" ]] || fail "expected path to be absent: $1"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"

  [[ "${haystack}" == *"${needle}"* ]] || fail "expected output to contain: ${needle}"
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"

  [[ "${haystack}" != *"${needle}"* ]] || fail "expected output not to contain: ${needle}"
}

assert_symlink_target() {
  local link_path="$1"
  local expected="$2"
  local actual=""

  actual="$(readlink "${link_path}")"
  [[ "${actual}" == "${expected}" ]] || fail "expected ${link_path} -> ${expected}, got ${actual}"
}

make_fake_java() {
  local dir="$1"
  local version="$2"

  mkdir -p "${dir}/bin"
  cat > "${dir}/bin/java" <<EOF
#!/usr/bin/env bash
printf 'openjdk ${version} 2026-04-21 LTS\n'
printf 'OpenJDK Runtime Environment Fake (build ${version})\n'
EOF
  chmod +x "${dir}/bin/java"
}

make_config() {
  local config_file="$1"
  local temp_root="$2"
  local delete_old="$3"

  cat > "${config_file}" <<EOF
JAVA_BASE_DIR="${temp_root}/java"
JDK_SOFTWARE_DIR="${temp_root}/software"
DEFAULT_JAVA_VERSION="11.0.31"
DEFAULT_JDK_ARCHIVE="zulu11.88.18-sa-jdk11.0.31-linux_x64.tar.gz"
DEFAULT_JDK_DIR="zulu11.88.18-sa-jdk11.0.31-linux_x64"
TARGET_JDK_CHMOD_MODE="0755"
JDK_SYMLINKS=(jdk11 jdk1.8.0_191)
STOP_COMMANDS=()
START_COMMANDS=()
DB_UPDATE_HOSTS=()
DB_JDK_COPY_HOSTS=()
DB_UPDATE_COMMAND="/bin/bash /opt/clouseau/upgrade_jdk_on_db.sh"
DELETE_OLD_JDK_AFTER_ARCHIVE="${delete_old}"
LOG_DIR="${temp_root}/logs"
STATE_DIR="${temp_root}/state"
LOG_RETENTION_DAYS=90
EOF
}

make_command_config() {
  local config_file="$1"
  local temp_root="$2"

  cat > "${config_file}" <<EOF
JAVA_BASE_DIR="${temp_root}/java"
JDK_SOFTWARE_DIR="${temp_root}/software"
DEFAULT_JAVA_VERSION="11.0.31"
DEFAULT_JDK_ARCHIVE="zulu11.88.18-sa-jdk11.0.31-linux_x64.tar.gz"
DEFAULT_JDK_DIR="zulu11.88.18-sa-jdk11.0.31-linux_x64"
TARGET_JDK_CHMOD_MODE="0755"
JDK_SYMLINKS=(jdk11 jdk1.8.0_191)
STOP_COMMANDS=(
  "cd /FCR_APP/abinitio/tmp && /FCR_APP/abinitio/management/scripts/ienv.abinitio.runner.sh stop all-services"
)
START_COMMANDS=(
  "cd /FCR_APP/abinitio/tmp && /FCR_APP/abinitio/management/scripts/ienv.abinitio.runner.sh start all-services"
)
DB_UPDATE_HOSTS=(gbl25152435.hc.cloud.uk.hsbc)
DB_JDK_COPY_HOSTS=(gbl25152435.hc.cloud.uk.hsbc)
DB_UPDATE_COMMAND="/bin/bash /opt/clouseau/upgrade_jdk_on_db.sh"
DELETE_OLD_JDK_AFTER_ARCHIVE="yes"
LOG_DIR="${temp_root}/logs"
STATE_DIR="${temp_root}/state"
LOG_RETENTION_DAYS=90
EOF
}

make_target_archive() {
  local temp_root="$1"
  local build_dir="${temp_root}/build"
  local target_name="zulu11.88.18-sa-jdk11.0.31-linux_x64"

  mkdir -p "${temp_root}/software" "${build_dir}"
  make_fake_java "${build_dir}/${target_name}" "11.0.31"
  tar -czf "${temp_root}/software/${target_name}.tar.gz" -C "${build_dir}" "${target_name}"
}

test_list_steps() {
  local output=""

  output="$("${SCRIPT}" --list-steps)"
  [[ "${output}" == *"step_9"* ]] || fail "--list-steps should include step_9"
}

test_upgrade_archives_and_deletes_old_jdk() {
  local temp_root=""
  local config_file=""

  temp_root="$(mktemp -d)"
  trap "rm -rf '${temp_root}'" RETURN
  config_file="${temp_root}/jdk_upgrade_dev.conf"

  mkdir -p "${temp_root}/java"
  make_fake_java "${temp_root}/java/zulu11.86.20-sa-jdk11.0.30-linux_x64" "11.0.30"
  ln -s zulu11.86.20-sa-jdk11.0.30-linux_x64 "${temp_root}/java/jdk11"
  ln -s zulu11.86.20-sa-jdk11.0.30-linux_x64 "${temp_root}/java/jdk1.8.0_191"
  make_target_archive "${temp_root}"
  make_config "${config_file}" "${temp_root}" "yes"

  "${SCRIPT}" --env dev --config "${config_file}" --auto-continue

  assert_symlink_target "${temp_root}/java/jdk11" "zulu11.88.18-sa-jdk11.0.31-linux_x64"
  assert_symlink_target "${temp_root}/java/jdk1.8.0_191" "zulu11.88.18-sa-jdk11.0.31-linux_x64"
  assert_exists "${temp_root}/java/zulu11.88.18-sa-jdk11.0.31-linux_x64/bin/java"
  assert_exists "${temp_root}/java/zulu11.86.20-sa-jdk11.0.30-linux_x64_$(date +%Y%m%d).tar.gz"
  assert_not_exists "${temp_root}/java/zulu11.86.20-sa-jdk11.0.30-linux_x64"
}

test_upgrade_keeps_old_jdk_when_configured() {
  local temp_root=""
  local config_file=""

  temp_root="$(mktemp -d)"
  trap "rm -rf '${temp_root}'" RETURN
  config_file="${temp_root}/jdk_upgrade_dev.conf"

  mkdir -p "${temp_root}/java"
  make_fake_java "${temp_root}/java/zulu11.86.20-sa-jdk11.0.30-linux_x64" "11.0.30"
  ln -s zulu11.86.20-sa-jdk11.0.30-linux_x64 "${temp_root}/java/jdk11"
  ln -s zulu11.86.20-sa-jdk11.0.30-linux_x64 "${temp_root}/java/jdk1.8.0_191"
  make_target_archive "${temp_root}"
  make_config "${config_file}" "${temp_root}" "no"

  "${SCRIPT}" --env dev --config "${config_file}" --auto-continue

  assert_exists "${temp_root}/java/zulu11.86.20-sa-jdk11.0.30-linux_x64_$(date +%Y%m%d).tar.gz"
  assert_exists "${temp_root}/java/zulu11.86.20-sa-jdk11.0.30-linux_x64/bin/java"
}

test_already_up_to_date_exits_without_archive() {
  local temp_root=""
  local config_file=""

  temp_root="$(mktemp -d)"
  trap "rm -rf '${temp_root}'" RETURN
  config_file="${temp_root}/jdk_upgrade_dev.conf"

  mkdir -p "${temp_root}/java"
  make_fake_java "${temp_root}/java/zulu11.88.18-sa-jdk11.0.31-linux_x64" "11.0.31"
  ln -s zulu11.88.18-sa-jdk11.0.31-linux_x64 "${temp_root}/java/jdk11"
  ln -s zulu11.88.18-sa-jdk11.0.31-linux_x64 "${temp_root}/java/jdk1.8.0_191"
  make_target_archive "${temp_root}"
  make_config "${config_file}" "${temp_root}" "yes"

  "${SCRIPT}" --env dev --config "${config_file}" --auto-continue

  assert_not_exists "${temp_root}/java/zulu11.88.18-sa-jdk11.0.31-linux_x64_$(date +%Y%m%d).tar.gz"
}

test_dry_run_displays_readable_commands() {
  local temp_root=""
  local config_file=""
  local output=""

  temp_root="$(mktemp -d)"
  trap "rm -rf '${temp_root}'" RETURN
  config_file="${temp_root}/jdk_upgrade_dev.conf"

  mkdir -p "${temp_root}/java" "${temp_root}/software"
  make_fake_java "${temp_root}/java/zulu11.86.20-sa-jdk11.0.30-linux_x64" "11.0.30"
  ln -s zulu11.86.20-sa-jdk11.0.30-linux_x64 "${temp_root}/java/jdk11"
  make_command_config "${config_file}" "${temp_root}"

  output="$("${SCRIPT}" --env dev --config "${config_file}" --from-step step_3 --auto-continue --dry-run 2>&1)"

  assert_contains "${output}" "bash -lc 'cd /FCR_APP/abinitio/tmp && /FCR_APP/abinitio/management/scripts/ienv.abinitio.runner.sh stop all-services'"
  assert_contains "${output}" "scp -qr ${temp_root}/java/jdk11/zulu11.88.18-sa-jdk11.0.31-linux_x64 gbl25152435.hc.cloud.uk.hsbc:/opt/clouseau/java/"
  assert_contains "${output}" "scp -q ${ROOT_DIR}/scripts/jdk/upgrade_jdk_on_db.sh gbl25152435.hc.cloud.uk.hsbc:/opt/clouseau/upgrade_jdk_on_db.sh"
  assert_contains "${output}" "scp -q ${ROOT_DIR}/configs/jdk/jdk_pg_upgrade_dev.conf gbl25152435.hc.cloud.uk.hsbc:/opt/clouseau/jdk_pg_upgrade_dev.conf"
  assert_contains "${output}" "ssh -q gbl25152435.hc.cloud.uk.hsbc -C 'chmod +x /opt/clouseau/upgrade_jdk_on_db.sh'"
  assert_contains "${output}" "ssh -q gbl25152435.hc.cloud.uk.hsbc -C '/bin/bash /opt/clouseau/upgrade_jdk_on_db.sh --env dev --config /opt/clouseau/jdk_pg_upgrade_dev.conf --java-version 11.0.31 --jdk-dir zulu11.88.18-sa-jdk11.0.31-linux_x64 --auto-continue'"
  assert_contains "${output}" "bash -lc 'cd /FCR_APP/abinitio/tmp && /FCR_APP/abinitio/management/scripts/ienv.abinitio.runner.sh start all-services'"
  assert_not_contains "${output}" '\ \&\&'
  assert_not_contains "${output}" '/bin/bash\ /opt'
}

test_old_jdk_basename_override_archives_requested_directory() {
  local temp_root=""
  local config_file=""

  temp_root="$(mktemp -d)"
  trap "rm -rf '${temp_root}'" RETURN
  config_file="${temp_root}/jdk_upgrade_dev.conf"

  mkdir -p "${temp_root}/java"
  make_fake_java "${temp_root}/java/zulu11.86.20-sa-jdk11.0.30-linux_x64" "11.0.30"
  make_fake_java "${temp_root}/java/zulu11.87.17-sa-jdk11.0.30-linux_x64" "11.0.30"
  ln -s zulu11.86.20-sa-jdk11.0.30-linux_x64 "${temp_root}/java/jdk11"
  ln -s zulu11.86.20-sa-jdk11.0.30-linux_x64 "${temp_root}/java/jdk1.8.0_191"
  make_target_archive "${temp_root}"
  make_config "${config_file}" "${temp_root}" "yes"

  "${SCRIPT}" --env dev --config "${config_file}" --auto-continue \
    --old-jdk-basename zulu11.87.17-sa-jdk11.0.30-linux_x64

  assert_symlink_target "${temp_root}/java/jdk11" "zulu11.88.18-sa-jdk11.0.31-linux_x64"
  assert_exists "${temp_root}/java/zulu11.87.17-sa-jdk11.0.30-linux_x64_$(date +%Y%m%d).tar.gz"
  assert_not_exists "${temp_root}/java/zulu11.87.17-sa-jdk11.0.30-linux_x64"
  assert_exists "${temp_root}/java/zulu11.86.20-sa-jdk11.0.30-linux_x64/bin/java"
}

test_fresh_run_overwrites_stale_old_jdk_state() {
  local temp_root=""
  local config_file=""
  local state_file=""

  temp_root="$(mktemp -d)"
  trap "rm -rf '${temp_root}'" RETURN
  config_file="${temp_root}/jdk_upgrade_dev.conf"
  state_file="${temp_root}/state/jdk_dev_11.0.31_old_jdk.env"

  mkdir -p "${temp_root}/java" "${temp_root}/state"
  make_fake_java "${temp_root}/java/zulu11.86.20-sa-jdk11.0.30-linux_x64" "11.0.30"
  make_fake_java "${temp_root}/java/zulu11.87.17-sa-jdk11.0.30-linux_x64" "11.0.30"
  ln -s zulu11.86.20-sa-jdk11.0.30-linux_x64 "${temp_root}/java/jdk11"
  ln -s zulu11.86.20-sa-jdk11.0.30-linux_x64 "${temp_root}/java/jdk1.8.0_191"
  printf 'OLD_JDK_BASENAME=%q\n' "zulu11.87.17-sa-jdk11.0.30-linux_x64" > "${state_file}"
  make_target_archive "${temp_root}"
  make_config "${config_file}" "${temp_root}" "yes"

  "${SCRIPT}" --env dev --config "${config_file}" --auto-continue

  assert_exists "${temp_root}/java/zulu11.86.20-sa-jdk11.0.30-linux_x64_$(date +%Y%m%d).tar.gz"
  assert_not_exists "${temp_root}/java/zulu11.86.20-sa-jdk11.0.30-linux_x64"
  assert_exists "${temp_root}/java/zulu11.87.17-sa-jdk11.0.30-linux_x64/bin/java"
  assert_contains "$(cat "${state_file}")" "zulu11.86.20-sa-jdk11.0.30-linux_x64"
}

test_old_jdk_basename_rejects_unsafe_values() {
  local temp_root=""
  local config_file=""
  local value=""
  local output=""

  temp_root="$(mktemp -d)"
  trap "rm -rf '${temp_root}'" RETURN
  config_file="${temp_root}/jdk_upgrade_dev.conf"

  mkdir -p "${temp_root}/java" "${temp_root}/software"
  make_config "${config_file}" "${temp_root}" "yes"

  for value in "../bad" "." ".."; do
    if output="$("${SCRIPT}" --env dev --config "${config_file}" --auto-continue --dry-run --old-jdk-basename "${value}" 2>&1)"; then
      fail "--old-jdk-basename should reject unsafe value: ${value}"
    fi
    assert_contains "${output}" "Refusing unsafe old JDK directory name"
  done
}

test_old_jdk_basename_rejects_target_jdk_dir() {
  local temp_root=""
  local config_file=""
  local output=""

  temp_root="$(mktemp -d)"
  trap "rm -rf '${temp_root}'" RETURN
  config_file="${temp_root}/jdk_upgrade_dev.conf"

  mkdir -p "${temp_root}/java" "${temp_root}/software"
  make_config "${config_file}" "${temp_root}" "yes"

  if output="$("${SCRIPT}" --env dev --config "${config_file}" --auto-continue --dry-run --old-jdk-basename zulu11.88.18-sa-jdk11.0.31-linux_x64 2>&1)"; then
    fail "--old-jdk-basename should reject the target JDK directory"
  fi
  assert_contains "${output}" "Refusing to archive/delete target JDK directory as old JDK"
}

main() {
  test_list_steps
  test_upgrade_archives_and_deletes_old_jdk
  test_upgrade_keeps_old_jdk_when_configured
  test_already_up_to_date_exits_without_archive
  test_dry_run_displays_readable_commands
  test_old_jdk_basename_override_archives_requested_directory
  test_fresh_run_overwrites_stale_old_jdk_state
  test_old_jdk_basename_rejects_unsafe_values
  test_old_jdk_basename_rejects_target_jdk_dir
  printf 'All JDK upgrade tests passed\n'
}

main "$@"
