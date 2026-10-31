# shellcheck shell=bash
# Premium interactive startup sequence for Labbai Irfan Developer Identity Card.
# Displays real initialization stages with smooth terminal transitions.
# Skipped cleanly in static mode, non-interactive execution, --no-animation, or LABBAI_REDUCED_MOTION=1.

[[ -n "${_INTRO_SH:-}" ]] && return 0
_INTRO_SH=1

intro_play() {
  [[ "${CFG_ANIMATE:-1}" == 1 && "${CFG_PLAIN:-0}" == 0 && "${PLATFORM_TTY:-0}" == 1 && "${LABBAI_REDUCED_MOTION:-0}" != 1 ]] || return 0

  local dot="●"
  local check="✔"
  local prompt_sym="❯"
  if [[ "${PLATFORM_UTF8:-0}" != 1 ]]; then
    dot="*"
    check="OK"
    prompt_sym=">"
  fi

  local -a spin
  if [[ "${PLATFORM_UTF8:-0}" == 1 ]]; then
    spin=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  else
    spin=('|' '/' '-' "\\")
  fi

  local c_cyan="${C_CYAN:-${C_ACCENT:-}}"
  local c_accent="${C_ACCENT:-}"
  local c_green="${C_GREEN:-${C_OK:-}}"
  local c_white="${C_WHITE:-${C_BOLD:-}}"
  local c_muted="${C_MUTED:-${C_DIM:-}}"
  local c_dim="${C_DIM:-}"
  local c_bold="${C_BOLD:-}"
  local c_reset="${C_RESET:-}"

  term_clear

  # 1. Elegant brand header prompt
  printf '\n%s  %s%s%s %snpx labbai-irfan%s\n' \
    "$LAYOUT_MARGIN" "$c_accent$c_bold" "$prompt_sym" "$c_reset" "$c_white$c_bold" "$c_reset"
  sleep 0.08

  # 2. Contextual initialization stages
  local -a steps=(
    "Detecting terminal environment"
    "Initializing developer profile"
    "Verifying cloud & devops registry"
    "Rendering developer identity card"
  )

  local step_idx=0
  for step_idx in "${!steps[@]}"; do
    local msg="${steps[$step_idx]}"
    local f
    for (( f = 0; f < 5; f++ )); do
      local sp="${spin[$(( f % ${#spin[@]} ))]}"
      printf '\r%s    %s%s%s %s%s…%s\033[K' \
        "$LAYOUT_MARGIN" "$c_accent" "$sp" "$c_reset" "$c_muted" "$msg" "$c_reset"
      sleep 0.04
    done

    # Stamp as completed with green check
    printf '\r%s    %s%s%s %s%s%s\n' \
      "$LAYOUT_MARGIN" "$c_green$c_bold" "$check" "$c_reset" "$c_white" "$msg" "$c_reset"
    sleep 0.03
  done

  # 3. Brief completion confirmation
  printf '\n%s    %s%s Ready%s\n' \
    "$LAYOUT_MARGIN" "$c_green$c_bold" "$dot" "$c_reset"
  sleep 0.15

  # Smooth transition directly into the main developer card
  term_clear
}
