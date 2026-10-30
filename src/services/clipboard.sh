# shellcheck shell=bash
# Copies text to the system clipboard.
# Returns 0 on success, 1 if no clipboard tool is available, 2 if the tool failed.

[[ -n "${_CLIPBOARD_SH:-}" ]] && return 0
_CLIPBOARD_SH=1

clipboard_copy() {
  local text="$1"
  [[ -n "$PLATFORM_CLIPBOARD" ]] || return 1
  log_debug "copy via $PLATFORM_CLIPBOARD"

  case "$PLATFORM_CLIPBOARD" in
    xclip) printf '%s' "$text" | xclip -selection clipboard >/dev/null 2>&1 || return 2 ;;
    xsel)  printf '%s' "$text" | xsel --clipboard --input >/dev/null 2>&1 || return 2 ;;
    *)     printf '%s' "$text" | "$PLATFORM_CLIPBOARD" >/dev/null 2>&1 || return 2 ;;
  esac
}
