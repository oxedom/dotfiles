#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
guard_file="$repo_root/shell/pnpm-dev-guard.bash"
test_tmp="$(mktemp -d)"
trap 'rm -rf -- "$test_tmp"' EXIT

fake_bin="$test_tmp/bin"
trace_file="$test_tmp/trace"
stdout_file="$test_tmp/stdout"
stderr_file="$test_tmp/stderr"
mkdir -p "$fake_bin"

cat >"$fake_bin/pnpm" <<'FAKE_PNPM'
#!/usr/bin/env bash
printf 'pnpm' >>"$TRACE_FILE"
printf '\t%s' "$@" >>"$TRACE_FILE"
printf '\n' >>"$TRACE_FILE"
FAKE_PNPM

cat >"$fake_bin/git" <<'FAKE_GIT'
#!/usr/bin/env bash
if [[ ${FAKE_GIT_FAIL:-0} == 1 ]]; then
  exit 128
fi
printf '%s\n' "${FAKE_GIT_COMMON_DIR:-/outside/repository/.git}"
FAKE_GIT

cat >"$fake_bin/systemctl" <<'FAKE_SYSTEMCTL'
#!/usr/bin/env bash
printf 'systemctl' >>"$TRACE_FILE"
printf '\t%s' "$@" >>"$TRACE_FILE"
printf '\n' >>"$TRACE_FILE"
[[ ${FAKE_SCOPE_ACTIVE:-0} == 1 ]]
FAKE_SYSTEMCTL

cat >"$fake_bin/systemd-run" <<'FAKE_SYSTEMD_RUN'
#!/usr/bin/env bash
printf 'systemd-run' >>"$TRACE_FILE"
printf '\t%s' "$@" >>"$TRACE_FILE"
printf '\n' >>"$TRACE_FILE"
exit "${FAKE_SYSTEMD_RUN_STATUS:-0}"
FAKE_SYSTEMD_RUN

chmod 0755 "$fake_bin/pnpm" "$fake_bin/git" \
  "$fake_bin/systemctl" "$fake_bin/systemd-run"

case_status=0

run_guard() {
  : >"$trace_file"
  : >"$stdout_file"
  : >"$stderr_file"

  set +e
  PATH="$fake_bin:$PATH" \
    TRACE_FILE="$trace_file" \
    GUARD_FILE="$guard_file" \
    FAKE_GIT_FAIL="${FAKE_GIT_FAIL:-0}" \
    FAKE_GIT_COMMON_DIR="${FAKE_GIT_COMMON_DIR:-/outside/repository/.git}" \
    FAKE_SCOPE_ACTIVE="${FAKE_SCOPE_ACTIVE:-0}" \
    FAKE_SYSTEMD_RUN_STATUS="${FAKE_SYSTEMD_RUN_STATUS:-0}" \
    bash --noprofile --norc -c '
      set -e
      PNPM_DEV_GUARD_COMMON_GIT_DIR=/workspace/product/.git
      PNPM_DEV_GUARD_UNIT=product-dev
      PNPM_DEV_GUARD_MEMORY_HIGH=2G
      PNPM_DEV_GUARD_MEMORY_MAX=3G
      . "$GUARD_FILE"
      pnpm "$@"
    ' pnpm-dev-guard-test "$@" >"$stdout_file" 2>"$stderr_file"
  case_status=$?
  set -e
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_status() {
  local test_name=$1 expected=$2
  [[ $case_status -eq $expected ]] ||
    fail "$test_name: expected status $expected, got $case_status; stderr: $(<"$stderr_file")"
}

assert_file_equals() {
  local test_name=$1 expected=$2 file=$3
  local expected_file="$test_tmp/expected"
  printf '%s' "$expected" >"$expected_file"
  if ! cmp -s "$expected_file" "$file"; then
    printf 'FAIL: %s\n' "$test_name" >&2
    diff -u "$expected_file" "$file" >&2 || true
    exit 1
  fi
}

assert_file_contains() {
  local test_name=$1 expected=$2 file=$3
  grep -Fq -- "$expected" "$file" ||
    fail "$test_name: expected '$expected' in $file; got: $(<"$file")"
}

assert_file_empty() {
  local test_name=$1 file=$2
  [[ ! -s $file ]] || fail "$test_name: expected empty $file; got: $(<"$file")"
}

FAKE_GIT_COMMON_DIR=/workspace/product/.git run_guard test
assert_status 'ordinary command status' 0
assert_file_equals 'ordinary command passes through' $'pnpm\ttest\n' "$trace_file"

FAKE_GIT_COMMON_DIR=/outside/repository/.git run_guard dev:all
assert_status 'outside checkout status' 0
assert_file_equals 'outside checkout passes through' $'pnpm\tdev:all\n' "$trace_file"

FAKE_GIT_FAIL=1 run_guard dev:all
assert_status 'failed Git lookup status' 0
assert_file_equals 'failed Git lookup passes through' $'pnpm\tdev:all\n' "$trace_file"

expected_guarded_trace=$'systemctl\t--user\t--quiet\tis-active\tproduct-dev.scope\n'
expected_guarded_trace+=$'systemd-run\t--user\t--scope\t--collect\t--quiet\t--unit=product-dev\t--property=MemoryHigh=2G\t--property=MemoryMax=3G\t--\t'
expected_guarded_trace+="$fake_bin/pnpm"

FAKE_GIT_COMMON_DIR=/workspace/product/.git run_guard dev:all
assert_status 'guarded shorthand status' 0
assert_file_equals 'guarded shorthand uses configured scope' \
  "$expected_guarded_trace"$'\tdev:all\n' "$trace_file"

FAKE_GIT_COMMON_DIR=/workspace/product/.git run_guard run dev:all
assert_status 'guarded explicit run status' 0
assert_file_equals 'guarded explicit run retains arguments' \
  "$expected_guarded_trace"$'\trun\tdev:all\n' "$trace_file"

FAKE_GIT_COMMON_DIR=/workspace/product/.git FAKE_SCOPE_ACTIVE=1 run_guard dev:all
assert_status 'duplicate status' 75
assert_file_equals 'duplicate only checks active scope' \
  $'systemctl\t--user\t--quiet\tis-active\tproduct-dev.scope\n' "$trace_file"
assert_file_contains 'duplicate explains refusal' \
  'pnpm dev:all is already running in product-dev.scope; refusing a duplicate.' \
  "$stderr_file"

FAKE_GIT_COMMON_DIR=/workspace/product/.git \
  FAKE_SYSTEMD_RUN_STATUS=42 run_guard dev:all
assert_status 'systemd-run failure status' 42
assert_file_equals 'systemd-run failure has no direct fallback' \
  "$expected_guarded_trace"$'\tdev:all\n' "$trace_file"
assert_file_empty 'systemd-run failure does not invent output' "$stdout_file"

printf 'PASS: 7 pnpm dev guard behavior tests\n'
