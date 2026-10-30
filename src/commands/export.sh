# shellcheck shell=bash
# --json: prints the whole profile as JSON (built by scripts/build.sh).

[[ -n "${_CMD_EXPORT_SH:-}" ]] && return 0
_CMD_EXPORT_SH=1

cmd_export() {
  local file="$APP_ROOT/src/data/generated/profile.json"
  if [[ ! -f "$file" ]]; then
    log_error "profile data is not built yet. Run: npm run build"
    exit "$EXIT_DEPENDENCY"
  fi
  cat "$file"
}
