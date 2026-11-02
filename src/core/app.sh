# shellcheck shell=bash
# Application bootstrap and main control flow.

[[ -n "${_APP_SH:-}" ]] && return 0
_APP_SH=1

APP_INTERACTIVE=0
_APP_CLEANED=0

app_run() {
  config_init
  args_parse "$@"

  case "$CFG_ACTION" in
    help)    args_usage; exit "$EXIT_OK" ;;
    version) printf '%s %s\n' "$APP_NAME" "$APP_VERSION"; exit "$EXIT_OK" ;;
    json)    app_print_json; exit "$EXIT_OK" ;;
  esac

  platform_detect
  colors_init
  layout_init
  app_load_data

  trap app_cleanup EXIT
  trap 'exit "$EXIT_INTERRUPT"' INT TERM
  # -E makes functions inherit the ERR trap, so unexpected failures get a friendly message.
  set -E
  trap app_internal_error ERR

  if [[ "$CFG_ACTION" == card || ( "$PLATFORM_TTY" != 1 && "$CFG_INTERACTIVE" != 1 ) ]]; then
    printf '\n'
    card_render
    if (( PLATFORM_WIDTH < 40 )); then
      printf '\n'
      layout_wrap "Widen the terminal to 40+ columns for the full card." "" "${C_DIM:-}"
    fi
    printf '\n'
    exit "$EXIT_OK"
  fi

  APP_INTERACTIVE=1
  SCREEN_BUF="$(mktemp 2>/dev/null || true)"
  term_alt_screen_on
  term_hide_cursor
  intro_play
  menu_loop app_main_render app_main_handle main
}

# Sources the compiled profile (built from src/data/*.json by scripts/build.sh).
app_load_data() {
  local data="$APP_ROOT/src/data/profile.sh"
  if [[ ! -f "$data" ]]; then
    log_error "profile data is not built yet. Run: npm run build"
    exit "$EXIT_DEPENDENCY"
  fi
  # shellcheck source=/dev/null
  source "$data"
}

# --json: the raw profile data as one JSON object, for scripts and tools. No jq needed.
app_print_json() {
  local f sep=""
  printf '{'
  for f in profile skills projects experience education certifications; do
    printf '%s"%s":' "$sep" "$f"
    tr -d '\r' <"$APP_ROOT/src/data/$f.json"
    sep=","
  done
  printf '}\n'
}

app_main_render() {
  card_render
  menu_items "1:About" "2:Skills" "3:Projects" "4:Career" "5:GitHub" "6:Contact" "7:Resume" "q:Quit"
  menu_prompt
}

app_main_handle() {
  case "$1" in
    1) cmd_about ;;
    2) cmd_skills ;;
    3) cmd_projects ;;
    4) cmd_career ;;
    5) cmd_github ;;
    6) cmd_contact ;;
    7) cmd_resume ;;
    *) return 1 ;;
  esac
}

app_quit() { exit "$EXIT_OK"; }

# Runs on any unexpected failure. Raw Bash errors are never shown to the user.
app_internal_error() {
  trap - ERR
  log_error "something went wrong. Run with LABBAI_DEBUG=1 and report it on the project's GitHub issues page."
  exit "$EXIT_ERROR"
}

# Runs once on any exit: stop animations, restore the terminal, say goodbye in interactive mode.
app_cleanup() {
  [[ "$_APP_CLEANED" == 1 ]] && return 0
  _APP_CLEANED=1
  anim_spin_stop
  [[ -n "$SCREEN_BUF" ]] && rm -f "$SCREEN_BUF"
  if [[ "$APP_INTERACTIVE" == 1 ]]; then
    term_alt_screen_off
    term_show_cursor
    app_goodbye
  fi
  return 0
}

# Sign-off left in the terminal after quitting, written like an email signature:
#   Thanks for your time.  — Labbai Irfan
#   ● Open to DevOps & Cloud Engineering opportunities
#   labbaiirfan09@gmail.com  ·  labbaiirfan.vercel.app
# One aligned column, one blank line above, none below (shells add their own before the prompt).
app_goodbye() {
  local r="${C_RESET:-}" m="$LAYOUT_MARGIN" cyan="${C_CYAN:-${C_ACCENT:-}}" site sep dash="—"
  [[ "${PLATFORM_UTF8:-0}" == 1 ]] || dash="-"
  card_clean_url site "$PROFILE_URL_PORTFOLIO"
  sep="  ${C_MUTED:-${C_DIM:-}}$ICON_DOT$r  "
  # Email and site on separate lines when both would not fit.
  (( ${#PROFILE_EMAIL} + ${#site} + 5 > LAYOUT_WIDTH )) && sep=$'\n'"$m"

  printf '\n%s%sThanks for your time.%s  %s%s %s%s\n' "$m" "${C_BOLD:-}" "$r" \
    "${C_MUTED:-${C_DIM:-}}" "$dash" "${C_ACCENT:-}${C_BOLD:-}$PROFILE_NAME" "$r"
  [[ -n "$PROFILE_AVAILABILITY" ]] && printf '%s%s%s%s %s\n' "$m" "${C_GREEN:-${C_OK:-}}" "$ICON_BULLET" "$r" "$PROFILE_AVAILABILITY"
  if [[ -n "$PROFILE_EMAIL" && -n "$site" ]]; then
    printf '%s%s%s%s%s%s%s%s\n' "$m" "$cyan" "$PROFILE_EMAIL" "$r" "$sep" "$cyan" "$site" "$r"
  elif [[ -n "$PROFILE_EMAIL$site" ]]; then
    printf '%s%s%s%s\n' "$m" "$cyan" "$PROFILE_EMAIL$site" "$r"
  fi
  return 0
}
