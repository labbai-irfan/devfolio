# shellcheck shell=bash
# Constants, exit codes and runtime config defaults.

[[ -n "${_CONFIG_SH:-}" ]] && return 0
_CONFIG_SH=1

readonly APP_NAME="labbai-irfan"

readonly EXIT_OK=0
readonly EXIT_ERROR=1
readonly EXIT_USAGE=2
readonly EXIT_DEPENDENCY=3
readonly EXIT_INTERRUPT=130

# Set by args_parse.
CFG_ACTION="run"     # run | help | version | card | json
CFG_THEME="${LABBAI_THEME:-default}"   # default | mono
CFG_COLOR=1
CFG_PLAIN=0
CFG_INTERACTIVE=0
CFG_ANIMATE=1

config_init() {
  # package.json always ships with the npm package, so it is the single version source.
  APP_VERSION="$(sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' "$APP_ROOT/package.json")"
  APP_VERSION="${APP_VERSION:-unknown}"
  log_debug "root=$APP_ROOT version=$APP_VERSION"
}
