# shellcheck shell=bash
# Section 5 — GitHub: public stats (live, or the build snapshot) and a link to the profile.

[[ -n "${_CMD_GITHUB_SH:-}" ]] && return 0
_CMD_GITHUB_SH=1

cmd_github() {
  printf '\n'
  anim_spin_start "Connecting to GitHub…"
  github_load
  anim_spin_stop
  menu_loop github_render github_handle
}

github_render() {
  layout_header "GitHub" "@$PROFILE_GITHUB_USER"
  printf '\n'
  github_body
  printf '\n'
  menu_items "o:Open GitHub profile"
  menu_prompt
  layout_footer
}

github_handle() {
  case "$1" in
    o|O) action_open "$PROFILE_URL_GITHUB" "GitHub link" ;;
    *) return 1 ;;
  esac
}

github_body() {
  local i name desc langs
  case "$GH_SOURCE" in
    live)     layout_wrap "Live from GitHub." ;;
    snapshot) layout_wrap "Snapshot from $GH_AS_OF. Live data unavailable${GH_ERROR:+: $GH_ERROR}." ;;
    *)        layout_wrap "GitHub stats are unavailable${GH_ERROR:+: $GH_ERROR}."; return 0 ;;
  esac

  printf '\n'
  layout_kv "Public repos" "$GH_REPOS" 14
  layout_kv "Followers" "$GH_FOLLOWERS" 14
  langs="$(validate_sanitize "$GH_LANGS")"
  [[ -n "$langs" ]] && layout_kv "Languages" "${langs//|/, }" 14

  if (( ${#GH_TOP_NAME[@]} > 0 )); then
    printf '\n%s%sTop repositories%s\n' "$LAYOUT_MARGIN" "$C_ACCENT" "$C_RESET"
    for (( i = 0; i < ${#GH_TOP_NAME[@]}; i++ )); do
      name="$(validate_sanitize "${GH_TOP_NAME[$i]}")"
      desc="$(validate_sanitize "${GH_TOP_DESC[$i]}")"
      layout_title_right "$name" "${GH_TOP_STARS[$i]} stars"
      [[ -n "$desc" ]] && layout_wrap "$desc"
      printf '\n'
    done
  fi
  return 0
}
