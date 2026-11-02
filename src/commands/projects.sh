# shellcheck shell=bash
# Section 3 — Projects: a selectable list, a detail screen per project, and a tag filter on "f".

[[ -n "${_CMD_PROJECTS_SH:-}" ]] && return 0
_CMD_PROJECTS_SH=1

PROJECT_FILTER=""     # tag to show; empty shows every project
PROJECT_VISIBLE=()    # project indexes shown in the list, in order (menu key N → PROJECT_VISIBLE[N-1])
PROJECT_TAG_LIST=()
PROJECT_CURRENT=0

cmd_projects() {
  PROJECT_FILTER=""
  menu_loop projects_render projects_handle
}

projects_matches() {
  [[ -z "$PROJECT_FILTER" ]] && return 0
  case "|${PROJECT_TAGS[$1]}|" in
    *"|$PROJECT_FILTER|"*) return 0 ;;
  esac
  return 1
}

projects_render() {
  local i k=0 label detail
  local -a items=() details=()
  PROJECT_VISIBLE=()
  for (( i = 0; i < ${#PROJECT_NAME[@]}; i++ )); do
    projects_matches "$i" || continue
    (( k < 9 )) || break
    k=$(( k + 1 ))
    PROJECT_VISIBLE+=("$i")
    label="${PROJECT_NAME[i]}"
    [[ "${PROJECT_FEATURED[i]:-0}" == 1 ]] && label="$label $ICON_STAR"
    items+=("$k:$label")
    detail="${PROJECT_CATEGORY[i]:-}"
    [[ -n "${PROJECT_STATUS[i]:-}" ]] && detail="${detail:+$detail  $ICON_DOT  }${PROJECT_STATUS[i]}"
    details+=("$detail")
  done

  layout_header "Projects" "$k of ${#PROJECT_NAME[@]}${PROJECT_FILTER:+  $ICON_DOT  tag: $PROJECT_FILTER}"
  (( ${#PROJECT_NAME[@]} == 0 )) && { printf '\n'; layout_empty; }
  MENU_DETAILS=(${details[@]+"${details[@]}"} "${PROJECT_FILTER:+Showing tag: $PROJECT_FILTER}")
  menu_items ${items[@]+"${items[@]}"} "f:Filter by tag"
  menu_prompt
}

projects_handle() {
  case "$1" in
    [1-9])
      (( $1 <= ${#PROJECT_VISIBLE[@]} )) || return 1
      PROJECT_CURRENT="${PROJECT_VISIBLE[$1 - 1]}"
      menu_loop projects_detail_render projects_detail_handle ;;
    f|F) projects_filter_menu ;;
    *) return 1 ;;
  esac
}

# projects_position — 0-based position of PROJECT_CURRENT in the visible list.
projects_position() {
  local p
  for (( p = 0; p < ${#PROJECT_VISIBLE[@]}; p++ )); do
    [[ "${PROJECT_VISIBLE[p]}" == "$PROJECT_CURRENT" ]] && break
  done
  printf -v "$1" '%s' "$p"
}

projects_detail_render() {
  local i=$PROJECT_CURRENT pos badges="" status="${PROJECT_STATUS[PROJECT_CURRENT]:-}" r="${C_RESET:-}"
  local muted="${C_MUTED:-${C_DIM:-}}"
  projects_position pos

  # One line of badges: status (green when live), featured, category.
  if [[ -n "$status" ]]; then
    case "$status" in
      "In Production"|Live|Active) badges="${C_GREEN:-${C_OK:-}}$ICON_BULLET $status$r" ;;
      *) badges="$muted$ICON_BULLET $status$r" ;;
    esac
  fi
  [[ "${PROJECT_FEATURED[i]:-0}" == 1 ]] && badges="${badges:+$badges   }${C_YELLOW:-}$ICON_STAR Featured$r"
  if [[ -n "${PROJECT_CATEGORY[i]:-}" ]]; then
    local vis
    layout_visible_len vis "$badges"
    # Category goes on its own line when the row would not fit.
    if (( vis + 3 + ${#PROJECT_CATEGORY[i]} > LAYOUT_WIDTH )); then
      badges="$badges"$'\n'"$LAYOUT_MARGIN$muted${PROJECT_CATEGORY[i]}$r"
    else
      badges="${badges:+$badges   }$muted${PROJECT_CATEGORY[i]}$r"
    fi
  fi

  layout_header "${PROJECT_NAME[i]}" "$(( pos + 1 )) of ${#PROJECT_VISIBLE[@]}"
  printf '\n'
  [[ -n "$badges" ]] && printf '%s%s\n\n' "$LAYOUT_MARGIN" "$badges"
  if [[ -n "${PROJECT_DESC[i]}" ]]; then
    layout_wrap "${PROJECT_DESC[i]}" "" "${C_WHITE:-}"
    printf '\n'
  fi
  [[ -n "${PROJECT_TAGS[i]}" ]] && layout_list 12 "Stack" "${PROJECT_TAGS[i]}"
  if [[ -n "${PROJECT_URL[i]}" ]]; then
    layout_kv "Repository" "${PROJECT_URL[i]}" 12 "${C_CYAN:-${C_ACCENT:-}}${C_BOLD:-}"
    menu_items "o:Open repository"
  else
    layout_kv "Repository" "No public link" 12 "${C_CYAN:-${C_ACCENT:-}}${C_BOLD:-}" "$muted"
    menu_items
  fi
  (( ${#PROJECT_VISIBLE[@]} > 1 )) && MENU_HINTS=("$KEYS_LEFTRIGHT:prev/next")
  menu_prompt
}

projects_detail_handle() {
  local pos
  case "$1" in
    o|O) [[ -n "${PROJECT_URL[PROJECT_CURRENT]}" ]] || return 1
         action_open "${PROJECT_URL[PROJECT_CURRENT]}" "repository link" ;;
    LEFT|RIGHT)
      projects_position pos
      if [[ "$1" == LEFT ]]; then pos=$(( pos - 1 )); else pos=$(( pos + 1 )); fi
      (( pos >= 0 && pos < ${#PROJECT_VISIBLE[@]} )) || return 1
      PROJECT_CURRENT="${PROJECT_VISIBLE[pos]}" ;;
    *) return 1 ;;
  esac
}

# Tags shared by at least two projects (a tag on a single project is not a useful filter).
projects_filter_menu() {
  local t
  PROJECT_TAG_LIST=()
  while IFS= read -r t; do
    [[ -n "$t" ]] && PROJECT_TAG_LIST+=("$t")
  done < <(printf '%s\n' ${PROJECT_TAGS[@]+"${PROJECT_TAGS[@]}"} | tr '|' '\n' | sort | uniq -d)
  menu_loop projects_filter_render projects_filter_handle
}

projects_filter_render() {
  local -a items=("a:All projects")
  local i
  for (( i = 0; i < ${#PROJECT_TAG_LIST[@]} && i < 9; i++ )); do
    items+=("$(( i + 1 )):${PROJECT_TAG_LIST[i]}")
  done
  layout_header "Filter projects by tag"
  menu_items "${items[@]}"
  menu_prompt
}

projects_filter_handle() {
  case "$1" in
    a|A) PROJECT_FILTER="" ;;
    [1-9])
      (( $1 <= ${#PROJECT_TAG_LIST[@]} )) || return 1
      PROJECT_FILTER="${PROJECT_TAG_LIST[$1 - 1]}" ;;
    *) return 1 ;;
  esac
  MENU_DONE=1
}
