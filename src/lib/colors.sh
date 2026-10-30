# shellcheck shell=bash
# Color palette. One accent, dim labels, three status colors. Everything is empty when colors are off.

[[ -n "${_COLORS_SH:-}" ]] && return 0
_COLORS_SH=1

C_ACCENT="" C_DIM="" C_BOLD="" C_OK="" C_WARN="" C_ERR="" C_RESET=""

# Colors are on only for a TTY, unless disabled by --no-color, --plain or NO_COLOR.
colors_init() {
  if [[ "${CFG_COLOR:-1}" != 1 || -n "${NO_COLOR:-}" || "${PLATFORM_TTY:-0}" != 1 || "${TERM:-}" == dumb ]]; then
    return 0
  fi
  C_DIM=$'\033[2m'
  C_BOLD=$'\033[1m'
  C_RESET=$'\033[0m'
  if [[ "${CFG_THEME:-default}" == mono ]]; then
    # Mono: no hue, emphasis by weight only.
    C_ACCENT=$'\033[1m'
    C_OK=$'\033[1m'
    C_WARN=$'\033[1m'
    C_ERR=$'\033[1m'
  else
    C_ACCENT=$'\033[36m'
    C_OK=$'\033[32m'
    C_WARN=$'\033[33m'
    C_ERR=$'\033[31m'
  fi
}
