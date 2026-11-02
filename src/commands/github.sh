# shellcheck shell=bash
# Section 5 — GitHub: public stats (live, or the dated build snapshot), languages, top repositories.
# Nothing is shown that did not come from the API, except numbers from profile.json, which are
# labelled as self-reported.

[[ -n "${_CMD_GITHUB_SH:-}" ]] && return 0
_CMD_GITHUB_SH=1

cmd_github() {
  printf '\n'
  anim_spin_start "Loading GitHub profile"
  github_load
  github_sanitize
  anim_spin_stop
  menu_loop github_render github_handle
}

# Strips terminal control sequences from API text once, so redraws don't re-run it.
github_sanitize() {
  local i
  GH_LANGS="$(validate_sanitize "$GH_LANGS")"
  for (( i = 0; i < ${#GH_TOP_NAME[@]}; i++ )); do
    GH_TOP_NAME[i]="$(validate_sanitize "${GH_TOP_NAME[i]}")"
    GH_TOP_DESC[i]="$(validate_sanitize "${GH_TOP_DESC[i]:-}")"
  done
}

github_render() {
  layout_header "GitHub" "@$PROFILE_GITHUB_USER"
  github_body
  menu_items "o:Open GitHub profile" "r:Open repositories"
  menu_prompt
}

github_handle() {
  case "$1" in
    o|O) action_open "$PROFILE_URL_GITHUB" "GitHub profile" ;;
    r|R) action_open "$PROFILE_URL_GITHUB?tab=repositories" "GitHub repositories" ;;
    *) return 1 ;;
  esac
}

github_body() {
  local i meta muted="${C_MUTED:-${C_DIM:-}}" label="${C_CYAN:-${C_ACCENT:-}}${C_BOLD:-}"
  local commits="${PROFILE_GH_COMMITS:-}" prs="${PROFILE_GH_PRS:-}" reviews="${PROFILE_GH_REVIEWS:-}" contribs="${PROFILE_GH_CONTRIBS:-}"
  printf '\n'
  case "$GH_SOURCE" in
    live)     layout_wrap "Live from the GitHub API." "" "$muted" ;;
    snapshot) layout_wrap "Snapshot from $GH_AS_OF. Live data is unavailable${GH_ERROR:+ ($GH_ERROR)}." "" "$muted" ;;
    *)        layout_wrap "GitHub data is unavailable${GH_ERROR:+ ($GH_ERROR)}. Press o to open the profile." "" "$muted" ;;
  esac

  if [[ "$GH_SOURCE" != none ]]; then
    printf '\n'
    layout_kv "Public repos" "$GH_REPOS" 15 "$label"
    layout_kv "Followers" "$GH_FOLLOWERS" 15 "$label"
    [[ -n "${GH_FOLLOWING:-}" ]] && layout_kv "Following" "$GH_FOLLOWING" 15 "$label"
    [[ -n "$GH_LANGS" ]] && layout_list 15 "Languages" "$GH_LANGS"
  fi

  if [[ -n "$commits$prs$reviews$contribs" ]]; then
    printf '\n'
    layout_section_title "SELF-REPORTED"
    [[ -n "$commits" ]] && layout_kv "Commits" "$commits" 15 "$label"
    [[ -n "$prs" ]] && layout_kv "Pull requests" "$prs" 15 "$label"
    [[ -n "$reviews" ]] && layout_kv "Code reviews" "$reviews" 15 "$label"
    [[ -n "$contribs" ]] && layout_kv "Contributions" "$contribs" 15 "$label"
  fi

  if (( ${#GH_TOP_NAME[@]} > 0 )); then
    printf '\n'
    layout_section_title "REPOSITORIES"
    for (( i = 0; i < ${#GH_TOP_NAME[@]}; i++ )); do
      (( i > 0 )) && printf '\n'
      meta="${GH_TOP_LANG[i]:-}"
      [[ "${GH_TOP_STARS[i]:-0}" != 0 ]] && meta="${meta:+$meta  }$ICON_STAR ${GH_TOP_STARS[i]}"
      layout_title_right "  ${GH_TOP_NAME[i]}" "$meta"
      [[ -n "${GH_TOP_DESC[i]:-}" ]] && layout_wrap "${GH_TOP_DESC[i]}" "  " "$muted"
      # owner/repo is enough on the GitHub screen, and fits narrow terminals.
      [[ -n "${GH_TOP_URL[i]:-}" ]] && printf '%s  %s%s%s\n' "$LAYOUT_MARGIN" "${C_CYAN:-${C_ACCENT:-}}" "${GH_TOP_URL[i]#https://github.com/}" "${C_RESET:-}"
    done
  fi
  return 0
}
