# shellcheck shell=bash
# Section 4 — Career Submenu: Experience, Education, Certifications, and Timeline.

[[ -n "${_CMD_CAREER_SH:-}" ]] && return 0
_CMD_CAREER_SH=1

cmd_career() {
  menu_loop career_render career_handle
}

career_render() {
  layout_header "Career & Education" "Experience & Milestones"
  menu_items "1:Experience" "2:Education" "3:Certifications" "4:Timeline"
  menu_prompt
  layout_footer
}

career_handle() {
  case "$1" in
    1) section_view "Work Experience" career_experience_body ;;
    2) section_view "Education" career_education_body ;;
    3) section_view "Certifications & Honors" career_certifications_body ;;
    4) section_view "Chronological Journey" career_timeline_body ;;
    *) return 1 ;;
  esac
}

# 1. Experience body
career_experience_body() {
  local i h
  local -a highlights
  local c_cyan="${C_CYAN:-${C_ACCENT:-}}"
  local c_muted="${C_MUTED:-${C_DIM:-}}"
  local c_dim="${C_DIM:-}"
  local c_reset="${C_RESET:-}"

  if (( ${#EXPERIENCE_ROLE[@]} == 0 )); then layout_empty; return 0; fi

  for (( i = 0; i < ${#EXPERIENCE_ROLE[@]}; i++ )); do
    layout_title_right "${EXPERIENCE_ROLE[$i]}" "${EXPERIENCE_START[$i]} – ${EXPERIENCE_END[$i]}"
    printf '%s%s%s%s' "$LAYOUT_MARGIN" "$c_cyan" "${EXPERIENCE_COMPANY[$i]}" "$c_reset"
    [[ -n "${EXPERIENCE_LOCATION[$i]}" ]] && printf ' %s%s %s%s' "$c_dim" "$ICON_DOT" "${EXPERIENCE_LOCATION[$i]}" "$c_reset"
    printf '\n'
    layout_split highlights "${EXPERIENCE_HIGHLIGHTS[$i]}"
    for h in ${highlights[@]+"${highlights[@]}"}; do
      [[ -n "$h" ]] && layout_wrap "$ICON_DOT $h" "  " "  " "$c_muted"
    done
    printf '\n'
  done
}

# 2. Education body
career_education_body() {
  local i
  local c_cyan="${C_CYAN:-${C_ACCENT:-}}"
  local c_muted="${C_MUTED:-${C_DIM:-}}"
  local c_reset="${C_RESET:-}"

  if (( ${#EDUCATION_DEGREE[@]} == 0 )); then layout_empty; return 0; fi

  for (( i = 0; i < ${#EDUCATION_DEGREE[@]}; i++ )); do
    layout_title_right "${EDUCATION_DEGREE[$i]}" "${EDUCATION_START[$i]} – ${EDUCATION_END[$i]}"
    printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "$c_cyan" "${EDUCATION_INSTITUTION[$i]}" "$c_reset"
    [[ -n "${EDUCATION_NOTES[$i]}" ]] && layout_wrap "${EDUCATION_NOTES[$i]}" "  " "  " "$c_muted"
    printf '\n'
  done
}

# 3. Certifications & Honors body
career_certifications_body() {
  local i
  local c_cyan="${C_CYAN:-${C_ACCENT:-}}"
  local c_dim="${C_DIM:-}"
  local c_reset="${C_RESET:-}"

  if (( ${#CERT_NAME[@]} == 0 )); then layout_empty; return 0; fi

  for (( i = 0; i < ${#CERT_NAME[@]}; i++ )); do
    layout_title_right "${CERT_NAME[$i]}" "${CERT_DATE[$i]}"
    printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "$c_cyan" "${CERT_ISSUER[$i]}" "$c_reset"
    [[ -n "${CERT_URL[$i]}" ]] && printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "$c_dim" "${CERT_URL[$i]}" "$c_reset"
    printf '\n'
  done
}

# 4. Chronological Journey Timeline body
career_timeline_body() {
  local i last
  local node="●" rule="│"
  [[ "${PLATFORM_UTF8:-0}" != 1 ]] && { node="o"; rule="|"; }

  local c_cyan="${C_CYAN:-${C_ACCENT:-}}"
  local c_accent="${C_ACCENT:-}"
  local c_green="${C_GREEN:-${C_OK:-}}"
  local c_purple="${C_PURPLE:-$c_accent}"
  local c_white="${C_WHITE:-${C_BOLD:-}}"
  local c_muted="${C_MUTED:-${C_DIM:-}}"
  local c_dim="${C_DIM:-}"
  local c_bold="${C_BOLD:-}"
  local c_reset="${C_RESET:-}"

  if (( ${#TIMELINE_DATE[@]} == 0 )); then layout_empty; return 0; fi
  last=$(( ${#TIMELINE_DATE[@]} - 1 ))

  for (( i = 0; i < ${#TIMELINE_DATE[@]}; i++ )); do
    local date="${TIMELINE_DATE[$i]}"
    local end_date="${TIMELINE_END[$i]:-}"
    local kind="${TIMELINE_KIND[$i]}"
    local title="${TIMELINE_TITLE[$i]:-}"
    local subtitle="${TIMELINE_SUBTITLE[$i]:-}"
    local loc="${TIMELINE_LOC[$i]:-}"
    local desc="${TIMELINE_DESC[$i]:-}"
    local text="${TIMELINE_TEXT[$i]:-}"

    # If title is empty, parse from TIMELINE_TEXT
    if [[ -z "$title" && -n "$text" ]]; then
      if [[ "$text" == *" at "* ]]; then
        title="${text%% at *}"
        subtitle="${text#* at }"
      elif [[ "$text" == *", "* ]]; then
        title="${text%%, *}"
        subtitle="${text#*, }"
      else
        title="$text"
        subtitle=""
      fi
    fi

    # Category color accent & badge styling
    local kind_col="$c_cyan"
    local date_display="$date"
    if [[ -n "$end_date" ]]; then
      date_display="$date – $end_date"
    fi

    case "$kind" in
      Work)
        kind_col="$c_cyan"
        ;;
      Education|Study)
        kind_col="$c_green"
        ;;
      Honor|Certification)
        kind_col="$c_purple"
        ;;
    esac

    # 1. Milestone node header: ●  2026-04 – present     [Work]
    # layout_margin (2 spaces) + node (1 char) + 2 spaces + date (22 chars) + space + [badge]
    printf '%s%s%s%s  %s%-22s%s %s[%s]%s\n' \
      "$LAYOUT_MARGIN" \
      "$kind_col" "$node" "$c_reset" \
      "$c_white$c_bold" "$date_display" "$c_reset" \
      "$kind_col$c_bold" "$kind" "$c_reset"

    # 2. Stem connector + Title: │  Junior Software Engineer
    # Rule is in the exact column as node above, followed by 2 spaces, aligning with date
    printf '%s%s%s%s  %s%s%s\n' \
      "$LAYOUT_MARGIN" \
      "$c_dim" "$rule" "$c_reset" \
      "$c_bold$c_white" "$title" "$c_reset"

    # 3. Stem connector + Subtitle: │  Wisetech MEP Consultants Pvt. Ltd. · Mumbai, India
    local sub_info="$subtitle"
    [[ -n "$loc" ]] && sub_info="$sub_info · $loc"
    if [[ -n "$sub_info" ]]; then
      printf '%s%s%s%s  %s%s%s\n' \
        "$LAYOUT_MARGIN" \
        "$c_dim" "$rule" "$c_reset" \
        "$c_muted" "$sub_info" "$c_reset"
    fi

    # 4. Stem connector + Highlight / Description summary (if present)
    if [[ -n "$desc" ]]; then
      local stem_indent="$c_dim$rule$c_reset  "
      layout_wrap "$desc" "$stem_indent" "$stem_indent" "$c_dim"
    fi

    # 5. Connecting link between timeline milestones
    if (( i < last )); then
      printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "$c_dim" "$rule" "$c_reset"
    fi
  done

  return 0
}
