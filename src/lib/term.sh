# shellcheck shell=bash
# Terminal primitives: size, TTY checks, cursor, screen, single-key input.

[[ -n "${_TERM_SH:-}" ]] && return 0
_TERM_SH=1

term_is_tty() { [[ -t 0 && -t 1 ]]; }

# Width via tput → $COLUMNS → 80.
term_width() {
  local w=""
  if command -v tput >/dev/null 2>&1; then w="$(tput cols 2>/dev/null || true)"; fi
  [[ "$w" =~ ^[0-9]+$ ]] || w="${COLUMNS:-}"
  [[ "$w" =~ ^[0-9]+$ ]] || w=80
  printf '%s' "$w"
}

# Height via tput → $LINES → 24.
term_height() {
  local h=""
  if command -v tput >/dev/null 2>&1; then h="$(tput lines 2>/dev/null || true)"; fi
  [[ "$h" =~ ^[0-9]+$ ]] || h="${LINES:-}"
  [[ "$h" =~ ^[0-9]+$ ]] || h=24
  printf '%s' "$h"
}

term_supports_utf8() {
  case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
    *[Uu][Tt][Ff]-8*|*[Uu][Tt][Ff]8*) return 0 ;;
  esac
  # Windows Terminal and mintty (Git Bash) are UTF-8 even without a locale.
  [[ -n "${WT_SESSION:-}" || -n "${MSYSTEM:-}" ]]
}

term_clear() {
  if [[ "${PLATFORM_TTY:-0}" == 1 ]]; then
    # \033[2J clears visible viewport, \033[H positions cursor at top-left
    printf '\033[2J\033[H'
  fi
  return 0
}
term_alt_screen_on()  { [[ "${PLATFORM_TTY:-0}" == 1 ]] && printf '\033[?1049h\033[H'; return 0; }
term_alt_screen_off() { [[ "${PLATFORM_TTY:-0}" == 1 ]] && printf '\033[?1049l'; return 0; }
term_hide_cursor()    { [[ "${PLATFORM_TTY:-0}" == 1 ]] && printf '\033[?25l'; return 0; }
term_show_cursor()    { [[ "${PLATFORM_TTY:-0}" == 1 ]] && printf '\033[?25h'; return 0; }

# term_read_key VAR — reads one key into VAR. Returns 1 on EOF (stdin closed).
term_read_key() {
  IFS= read -rsn1 "$1"
}
