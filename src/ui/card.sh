# shellcheck shell=bash
# The developer card shown on the main screen and in static (--card / piped) mode.

[[ -n "${_CARD_SH:-}" ]] && return 0
_CARD_SH=1

card_render() {
  local where="$PROFILE_LOCATION"
  [[ -n "$PROFILE_AVAILABILITY" ]] && where="$where  $ICON_DOT  $PROFILE_AVAILABILITY"

  if layout_has_box; then
    printf '\n'
    layout_box_top
    layout_box_line ""
    layout_box_line "$(printf '%s' "$PROFILE_NAME" | tr '[:lower:]' '[:upper:]')" "$C_BOLD$C_ACCENT"
    layout_box_line "$PROFILE_TITLE"
    layout_box_line ""
    layout_box_line "$PROFILE_TAGLINE"
    layout_box_line "$where" "$C_DIM"
    layout_box_line ""
    [[ -n "$PROFILE_URL_PORTFOLIO" ]] && layout_box_kv "Portfolio" "$PROFILE_URL_PORTFOLIO"
    [[ -n "$PROFILE_URL_GITHUB" ]]    && layout_box_kv "GitHub" "$PROFILE_URL_GITHUB"
    [[ -n "$PROFILE_URL_LINKEDIN" ]]  && layout_box_kv "LinkedIn" "$PROFILE_URL_LINKEDIN"
    layout_box_line ""
    layout_box_bottom
  else
    # Narrow terminal: same content, no border.
    printf '\n%s%s%s%s%s\n' "$LAYOUT_MARGIN" "$C_BOLD$C_ACCENT" "$(printf '%s' "$PROFILE_NAME" | tr '[:lower:]' '[:upper:]')" "$C_RESET" ""
    layout_wrap "$PROFILE_TITLE"
    printf '\n'
    layout_wrap "$PROFILE_TAGLINE"
    layout_wrap "$where"
    printf '\n'
    [[ -n "$PROFILE_URL_PORTFOLIO" ]] && layout_kv "Portfolio" "$PROFILE_URL_PORTFOLIO" 11
    [[ -n "$PROFILE_URL_GITHUB" ]]    && layout_kv "GitHub" "$PROFILE_URL_GITHUB" 11
    [[ -n "$PROFILE_URL_LINKEDIN" ]]  && layout_kv "LinkedIn" "$PROFILE_URL_LINKEDIN" 11
  fi
  return 0
}

# Right-aligned version line under the menu.
card_footer() {
  local text="npx $APP_NAME $ICON_DOT v$APP_VERSION"
  printf '%s%s%*s%s\n' "$LAYOUT_MARGIN" "$C_DIM" "$LAYOUT_WIDTH" "$text" "$C_RESET"
}
