# shellcheck shell=bash
# Section 3 — Projects Screen: Premium engineering showcase unified with the design system.

[[ -n "${_CMD_PROJECTS_SH:-}" ]] && return 0
_CMD_PROJECTS_SH=1

PROJECT_FILTER=""   # tag to show; empty shows every project
PROJECT_TAG_LIST=()
PROJECT_SELECTED=0

cmd_projects() {
  PROJECT_FILTER=""
  section_view "Projects Portfolio" projects_body
}

projects_matches() {
  [[ -z "$PROJECT_FILTER" ]] && return 0
  case "|${PROJECT_TAGS[$1]}|" in
    *"|$PROJECT_FILTER|"*) return 0 ;;
  esac
  return 1
}

projects_all_tags() {
  local i
  for (( i = 0; i < ${#PROJECT_TAGS[@]}; i++ )); do
    printf '%s\n' "${PROJECT_TAGS[$i]}" | tr '|' '\n'
  done | sort -u
}

projects_body() {
  local i shown=0
  local icon="◆"
  [[ "${PLATFORM_UTF8:-0}" != 1 ]] && icon=">"
  local feat_star="★ "
  [[ "${PLATFORM_UTF8:-0}" != 1 ]] && feat_star="*"

  local c_cyan="${C_CYAN:-${C_ACCENT:-}}"
  local c_accent="${C_ACCENT:-}"
  local c_green="${C_GREEN:-${C_OK:-}}"
  local c_yellow="${C_YELLOW:-${C_WARN:-$c_accent}}"
  local c_white="${C_WHITE:-${C_BOLD:-}}"
  local c_muted="${C_MUTED:-${C_DIM:-}}"
  local c_dim="${C_DIM:-}"
  local c_bold="${C_BOLD:-}"
  local c_reset="${C_RESET:-}"

  if (( ${#PROJECT_NAME[@]} == 0 )); then
    layout_empty
    return 0
  fi

  for (( i = 0; i < ${#PROJECT_NAME[@]}; i++ )); do
    projects_matches "$i" || continue

    local name="${PROJECT_NAME[$i]}"
    local cat="${PROJECT_CATEGORY[$i]:-Software Engineering}"
    local desc="${PROJECT_DESC[$i]}"
    local is_feat="${PROJECT_FEATURED[$i]:-0}"
    local status="${PROJECT_STATUS[$i]:-Completed}"
    local url="${PROJECT_URL[$i]}"

    # 1. Header: Icon + Name (left) and Featured + Status badges (right)
    local left_vis_len=$(( 3 + ${#name} ))
    local right_str=""
    local right_vis_len=0

    if [[ "$is_feat" == "1" ]]; then
      right_str="${c_yellow}${c_bold}${feat_star}FEATURED${c_reset}"
      right_vis_len=$(( right_vis_len + 10 ))
    fi

    if [[ -n "$status" ]]; then
      local status_col="$c_muted"
      [[ "$status" == "In Production" ]] && status_col="$c_green"
      [[ -n "$right_str" ]] && { right_str="${right_str}  "; right_vis_len=$(( right_vis_len + 2 )); }
      right_str="${right_str}${status_col}[${status}]${c_reset}"
      right_vis_len=$(( right_vis_len + ${#status} + 2 ))
    fi

    local pad=$(( LAYOUT_WIDTH - left_vis_len - right_vis_len ))
    if (( pad >= 2 )); then
      printf '\n%s%s%s%s  %s%s%s%*s%s\n' \
        "$LAYOUT_MARGIN" \
        "$c_cyan" "$icon" "$c_reset" \
        "$c_bold$c_white" "$name" "$c_reset" \
        "$pad" '' \
        "$right_str"
    else
      printf '\n%s%s%s%s  %s%s%s\n' \
        "$LAYOUT_MARGIN" \
        "$c_cyan" "$icon" "$c_reset" \
        "$c_bold$c_white" "$name" "$c_reset"
      [[ -n "$right_str" ]] && printf '%s   %s\n' "$LAYOUT_MARGIN" "$right_str"
    fi

    # 2. Subtitle / Category
    printf '%s   %s%s%s\n' "$LAYOUT_MARGIN" "$c_muted" "$cat" "$c_reset"

    # 3. Description
    if [[ -n "$desc" ]]; then
      layout_wrap "$desc" "   " "   " "$c_white"
    fi
    printf '\n'

    # 4. Tech stack pill badges with clean wrapping
    local -a ptags=()
    IFS='|' read -r -a ptags <<< "${PROJECT_TAGS[$i]}"
    local line=""
    local line_vis_len=0
    local max_line_width=$(( LAYOUT_WIDTH - 3 ))

    for t in "${ptags[@]}"; do
      [[ -z "$t" ]] && continue
      local pill="[${t}]"
      local pill_len=${#pill}
      if [[ -z "$line" ]]; then
        line="${c_cyan}[${c_reset}${t}${c_cyan}]${c_reset}"
        line_vis_len=$pill_len
      elif (( line_vis_len + 1 + pill_len > max_line_width )); then
        printf '%s   %s\n' "$LAYOUT_MARGIN" "$line"
        line="${c_cyan}[${c_reset}${t}${c_cyan}]${c_reset}"
        line_vis_len=$pill_len
      else
        line="${line} ${c_cyan}[${c_reset}${t}${c_cyan}]${c_reset}"
        line_vis_len=$(( line_vis_len + 1 + pill_len ))
      fi
    done
    [[ -n "$line" ]] && printf '%s   %s\n' "$LAYOUT_MARGIN" "$line"

    # 5. Repository link
    if [[ -n "$url" ]]; then
      printf '%s   %sRepository:%s %s%s%s\n' \
        "$LAYOUT_MARGIN" \
        "$c_cyan" "$c_reset" \
        "$c_dim$c_white" "$url" "$c_reset"
    fi

    shown=$(( shown + 1 ))
  done

  (( shown == 0 )) && layout_empty
  return 0
}
