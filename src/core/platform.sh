# shellcheck shell=bash
# Detects OS, terminal capabilities and external tools (browser, clipboard) once at startup.

[[ -n "${_PLATFORM_SH:-}" ]] && return 0
_PLATFORM_SH=1

PLATFORM_OS="unknown"   # linux | macos | wsl | gitbash | unknown
PLATFORM_TTY=0
PLATFORM_UTF8=0
PLATFORM_WIDTH=80
PLATFORM_OPENER=""      # command that opens a URL, empty if none found
PLATFORM_CLIPBOARD=""   # command that copies stdin, empty if none found

platform_detect() {
  case "$(uname -s 2>/dev/null || true)" in
    Darwin) PLATFORM_OS="macos" ;;
    MINGW*|MSYS*|CYGWIN*) PLATFORM_OS="gitbash" ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then PLATFORM_OS="wsl"; else PLATFORM_OS="linux"; fi ;;
  esac

  if term_is_tty; then PLATFORM_TTY=1; fi
  if [[ "${CFG_PLAIN:-0}" != 1 ]] && term_supports_utf8; then PLATFORM_UTF8=1; fi
  PLATFORM_WIDTH="$(term_width)"
  platform_detect_tools

  log_debug "os=$PLATFORM_OS tty=$PLATFORM_TTY utf8=$PLATFORM_UTF8 width=$PLATFORM_WIDTH opener=$PLATFORM_OPENER clipboard=$PLATFORM_CLIPBOARD"
}

# platform_first_command CANDIDATE... — prints the first candidate that exists on PATH.
platform_first_command() {
  local c
  for c in "$@"; do
    if validate_has_command "$c"; then printf '%s' "$c"; return 0; fi
  done
  return 1
}

platform_detect_tools() {
  case "$PLATFORM_OS" in
    macos)
      PLATFORM_OPENER="$(platform_first_command open || true)"
      PLATFORM_CLIPBOARD="$(platform_first_command pbcopy || true)" ;;
    wsl)
      PLATFORM_OPENER="$(platform_first_command wslview explorer.exe xdg-open || true)"
      PLATFORM_CLIPBOARD="$(platform_first_command clip.exe || true)" ;;
    gitbash)
      PLATFORM_OPENER="$(platform_first_command cmd.exe explorer.exe || true)"
      PLATFORM_CLIPBOARD="$(platform_first_command clip.exe clip || true)" ;;
    *)
      PLATFORM_OPENER="$(platform_first_command xdg-open || true)"
      if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        PLATFORM_CLIPBOARD="$(platform_first_command wl-copy xclip xsel || true)"
      else
        PLATFORM_CLIPBOARD="$(platform_first_command xclip xsel wl-copy || true)"
      fi ;;
  esac
}
