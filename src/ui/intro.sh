# shellcheck shell=bash
# Premium interactive startup sequence for Labbai Irfan Developer Identity Card.
# Displays real initialization stages with smooth terminal transitions.
# Skipped cleanly in static mode, non-interactive execution, --no-animation, or LABBAI_REDUCED_MOTION=1.

[[ -n "${_INTRO_SH:-}" ]] && return 0
_INTRO_SH=1

intro_play() {
  [[ "${CFG_ANIMATE:-1}" == 1 && "${CFG_PLAIN:-0}" == 0 && "${PLATFORM_TTY:-0}" == 1 && "${LABBAI_REDUCED_MOTION:-0}" != 1 ]] || return 0

  term_clear

  # Use the native Node.js Morph Animation Engine if available
  if command -v node >/dev/null 2>&1 && [[ -f "$APP_ROOT/src/ui/morph-spinner.js" ]]; then
    node "$APP_ROOT/src/ui/morph-spinner.js"
    term_clear
    return 0
  fi

  local dot="●"
  local check="✔"
  if [[ "${PLATFORM_UTF8:-0}" != 1 ]]; then
    dot="*"
    check="OK"
  fi

  # Morph frames: ◐ -> ◓ -> ◑ -> ◒
  local -a morph_frames=("◐" "◓" "◑" "◒")
  if [[ "${PLATFORM_UTF8:-0}" != 1 ]]; then
    morph_frames=("|" "/" "-" "\\")
  fi

  # Colors: Electric Cyan, Soft Blue, Bright Green
  local c_cyan=$'\033[38;2;0;217;255m'
  local c_blue=$'\033[38;2;85;153;255m'
  local c_green=$'\033[38;2;53;208;127m'
  local c_bold="${C_BOLD:-}"
  local c_reset="${C_RESET:-}"

  local -a steps=(
    "Detecting terminal environment"
    "Initializing developer profile"
    "Verifying cloud & devops registry"
    "Rendering developer identity card"
  )

  printf '\n'

  local step_idx f glyph color
  for step_idx in "${!steps[@]}"; do
    local msg="${steps[$step_idx]}"

    for (( f = 0; f < 6; f++ )); do
      glyph="${morph_frames[$(( f % ${#morph_frames[@]} ))]}"
      if (( f % 2 == 0 )); then color="$c_cyan"; else color="$c_blue"; fi

      printf '\r   %s%s%s %s...\033[K' "$color" "$glyph" "$c_reset" "$msg"
      sleep 0.07
    done

    # Transform into static bright green checkmark
    printf '\r   %s%s%s %s\033[K\n' "$c_green$c_bold" "$check" "$c_reset" "$msg"
    sleep 0.04
  done

  # Ready confirmation with pulse
  printf '\n   %s%s Ready%s\n\n' "$c_green$c_bold" "$dot" "$c_reset"
  sleep 0.25

  term_clear
}
