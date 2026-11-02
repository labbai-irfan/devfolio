# shellcheck shell=bash
# Section 8 — Pipeline: how this CLI is engineered — its real build, test and release pipeline
# (.github/workflows/ci.yml + release.yml) and the techniques behind the interface.

[[ -n "${_CMD_BUILT_SH:-}" ]] && return 0
_CMD_BUILT_SH=1

cmd_built() { section_view "Pipeline" built_body "how this CLI is built and shipped"; }

# built_row LABEL TEXT [COLOR] — label column with TEXT wrapped beside it.
built_row() {
  local lead
  printf -v lead '%s%-10s%s' "${C_CYAN:-${C_ACCENT:-}}${C_BOLD:-}" "$1" "${C_RESET:-}"
  layout_wrap "$2" "$lead" "          " "${3:-${C_WHITE:-}}"
}

# built_stage NAME TEXT [last] — one node of the pipeline, joined to the next by the timeline rule.
built_stage() {
  local r="${C_RESET:-}" rule lead
  rule="${C_BORDER:-${C_DIM:-}}$ICON_RULE$r"
  printf -v lead '%s%s%s %s%-9s%s' "${C_GREEN:-${C_OK:-}}" "$ICON_NODE" "$r" "${C_CYAN:-${C_ACCENT:-}}${C_BOLD:-}" "$1" "$r"
  layout_wrap "$2" "$lead" "$rule          " "${C_WHITE:-}"
  [[ -n "${3:-}" ]] || printf '%s%s\n' "$LAYOUT_MARGIN" "$rule"
}

built_body() {
  local -a modules=("$APP_ROOT"/src/{lib,core,ui,services,commands}/*.sh)
  local arrow="->" source=""
  [[ "${PLATFORM_UTF8:-0}" == 1 ]] && arrow="→"
  source="$(sed -n 's/.*"url": *"git+\(https:\/\/github\.com\/[^"]*\)\.git".*/\1/p' "$APP_ROOT/package.json" | head -1)"

  layout_section_title "PIPELINE"
  built_stage "Code" "Bash 3.2+ split into ${#modules[@]} modules (lib, core, ui, services, commands). No runtime dependencies; Node is only the npx launcher."
  built_stage "Check" "Syntax check $ICON_DOT ShellCheck $ICON_DOT profile data validated with jq $ICON_DOT smoke tests of every screen, width and mode."
  built_stage "Build" "Packaged and run on Linux, macOS and Windows in GitHub Actions, with a package size limit."
  built_stage "Release" "Git tag $arrow release check $arrow npm publish with provenance $arrow GitHub Release notes from the changelog."
  built_stage "Run" "npx labbai-irfan" last

  printf '\n'
  layout_section_title "UNDER THE HOOD"
  built_row "Data" "Profile kept in JSON, validated, then compiled to Bash at build time, so visitors never need jq."
  built_row "GitHub" "Live from the public REST API, with a dated snapshot from the last build when offline."
  built_row "Screen" "Every frame is rendered off-screen and written at once: no flicker, no leftover characters."
  built_row "Input" "Arrow keys, mouse wheel and terminal resize, with Unicode and plain ASCII fallbacks."
  built_row "Access" "Respects NO_COLOR, --plain, reduced motion and offline mode; static card when piped."

  if [[ -n "$source" ]]; then
    printf '\n'
    built_row "Source" "$source" "${C_CYAN:-${C_ACCENT:-}}"
  fi
  return 0
}
