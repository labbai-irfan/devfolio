# shellcheck shell=bash
# Section 4 — Career submenu: Experience, Education, Certifications, and a vertical Timeline.

[[ -n "${_CMD_CAREER_SH:-}" ]] && return 0
_CMD_CAREER_SH=1

cmd_career() { menu_loop career_render career_handle; }

career_render() {
  layout_header "Career"
  menu_items "1:Experience" "2:Education" "3:Certifications" "4:Timeline"
  menu_prompt
}

career_handle() {
  case "$1" in
    1) section_view "Experience" career_experience_body ;;
    2) section_view "Education" career_education_body ;;
    3) section_view "Certifications" career_certifications_body ;;
    4) section_view "Timeline" career_timeline_body "newest first" ;;
    *) return 1 ;;
  esac
}

career_dash() { if [[ "${PLATFORM_UTF8:-0}" == 1 ]]; then printf -v "$1" ' – '; else printf -v "$1" ' - '; fi; }

career_experience_body() {
  local i h dash
  local -a highlights=()
  career_dash dash
  if (( ${#EXPERIENCE_ROLE[@]} == 0 )); then layout_empty; return 0; fi
  for (( i = 0; i < ${#EXPERIENCE_ROLE[@]}; i++ )); do
    layout_title_right "${EXPERIENCE_ROLE[i]}" "${EXPERIENCE_START[i]}$dash${EXPERIENCE_END[i]}"
    printf '%s%s%s' "$LAYOUT_MARGIN" "${C_CYAN:-${C_ACCENT:-}}" "${EXPERIENCE_COMPANY[i]}"
    [[ -n "${EXPERIENCE_LOCATION[i]}" ]] && printf ' %s%s %s' "${C_MUTED:-${C_DIM:-}}" "$ICON_DOT" "${EXPERIENCE_LOCATION[i]}"
    printf '%s\n' "${C_RESET:-}"
    layout_split highlights "${EXPERIENCE_HIGHLIGHTS[i]}"
    for h in ${highlights[@]+"${highlights[@]}"}; do
      [[ -n "$h" ]] && layout_wrap "$ICON_DOT $h" "  " "    " "${C_WHITE:-}"
    done
    printf '\n'
  done
}

career_education_body() {
  local i dash
  career_dash dash
  if (( ${#EDUCATION_DEGREE[@]} == 0 )); then layout_empty; return 0; fi
  for (( i = 0; i < ${#EDUCATION_DEGREE[@]}; i++ )); do
    layout_title_right "${EDUCATION_DEGREE[i]}" "${EDUCATION_START[i]}$dash${EDUCATION_END[i]}"
    printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "${C_CYAN:-${C_ACCENT:-}}" "${EDUCATION_INSTITUTION[i]}" "${C_RESET:-}"
    [[ -n "${EDUCATION_NOTES[i]}" ]] && layout_wrap "${EDUCATION_NOTES[i]}" "  " "${C_WHITE:-}"
    printf '\n'
  done
}

career_certifications_body() {
  local i
  if (( ${#CERT_NAME[@]} == 0 )); then layout_empty; return 0; fi
  for (( i = 0; i < ${#CERT_NAME[@]}; i++ )); do
    layout_title_right "${CERT_NAME[i]}" "${CERT_DATE[i]}"
    [[ -n "${CERT_ISSUER[i]}" ]] && printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "${C_CYAN:-${C_ACCENT:-}}" "${CERT_ISSUER[i]}" "${C_RESET:-}"
    [[ -n "${CERT_URL[i]}" ]] && printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "${C_MUTED:-${C_DIM:-}}" "${CERT_URL[i]}" "${C_RESET:-}"
    printf '\n'
  done
}

# Vertical timeline: a node per milestone (date range + kind), its title and organisation on the stem,
# a one-line summary, and a connector to the next milestone. Built by scripts/build.sh, newest first.
career_timeline_body() {
  local i last col when dash sub r="${C_RESET:-}" stem
  career_dash dash
  if (( ${#TIMELINE_DATE[@]} == 0 )); then layout_empty; return 0; fi
  last=$(( ${#TIMELINE_DATE[@]} - 1 ))
  stem="${C_BORDER:-${C_DIM:-}}$ICON_RULE$r  "

  for (( i = 0; i <= last; i++ )); do
    case "${TIMELINE_KIND[i]:-}" in
      Work)      col="${C_CYAN:-${C_ACCENT:-}}" ;;
      Education) col="${C_GREEN:-${C_OK:-}}" ;;
      *)         col="${C_PURPLE:-${C_ACCENT:-}}" ;;
    esac
    when="${TIMELINE_DATE[i]}"
    [[ -n "${TIMELINE_END[i]:-}" ]] && when="$when$dash${TIMELINE_END[i]}"
    sub="${TIMELINE_SUBTITLE[i]:-}"
    [[ -n "${TIMELINE_LOC[i]:-}" ]] && sub="$sub $ICON_DOT ${TIMELINE_LOC[i]}"

    printf '%s%s%s%s  %s%s%s  %s[%s]%s\n' "$LAYOUT_MARGIN" "$col" "$ICON_NODE" "$r" \
      "${C_WHITE:-}${C_BOLD:-}" "$when" "$r" "$col" "${TIMELINE_KIND[i]}" "$r"
    layout_wrap "${TIMELINE_TITLE[i]:-}" "$stem" "$stem" "${C_BOLD:-}"
    [[ -n "$sub" ]] && layout_wrap "$sub" "$stem" "$stem" "${C_CYAN:-${C_ACCENT:-}}"
    [[ -n "${TIMELINE_DESC[i]:-}" ]] && layout_wrap "${TIMELINE_DESC[i]}" "$stem" "$stem" "${C_MUTED:-${C_DIM:-}}"
    (( i < last )) && printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "${C_BORDER:-${C_DIM:-}}" "$ICON_RULE" "$r"
  done
  return 0
}
