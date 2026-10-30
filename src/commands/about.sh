# shellcheck shell=bash
# Section 1 — About.

[[ -n "${_CMD_ABOUT_SH:-}" ]] && return 0
_CMD_ABOUT_SH=1

cmd_about() { section_view "About" about_body; }

about_body() {
  local p
  for p in ${PROFILE_ABOUT[@]+"${PROFILE_ABOUT[@]}"}; do
    layout_wrap "$p"
    printf '\n'
  done
  (( ${#PROFILE_ABOUT[@]} == 0 )) && { layout_empty; printf '\n'; }
  layout_kv "Location" "$PROFILE_LOCATION" 14
  [[ -n "$PROFILE_AVAILABILITY" ]] && layout_kv "Availability" "$PROFILE_AVAILABILITY" 14
  return 0
}
