# shellcheck shell=bash
# Section 2 — Skills Screen: Structured categories styled in full alignment with the About design system.

[[ -n "${_CMD_SKILLS_SH:-}" ]] && return 0
_CMD_SKILLS_SH=1

cmd_skills() { section_view "Skills & Tech Stack" skills_body; }

skills_body() {
  local i items item
  local c_cyan="${C_CYAN:-${C_ACCENT:-}}"
  local c_accent="${C_ACCENT:-}"
  local c_white="${C_WHITE:-${C_BOLD:-}}"
  local c_muted="${C_MUTED:-${C_DIM:-}}"
  local c_dim="${C_DIM:-}"
  local c_bold="${C_BOLD:-}"
  local c_reset="${C_RESET:-}"

  if (( ${#SKILL_CATEGORY[@]} == 0 )); then
    layout_empty
    return 0
  fi

  for (( i = 0; i < ${#SKILL_CATEGORY[@]}; i++ )); do
    layout_section_title "${SKILL_CATEGORY[$i]}"

    items="${SKILL_ITEMS[$i]}"
    local -a item_arr=()
    IFS='|' read -r -a item_arr <<< "$items"

    layout_tag_pills "${item_arr[@]}"
    printf '\n'
  done
}
