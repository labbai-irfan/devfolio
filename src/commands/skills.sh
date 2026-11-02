# shellcheck shell=bash
# Section 2 — Skills: category on the left, its skills on the right (stacked on narrow terminals).
# Skills that are also tags on a listed project are highlighted: a real signal, not a made-up rating.

[[ -n "${_CMD_SKILLS_SH:-}" ]] && return 0
_CMD_SKILLS_SH=1

cmd_skills() {
  local i n=0
  local -a items=()
  for (( i = 0; i < ${#SKILL_ITEMS[@]}; i++ )); do
    layout_split items "${SKILL_ITEMS[i]}"
    n=$(( n + ${#items[@]} ))
  done
  section_view "Skills" skills_body "$n skills in ${#SKILL_CATEGORY[@]} areas"
}

skills_body() {
  local i c tags lw=0
  if (( ${#SKILL_CATEGORY[@]} == 0 )); then layout_empty; return 0; fi
  skills_project_tags tags

  # Label column as wide as the longest category, if that still leaves room for the skills.
  for c in "${SKILL_CATEGORY[@]}"; do (( ${#c} + 3 > lw )) && lw=$(( ${#c} + 3 )); done
  (( LAYOUT_WIDTH - lw >= 30 )) || lw=0

  if skills_any_used "$tags"; then
    printf '%s%s%s%s %sused in my projects%s\n\n' "$LAYOUT_MARGIN" "${C_GREEN:-${C_OK:-}}${C_BOLD:-}" \
      "$ICON_BULLET" "${C_RESET:-}" "${C_MUTED:-${C_DIM:-}}" "${C_RESET:-}"
  fi
  for (( i = 0; i < ${#SKILL_CATEGORY[@]}; i++ )); do
    (( i > 0 )) && printf '\n'
    layout_list "$lw" "${SKILL_CATEGORY[i]}" "${SKILL_ITEMS[i]}" "$tags"
  done
  return 0
}

# skills_project_tags VAR — every project tag as "|a|b|c|", for highlight lookups.
skills_project_tags() {
  local IFS='|'
  printf -v "$1" '|%s|' "${PROJECT_TAGS[*]-}"
}

# skills_any_used TAGS — succeeds when at least one skill is also a project tag.
skills_any_used() {
  local i s
  local -a items=()
  for (( i = 0; i < ${#SKILL_ITEMS[@]}; i++ )); do
    layout_split items "${SKILL_ITEMS[i]}"
    for s in ${items[@]+"${items[@]}"}; do [[ "$1" == *"|$s|"* ]] && return 0; done
  done
  return 1
}
