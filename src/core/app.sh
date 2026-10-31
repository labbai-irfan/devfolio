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
    card_render
    if (( PLATFORM_WIDTH < 40 )); then
      printf '\n%s%sWiden the terminal to 40+ columns for the full card.%s\n' "$LAYOUT_MARGIN" "$C_DIM" "$C_RESET"
    fi
    printf '\n'
    exit "$EXIT_OK"
  fi

  APP_INTERACTIVE=1
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

app_main_render() {
  card_render
  menu_items "1:About" "2:Skills" "3:Projects" "4:Career" "5:GitHub" "6:Contact" "7:Resume" "8:Portfolio" "q:Quit"
  menu_prompt
  card_footer
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
    8) cmd_portfolio ;;
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

# Runs once on any exit: restore the terminal, say goodbye in interactive mode.
app_cleanup() {
  [[ "$_APP_CLEANED" == 1 ]] && return 0
  _APP_CLEANED=1
  anim_spin_stop
  if [[ "$APP_INTERACTIVE" == 1 ]]; then
    term_show_cursor
    printf '%s\n%sThanks for stopping by %s %s%s\n\n' "$C_RESET" "$LAYOUT_MARGIN" "$ICON_DOT" "$PROFILE_URL_PORTFOLIO" "$C_RESET"
  fi
}
