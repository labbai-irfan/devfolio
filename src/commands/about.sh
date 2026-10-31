# shellcheck shell=bash
# Section 1 — About Screen Transformation.
# Structured narrative: Introduction, Current Focus & Philosophy, Snapshot & Engineering Journey.

[[ -n "${_CMD_ABOUT_SH:-}" ]] && return 0
_CMD_ABOUT_SH=1

cmd_about() { section_view "About Me" about_body; }

about_body() {
  local p
  local dot="●"
  [[ "${PLATFORM_UTF8:-0}" != 1 ]] && dot="*"

  local c_cyan="${C_CYAN:-${C_ACCENT:-}}"
  local c_accent="${C_ACCENT:-}"
  local c_green="${C_GREEN:-${C_OK:-}}"
  local c_white="${C_WHITE:-${C_BOLD:-}}"
  local c_muted="${C_MUTED:-${C_DIM:-}}"
  local c_dim="${C_DIM:-}"
  local c_bold="${C_BOLD:-}"
  local c_reset="${C_RESET:-}"

  # 1. Professional Introduction
  layout_section_title "PROFESSIONAL PROFILE"
  if (( ${#PROFILE_ABOUT[@]} > 0 )); then
    layout_wrap "${PROFILE_ABOUT[0]}" "  " "$c_white"
  else
    layout_empty
  fi
  printf '\n'

  # 2. Current Engineering Focus
  layout_section_title "CURRENT TECHNICAL FOCUS"
  if (( ${#PROFILE_ABOUT[@]} > 1 )); then
    layout_wrap "${PROFILE_ABOUT[1]}" "  " "$c_muted"
  fi
  printf '\n'

  # Core Pillars Pill Badges
  layout_tag_pills "DevOps & CI/CD" "Cloud Architecture" "Docker" "AWS" "Linux & Shell" "Automation"
  printf '\n'

  # 3. Quick Snapshot / Status
  layout_section_title "PROFILE SNAPSHOT"
  layout_kv "Role" "$PROFILE_TITLE" 14 "$c_cyan" "$c_white"
  [[ -n "$PROFILE_LOCATION" ]] && layout_kv "Location" "$PROFILE_LOCATION" 14 "$c_cyan" "$c_white"
  [[ -n "$PROFILE_AVAILABILITY" ]] && layout_kv "Availability" "$dot $PROFILE_AVAILABILITY" 14 "$c_cyan" "$c_green"
  [[ -n "$PROFILE_EMAIL" ]] && layout_kv "Contact" "$PROFILE_EMAIL" 14 "$c_cyan" "$c_white"

  return 0
}
