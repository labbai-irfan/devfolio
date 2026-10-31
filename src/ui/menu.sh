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

MENU_COLS=2
MENU_GRID_ROWS=4
MENU_TOTAL_ITEMS=0

# menu_items "KEY:Label" ...
# Renders 4 items in Column 1, 4 items in Column 2, and [q] Quit centered below.
menu_items() {
  local -a items=("$@")
  local n=${#items[@]}
  local col_gap=8
  local c_accent="${C_ACCENT:-}" c_err="${C_ERR:-}" c_bold="${C_BOLD:-}" c_reset="${C_RESET:-}"
  local c_white="${C_WHITE:-}" c_dim="${C_DIM:-}"

  MENU_KEYS=()
  for item in "${items[@]}"; do MENU_KEYS+=("${item%%:*}"); done
  MENU_TOTAL_ITEMS=$n

  # Check if last item is 'q' (Quit)
  local has_quit=0
  if (( n > 0 && n % 2 != 0 )) && [[ "${items[$(( n - 1 ))]%%:*}" == "q" ]]; then
    has_quit=1
  fi

  local grid_items=$n
  [[ "$has_quit" == 1 ]] && grid_items=$(( n - 1 ))

  local rows=$(( (grid_items + 1) / 2 ))
  (( rows < 1 )) && rows=1
  MENU_GRID_ROWS=$rows
  MENU_COLS=2

  # Calculate column width
  local col0_max=0 col1_max=0 j
  for (( j = 0; j < rows; j++ )); do
    local l0="${items[$j]#*:}"
    local len0=$(( 6 + ${#l0} ))
    (( len0 > col0_max )) && col0_max=$len0
  done
  for (( j = rows; j < grid_items; j++ )); do
    local l1="${items[$j]#*:}"
    local len1=$(( 6 + ${#l1} ))
    (( len1 > col1_max )) && col1_max=$len1
  done

  local col0_width=$(( col0_max + col_gap ))
  (( col0_width < 26 )) && col0_width=26

  printf '\n'

  # Render 4x4 Grid
  local r
  for (( r = 0; r < rows; r++ )); do
    local line="$LAYOUT_MARGIN  "

    # Col 0 (left)
    local idx0=$r
    if (( idx0 < grid_items )); then
      local it0="${items[$idx0]}"
      local k0="${it0%%:*}"
      local lbl0="${it0#*:}"
      local pfx0="  "
      local kfmt0="$c_accent${c_bold}[$k0]$c_reset"
      local lfmt0="$lbl0"

      if (( idx0 == MENU_SELECTED_INDEX )); then
        pfx0="${c_accent}❯ ${c_reset}"
        kfmt0="$c_accent${c_bold}[$k0]$c_reset"
        lfmt0="$c_white$c_bold$lbl0$c_reset"
      fi

      # Calculate pure visible length of label (stripping ANSI color codes)
      local clean_lbl0
      clean_lbl0="$(printf '%s' "$lbl0" | sed 's/\x1b\[[0-9;]*m//g')"
      local vis_len=$(( 6 + ${#k0} + ${#clean_lbl0} ))
      local pad=$(( col0_width - vis_len ))
      (( pad < 4 )) && pad=4

      line="${line}${pfx0}${kfmt0} ${lfmt0}$(printf '%*s' "$pad" '')"
    fi

    # Col 1 (right)
    local idx1=$(( r + rows ))
    if (( idx1 < grid_items )); then
      local it1="${items[$idx1]}"
      local k1="${it1%%:*}"
      local lbl1="${it1#*:}"
      local pfx1="  "
      local kfmt1="$c_accent${c_bold}[$k1]$c_reset"
      local lfmt1="$lbl1"

      if (( idx1 == MENU_SELECTED_INDEX )); then
        pfx1="${c_accent}❯ ${c_reset}"
        kfmt1="$c_accent${c_bold}[$k1]$c_reset"
        lfmt1="$c_white$c_bold$lbl1$c_reset"
      fi

      line="${line}${pfx1}${kfmt1} ${lfmt1}"
    fi

    printf '%s\n' "$line"
  done

  # Render Quit item centered below the grid
  if [[ "$has_quit" == 1 ]]; then
    local q_idx=$(( n - 1 ))
    local it_q="${items[$q_idx]}"
    local kq="${it_q%%:*}"
    local lblq="${it_q#*:}"
    local pfxq="  "
    local kfmtq="$c_err${c_bold}[$kq]$c_reset"
    local lfmtq="$c_dim$lblq$c_reset"

    if (( q_idx == MENU_SELECTED_INDEX )); then
      pfxq="${c_err}❯ ${c_reset}"
      kfmtq="$c_err${c_bold}[$kq]$c_reset"
      lfmtq="$c_err$c_bold$lblq$c_reset"
    fi

    # Clean centered or left-aligned divider row for Quit
    printf '\n%s  %s%s %s\n' "$LAYOUT_MARGIN" "$pfxq" "$kfmtq" "$lfmtq"
  fi
}

menu_prompt() {
  local c_accent="${C_ACCENT:-}" c_dim="${C_DIM:-${C_MUTED:-}}" c_bold="${C_BOLD:-}" c_reset="${C_RESET:-}"
  local prompt_sym="❯"
  [[ "${PLATFORM_UTF8:-0}" != 1 ]] && prompt_sym=">"

  local prompt_text="Use ↑/↓/←/→ to navigate · Enter to select"
  local badge="${c_accent}npx $APP_NAME${c_reset} ${c_dim}· v$APP_VERSION${c_reset}"
  local plain_prompt="> Use ↑/↓/←/→ to navigate · Enter to select"
  local plain_badge="npx $APP_NAME · v$APP_VERSION"

  local pad=$(( LAYOUT_WIDTH - ${#plain_prompt} - ${#plain_badge} - 2 ))
  (( pad < 2 )) && pad=2

  # Subtle muted prompt: small cyan chevron, dimmed guide text, clean version badge
  printf '\n%s  %s%s%s %s%s%s%*s%s\n' \
    "$LAYOUT_MARGIN" \
    "$c_accent" "$prompt_sym" "$c_reset" \
    "$c_dim" "$prompt_text" "$c_reset" \
    "$pad" '' \
    "$badge"

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

  local first_render=1
  local should_teleprompt=0
  if [[ "${CFG_ANIMATE:-1}" == 1 && "${LABBAI_REDUCED_MOTION:-0}" != 1 && "${PLATFORM_TTY:-0}" == 1 ]]; then
    should_teleprompt=1
  fi

  while :; do
    term_clear
    layout_header "$title" "$right"
    for (( i = start; i < start + page_size && i < total; i++ )); do
      printf '%s\n' "${lines[$i]}"
      if [[ "$first_render" == 1 && "$should_teleprompt" == 1 ]]; then
        sleep 0.015
      fi
    done
    first_render=0
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

# read_raw_key reads a single key or parses escape sequences for arrows (CSI and SS3)
term_read_input() {
  local k rest
  IFS= read -rsn1 k || return 1
  if [[ "$k" == $'\033' ]]; then
    read -rsn2 -t 0.05 rest || true
    case "$rest" in
      '[A'|'OA') echo "UP" ;;
      '[B'|'OB') echo "DOWN" ;;
      '[C'|'OC') echo "RIGHT" ;;
      '[D'|'OD') echo "LEFT" ;;
      *)         echo "ESC" ;;
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
  local first_draw=1

  while :; do
    if [[ "$first_draw" == 1 ]]; then
      term_clear
      first_draw=0
    else
      # Instant in-place repositioning without wiping the buffer, zero flicker
      printf '\033[H'
    fi
    "$render"
    # Clear any residual lines below content
    printf '\033[J'
    input_key="$(term_read_input)" || app_quit

    # menu_items (called by render, just above) filled MENU_KEYS with this screen's actual keys.
    local total_items=${#MENU_KEYS[@]}

    case "$input_key" in
      UP)
        if (( total_items > 0 )); then
          local q_idx=$(( total_items - 1 ))
          local rows=${MENU_GRID_ROWS:-4}
          if (( rows == 1 )); then
            # 1-row layout: navigate back
            if (( MENU_SELECTED_INDEX > 0 )); then
              MENU_SELECTED_INDEX=$(( MENU_SELECTED_INDEX - 1 ))
            else
              MENU_SELECTED_INDEX=$(( total_items - 1 ))
            fi
          elif (( MENU_SELECTED_INDEX == q_idx )); then
            # From Quit, go to last item of left column (idx rows - 1)
            MENU_SELECTED_INDEX=$(( rows - 1 ))
          else
            local col=$(( MENU_SELECTED_INDEX / rows ))
            local row=$(( MENU_SELECTED_INDEX % rows ))
            if (( row > 0 )); then
              MENU_SELECTED_INDEX=$(( MENU_SELECTED_INDEX - 1 ))
            else
              # At top of column: jump to Quit
              MENU_SELECTED_INDEX=$q_idx
            fi
          fi
        fi
        continue
        ;;
      DOWN)
        if (( total_items > 0 )); then
          local q_idx=$(( total_items - 1 ))
          local rows=${MENU_GRID_ROWS:-4}
          if (( rows == 1 )); then
            # 1-row layout: navigate forward
            if (( MENU_SELECTED_INDEX + 1 < total_items )); then
              MENU_SELECTED_INDEX=$(( MENU_SELECTED_INDEX + 1 ))
            else
              MENU_SELECTED_INDEX=0
            fi
          elif (( MENU_SELECTED_INDEX == q_idx )); then
            # From Quit, go to top left (0)
            MENU_SELECTED_INDEX=0
          else
            local col=$(( MENU_SELECTED_INDEX / rows ))
            local row=$(( MENU_SELECTED_INDEX % rows ))
            if (( row < rows - 1 && MENU_SELECTED_INDEX + 1 < q_idx )); then
              MENU_SELECTED_INDEX=$(( MENU_SELECTED_INDEX + 1 ))
            else
              # At bottom of column: jump to Quit
              MENU_SELECTED_INDEX=$q_idx
            fi
          fi
        fi
        continue
        ;;
      LEFT)
        if (( total_items > 0 )); then
          local q_idx=$(( total_items - 1 ))
          local rows=${MENU_GRID_ROWS:-4}
          if (( rows == 1 )); then
            # 1-row horizontal layout: navigate left
            if (( MENU_SELECTED_INDEX > 0 )); then
              MENU_SELECTED_INDEX=$(( MENU_SELECTED_INDEX - 1 ))
            else
              MENU_SELECTED_INDEX=$(( total_items - 1 ))
            fi
          elif (( MENU_SELECTED_INDEX == q_idx )); then
            # From Quit, jump up to left column bottom
            MENU_SELECTED_INDEX=$(( rows - 1 ))
          elif (( MENU_SELECTED_INDEX >= rows && MENU_SELECTED_INDEX < q_idx )); then
            # In column 1, jump directly left to column 0 on the same row
            MENU_SELECTED_INDEX=$(( MENU_SELECTED_INDEX - rows ))
          fi
        fi
        continue
        ;;
      RIGHT)
        if (( total_items > 0 )); then
          local q_idx=$(( total_items - 1 ))
          local rows=${MENU_GRID_ROWS:-4}
          if (( rows == 1 )); then
            # 1-row horizontal layout: navigate right (e.g. 0 -> 1)
            if (( MENU_SELECTED_INDEX + 1 < total_items )); then
              MENU_SELECTED_INDEX=$(( MENU_SELECTED_INDEX + 1 ))
            else
              MENU_SELECTED_INDEX=0
            fi
          elif (( MENU_SELECTED_INDEX == q_idx )); then
            # From Quit, jump up to right column bottom
            local target_r=$(( rows * 2 - 1 ))
            (( target_r >= q_idx )) && target_r=$(( q_idx - 1 ))
            MENU_SELECTED_INDEX=$target_r
          elif (( MENU_SELECTED_INDEX < rows )); then
            # In column 0 (0..rows-1), jump directly right to column 1 on the same row
            local target_c1=$(( MENU_SELECTED_INDEX + rows ))
            if (( target_c1 <= q_idx - 1 )); then
              MENU_SELECTED_INDEX=$target_c1
            fi
          fi
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
