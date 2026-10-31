# shellcheck shell=bash
# Section 6 — Contact Screen Transformation: Interactive channels with clear visual feedback.

[[ -n "${_CMD_CONTACT_SH:-}" ]] && return 0
_CMD_CONTACT_SH=1

cmd_contact() { menu_loop contact_render contact_handle; }

# contact_item KEY LABEL VALUE — label with a dim "(not available)" suffix when VALUE is empty.
contact_item() {
  if [[ -n "$3" ]]; then
    printf '%s:%s' "$1" "$2"
  else
    printf '%s:%s %s(n/a)%s' "$1" "$2" "${C_MUTED:-${C_DIM:-}}" "${C_RESET:-}"
  fi
}

contact_render() {
  local c_cyan="${C_CYAN:-${C_ACCENT:-}}"
  local c_white="${C_WHITE:-${C_BOLD:-}}"
  local c_muted="${C_MUTED:-${C_DIM:-}}"

  layout_header "Connect & Reach Out" "Direct Channels"

  layout_section_title "CONTACT DETAILS"
  [[ -n "$PROFILE_EMAIL" ]] && layout_kv "Email" "$PROFILE_EMAIL" 14 "$c_cyan" "$c_white"
  [[ -n "$PROFILE_WHATSAPP" ]] && layout_kv "WhatsApp" "+$PROFILE_WHATSAPP" 14 "$c_cyan" "$c_white"
  [[ -n "$PROFILE_LOCATION" ]] && layout_kv "Location" "$PROFILE_LOCATION" 14 "$c_cyan" "$c_white"
  [[ -n "$PROFILE_URL_PORTFOLIO" ]] && layout_kv "Portfolio" "$PROFILE_URL_PORTFOLIO" 14 "$c_cyan" "$c_white"
  [[ -n "$PROFILE_URL_LINKEDIN" ]] && layout_kv "LinkedIn" "$PROFILE_URL_LINKEDIN" 14 "$c_cyan" "$c_white"
  [[ -n "$PROFILE_URL_GITHUB" ]] && layout_kv "GitHub" "$PROFILE_URL_GITHUB" 14 "$c_cyan" "$c_white"

  layout_section_title "QUICK ACTIONS"
  menu_items \
    "$(contact_item 1 "Send email" "$PROFILE_EMAIL")" \
    "$(contact_item 2 "Open WhatsApp" "$PROFILE_WHATSAPP")" \
    "$(contact_item 3 "Open LinkedIn" "$PROFILE_URL_LINKEDIN")" \
    "$(contact_item 4 "Open GitHub" "$PROFILE_URL_GITHUB")"
  menu_prompt
  layout_footer
}

contact_handle() {
  case "$1" in
    1) if [[ -n "$PROFILE_EMAIL" ]]; then action_open "mailto:$PROFILE_EMAIL" "email address"; else menu_status warn "No email address available."; fi ;;
    2) if [[ -n "$PROFILE_WHATSAPP" ]]; then action_open "https://wa.me/$PROFILE_WHATSAPP" "WhatsApp chat"; else menu_status warn "No WhatsApp number available."; fi ;;
    3) action_open "$PROFILE_URL_LINKEDIN" "LinkedIn link" ;;
    4) action_open "$PROFILE_URL_GITHUB" "GitHub link" ;;
    *) return 1 ;;
  esac
}
