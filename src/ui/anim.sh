# shellcheck shell=bash
# Spinner for real background work (network calls, downloads) — never fake progress.
# The slow call itself still runs synchronously in the caller; only the animation is backgrounded,
# so the caller's variable assignments are unaffected. Auto-disabled without a TTY, with
# --no-animation/--plain, or when LABBAI_REDUCED_MOTION=1.

[[ -n "${_ANIM_SH:-}" ]] && return 0
_ANIM_SH=1

ANIM_SPIN_PID=""

anim_enabled() {
  [[ "${CFG_ANIMATE:-1}" == 1 && "${LABBAI_REDUCED_MOTION:-0}" != 1 && "${PLATFORM_TTY:-0}" == 1 ]]
}

# anim_spin_start MESSAGE — starts a spinner for the work the caller is about to do.
# Prints MESSAGE once (no animation) when animation is disabled.
anim_spin_start() {
  local msg="$1"
  if ! anim_enabled; then
    printf '%s  %s%s%s\n' "$LAYOUT_MARGIN" "${C_DIM:-}" "$msg" "${C_RESET:-}"
    return 0
  fi
  (
    local -a morph_frames=("◐" "◓" "◑" "◒")
    if [[ "${PLATFORM_UTF8:-0}" != 1 ]]; then
      morph_frames=("|" "/" "-" "\\")
    fi
    local i=0 c_cyan="${C_CYAN:-${C_ACCENT:-}}" c_blue="${C_BLUE:-}" c_reset="${C_RESET:-}" color glyph
    while :; do
      glyph="${morph_frames[$(( i % ${#morph_frames[@]} ))]}"
      if (( i % 2 == 0 )); then color="$c_cyan"; else color="$c_blue"; fi
      printf '\r%s  %s%s%s %s...\033[K' "$LAYOUT_MARGIN" "$color" "$glyph" "$c_reset" "$msg"
      i=$(( i + 1 ))
      sleep 0.08
    done
  ) &
  ANIM_SPIN_PID=$!
}

# anim_spin_stop — stops the spinner started above and clears its line. Safe to call unconditionally.
anim_spin_stop() {
  [[ -n "$ANIM_SPIN_PID" ]] || return 0
  kill "$ANIM_SPIN_PID" 2>/dev/null
  wait "$ANIM_SPIN_PID" 2>/dev/null
  ANIM_SPIN_PID=""
  anim_enabled && printf '\r\033[K'
  return 0
}
