# shellcheck shell=bash

# Opt-in guard for one pnpm dev:all process per Git repository. Source this file
# after setting PNPM_DEV_GUARD_COMMON_GIT_DIR in a machine-local configuration.

_PNPM_DEV_GUARD_COMMON_GIT_DIR="$(
  realpath -m -- "${PNPM_DEV_GUARD_COMMON_GIT_DIR:?must be set before sourcing pnpm-dev-guard.bash}"
)"
_PNPM_DEV_GUARD_UNIT="${PNPM_DEV_GUARD_UNIT:-pnpm-dev-all}"
_PNPM_DEV_GUARD_MEMORY_HIGH="${PNPM_DEV_GUARD_MEMORY_HIGH:-3G}"
_PNPM_DEV_GUARD_MEMORY_MAX="${PNPM_DEV_GUARD_MEMORY_MAX:-4G}"
_PNPM_DEV_GUARD_BIN="$(type -P pnpm)"

_pnpm_dev_guard_is_dev_all() {
  [[ $# -eq 1 && $1 == dev:all ]] ||
    [[ $# -eq 2 && $1 == run && $2 == dev:all ]]
}

_pnpm_dev_guard_is_target_checkout() {
  local common_dir
  common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  [[ "$(realpath -m -- "$common_dir")" == "$_PNPM_DEV_GUARD_COMMON_GIT_DIR" ]]
}

pnpm() {
  if [[ -z $_PNPM_DEV_GUARD_BIN ]]; then
    printf '%s\n' 'pnpm dev guard could not resolve the pnpm executable.' >&2
    return 127
  fi

  if ! _pnpm_dev_guard_is_dev_all "$@" ||
    ! _pnpm_dev_guard_is_target_checkout; then
    "$_PNPM_DEV_GUARD_BIN" "$@"
    return
  fi

  if systemctl --user --quiet is-active "$_PNPM_DEV_GUARD_UNIT.scope"; then
    printf 'pnpm dev:all is already running in %s.scope; refusing a duplicate.\n' \
      "$_PNPM_DEV_GUARD_UNIT" >&2
    return 75
  fi

  systemd-run --user --scope --collect --quiet \
    "--unit=$_PNPM_DEV_GUARD_UNIT" \
    "--property=MemoryHigh=$_PNPM_DEV_GUARD_MEMORY_HIGH" \
    "--property=MemoryMax=$_PNPM_DEV_GUARD_MEMORY_MAX" \
    -- "$_PNPM_DEV_GUARD_BIN" "$@"
}
