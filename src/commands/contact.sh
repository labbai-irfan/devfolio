# shellcheck shell=bash
# Section 6 — Contact: a grid of the channels that are filled in (empty ones are hidden, not shown as
# "n/a"); the selected channel's address shows under the grid. c/u copy.

[[ -n "${_CMD_CONTACT_SH:-}" ]] && return 0
_CMD_CONTACT_SH=1

CONTACT_ACTIONS=()   # action for menu key N is CONTACT_ACTIONS[N-1]: email | whatsapp | linkedin | github | portfolio

cmd_contact() { menu_loop contact_render contact_handle; }

# contact_item VAR KEY LABEL VALUE — "KEY:LABEL", or "KEY:LABEL (n/a)" (dimmed by the menu) when VALUE
# is empty. Writes into VAR so renders stay subshell-free. Also used by the Resume screen.
contact_item() {
  if [[ -n "$4" ]]; then printf -v "$1" '%s:%s' "$2" "$3"; else printf -v "$1" '%s:%s (n/a)' "$2" "$3"; fi
}

contact_render() {
  local portfolio linkedin github k
  local -a items=() details=()
  card_clean_url portfolio "$PROFILE_URL_PORTFOLIO"
  card_clean_url linkedin "$PROFILE_URL_LINKEDIN"
  card_clean_url github "$PROFILE_URL_GITHUB"

  CONTACT_ACTIONS=()
  # contact_add ACTION LABEL VALUE — adds a numbered channel only when VALUE is set.
  contact_add() {
    [[ -n "$3" ]] || return 0
    CONTACT_ACTIONS+=("$1")
    k=${#CONTACT_ACTIONS[@]}
    items+=("$k:$2")
    details+=("$3")
  }
  contact_add email "Email" "$PROFILE_EMAIL"
  contact_add whatsapp "WhatsApp" "${PROFILE_WHATSAPP:++$PROFILE_WHATSAPP}"
  contact_add linkedin "LinkedIn" "$linkedin"
  contact_add github "GitHub" "$github"
  contact_add portfolio "Portfolio" "$portfolio"
  if [[ -n "$PROFILE_EMAIL" ]]; then items+=("c:Copy email"); details+=("Copies $PROFILE_EMAIL"); fi
  if [[ -n "$portfolio" ]]; then items+=("u:Copy portfolio URL"); details+=("Copies $PROFILE_URL_PORTFOLIO"); fi

  layout_header "Contact"
  if (( ${#items[@]} == 0 )); then printf '\n'; layout_empty; fi
  MENU_DETAILS=(${details[@]+"${details[@]}"})
  menu_items ${items[@]+"${items[@]}"}
  menu_prompt
}

contact_handle() {
  local action=""
  case "$1" in
    [1-9]) action="${CONTACT_ACTIONS[$1 - 1]:-}" ;;
    c|C) [[ -n "$PROFILE_EMAIL" ]] || return 1; action_copy "$PROFILE_EMAIL" "Email address"; return 0 ;;
    u|U) [[ -n "$PROFILE_URL_PORTFOLIO" ]] || return 1; action_copy "$PROFILE_URL_PORTFOLIO" "Portfolio URL"; return 0 ;;
  esac
  case "$action" in
    email)     action_open "mailto:$PROFILE_EMAIL" "email address" ;;
    whatsapp)  action_open "https://wa.me/$PROFILE_WHATSAPP" "WhatsApp link" ;;
    linkedin)  action_open "$PROFILE_URL_LINKEDIN" "LinkedIn link" ;;
    github)    action_open "$PROFILE_URL_GITHUB" "GitHub link" ;;
    portfolio) action_open "$PROFILE_URL_PORTFOLIO" "portfolio link" ;;
    *) return 1 ;;
  esac
}
