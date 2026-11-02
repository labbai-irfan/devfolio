# shellcheck shell=bash
# Start-up flourish: a typed "whoami" answered with the real name and title (~0.3 s).
# It shows no progress steps, because no real work happens here worth reporting.
# Skipped without a TTY, with --no-animation/--plain, or with LABBAI_REDUCED_MOTION=1.

[[ -n "${_INTRO_SH:-}" ]] && return 0
_INTRO_SH=1

intro_play() {
  [[ "${CFG_PLAIN:-0}" == 0 ]] && anim_enabled || return 0

  local cmd="whoami" i
  term_clear
  printf '\n%s%s$%s ' "$LAYOUT_MARGIN" "${C_OK:-}" "${C_RESET:-}"
  for (( i = 0; i < ${#cmd}; i++ )); do
    printf '%s' "${cmd:i:1}"
    sleep 0.03
  done
  printf '\n%s%s%s%s  %s%s%s\n' "$LAYOUT_MARGIN" "${C_BOLD:-}${C_ACCENT:-}" "$PROFILE_NAME" "${C_RESET:-}" \
    "${C_MUTED:-${C_DIM:-}}" "$PROFILE_TITLE" "${C_RESET:-}"
  sleep 0.15
}
