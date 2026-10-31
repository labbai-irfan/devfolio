# shellcheck shell=bash
# The developer card shown on the main screen and in static (--card / piped) mode.

[[ -n "${_CARD_SH:-}" ]] && return 0
_CARD_SH=1

card_render() {
  local dot="●"
  [[ "${PLATFORM_UTF8:-0}" != 1 ]] && dot="*"

  # Safe fallbacks for colors
  local c_accent="${C_ACCENT:-}"
  local c_cyan="${C_CYAN:-${C_ACCENT:-}}"
  local c_green="${C_GREEN:-${C_OK:-}}"
  local c_white="${C_WHITE:-${C_BOLD:-}}"
  local c_dim="${C_DIM:-}"
  local c_bold="${C_BOLD:-}"
  local c_reset="${C_RESET:-}"

  if layout_has_box; then
    printf '\n'
    layout_box_top

    # Header / Identity
    layout_box_line ""
    layout_box_line "$PROFILE_NAME" "$c_bold$c_accent"
    layout_box_line "$PROFILE_TITLE" "$c_cyan"
    layout_box_line ""
    layout_box_separator

    # Philosophy & Status
    layout_box_line ""
    layout_box_line "$PROFILE_TAGLINE" "$c_bold$c_white"
    layout_box_line ""
    [[ -n "$PROFILE_LOCATION" ]] && layout_box_kv "LOCATION" "$PROFILE_LOCATION"
    [[ -n "$PROFILE_AVAILABILITY" ]] && layout_box_kv "STATUS" "$dot $PROFILE_AVAILABILITY" "$c_green"
    layout_box_line ""
    layout_box_separator

    # Links
    layout_box_line ""
    [[ -n "$PROFILE_URL_PORTFOLIO" ]] && layout_box_kv "PORTFOLIO" "$PROFILE_URL_PORTFOLIO"
    [[ -n "$PROFILE_URL_GITHUB" ]]    && layout_box_kv "GITHUB"    "$PROFILE_URL_GITHUB"
    [[ -n "$PROFILE_URL_LINKEDIN" ]]  && layout_box_kv "LINKEDIN"  "$PROFILE_URL_LINKEDIN"
    [[ -n "$PROFILE_EMAIL" ]]         && layout_box_kv "EMAIL"     "$PROFILE_EMAIL"
    layout_box_line ""
    layout_box_bottom
  else
    # Responsive mobile/narrow fallback
    printf '\n%s%s%s%s\n' "$LAYOUT_MARGIN" "$c_bold$c_accent" "$PROFILE_NAME" "$c_reset"
    layout_wrap "$PROFILE_TITLE" "" "$c_cyan"
    printf '\n'
    layout_wrap "$PROFILE_TAGLINE" "" "$c_bold$c_white"
    printf '\n'
    [[ -n "$PROFILE_LOCATION" ]] && layout_kv "LOCATION" "$PROFILE_LOCATION" 12
    [[ -n "$PROFILE_AVAILABILITY" ]] && layout_kv "STATUS" "$dot $PROFILE_AVAILABILITY" 12
    printf '\n'
    layout_separator
    printf '\n'
    [[ -n "$PROFILE_URL_PORTFOLIO" ]] && layout_kv "PORTFOLIO" "$PROFILE_URL_PORTFOLIO" 12
    [[ -n "$PROFILE_URL_GITHUB" ]]    && layout_kv "GITHUB"    "$PROFILE_URL_GITHUB" 12
    [[ -n "$PROFILE_URL_LINKEDIN" ]]  && layout_kv "LINKEDIN"  "$PROFILE_URL_LINKEDIN" 12
    [[ -n "$PROFILE_EMAIL" ]]         && layout_kv "EMAIL"     "$PROFILE_EMAIL" 12
  fi
  return 0
}

# Right-aligned version badge under the menu.
card_footer() {
  local c_accent="${C_ACCENT:-}"
  local c_dim="${C_DIM:-}"
  local c_reset="${C_RESET:-}"
  local badge="${c_accent}npx $APP_NAME${c_reset} ${c_dim}· v$APP_VERSION${c_reset}"
  local plain="npx $APP_NAME · v$APP_VERSION"
  local pad=$(( LAYOUT_WIDTH - ${#plain} ))
  (( pad < 0 )) && pad=0
  printf '%s%*s%s\n\n' "$LAYOUT_MARGIN" "$pad" '' "$badge"
}
