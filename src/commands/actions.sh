# shellcheck shell=bash
# Shared open/copy actions: call the service, turn its status code into a menu message.
# The URL or text is always shown when the action cannot complete, so the user is never stuck.

[[ -n "${_CMD_ACTIONS_SH:-}" ]] && return 0
_CMD_ACTIONS_SH=1

# action_open URL [WHAT]
action_open() {
  local url="$1" what="${2:-link}"
  if [[ -z "$url" ]]; then menu_status warn "No $what available."; return 0; fi
  if browser_open "$url"; then
    menu_status ok "Opening $url …"
  else
    case $? in
      1) menu_status warn "No browser opener found. Here is the $what: $url" ;;
      *) menu_status err "Could not open a browser. Here is the $what: $url" ;;
    esac
  fi
}

# action_copy TEXT WHAT
action_copy() {
  local text="$1" what="$2"
  if [[ -z "$text" ]]; then menu_status warn "No $what available."; return 0; fi
  if clipboard_copy "$text"; then
    menu_status ok "$what copied to clipboard."
  else
    case $? in
      1) menu_status warn "No clipboard tool found. Copy it manually: $text" ;;
      *) menu_status err "Copy failed. Copy it manually: $text" ;;
    esac
  fi
}
