# shellcheck shell=bash
# Section 1 — About: quick facts at a glance (current role, location, status, focus areas),
# then the profile paragraphs.

[[ -n "${_CMD_ABOUT_SH:-}" ]] && return 0
_CMD_ABOUT_SH=1

cmd_about() { section_view "About" about_body "$PROFILE_NAME"; }

about_body() {
  local i role="" label="${C_CYAN:-${C_ACCENT:-}}${C_BOLD:-}" focus=""
  local -a titles=("PROFILE" "CURRENT FOCUS")

  # Current role: the first experience entry that has not ended.
  for (( i = 0; i < ${#EXPERIENCE_ROLE[@]}; i++ )); do
    if [[ "${EXPERIENCE_END[i]}" == present ]]; then
      role="${EXPERIENCE_ROLE[i]} at ${EXPERIENCE_COMPANY[i]}"
      break
    fi
  done
  local IFS='|'
  focus="${PROFILE_FOCUS[*]-}"
  IFS=$' \t\n'

  [[ -n "$role" ]] && layout_kv "Role" "$role" 11 "$label"
  [[ -n "$PROFILE_LOCATION" ]] && layout_kv "Based in" "$PROFILE_LOCATION" 11 "$label"
  [[ -n "$PROFILE_AVAILABILITY" ]] && layout_kv "Status" "$ICON_BULLET $PROFILE_AVAILABILITY" 11 "$label" "${C_GREEN:-${C_OK:-}}"
  [[ -n "$focus" ]] && layout_list 11 "Areas" "$focus"

  for (( i = 0; i < ${#PROFILE_ABOUT[@]}; i++ )); do
    printf '\n'
    (( i < ${#titles[@]} )) && layout_section_title "${titles[i]}"
    layout_wrap "${PROFILE_ABOUT[i]}" "  " "${C_WHITE:-}"
  done
  return 0
}
