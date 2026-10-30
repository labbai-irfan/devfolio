# shellcheck shell=bash
# Command-line flag parsing → CFG_* variables.

[[ -n "${_ARGS_SH:-}" ]] && return 0
_ARGS_SH=1

args_usage() {
  cat <<EOF
Usage: npx $APP_NAME [options]

Interactive developer card for Labbai Irfan.
Runs interactively in a terminal; prints a static card when piped.

Options:
      --card           Print the static card and exit.
      --theme <name>   Color theme: default or mono (also LABBAI_THEME).
      --plain          No colors, no box drawing, ASCII only.
      --no-color       Disable colors (same as NO_COLOR=1).
      --interactive    Force interactive mode even without a detected TTY.
      --no-animation   Skip the start-up animation.
  -h, --help           Show this help and exit.
  -v, --version        Show version and exit.
EOF
}

args_parse() {
  while (( $# > 0 )); do
    case "$1" in
      -h|--help)     CFG_ACTION="help" ;;
      -v|--version)  CFG_ACTION="version" ;;
      --card)        CFG_ACTION="card" ;;
      --theme)
        if (( $# < 2 )); then
          log_error "--theme needs a value: default or mono"
          exit "$EXIT_USAGE"
        fi
        case "$2" in
          default|mono) CFG_THEME="$2" ;;
          *) log_error "unknown theme '$2' (use default or mono)"; exit "$EXIT_USAGE" ;;
        esac
        shift
        ;;
      --plain)       CFG_PLAIN=1; CFG_COLOR=0 ;;
      --no-color)    CFG_COLOR=0 ;;
      --interactive) CFG_INTERACTIVE=1 ;;
      --no-animation) CFG_ANIMATE=0 ;;
      *)
        log_error "unknown option '$1'"
        printf 'Run "npx %s --help" for usage.\n' "$APP_NAME" >&2
        exit "$EXIT_USAGE"
        ;;
    esac
    shift
  done
}
