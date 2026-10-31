# shellcheck shell=bash
# The developer card shown on the main screen and in static (--card / piped) mode.
# Master crafted terminal UI/UX for Labbai Irfan.

[[ -n "${_CARD_SH:-}" ]] && return 0
_CARD_SH=1

CARD_ANIM_SHOWN=0

# Clean display URLs: strips protocol and trailing slash for elegant presentation
card_clean_url() {
  local u="$1"
  u="${u#https://}"
  u="${u#http://}"
  u="${u%/}"
  printf '%s' "$u"
}

card_render() {
  local is_static=0
  if [[ "${CFG_ACTION:-}" == "card" || "${PLATFORM_TTY:-0}" != 1 || "${CFG_INTERACTIVE:-0}" != 1 ]]; then
    is_static=1
  fi

  local dot="●"
  [[ "${PLATFORM_UTF8:-0}" != 1 ]] && dot="*"

  # Colors with safe fallback
  local c_accent="${C_ACCENT:-}"
  local c_cyan="${C_CYAN:-${C_ACCENT:-}}"
  local c_green="${C_GREEN:-${C_OK:-}}"
  local c_white="${C_WHITE:-${C_BOLD:-}}"
  local c_muted="${C_MUTED:-${C_DIM:-}}"
  local c_dim="${C_DIM:-}"
  local c_bold="${C_BOLD:-}"
  local c_reset="${C_RESET:-}"

  # Cleaned URLs
  local disp_portfolio disp_github disp_linkedin disp_email
  disp_portfolio="$(card_clean_url "${PROFILE_URL_PORTFOLIO:-}")"
  disp_github="$(card_clean_url "${PROFILE_URL_GITHUB:-}")"
  disp_linkedin="$(card_clean_url "${PROFILE_URL_LINKEDIN:-}")"
  disp_email="${PROFILE_EMAIL:-}"

  local should_anim=0
  if [[ "$is_static" == 0 && "${CARD_ANIM_SHOWN:-0}" == 0 && "${CFG_ANIMATE:-1}" == 1 && "${LABBAI_REDUCED_MOTION:-0}" != 1 ]]; then
    should_anim=1
    CARD_ANIM_SHOWN=1
  fi

  if layout_has_box; then
    layout_box_top

    # Section 1: Identity & Professional Focus
    layout_box_line "$PROFILE_NAME" "$c_bold$c_accent"
    [[ "$should_anim" == 1 ]] && sleep 0.04
    layout_box_line "$PROFILE_TITLE" "$c_cyan"
    layout_box_separator

    # Section 2: Core Tagline & Engineering Philosophy
    layout_box_line "“$PROFILE_TAGLINE”" "$c_bold$c_white"
    layout_box_separator

    # Section 3: Location & Career Availability
    [[ -n "${PROFILE_LOCATION:-}" ]] && layout_box_kv "LOCATION" "$PROFILE_LOCATION" "$c_white" 14
    [[ "$should_anim" == 1 ]] && sleep 0.03
    if [[ -n "${PROFILE_AVAILABILITY:-}" ]]; then
      layout_box_kv "AVAILABILITY" "$dot $PROFILE_AVAILABILITY" "$c_green" 14
    fi
    layout_box_separator

    # Section 4: Verified Channels & Links
    [[ -n "$disp_portfolio" ]] && layout_box_kv "PORTFOLIO" "$disp_portfolio" "$c_white" 14
    [[ "$should_anim" == 1 ]] && sleep 0.02
    [[ -n "$disp_github" ]]    && layout_box_kv "GITHUB"    "$disp_github" "$c_white" 14
    [[ "$should_anim" == 1 ]] && sleep 0.02
    [[ -n "$disp_linkedin" ]]  && layout_box_kv "LINKEDIN"  "$disp_linkedin" "$c_white" 14
    [[ "$should_anim" == 1 ]] && sleep 0.02
    [[ -n "$disp_email" ]]     && layout_box_kv "EMAIL"     "$disp_email" "$c_white" 14
    layout_box_separator

    # Section 5: Subtle Architectural Badge
    layout_box_line "SOFTWARE ENGINEERING  ·  DEVOPS  ·  CLOUD INFRASTRUCTURE" "$c_muted"
    layout_box_bottom

  else
    # Responsive clean fallback for narrow mobile terminals
    printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "$c_bold$c_accent" "$PROFILE_NAME" "$c_reset"
    layout_wrap "$PROFILE_TITLE" "" "$c_cyan"
    layout_wrap "“$PROFILE_TAGLINE”" "" "$c_bold$c_white"
    [[ -n "${PROFILE_LOCATION:-}" ]] && layout_kv "LOCATION" "$PROFILE_LOCATION" 14
    [[ -n "${PROFILE_AVAILABILITY:-}" ]] && layout_kv "STATUS" "$dot $PROFILE_AVAILABILITY" 14
    layout_separator
    [[ -n "$disp_portfolio" ]] && layout_kv "PORTFOLIO" "$disp_portfolio" 14
    [[ -n "$disp_github" ]]    && layout_kv "GITHUB"    "$disp_github" 14
    [[ -n "$disp_linkedin" ]]  && layout_kv "LINKEDIN"  "$disp_linkedin" 14
    [[ -n "$disp_email" ]]     && layout_kv "EMAIL"     "$disp_email" 14
  fi

  return 0
}

# Right-aligned professional version badge under menu.
card_footer() {
  local c_accent="${C_ACCENT:-}"
  local c_muted="${C_MUTED:-${C_DIM:-}}"
  local c_reset="${C_RESET:-}"
  local badge="${c_accent}npx $APP_NAME${c_reset} ${c_muted}· v$APP_VERSION${c_reset}"
  local plain="npx $APP_NAME · v$APP_VERSION"
  local pad=$(( LAYOUT_WIDTH - ${#plain} ))
  (( pad < 0 )) && pad=0
  printf '%s%*s%s\n' "$LAYOUT_MARGIN" "$pad" '' "$badge"
}
