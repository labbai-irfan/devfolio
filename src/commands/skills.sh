# shellcheck shell=bash
# Section 2 — Skills, grouped by category.

[[ -n "${_CMD_SKILLS_SH:-}" ]] && return 0
_CMD_SKILLS_SH=1

cmd_skills() { section_view "Skills" skills_body; }

skills_body() {
  local i items
  if (( ${#SKILL_CATEGORY[@]} == 0 )); then layout_empty; return 0; fi
  for (( i = 0; i < ${#SKILL_CATEGORY[@]}; i++ )); do
    printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "$C_ACCENT" "${SKILL_CATEGORY[$i]}" "$C_RESET"
    items="${SKILL_ITEMS[$i]}"
    layout_wrap "${items//|/, }" "  "
    printf '\n'
  done
}
