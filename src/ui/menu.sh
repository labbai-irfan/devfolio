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
MENU_KEYS=()      # keys drawn by the most recent menu_items call, in argument order

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
# Formats into clean, perfectly aligned columns without ANSI width corruption.
menu_items() {
  local n=$# cols=1 rows i j item key label col_gap=6
  local c_accent="${C_ACCENT:-}" c_err="${C_ERR:-}" c_bold="${C_BOLD:-}" c_reset="${C_RESET:-}"
  local c_white="${C_WHITE:-}" c_dim="${C_DIM:-}"

  (( n > 4 )) && layout_has_box && cols=2
  rows=$(( (n + cols - 1) / cols ))
  local -a items=("$@")

  MENU_KEYS=()
  for item in "${items[@]}"; do MENU_KEYS+=("${item%%:*}"); done

  # Find the maximum visible width of items in each column
  local -a col_widths=(0 0)
  for (( j = 0; j < n; j++ )); do
    local c=$(( j / rows ))
    item="${items[$j]}"
    key="${item%%:*}"
    label="${item#*:}"
    # Visible text is: "  [KEY] LABEL" (prefix 2 chars + bracketed key 5 chars + space 1 + label)
    local item_len=$(( 8 + ${#label} ))
    if (( item_len > col_widths[c] )); then
      col_widths[c]=$item_len
    fi
  done

  # Add padding to column 0 so column 1 starts at a consistent, aligned offset
  local col0_target=$(( col_widths[0] + col_gap ))
  (( col0_target < 28 )) && col0_target=28

  printf '\n'
  for (( i = 0; i < rows; i++ )); do
    local line="$LAYOUT_MARGIN  "

    # Column 0 item
    local idx0=$i
    if (( idx0 < n )); then
      item="${items[$idx0]}"
      key="${item%%:*}"
      label="${item#*:}"

      local prefix="  "
      local key_fmt="$c_accent${c_bold}[$key]$c_reset"
      local label_fmt="$label"
      [[ "$key" == "q" ]] && key_fmt="$c_err${c_bold}[$key]$c_reset"

      if (( idx0 == MENU_SELECTED_INDEX )); then
        prefix="${c_accent}❯ ${c_reset}"
        if [[ "$key" == "q" ]]; then
          key_fmt="$c_err${c_bold}[$key]$c_reset"
          label_fmt="$c_err$c_bold$label$c_reset"
        else
          key_fmt="$c_accent${c_bold}[$key]$c_reset"
          label_fmt="$c_white$c_bold$label$c_reset"
        fi
      fi

      # Visible length of column 0 content (without color codes) is: 2 + 1 + ${#key} + 2 + 1 + ${#label}
      local vis_len=$(( 6 + ${#key} + ${#label} ))
      local pad=$(( col0_target - vis_len ))
      (( pad < 2 )) && pad=2

      line="${line}${prefix}${key_fmt} ${label_fmt}$(printf '%*s' "$pad" '')"
    fi

    # Column 1 item (if present)
    if (( cols > 1 )); then
      local idx1=$(( i + rows ))
      if (( idx1 < n )); then
        item="${items[$idx1]}"
        key="${item%%:*}"
        label="${item#*:}"

        local prefix="  "
        local key_fmt="$c_accent${c_bold}[$key]$c_reset"
        local label_fmt="$label"
        [[ "$key" == "q" ]] && key_fmt="$c_err${c_bold}[$key]$c_reset"

        if (( idx1 == MENU_SELECTED_INDEX )); then
          prefix="${c_accent}❯ ${c_reset}"
          if [[ "$key" == "q" ]]; then
            key_fmt="$c_err${c_bold}[$key]$c_reset"
            label_fmt="$c_err$c_bold$label$c_reset"
          else
            key_fmt="$c_accent${c_bold}[$key]$c_reset"
            label_fmt="$c_white$c_bold$label$c_reset"
          fi
        fi

        line="${line}${prefix}${key_fmt} ${label_fmt}"
      fi
    fi

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
    for (( i = start; i < start + page_size && i < total; i++ )); do printf '%s\n' "${lines[$i]}"; done
    layout_separator
    if (( start + page_size < total )); then
      local c_dim="${C_DIM:-}" c_bold="${C_BOLD:-}"
      printf '%s%s[b]%s %sBack%s     %s[q]%s %sQuit%s     %s[Space/Enter]%s %sMore (page %d of %d)%s\n' \
        "$LAYOUT_MARGIN" \
        "$c_accent$c_bold" "$c_reset" "$c_dim" "$c_reset" \
        "${C_ERR:-}$c_bold" "$c_reset" "$c_dim" "$c_reset" \
        "$c_accent$c_bold" "$c_reset" "$c_dim" \
        "$(( start / page_size + 1 ))" "$(( (total + page_size - 1) / page_size ))" "$c_reset"
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

    # menu_items (called by render, just above) filled MENU_KEYS with this screen's actual keys.
    local total_items=${#MENU_KEYS[@]}

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
          input_key="${MENU_KEYS[$MENU_SELECTED_INDEX]}"
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
        if [[ "${MENU_KEYS[$idx]}" == "$input_key" ]]; then
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
