# shellcheck shell=bash
# Start-up animation: a typed "whoami" and a short spinner, about one second in total.
# Only runs in an interactive terminal, and is skipped by --no-animation or --plain.

[[ -n "${_INTRO_SH:-}" ]] && return 0
_INTRO_SH=1

intro_play() {
  [[ "${CFG_ANIMATE:-1}" == 1 && "${CFG_PLAIN:-0}" == 0 && "${PLATFORM_TTY:-0}" == 1 ]] || return 0

  local cmd="whoami" i
  local -a spin
  if [[ "$PLATFORM_UTF8" == 1 ]]; then
    spin=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  else
    spin=('|' '/' '-' "\\")
  fi

  term_clear
  printf '\n%s  %s$%s ' "$LAYOUT_MARGIN" "$C_OK" "$C_RESET"
  for (( i = 0; i < ${#cmd}; i++ )); do
    printf '%s' "${cmd:$i:1}"
    sleep 0.04
  done
  printf '\n'
  sleep 0.2

  for (( i = 0; i < 12; i++ )); do
    printf '\r%s  %s%s%s Loading profile…' "$LAYOUT_MARGIN" "$C_ACCENT" "${spin[$(( i % ${#spin[@]} ))]}" "$C_RESET"
    sleep 0.07
  done
  printf '\r\033[K'
}
