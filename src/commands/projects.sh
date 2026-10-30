# shellcheck shell=bash
# Section 3 — Projects, with a tag filter on "f".

[[ -n "${_CMD_PROJECTS_SH:-}" ]] && return 0
_CMD_PROJECTS_SH=1

PROJECT_FILTER=""   # tag to show; empty shows every project
PROJECT_TAG_LIST=()

cmd_projects() {
  PROJECT_FILTER=""
  menu_loop projects_render projects_handle
}

# projects_matches INDEX — succeeds when project INDEX passes the current tag filter.
projects_matches() {
  [[ -z "$PROJECT_FILTER" ]] && return 0
  case "|${PROJECT_TAGS[$1]}|" in
    *"|$PROJECT_FILTER|"*) return 0 ;;
  esac
  return 1
}

projects_visible() {
  local i n=0
  for (( i = 0; i < ${#PROJECT_NAME[@]}; i++ )); do
    projects_matches "$i" && n=$(( n + 1 ))
  done
  printf '%s' "$n"
}

projects_all_tags() {
  local i
  for (( i = 0; i < ${#PROJECT_TAGS[@]}; i++ )); do
    printf '%s\n' "${PROJECT_TAGS[$i]}" | tr '|' '\n'
  done | sort -u
}

projects_render() {
  local total=${#PROJECT_NAME[@]}
  layout_header "Projects" "$(projects_visible) of $total shown${PROJECT_FILTER:+ $ICON_DOT tag: $PROJECT_FILTER}"
  printf '\n'
  projects_body
  printf '\n'
  menu_items "f:Filter by tag"
  menu_prompt
  layout_footer
}

projects_body() {
  local i shown=0
  if (( ${#PROJECT_NAME[@]} == 0 )); then layout_empty; return 0; fi
  for (( i = 0; i < ${#PROJECT_NAME[@]}; i++ )); do
    projects_matches "$i" || continue
    layout_title_right "${PROJECT_NAME[$i]}" "${PROJECT_TAGS[$i]//|/  }"
    [[ -n "${PROJECT_DESC[$i]}" ]] && layout_wrap "${PROJECT_DESC[$i]}"
    [[ -n "${PROJECT_URL[$i]}" ]] && printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "$C_DIM" "${PROJECT_URL[$i]}" "$C_RESET"
    printf '\n'
    shown=$(( shown + 1 ))
  done
  (( shown == 0 )) && layout_empty
  return 0
}

projects_handle() {
  case "$1" in
    f|F) projects_filter_menu ;;
    *) return 1 ;;
  esac
}

projects_filter_menu() {
  local t
  PROJECT_TAG_LIST=()
  while IFS= read -r t; do
    [[ -n "$t" ]] && PROJECT_TAG_LIST+=("$t")
  done < <(projects_all_tags)
  menu_loop projects_filter_render projects_filter_handle
  MENU_DONE=""
}

projects_filter_render() {
  local -a items=("a:All projects")
  local i
  for (( i = 0; i < ${#PROJECT_TAG_LIST[@]} && i < 9; i++ )); do
    items+=("$(( i + 1 )):${PROJECT_TAG_LIST[$i]}")
  done
  layout_header "Filter by tag"
  printf '\n'
  menu_items "${items[@]}"
  menu_prompt
  layout_footer
}

projects_filter_handle() {
  local idx
  case "$1" in
    a|A) PROJECT_FILTER="" ;;
    [1-9])
      idx=$(( $1 - 1 ))
      (( idx < ${#PROJECT_TAG_LIST[@]} )) || return 1
      PROJECT_FILTER="${PROJECT_TAG_LIST[$idx]}" ;;
    *) return 1 ;;
  esac
  MENU_DONE=1
  return 0
}
