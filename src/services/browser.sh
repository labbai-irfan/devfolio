# shellcheck shell=bash
# Opens a URL in the default browser (or mail client for mailto:).
# Returns 0 on success, 1 if no opener is available, 2 if the URL is invalid or the opener failed.

[[ -n "${_BROWSER_SH:-}" ]] && return 0
_BROWSER_SH=1

browser_open() {
  local url="$1"
  validate_url "$url" || return 2
  [[ -n "$PLATFORM_OPENER" ]] || return 1
  log_debug "open: $PLATFORM_OPENER $url"

  case "$PLATFORM_OPENER" in
    # `start` needs an empty title argument, otherwise it treats the URL as the window title.
    cmd.exe) cmd.exe //c start "" "$url" >/dev/null 2>&1 || return 2 ;;
    # xdg-open may block while the browser starts; detach it so the menu stays responsive.
    xdg-open|wslview) ( "$PLATFORM_OPENER" "$url" >/dev/null 2>&1 & ) ;;
    *) "$PLATFORM_OPENER" "$url" >/dev/null 2>&1 || return 2 ;;
  esac
}
