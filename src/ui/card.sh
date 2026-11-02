# shellcheck shell=bash
# The developer card shown on the main screen and in static (--card / piped) mode.
# Compact mode (short terminals) keeps every fact but drops the decorative separator and focus rows.

[[ -n "${_CARD_SH:-}" ]] && return 0
_CARD_SH=1

# card_clean_url VAR URL — URL without protocol and trailing slash, for display.
card_clean_url() {
  local u="${2#https://}"
  u="${u#http://}"
  printf -v "$1" '%s' "${u%/}"
}

card_render() {
  local portfolio github linkedin focus="" f
  local cyan="${C_CYAN:-${C_ACCENT:-}}" green="${C_GREEN:-${C_OK:-}}" white="${C_WHITE:-${C_BOLD:-}}"
  local muted="${C_MUTED:-${C_DIM:-}}" b="${C_BOLD:-}" r="${C_RESET:-}"
  local tagline="$QUOTE_OPEN$PROFILE_TAGLINE$QUOTE_CLOSE"

  card_clean_url portfolio "${PROFILE_URL_PORTFOLIO:-}"
  card_clean_url github "${PROFILE_URL_GITHUB:-}"
  card_clean_url linkedin "${PROFILE_URL_LINKEDIN:-}"
  for f in ${PROFILE_FOCUS[@]+"${PROFILE_FOCUS[@]}"}; do
    focus="${focus:+$focus  $ICON_DOT  }$f"
  done
  # Footer comes from profile.json "focus", uppercased (tr: bash 3 has no ${f^^}).
  focus="$(printf '%s' "$focus" | tr '[:lower:]' '[:upper:]')"

  if ! layout_has_box; then
    printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "$b${C_ACCENT:-}" "$PROFILE_NAME" "$r"
    layout_wrap "$PROFILE_TITLE" "" "$cyan"
    [[ -n "$PROFILE_TAGLINE" ]] && layout_wrap "$tagline" "" "$b$white"
    printf '\n'
    [[ -n "$PROFILE_LOCATION" ]] && layout_kv "LOCATION" "$PROFILE_LOCATION" 12
    [[ -n "$PROFILE_AVAILABILITY" ]] && layout_kv "STATUS" "$ICON_BULLET $PROFILE_AVAILABILITY" 12 "" "$green"
    layout_separator
    [[ -n "$portfolio" ]] && layout_kv "PORTFOLIO" "$portfolio" 12
    [[ -n "$github" ]] && layout_kv "GITHUB" "$github" 12
    [[ -n "$linkedin" ]] && layout_kv "LINKEDIN" "$linkedin" 12
    [[ -n "$PROFILE_EMAIL" ]] && layout_kv "EMAIL" "$PROFILE_EMAIL" 12
    [[ -n "$focus" ]] && { layout_separator; layout_wrap "$focus" "" "$muted"; }
    return 0
  fi

  layout_box_top
  layout_box_line "$PROFILE_NAME" "$b${C_ACCENT:-}"
  layout_box_line "$PROFILE_TITLE" "$cyan"
  [[ -n "$PROFILE_TAGLINE" ]] && layout_box_line "$tagline" "$b$white"
  layout_box_separator

  [[ -n "$PROFILE_LOCATION" ]] && layout_box_kv "LOCATION" "$PROFILE_LOCATION" "$white" 14
  [[ -n "$PROFILE_AVAILABILITY" ]] && layout_box_kv "AVAILABILITY" "$ICON_BULLET $PROFILE_AVAILABILITY" "$green" 14
  layout_box_separator

  [[ -n "$portfolio" ]] && layout_box_kv "PORTFOLIO" "$portfolio" "$white" 14
  [[ -n "$github" ]] && layout_box_kv "GITHUB" "$github" "$white" 14
  [[ -n "$linkedin" ]] && layout_box_kv "LINKEDIN" "$linkedin" "$white" 14
  [[ -n "$PROFILE_EMAIL" ]] && layout_box_kv "EMAIL" "$PROFILE_EMAIL" "$white" 14

  if [[ -n "$focus" ]]; then
    layout_box_separator
    layout_box_line "$focus" "$muted"
  fi
  layout_box_bottom
}
