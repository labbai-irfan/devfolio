# shellcheck shell=bash
# Color palette: Minimal, sophisticated, modern dark terminal palette.
# Primary Cyan: #00D9FF (ANSI 256 #45 / #51)
# Secondary Green: #45E89A (ANSI 256 #84 / #48)
# Primary Text: #E8E8E8 (ANSI 256 #254)
# Secondary Text: #858585 (ANSI 256 #244 / #245)
# Accent Purple / Slate: (ANSI 256 #141)

[[ -n "${_COLORS_SH:-}" ]] && return 0
_COLORS_SH=1

C_ACCENT="" C_DIM="" C_BOLD="" C_OK="" C_WARN="" C_ERR="" C_RESET=""
C_CYAN="" C_BLUE="" C_PURPLE="" C_GREEN="" C_YELLOW="" C_WHITE="" C_MUTED="" C_BORDER=""

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
    C_CYAN=$'\033[1m'
    C_BLUE=$'\033[1m'
    C_PURPLE=$'\033[1m'
    C_GREEN=$'\033[1m'
    C_YELLOW=$'\033[1m'
    C_WHITE=$'\033[1m'
    C_MUTED=$'\033[2m'
    C_BORDER=$'\033[2m'
  else
    # 256-color palette
    C_ACCENT=$'\033[38;5;51m'     # Vibrant Electric Cyan (#00D9FF)
    C_CYAN=$'\033[38;5;45m'       # Deep Sky Cyan
    C_BLUE=$'\033[38;5;75m'       # Soft Steel Blue
    C_PURPLE=$'\033[38;5;141m'    # Lavender
    C_GREEN=$'\033[38;5;84m'      # Mint Green (#45E89A)
    C_YELLOW=$'\033[38;5;221m'    # Amber Warmth
    C_WHITE=$'\033[38;5;254m'     # Primary Text (#E8E8E8)
    C_MUTED=$'\033[38;5;244m'     # Secondary Text (#858585)
    C_BORDER=$'\033[38;5;239m'    # Sophisticated Border (#555555)
    C_OK=$'\033[38;5;84m'
    C_WARN=$'\033[38;5;221m'
    C_ERR=$'\033[38;5;203m'
  fi
}
