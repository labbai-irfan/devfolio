# shellcheck shell=bash
# Section 6 — Contact submenu.

[[ -n "${_CMD_CONTACT_SH:-}" ]] && return 0
_CMD_CONTACT_SH=1

cmd_contact() { menu_loop contact_render contact_handle; }

# contact_item KEY LABEL VALUE — label with a dim "(not available)" suffix when VALUE is empty.
contact_item() {
  if [[ -n "$3" ]]; then printf '%s:%s' "$1" "$2"; else printf '%s:%s %s(n/a)%s' "$1" "$2" "$C_DIM" "$C_RESET"; fi
}

contact_render() {
  layout_header "Contact"
  menu_items \
    "$(contact_item 1 "Send email" "$PROFILE_EMAIL")" \
    "$(contact_item 2 "Copy email address" "$PROFILE_EMAIL")" \
    "$(contact_item 3 "Open LinkedIn" "$PROFILE_URL_LINKEDIN")" \
    "$(contact_item 4 "Open GitHub" "$PROFILE_URL_GITHUB")" \
    "$(contact_item 5 "Open WhatsApp" "$PROFILE_WHATSAPP")" \
    "$(contact_item 6 "Copy portfolio URL" "$PROFILE_URL_PORTFOLIO")"
  menu_prompt
  layout_footer
}

contact_handle() {
  case "$1" in
    1) if [[ -n "$PROFILE_EMAIL" ]]; then action_open "mailto:$PROFILE_EMAIL" "email address"; else menu_status warn "No email address available."; fi ;;
    2) action_copy "$PROFILE_EMAIL" "Email address" ;;
    3) action_open "$PROFILE_URL_LINKEDIN" "LinkedIn link" ;;
    4) action_open "$PROFILE_URL_GITHUB" "GitHub link" ;;
    5) if [[ -n "$PROFILE_WHATSAPP" ]]; then action_open "https://wa.me/$PROFILE_WHATSAPP" "WhatsApp link"; else menu_status warn "No WhatsApp number available."; fi ;;
    6) action_copy "$PROFILE_URL_PORTFOLIO" "Portfolio URL" ;;
    *) return 1 ;;
  esac
}
