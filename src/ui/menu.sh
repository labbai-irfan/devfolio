# shellcheck shell=bash
# Generic single-key menu: render → read key → dispatch. Reused by the main menu and every submenu.

[[ -n "${_MENU_SH:-}" ]] && return 0
_MENU_SH=1

MENU_STATUS=""   # one-line feedback shown under the menu until the next key press

# menu_status LEVEL TEXT — LEVEL is ok | warn | err | hint
menu_status() {
  case "$1" in
    ok)   MENU_STATUS="$C_OK$ICON_OK$C_RESET $2" ;;
    warn) MENU_STATUS="$C_WARN$ICON_WARN$C_RESET $2" ;;
    err)  MENU_STATUS="$C_ERR$ICON_ERR$C_RESET $2" ;;
    *)    MENU_STATUS="$C_DIM$2$C_RESET" ;;
  esac
}

# menu_items "KEY:Label" ... — two columns when there are more than 4 items and room for it.
menu_items() {
  local n=$# cols=1 rows i j item key label line
  (( n > 4 )) && layout_has_box && cols=2
  rows=$(( (n + cols - 1) / cols ))
  local -a items=("$@")
  printf '\n'
  for (( i = 0; i < rows; i++ )); do
    line="$LAYOUT_MARGIN   "
    for (( j = i; j < n; j += rows )); do
      item="${items[$j]}"
      key="${item%%:*}"
      label="${item#*:}"
      printf -v line '%s%s%s%s  %-14s' "$line" "$C_ACCENT" "$key" "$C_RESET" "$label"
    done
    printf '%s\n' "$line"
  done
}

menu_prompt() {
  printf '\n%s   Press a key %s%s%s\n' "$LAYOUT_MARGIN" "$C_DIM" "$ICON_PROMPT" "$C_RESET"
  if [[ -n "$MENU_STATUS" ]]; then printf '%s   %s\n' "$LAYOUT_MARGIN" "$MENU_STATUS"; else printf '\n'; fi
}

# section_view TITLE BODY_FN [RIGHT_TEXT] — read-only screen. BODY_FN prints the content; long content is paged.
#   b returns to the caller, q quits, any other key shows the next page.
section_view() {
  local title="$1" body_fn="$2" right="${3:-}" key line i start=0 total page_size
  local -a lines=()
  while IFS= read -r line; do lines+=("$line"); done <<<"$("$body_fn")"
  total=${#lines[@]}
  page_size=$(( $(term_height) - 8 ))
  (( page_size < 5 )) && page_size=5

  while :; do
    term_clear
    layout_header "$title" "$right"
    printf '\n'
    for (( i = start; i < start + page_size && i < total; i++ )); do printf '%s\n' "${lines[$i]}"; done
    printf '\n'
    layout_separator
    if (( start + page_size < total )); then
      printf '%s%sb%s  Back     %sq%s  Quit     %sany key%s  More\n' "$LAYOUT_MARGIN" "$C_ACCENT" "$C_RESET" "$C_ACCENT" "$C_RESET" "$C_ACCENT" "$C_RESET"
    else
      layout_footer
    fi
    term_read_key key || app_quit
    case "$key" in
      q|Q) app_quit ;;
      b|B) return 0 ;;
      *) (( start + page_size < total )) && start=$(( start + page_size )) ;;
    esac
  done
}

# menu_loop RENDER_FN HANDLE_FN [main]
#   RENDER_FN draws the whole screen. HANDLE_FN receives the key and returns 0 if it handled it.
#   q quits from anywhere; b returns to the caller (ignored on the main menu); EOF on stdin quits.
menu_loop() {
  local render="$1" handle="$2" is_main="${3:-}" key
  MENU_STATUS=""
  MENU_DONE=""
  while :; do
    term_clear
    "$render"
    term_read_key key || app_quit
    case "$key" in
      q|Q) app_quit ;;
      b|B) [[ -n "$is_main" ]] || return 0 ;;
    esac
    if ! "$handle" "$key"; then
      if [[ -n "$is_main" ]]; then
        menu_status hint "Use the keys shown, q to quit."
      else
        menu_status hint "Use the keys shown, b to go back, q to quit."
      fi
    fi
    # A handler sets MENU_DONE to leave this screen (used by the project tag picker).
    [[ -z "$MENU_DONE" ]] || return 0
  done
}
