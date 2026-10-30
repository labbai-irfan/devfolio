# shellcheck shell=bash
# Small validators used before acting on data or printing untrusted text.

[[ -n "${_VALIDATE_SH:-}" ]] && return 0
_VALIDATE_SH=1

validate_url()         { [[ "$1" =~ ^(https://|mailto:)[^[:space:]]+$ ]]; }
validate_has_command() { command -v "$1" >/dev/null 2>&1; }

# Strips ANSI escapes and control characters so remote text cannot drive the terminal.
validate_sanitize() {
  printf '%s' "$1" | sed -e $'s/\033\\[[0-9;?]*[A-Za-z]//g' | tr -d '\000-\010\013-\037\177'
}
