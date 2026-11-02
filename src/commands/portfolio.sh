# shellcheck shell=bash
# Section 8 — Portfolio: QR code (when the build had qrencode) and "o" to open it in the browser.

[[ -n "${_CMD_PORTFOLIO_SH:-}" ]] && return 0
_CMD_PORTFOLIO_SH=1

cmd_portfolio() { menu_loop portfolio_render portfolio_handle; }

portfolio_render() {
  local qr="$APP_ROOT/src/data/qr.txt" line url
  card_clean_url url "$PROFILE_URL_PORTFOLIO"
  layout_header "Portfolio" "$url"
  printf '\n'
  if [[ -f "$qr" && "$PLATFORM_UTF8" == 1 ]] && (( PLATFORM_WIDTH >= 40 )); then
    while IFS= read -r line; do printf '%s%s\n' "$LAYOUT_MARGIN" "$line"; done <"$qr"
  else
    layout_kv "URL" "$PROFILE_URL_PORTFOLIO" 6
  fi
  menu_items "o:Open in browser"
  menu_prompt
}

portfolio_handle() {
  case "$1" in
    o|O) action_open "$PROFILE_URL_PORTFOLIO" "portfolio link" ;;
    *) return 1 ;;
  esac
}
