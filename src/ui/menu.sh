# shellcheck shell=bash
# Generic single-key & arrow-navigable menu: render → read key → dispatch.
# Supports both:
# 1. Direct number/letter key presses (e.g. 1, 2, q, b)
# 2. Arrow keys (Up/Down/Left/Right), Tab, and Enter to navigate and select

[[ -n "${_MENU_SH:-}" ]] && return 0
_MENU_SH=1

MENU_STATUS=""   # one-line feedback shown under the menu until the next key press
MENU_DONE=""
MENU_SELECTED_INDEX=0

# menu_status LEVEL TEXT — LEVEL is ok | warn | err | hint
menu_status() {
  local c_ok="${C_OK:-}" c_warn="${C_WARN:-}" c_err="${C_ERR:-}" c_dim="${C_DIM:-}" c_reset="${C_RESET:-}"
  case "$1" in
    ok)   MENU_STATUS="$c_ok$ICON_OK$c_reset $2" ;;
    warn) MENU_STATUS="$c_warn$ICON_WARN$c_reset $2" ;;
    err)  MENU_STATUS="$c_err$ICON_ERR$c_reset $2" ;;
    *)    MENU_STATUS="$c_dim$2$c_reset" ;;
  esac
}

# menu_items "KEY:Label" ...
# Formats into two balanced columns with ample spacing to prevent overlapping.
# When selected by arrows, items highlight with an active cursor indicator.
menu_items() {
  local n=$# cols=1 rows i j item key label col_width=28
  local c_accent="${C_ACCENT:-}" c_err="${C_ERR:-}" c_bold="${C_BOLD:-}" c_reset="${C_RESET:-}"
  local c_white="${C_WHITE:-}" c_dim="${C_DIM:-}"

  (( n > 4 )) && layout_has_box && cols=2
  rows=$(( (n + cols - 1) / cols ))
  local -a items=("$@")

  printf '\n'
  for (( i = 0; i < rows; i++ )); do
    local line="$LAYOUT_MARGIN  "
    for (( j = i; j < n; j += rows )); do
      item="${items[$j]}"
      key="${item%%:*}"
      label="${item#*:}"

      local prefix="  "
      local key_fmt="$c_accent$c_bold[$key]$c_reset"
      [[ "$key" == "q" ]] && key_fmt="$c_err$c_bold[$key]$c_reset"

      if (( j == MENU_SELECTED_INDEX )); then
        prefix="${c_accent}❯ ${c_reset}"
        if [[ "$key" == "q" ]]; then
          key_fmt="$c_err$c_bold[$key]$c_reset"
          label="$c_err$c_bold$label$c_reset"
        else
          key_fmt="$c_accent$c_bold[$key]$c_reset"
          label="$c_white$c_bold$label$c_reset"
        fi
      fi

      local item_rendered
      printf -v item_rendered '%s%s %-*s' "$prefix" "$key_fmt" "$col_width" "$label"

      line="${line}${item_rendered}"
    done
    printf '%s\n' "$line"
  done
}

menu_prompt() {
  local c_accent="${C_ACCENT:-}" c_dim="${C_DIM:-}" c_bold="${C_BOLD:-}" c_reset="${C_RESET:-}"
  printf '\n%s  %s❯%s %sNavigate with ↑/↓/Enter or press key directly%s\n' \
    "$LAYOUT_MARGIN" "$c_accent$c_bold" "$c_reset" "$c_dim" "$c_reset"
  if [[ -n "$MENU_STATUS" ]]; then
    printf '%s  %s\n' "$LAYOUT_MARGIN" "$MENU_STATUS"
  else
    printf '\n'
  fi
}

# section_view TITLE BODY_FN [RIGHT_TEXT] — read-only screen. BODY_FN prints the content; long content is paged.
section_view() {
  local title="$1" body_fn="$2" right="${3:-}" key line i start=0 total page_size
  local c_accent="${C_ACCENT:-}" c_reset="${C_RESET:-}"
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
      printf '%s%sb%s  Back     %sq%s  Quit     %sany key%s  More\n' "$LAYOUT_MARGIN" "$c_accent" "$c_reset" "$c_accent" "$c_reset" "$c_accent" "$c_reset"
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

# read_raw_key reads a single key or parses escape sequences for arrows
term_read_input() {
  local k rest
  IFS= read -rsn1 k || return 1
  if [[ "$k" == $'\033' ]]; then
    read -rsn2 -t 0.1 rest || true
    case "$rest" in
      '[A') echo "UP" ;;
      '[B') echo "DOWN" ;;
      '[C') echo "RIGHT" ;;
      '[D') echo "LEFT" ;;
      *)    echo "ESC" ;;
    esac
    return 0
  fi
  if [[ -z "$k" ]]; then
    echo "ENTER"
    return 0
  fi
  echo "$k"
  return 0
}

# menu_loop RENDER_FN HANDLE_FN [main]
# Supports both:
# 1. Direct key presses (e.g. '1', '2', 'q', 'b')
# 2. Arrow keys (Up/Down/Left/Right) & Enter
menu_loop() {
  local render="$1" handle="$2" is_main="${3:-}" input_key
  MENU_STATUS=""
  MENU_DONE=""
  MENU_SELECTED_INDEX=0

  while :; do
    term_clear
    "$render"
    input_key="$(term_read_input)" || app_quit

    # Determine total items on this screen
    local -a current_keys=()
    case "$render" in
      app_main_render) current_keys=(1 2 3 4 5 6 7 8 q) ;;
      contact_render)  current_keys=(1 2 3 4 5 6) ;;
      career_render)   current_keys=(1 2 3) ;;
      *)               current_keys=() ;;
    esac
    local total_items=${#current_keys[@]}

    case "$input_key" in
      UP|LEFT)
        if (( total_items > 0 )); then
          MENU_SELECTED_INDEX=$(( (MENU_SELECTED_INDEX - 1 + total_items) % total_items ))
        fi
        continue
        ;;
      DOWN|RIGHT)
        if (( total_items > 0 )); then
          MENU_SELECTED_INDEX=$(( (MENU_SELECTED_INDEX + 1) % total_items ))
        fi
        continue
        ;;
      ENTER)
        if (( total_items > 0 && MENU_SELECTED_INDEX < total_items )); then
          input_key="${current_keys[$MENU_SELECTED_INDEX]}"
        else
          continue
        fi
        ;;
      ESC)
        [[ -n "$is_main" ]] || return 0
        continue
        ;;
      q|Q)
        app_quit
        ;;
      b|B)
        [[ -n "$is_main" ]] || return 0
        ;;
    esac

    # If it was a direct keypress, update selected index to match
    if (( total_items > 0 )); then
      local idx
      for (( idx = 0; idx < total_items; idx++ )); do
        if [[ "${current_keys[$idx]}" == "$input_key" ]]; then
          MENU_SELECTED_INDEX=$idx
          break
        fi
      done
    fi

    if ! "$handle" "$input_key"; then
      if [[ -n "$is_main" ]]; then
        menu_status hint "Use arrows + Enter, or press keys [1-8], [q] to quit."
      else
        menu_status hint "Use arrows + Enter, [b] to go back, [q] to quit."
      fi
    fi

    [[ -z "$MENU_DONE" ]] || return 0
  done
}
