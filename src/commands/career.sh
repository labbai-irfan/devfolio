# shellcheck shell=bash
# Section 4 — Career submenu: Experience, Education, Certifications, Timeline.

[[ -n "${_CMD_CAREER_SH:-}" ]] && return 0
_CMD_CAREER_SH=1

cmd_career() { menu_loop career_render career_handle; }

career_render() {
  layout_header "Career"
  menu_items "1:Experience" "2:Education" "3:Certifications" "4:Timeline"
  menu_prompt
  layout_footer
}

career_handle() {
  case "$1" in
    1) section_view "Experience" career_experience_body ;;
    2) section_view "Education" career_education_body ;;
    3) section_view "Certifications" career_certifications_body ;;
    4) section_view "Timeline" career_timeline_body ;;
    *) return 1 ;;
  esac
}

# Newest first, merged from dated experience, education and certifications (built by scripts/build.sh).
career_timeline_body() {
  local i
  if (( ${#TIMELINE_DATE[@]} == 0 )); then layout_empty; return 0; fi
  for (( i = 0; i < ${#TIMELINE_DATE[@]}; i++ )); do
    printf '%s%s%-8s%s %s%-14s%s %s\n' "$LAYOUT_MARGIN" "$C_DIM" "${TIMELINE_DATE[$i]}" "$C_RESET" \
      "$C_ACCENT" "${TIMELINE_KIND[$i]}" "$C_RESET" "${TIMELINE_TEXT[$i]}"
  done
  return 0
}

career_experience_body() {
  local i h
  local -a highlights
  if (( ${#EXPERIENCE_ROLE[@]} == 0 )); then layout_empty; return 0; fi
  for (( i = 0; i < ${#EXPERIENCE_ROLE[@]}; i++ )); do
    layout_title_right "${EXPERIENCE_ROLE[$i]}" "${EXPERIENCE_START[$i]} – ${EXPERIENCE_END[$i]}"
    printf '%s%s%s' "$LAYOUT_MARGIN" "$C_ACCENT" "${EXPERIENCE_COMPANY[$i]}"
    [[ -n "${EXPERIENCE_LOCATION[$i]}" ]] && printf ' %s%s %s' "$C_DIM" "$ICON_DOT" "${EXPERIENCE_LOCATION[$i]}"
    printf '%s\n' "$C_RESET"
    layout_split highlights "${EXPERIENCE_HIGHLIGHTS[$i]}"
    for h in ${highlights[@]+"${highlights[@]}"}; do
      [[ -n "$h" ]] && layout_wrap "$ICON_DOT $h" "  "
    done
    printf '\n'
  done
}

career_education_body() {
  local i
  if (( ${#EDUCATION_DEGREE[@]} == 0 )); then layout_empty; return 0; fi
  for (( i = 0; i < ${#EDUCATION_DEGREE[@]}; i++ )); do
    layout_title_right "${EDUCATION_DEGREE[$i]}" "${EDUCATION_START[$i]} – ${EDUCATION_END[$i]}"
    printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "$C_ACCENT" "${EDUCATION_INSTITUTION[$i]}" "$C_RESET"
    [[ -n "${EDUCATION_NOTES[$i]}" ]] && layout_wrap "${EDUCATION_NOTES[$i]}" "  "
    printf '\n'
  done
}

career_certifications_body() {
  local i
  if (( ${#CERT_NAME[@]} == 0 )); then layout_empty; return 0; fi
  for (( i = 0; i < ${#CERT_NAME[@]}; i++ )); do
    layout_title_right "${CERT_NAME[$i]}" "${CERT_DATE[$i]}"
    printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "$C_ACCENT" "${CERT_ISSUER[$i]}" "$C_RESET"
    [[ -n "${CERT_URL[$i]}" ]] && printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "$C_DIM" "${CERT_URL[$i]}" "$C_RESET"
    printf '\n'
  done
}
