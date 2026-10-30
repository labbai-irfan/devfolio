# shellcheck shell=bash
# Diagnostics. User-facing text is printed by the UI layer; errors and debug output go to stderr.

[[ -n "${_LOG_SH:-}" ]] && return 0
_LOG_SH=1

log_error() { printf 'labbai-irfan: %s\n' "$*" >&2; }

log_debug() {
  if [[ "${LABBAI_DEBUG:-}" == 1 ]]; then printf 'debug: %s\n' "$*" >&2; fi
  return 0
}
