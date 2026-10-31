# shellcheck shell=bash
# Section 5 — GitHub: Complete developer activity, telemetry, commits, PRs & repositories.

[[ -n "${_CMD_GITHUB_SH:-}" ]] && return 0
_CMD_GITHUB_SH=1

cmd_github() {
  printf '\n'
  anim_spin_start "Syncing GitHub developer telemetry…"
  github_load
  anim_spin_stop
  menu_loop github_render github_handle
}

github_render() {
  layout_header "GitHub Telemetry" "@$PROFILE_GITHUB_USER"
  github_body
  printf '\n'
  menu_items "o:Open GitHub profile" "r:Explore Repositories on Web"
  menu_prompt
  layout_footer
}

github_handle() {
  case "$1" in
    o|O) action_open "$PROFILE_URL_GITHUB" "GitHub profile" ;;
    r|R) action_open "$PROFILE_URL_GITHUB?tab=repositories" "GitHub repositories" ;;
    *) return 1 ;;
  esac
}

github_body() {
  local i name desc langs stars lang url
  local c_cyan="${C_CYAN:-${C_ACCENT:-}}"
  local c_accent="${C_ACCENT:-}"
  local c_green="${C_GREEN:-${C_OK:-}}"
  local c_white="${C_WHITE:-${C_BOLD:-}}"
  local c_muted="${C_MUTED:-${C_DIM:-}}"
  local c_dim="${C_DIM:-}"
  local c_bold="${C_BOLD:-}"
  local c_reset="${C_RESET:-}"

  # 1. Telemetry Status
  case "$GH_SOURCE" in
    live)     layout_wrap "Live telemetry synced via GitHub REST API." "  " "$c_muted" ;;
    snapshot) layout_wrap "Telemetry snapshot as of $GH_AS_OF (offline mode)." "  " "$c_muted" ;;
    *)        layout_wrap "Telemetry snapshot as of $GH_AS_OF." "  " "$c_muted" ;;
  esac
  printf '\n'

  # 2. Activity & Engagement Metrics
  layout_section_title "ACTIVITY & COLLABORATION" "◆"
  layout_kv "Username" "@$PROFILE_GITHUB_USER" 18 "$c_cyan" "$c_white"
  layout_kv "Public Repos" "${GH_REPOS:-14}" 18 "$c_cyan" "$c_white"
  layout_kv "Total Commits" "${PROFILE_GH_COMMITS:-350+}" 18 "$c_cyan" "$c_white"
  layout_kv "Pull Requests" "${PROFILE_GH_PRS:-25+}" 18 "$c_cyan" "$c_white"
  layout_kv "Contributions" "${PROFILE_GH_CONTRIBS:-400+}" 18 "$c_cyan" "$c_green"
  layout_kv "Followers" "${GH_FOLLOWERS:-0}" 18 "$c_cyan" "$c_white"
  layout_kv "Following" "${GH_FOLLOWING:-2}" 18 "$c_cyan" "$c_white"
  layout_kv "Profile" "https://github.com/$PROFILE_GITHUB_USER" 18 "$c_cyan" "$c_white"
  printf '\n'

  # 3. Primary Languages Ecosystem
  langs="$(validate_sanitize "${GH_LANGS:-TypeScript|JavaScript|HCL|HTML|Shell|Python}")"
  if [[ -n "$langs" ]]; then
    layout_section_title "PRIMARY LANGUAGES" "◆"
    local -a lang_arr=()
    IFS='|' read -r -a lang_arr <<< "$langs"
    layout_tag_pills "${lang_arr[@]}"
    printf '\n'
  fi

  # 4. Featured & Active Repositories
  if (( ${#GH_TOP_NAME[@]} > 0 )); then
    layout_section_title "ACTIVE & FEATURED REPOSITORIES" "◆"

    for (( i = 0; i < ${#GH_TOP_NAME[@]}; i++ )); do
      name="$(validate_sanitize "${GH_TOP_NAME[$i]}")"
      desc="$(validate_sanitize "${GH_TOP_DESC[$i]}")"
      stars="${GH_TOP_STARS[$i]:-0}"
      lang="${GH_TOP_LANG[$i]:-Code}"
      url="${GH_TOP_URL[$i]:-https://github.com/$PROFILE_GITHUB_USER/$name}"

      # Title row with language badge & stars
      local star_info=""
      (( stars > 0 )) && star_info=" · ★ $stars"
      printf '%s  %s%s%s  %s[%s%s]%s\n' \
        "$LAYOUT_MARGIN" "$c_white$c_bold" "$name" "$c_reset" \
        "$c_cyan" "$lang" "$star_info" "$c_reset"

      # Description or fallback
      if [[ -n "$desc" ]]; then
        layout_wrap "$desc" "    " "$c_muted"
      else
        printf '%s    %sNo description provided%s\n' "$LAYOUT_MARGIN" "$c_muted" "$c_reset"
      fi

      # Direct repo URL link
      printf '%s    %s🔗 %s%s\n\n' "$LAYOUT_MARGIN" "$c_muted" "$url" "$c_reset"
    done
  fi
}
