# shellcheck shell=bash
# Terminal primitives: size, TTY checks, cursor, screen, key input.

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

term_clear() { [[ "${PLATFORM_TTY:-0}" == 1 ]] && printf '\033[2J\033[H'; return 0; }


# Alternate screen + SGR mouse reporting. With mouse reporting on, the wheel arrives as mouse
# events (which term_read_input reports as WHEEL_UP/WHEEL_DOWN) instead of being turned into
# arrow keys by the terminal — VS Code/xterm.js ignores the ?1007 opt-out, so this is the only
# reliable way to stop scrolling from moving the menu selection.
term_alt_screen_on()  { [[ "${PLATFORM_TTY:-0}" == 1 ]] && printf '\033[?1049h\033[?1000h\033[?1006h\033[H'; return 0; }
term_alt_screen_off() { [[ "${PLATFORM_TTY:-0}" == 1 ]] && printf '\033[?1006l\033[?1000l\033[?1049l'; return 0; }

term_hide_cursor() { [[ "${PLATFORM_TTY:-0}" == 1 ]] && printf '\033[?25l'; return 0; }
term_show_cursor() { [[ "${PLATFORM_TTY:-0}" == 1 ]] && printf '\033[?25h'; return 0; }

# True when more input is already queued (a burst of keys); used to skip intermediate redraws.
# Bash 3.2 has no fractional/zero read timeout, so there it always reports "nothing queued".
term_input_pending() {
  (( BASH_VERSINFO[0] >= 4 )) || return 1
  read -t 0 -r 2>/dev/null
}

# term_read_input — prints one key name: a literal character, ENTER, ESC, UP, DOWN, LEFT, RIGHT,
# PGUP, PGDN, HOME, END, WHEEL_UP, WHEEL_DOWN, RESIZE, or IGNORE (other mouse/unknown sequences).
# Returns 1 on EOF. Always called as $(term_read_input), so the WINCH trap only lives in that subshell;
# a trapped signal interrupts the blocking read, so a resize is reported immediately.
term_read_input() {
  local k ch seq=""
  trap 'echo RESIZE; exit 0' WINCH
  IFS= read -rsn1 k || return 1

  if [[ "$k" != $'\033' ]]; then
    if [[ -z "$k" || "$k" == $'\r' ]]; then echo ENTER; else printf '%s\n' "$k"; fi
    return 0
  fi

  # Bash 3.2 (macOS) only accepts whole-second timeouts.
  local t=0.05
  (( BASH_VERSINFO[0] >= 4 )) || t=1

  IFS= read -rsn1 -t "$t" ch 2>/dev/null || { echo ESC; return 0; }
  seq="$ch"
  if [[ "$ch" == '[' ]]; then
    # CSI: read until the final byte. Covers arrows, ~-keys and SGR mouse (ESC [ < b ; x ; y M).
    while IFS= read -rsn1 -t "$t" ch 2>/dev/null; do
      seq="$seq$ch"
      # X10 mouse: ESC [ M + 3 raw bytes.
      if [[ "$seq" == '[M' ]]; then read -rsn3 -t "$t" ch 2>/dev/null; echo IGNORE; return 0; fi
      [[ "$ch" == [[:alpha:]~@] ]] && break
    done
  elif [[ "$ch" == O ]]; then
    IFS= read -rsn1 -t "$t" ch 2>/dev/null && seq="$seq$ch"
  fi

  case "$seq" in
    '[A'|OA) echo UP ;;
    '[B'|OB) echo DOWN ;;
    '[C'|OC) echo RIGHT ;;
    '[D'|OD) echo LEFT ;;
    '[5~') echo PGUP ;;
    '[6~') echo PGDN ;;
    '[H'|OH|'[1~'|'[7~') echo HOME ;;
    '[F'|OF|'[4~'|'[8~') echo END ;;
    '[<64;'*M) echo WHEEL_UP ;;
    '[<65;'*M) echo WHEEL_DOWN ;;
    *) echo IGNORE ;;
  esac
}
