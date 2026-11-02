# shellcheck shell=bash
# Screens: menu_loop (selectable menu) and section_view (scrollable read-only page).
# Frames are rendered into a buffer and written in one go, so repaints never flicker.

[[ -n "${_MENU_SH:-}" ]] && return 0
_MENU_SH=1

MENU_STATUS=""          # one-line feedback, shown until the next key press
MENU_DONE=""            # a handler sets this to leave the current menu_loop
MENU_IS_MAIN=""
MENU_SELECTED_INDEX=0
MENU_KEYS=()            # keys drawn by the most recent menu_items call, in argument order
MENU_ROWS=1 MENU_COLS=1 MENU_GRID_N=0 MENU_HAS_QUIT=0
SCREEN_BUF=""           # temp file frames are rendered into (set by app_run in interactive mode)

# menu_status LEVEL TEXT — LEVEL is ok | warn | err | hint
menu_status() {
  local r="${C_RESET:-}"
  case "$1" in
    ok)   MENU_STATUS="${C_OK:-}$ICON_OK$r $2" ;;
    warn) MENU_STATUS="${C_WARN:-}$ICON_WARN$r $2" ;;
    err)  MENU_STATUS="${C_ERR:-}$ICON_ERR$r $2" ;;
    *)    MENU_STATUS="${C_MUTED:-${C_DIM:-}}$2$r" ;;
  esac
}

# screen_paint FN [ARGS...] — renders FN into the buffer, then writes the frame at once,
# erasing the rest of every line and everything below it.
screen_paint() {
  local frame=""
  if [[ -z "$SCREEN_BUF" || "${PLATFORM_TTY:-0}" != 1 ]]; then "$@"; return 0; fi
  "$@" >"$SCREEN_BUF"
  IFS= read -r -d '' frame <"$SCREEN_BUF" || true
  printf '\033[H%s\033[J' "${frame//$'\n'/$'\033[K\n'}"
}

# screen_refresh_size — re-reads the terminal size after a resize and recomputes the layout.
screen_refresh_size() {
  PLATFORM_WIDTH="$(term_width)"
  PLATFORM_HEIGHT="$(term_height)"
  layout_init
}

MENU_DETAILS=()  # optional per-item detail (same order as the items); the selected one shows under the grid

# menu_items "KEY:Label" ... — every menu uses the same two-column grid (one column only when it would
# not fit). A trailing "q:Quit" sits on its own row below. Labels ending in " (n/a)" are dimmed.
# If the render set MENU_DETAILS, the selected item's detail is shown on one line under the grid.
menu_items() {
  local -a items=("$@") w=()
  local n=$# grid=$# i k lbl cell line pad w0=0 w1=0 rows cols=1
  local a="${C_ACCENT:-}" b="${C_BOLD:-}" r="${C_RESET:-}" m="${C_MUTED:-${C_DIM:-}}" hi="${C_WHITE:-}"

  MENU_KEYS=()
  for i in "${items[@]}"; do MENU_KEYS+=("${i%%:*}"); done
  MENU_HAS_QUIT=0
  if (( n > 1 )) && [[ "${MENU_KEYS[n-1]}" == q ]]; then MENU_HAS_QUIT=1; grid=$(( n - 1 )); fi
  (( MENU_SELECTED_INDEX < n )) || MENU_SELECTED_INDEX=0

  # Visible cell width: "❯ " + "[k]" + " " + label.
  for (( i = 0; i < grid; i++ )); do w[i]=$(( ${#items[i]} + 4 )); done
  rows=$grid
  if (( grid >= 2 )); then
    rows=$(( (grid + 1) / 2 ))
    for (( i = 0; i < grid; i++ )); do
      if (( i < rows )); then (( w[i] > w0 )) && w0=${w[i]}; else (( w[i] > w1 )) && w1=${w[i]}; fi
    done
    (( w0 + 4 + w1 <= LAYOUT_WIDTH - 2 )) && cols=2
    (( cols == 2 )) || rows=$grid
  fi
  MENU_ROWS=$rows MENU_COLS=$cols MENU_GRID_N=$grid
  (( n > 0 )) || return 0

  printf '\n'
  local row col
  for (( row = 0; row < rows; row++ )); do
    line="$LAYOUT_MARGIN  "
    for (( col = 0; col < cols; col++ )); do
      i=$(( col * rows + row ))
      (( i < grid )) || continue
      menu_cell cell "$i" "${items[i]}" "$a"
      line="$line$cell"
      if (( col == 0 && cols == 2 )); then
        pad=$(( w0 + 4 - w[i] ))
        printf -v line '%s%*s' "$line" "$pad" ''
      fi
    done
    printf '%s\n' "$line"
  done

  if (( ${#MENU_DETAILS[@]} > 0 )); then
    local detail="${MENU_DETAILS[MENU_SELECTED_INDEX]:-}" dw=$(( LAYOUT_WIDTH - 4 ))
    (( ${#detail} > dw )) && detail="${detail:0:$(( dw - ${#ICON_ELLIPSIS} ))}$ICON_ELLIPSIS"
    # Always one line (blank when the item has no detail), so the screen height never jumps.
    printf '\n%s    %s%s%s\n' "$LAYOUT_MARGIN" "$m" "$detail" "$r"
    MENU_DETAILS=()
  fi

  if (( MENU_HAS_QUIT )); then
    menu_cell cell "$grid" "${items[grid]}" "${C_ERR:-}"
    printf '\n%s  %s\n' "$LAYOUT_MARGIN" "$cell"
  fi
  return 0
}

# menu_cell VAR INDEX "KEY:Label" KEY_COLOR — one rendered menu entry.
menu_cell() {
  local key="${3%%:*}" lbl="${3#*:}" kc="$4" b="${C_BOLD:-}" r="${C_RESET:-}" lc="${C_WHITE:-}" pre="  "
  [[ "$lbl" == *" (n/a)" || "$key" == q ]] && lc="${C_MUTED:-${C_DIM:-}}"
  # Line = margin + 2 + "❯ " + "[k] " + label; truncate the label rather than overflow.
  local max=$(( LAYOUT_WIDTH - 2 - 2 - ${#key} - 3 ))
  (( ${#lbl} > max && max > ${#ICON_ELLIPSIS} )) && lbl="${lbl:0:$(( max - ${#ICON_ELLIPSIS} ))}$ICON_ELLIPSIS"
  if (( $2 == MENU_SELECTED_INDEX )); then
    pre="$kc$ICON_PROMPT$r "
    lc="$lc$b"
  fi
  printf -v "$1" '%s%s[%s]%s %s%s%s' "$pre" "$kc$b" "$key" "$r" "$lc" "$lbl" "$r"
}

# menu_prompt — key hints for the current menu, the version badge on the main menu, then the status line.
MENU_HINTS=()   # extra "KEY:Action" hints a render can set for the next menu_prompt (e.g. prev/next)

menu_prompt() {
  local -a keys=()
  (( ${#MENU_KEYS[@]} > 1 )) && keys+=("$KEYS_ARROWS:move")
  (( ${#MENU_KEYS[@]} > 0 )) && keys+=("enter:select")
  keys+=(${MENU_HINTS[@]+"${MENU_HINTS[@]}"})
  [[ -n "$MENU_IS_MAIN" ]] || keys+=("b:back")
  keys+=("q:quit")
  MENU_HINTS=()
  LAYOUT_KEYS_RIGHT=""
  [[ -n "$MENU_IS_MAIN" ]] && LAYOUT_KEYS_RIGHT="npx $APP_NAME v$APP_VERSION"
  printf '\n'
  layout_separator
  layout_keys "${keys[@]}"
  LAYOUT_KEYS_RIGHT=""
  printf '%s%s\n' "$LAYOUT_MARGIN" "$MENU_STATUS"
}

# menu_move UP|DOWN|LEFT|RIGHT — moves the selection inside the grid. Never wraps; Quit is only
# reached by moving down from a bottom row (or by pressing q).
menu_move() {
  local i=$MENU_SELECTED_INDEX rows=$MENU_ROWS n=$MENU_GRID_N quit=-1
  (( n > 0 && rows > 0 )) || return 0
  (( MENU_HAS_QUIT )) && quit=$n
  if (( i == quit )); then
    if [[ "$1" == UP ]]; then i=$(( rows - 1 )); fi
  else
    local row=$(( i % rows )) col=$(( i / rows ))
    case "$1" in
      # Up/down follow reading order: across to the next column, then to Quit below the grid.
      UP)    (( i > 0 )) && i=$(( i - 1 )) ;;
      DOWN)  if (( row < rows - 1 && i + 1 < n )); then i=$(( i + 1 ))
             elif (( quit >= 0 )); then i=$quit
             elif (( i + 1 < n )); then i=$(( i + 1 )); fi ;;
      LEFT)  (( col > 0 )) && i=$(( i - rows )) ;;
      RIGHT) (( col < MENU_COLS - 1 && i + rows < n )) && i=$(( i + rows )) ;;
    esac
  fi
  MENU_SELECTED_INDEX=$i
}

# menu_loop RENDER_FN HANDLE_FN [main]
#   RENDER_FN draws the screen (calling menu_items + menu_prompt). HANDLE_FN gets the chosen key and
#   returns 0 if it handled it. b/Esc go back (ignored on the main menu), q quits, EOF quits.
#   The caller's selection, status and main-menu flag are restored on return.
menu_loop() {
  # dirty: 0 = up to date, 1 = selection moved (frame may be skipped while keys are queued),
  # 2 = must paint (first frame, after a handler or resize — painting is what sets MENU_KEYS).
  local render="$1" handle="$2" key prev dirty=2
  local saved_main="$MENU_IS_MAIN" saved_sel="$MENU_SELECTED_INDEX" saved_status="$MENU_STATUS"
  MENU_IS_MAIN="${3:-}" MENU_STATUS="" MENU_DONE="" MENU_SELECTED_INDEX=0

  while :; do
    if (( dirty == 2 )) || { (( dirty == 1 )) && ! term_input_pending; }; then
      screen_paint "$render"
      dirty=0
    fi
    key="$(term_read_input)" || app_quit

    case "$key" in
      IGNORE|WHEEL_UP|WHEEL_DOWN|PGUP|PGDN|HOME|END) continue ;;
      RESIZE) screen_refresh_size; dirty=2; continue ;;
      UP|DOWN|LEFT|RIGHT)
        prev=$MENU_SELECTED_INDEX
        menu_move "$key"
        if (( prev != MENU_SELECTED_INDEX )); then
          (( dirty == 2 )) || dirty=1
        # Left/right the grid can't use go to the screen (e.g. previous/next project). No hint if unused.
        elif [[ "$key" == LEFT || "$key" == RIGHT ]] && "$handle" "$key"; then
          MENU_STATUS="" dirty=2
        fi
        continue ;;
      ENTER) key="${MENU_KEYS[MENU_SELECTED_INDEX]:-}" ;;
      ESC|b|B)
        [[ -n "$MENU_IS_MAIN" ]] && continue
        break ;;
      q|Q) app_quit ;;
    esac

    MENU_STATUS=""
    for (( prev = 0; prev < ${#MENU_KEYS[@]}; prev++ )); do
      [[ "${MENU_KEYS[prev]}" == "$key" ]] && MENU_SELECTED_INDEX=$prev
    done
    "$handle" "$key" || menu_status hint "Press one of the keys shown on screen."
    dirty=2
    [[ -z "$MENU_DONE" ]] || break
  done

  MENU_IS_MAIN="$saved_main" MENU_SELECTED_INDEX="$saved_sel" MENU_STATUS="$saved_status" MENU_DONE=""
  return 0
}

# section_view TITLE BODY_FN [RIGHT_TEXT] — read-only page. Arrows/wheel scroll by line, Space/PgDn
# by page, Home/End jump, b/Esc go back, q quits.
section_view() {
  local title="$1" body_fn="$2" right="${3:-}" key line start=0 prev total=0 page max collect=1 dirty=2
  local -a lines=()

  while :; do
    if (( collect )); then
      lines=()
      while IFS= read -r line; do lines+=("$line"); done < <("$body_fn")
      total=${#lines[@]}
      page=$(( ${PLATFORM_HEIGHT:-24} - 7 ))
      (( page < 5 )) && page=5
      max=$(( total > page ? total - page : 0 ))
      (( start > max )) && start=$max
      collect=0
    fi
    if (( dirty == 2 )) || { (( dirty == 1 )) && ! term_input_pending; }; then
      screen_paint section_frame "$title" "$right"
      dirty=0
    fi
    key="$(term_read_input)" || app_quit

    prev=$start
    case "$key" in
      q|Q) app_quit ;;
      b|B|ESC|LEFT) return 0 ;;
      RESIZE) screen_refresh_size; collect=1; dirty=2; continue ;;
      UP)         start=$(( start - 1 )) ;;
      DOWN)       start=$(( start + 1 )) ;;
      WHEEL_UP)   start=$(( start - 3 )) ;;
      WHEEL_DOWN) start=$(( start + 3 )) ;;
      PGUP)       start=$(( start - page )) ;;
      PGDN|ENTER|' ') start=$(( start + page )) ;;
      HOME)       start=0 ;;
      END)        start=$max ;;
    esac
    (( start > max )) && start=$max
    (( start < 0 )) && start=0
    (( start == prev )) || dirty=1
  done
}

# section_frame TITLE RIGHT — one frame of section_view (reads its lines/start/page/total).
# shellcheck disable=SC2154
section_frame() {
  local i end=$(( start + page ))
  layout_header "$1" "$2"
  printf '\n'
  for (( i = start; i < end && i < total; i++ )); do printf '%s\n' "${lines[i]}"; done
  printf '\n'
  layout_separator
  if (( total > page )); then
    LAYOUT_KEYS_RIGHT="$(( start + 1 ))-$(( i ))/$total"
    layout_keys "$KEYS_UPDOWN:scroll" "space:page" "b:back" "q:quit"
    LAYOUT_KEYS_RIGHT=""
  else
    layout_keys "b:back" "q:quit"
  fi
}
