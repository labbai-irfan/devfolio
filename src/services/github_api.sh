# shellcheck shell=bash
# GitHub public stats (no token needed): profile counts, top languages and top own repositories,
# loaded live at runtime or from the dated build snapshot (src/data/github.sh).

[[ -n "${_GITHUB_API_SH:-}" ]] && return 0
_GITHUB_API_SH=1

GH_SOURCE="none"   # live | snapshot | none
GH_AS_OF=""        # snapshot date, YYYY-MM-DD
GH_ERROR=""        # why live data is missing: offline | rate limit reached | user not found | unavailable
GH_REPOS=""
GH_FOLLOWERS=""
GH_FOLLOWING=""
GH_LANGS=""        # "|"-joined, most used first
GH_TOP_NAME=()
GH_TOP_STARS=()
GH_TOP_DESC=()
GH_TOP_LANG=()
GH_TOP_URL=()

# github_get URL OUTFILE — prints HTTP status code, or 000 when request never completed.
github_get() {
  local url="$1" out="$2" code
  code="$(curl -sS --max-time 5 -o "$out" -w '%{http_code}' \
    -H 'Accept: application/vnd.github+json' \
    ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
    "$url" 2>/dev/null)" || true
  printf '%s' "${code:-000}"
}

github_status_reason() {
  case "$1" in
    000) printf 'offline' ;;
    403|429) printf 'rate limit reached' ;;
    404) printf 'user not found' ;;
    *) printf 'unavailable' ;;
  esac
}

# github_render_shell USER_JSON_FILE REPOS_JSON_FILE — prints GH_* assignments.
github_render_shell() {
  jq -n -r --slurpfile user "$1" --slurpfile repos "$2" '
    ($user[0]) as $u
    | ($repos[0] | map(select((.fork | not) and (.archived | not)))) as $own
    | ($own | sort_by(.updated_at // "") | reverse | sort_by(-(.stargazers_count // 0)) | .[0:6]) as $top
    | ($own | map(.language // empty) | group_by(.) | map({l: .[0], n: length})
        | sort_by(-.n) | .[0:6] | map(.l) | join("|")) as $langs
    | "GH_REPOS=\($u.public_repos // 0)",
      "GH_FOLLOWERS=\($u.followers // 0)",
      "GH_FOLLOWING=\($u.following // 0)",
      "GH_LANGS=\($langs | @sh)",
      "GH_TOP_NAME=(\($top | map(.name // "" | @sh) | join(" ")))",
      "GH_TOP_STARS=(\($top | map(.stargazers_count // 0 | tostring | @sh) | join(" ")))",
      "GH_TOP_DESC=(\($top | map(.description // "" | @sh) | join(" ")))",
      "GH_TOP_LANG=(\($top | map(.language // "" | @sh) | join(" ")))",
      "GH_TOP_URL=(\($top | map(.html_url // "" | @sh) | join(" ")))"
  '
}

# github_fetch_shell USER OUTFILE — writes GH_* assignments to OUTFILE.
github_fetch_shell() {
  local user="$1" out="$2" body_u body_r status code=0
  GH_ERROR=""
  [[ "$user" =~ ^[A-Za-z0-9-]{1,39}$ ]] || { GH_ERROR="not configured"; return 1; }

  body_u="$(mktemp)"
  body_r="$(mktemp)"
  status="$(github_get "https://api.github.com/users/$user" "$body_u")"
  if [[ "$status" == 200 ]]; then
    status="$(github_get "https://api.github.com/users/$user/repos?per_page=100&sort=updated" "$body_r")"
  fi
  if [[ "$status" == 200 ]] && github_render_shell "$body_u" "$body_r" >"$out"; then
    code=0
  else
    code=1
    GH_ERROR="$(github_status_reason "$status")"
  fi
  rm -f "$body_u" "$body_r"
  return "$code"
}

# github_load — fills GH_* once per session: live when possible, otherwise snapshot.
github_load() {
  local tmp
  [[ -n "${GH_LOADED:-}" ]] && return 0
  GH_LOADED=1

  if [[ "${LABBAI_OFFLINE:-}" == 1 ]]; then
    GH_ERROR="offline mode"
  elif ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    GH_ERROR="curl or jq is missing"
  else
    tmp="$(mktemp)"
    if github_fetch_shell "$PROFILE_GITHUB_USER" "$tmp"; then
      # shellcheck source=/dev/null
      source "$tmp"
      GH_SOURCE="live"
      GH_AS_OF="$(date +%Y-%m-%d)"
      rm -f "$tmp"
      return 0
    fi
    rm -f "$tmp"
  fi
  github_load_snapshot
}

github_load_snapshot() {
  local snap="$APP_ROOT/src/data/github.sh" reason="$GH_ERROR"
  [[ -f "$snap" ]] || return 0
  # shellcheck source=/dev/null
  source "$snap"
  [[ -n "$reason" ]] && GH_ERROR="$reason"
  return 0
}
