#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${ROOT_DIR}/scripts/jdk/upgrade_jdk_on_db.sh"

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
DEFAULT_JAVA_VERSION="11.0.31"
DEFAULT_JDK_DIR="zulu11.88.18-sa-jdk11.0.31-linux_x64"
JDK_SYMLINKS=(jdk-11)
DELETE_OLD_JDK_AFTER_ARCHIVE="${delete_old}"
LOG_DIR="${temp_root}/logs"
STATE_DIR="${temp_root}/state"
LOG_RETENTION_DAYS=90
EOF
}

test_list_steps() {
  local output=""

  output="$("${SCRIPT}" --list-steps)"
  [[ "${output}" == *"step_4"* ]] || fail "--list-steps should include step_4"
}

test_upgrade_archives_and_deletes_old_jdk() {
  local temp_root=""
  local config_file=""

  temp_root="$(mktemp -d)"
  trap "rm -rf '${temp_root}'" RETURN
  config_file="${temp_root}/jdk_pg_upgrade_dev.conf"

  mkdir -p "${temp_root}/java"
  make_fake_java "${temp_root}/java/zulu11.86.20-sa-jdk11.0.30-linux_x64" "11.0.30"
  make_fake_java "${temp_root}/java/zulu11.88.18-sa-jdk11.0.31-linux_x64" "11.0.31"
  ln -s zulu11.86.20-sa-jdk11.0.30-linux_x64 "${temp_root}/java/jdk-11"
  make_config "${config_file}" "${temp_root}" "yes"

  "${SCRIPT}" --env dev --config "${config_file}" --auto-continue

  assert_symlink_target "${temp_root}/java/jdk-11" "zulu11.88.18-sa-jdk11.0.31-linux_x64"
  assert_exists "${temp_root}/java/zulu11.86.20-sa-jdk11.0.30-linux_x64_$(date +%Y%m%d).tar.gz"
  assert_not_exists "${temp_root}/java/zulu11.86.20-sa-jdk11.0.30-linux_x64"
}

test_already_target_is_idempotent() {
  local temp_root=""
  local config_file=""

  temp_root="$(mktemp -d)"
  trap "rm -rf '${temp_root}'" RETURN
  config_file="${temp_root}/jdk_pg_upgrade_dev.conf"

  mkdir -p "${temp_root}/java"
  make_fake_java "${temp_root}/java/zulu11.88.18-sa-jdk11.0.31-linux_x64" "11.0.31"
  ln -s zulu11.88.18-sa-jdk11.0.31-linux_x64 "${temp_root}/java/jdk-11"
  make_config "${config_file}" "${temp_root}" "yes"

  "${SCRIPT}" --env dev --config "${config_file}" --auto-continue

  assert_symlink_target "${temp_root}/java/jdk-11" "zulu11.88.18-sa-jdk11.0.31-linux_x64"
  assert_not_exists "${temp_root}/java/zulu11.88.18-sa-jdk11.0.31-linux_x64_$(date +%Y%m%d).tar.gz"
}

test_dry_run_displays_readable_commands() {
  local temp_root=""
  local config_file=""
  local output=""

  temp_root="$(mktemp -d)"
  trap "rm -rf '${temp_root}'" RETURN
  config_file="${temp_root}/jdk_pg_upgrade_dev.conf"

  mkdir -p "${temp_root}/java"
  make_config "${config_file}" "${temp_root}" "yes"

  output="$("${SCRIPT}" --env dev --config "${config_file}" --auto-continue --dry-run 2>&1)"

  assert_contains "${output}" "test -d ${temp_root}/java/zulu11.88.18-sa-jdk11.0.31-linux_x64"
  assert_contains "${output}" "ln -sfn zulu11.88.18-sa-jdk11.0.31-linux_x64 ${temp_root}/java/jdk-11"
  assert_contains "${output}" "Would verify active Java version contains 11.0.31"
}

test_old_jdk_basename_rejects_unsafe_values() {
  local temp_root=""
  local config_file=""
  local value=""
  local output=""

  temp_root="$(mktemp -d)"
  trap "rm -rf '${temp_root}'" RETURN
  config_file="${temp_root}/jdk_pg_upgrade_dev.conf"

  mkdir -p "${temp_root}/java"
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
  config_file="${temp_root}/jdk_pg_upgrade_dev.conf"

  mkdir -p "${temp_root}/java"
  make_config "${config_file}" "${temp_root}" "yes"

  if output="$("${SCRIPT}" --env dev --config "${config_file}" --auto-continue --dry-run --old-jdk-basename zulu11.88.18-sa-jdk11.0.31-linux_x64 2>&1)"; then
    fail "--old-jdk-basename should reject the target JDK directory"
  fi
  assert_contains "${output}" "Refusing to archive/delete target JDK directory as old JDK"
}

test_version_verification_failure_stops_workflow() {
  local temp_root=""
  local config_file=""
  local output=""

  temp_root="$(mktemp -d)"
  trap "rm -rf '${temp_root}'" RETURN
  config_file="${temp_root}/jdk_pg_upgrade_dev.conf"

  mkdir -p "${temp_root}/java"
  make_fake_java "${temp_root}/java/zulu11.86.20-sa-jdk11.0.30-linux_x64" "11.0.30"
  make_fake_java "${temp_root}/java/zulu11.88.18-sa-jdk11.0.31-linux_x64" "11.0.30"
  ln -s zulu11.86.20-sa-jdk11.0.30-linux_x64 "${temp_root}/java/jdk-11"
  make_config "${config_file}" "${temp_root}" "yes"

  if output="$("${SCRIPT}" --env dev --config "${config_file}" --auto-continue 2>&1)"; then
    fail "version verification should fail when target java reports the wrong version"
  fi
  assert_contains "${output}" "JDK upgrade verification failed. Expected java version 11.0.31"
}

main() {
  test_list_steps
  test_upgrade_archives_and_deletes_old_jdk
  test_already_target_is_idempotent
  test_dry_run_displays_readable_commands
  test_old_jdk_basename_rejects_unsafe_values
  test_old_jdk_basename_rejects_target_jdk_dir
  test_version_verification_failure_stops_workflow
  printf 'All PG JDK upgrade tests passed\n'
}

main "$@"
