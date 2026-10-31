# shellcheck shell=bash
# Layout primitives: content width, box drawing, headers, separators, word wrap, rows.

[[ -n "${_LAYOUT_SH:-}" ]] && return 0
_LAYOUT_SH=1

readonly LAYOUT_MARGIN="  "
readonly LAYOUT_MAX_WIDTH=78
readonly LAYOUT_MIN_BOX_WIDTH=60

LAYOUT_WIDTH=76

BOX_TL="+" BOX_TR="+"
BOX_BL="+" BOX_BR="+"
BOX_H="-" BOX_V="|"
BOX_ML="+" BOX_MR="+"

ICON_OK="OK"
ICON_WARN="!"
ICON_ERR="X"
ICON_PROMPT=">"
ICON_DOT="-"

layout_init() {
  local terminal_width="${PLATFORM_WIDTH:-80}"
  local margin_width=${#LAYOUT_MARGIN}
  local w=$(( terminal_width - margin_width * 2 ))

  (( w > LAYOUT_MAX_WIDTH )) && w=$LAYOUT_MAX_WIDTH
  (( w < 20 )) && w=20

  LAYOUT_WIDTH=$w

  if [[ "${PLATFORM_UTF8:-0}" == 1 ]]; then
    BOX_TL="╭" BOX_TR="╮"
    BOX_BL="╰" BOX_BR="╯"
    BOX_H="─" BOX_V="│"
    BOX_ML="├" BOX_MR="┤"

    ICON_OK="✔"
    ICON_WARN="!"
    ICON_ERR="✖"
    ICON_PROMPT="❯"
    ICON_DOT="·"
  fi
}

layout_has_box() {
  (( PLATFORM_WIDTH >= LAYOUT_MIN_BOX_WIDTH ))
}

# --------------------------------------------------
# Text utilities
# --------------------------------------------------

# Repeat a character.
layout_repeat() {
  local char="$1"
  local count="$2"
  local output=""

  (( count <= 0 )) && return 0

  printf -v output '%*s' "$count" ''
  printf '%s' "${output// /$char}"
}

# --------------------------------------------------
# Standard separators
# --------------------------------------------------

layout_separator() {
  local c_border="${C_BORDER:-${C_DIM:-}}"
  local avail_width=${PLATFORM_WIDTH:-$LAYOUT_WIDTH}
  (( avail_width > 80 )) && avail_width=80
  local w=$(( avail_width - ${#LAYOUT_MARGIN} * 2 ))
  (( w < 20 )) && w=$LAYOUT_WIDTH

  printf '%s%s%s%s\n' \
    "$LAYOUT_MARGIN" \
    "$c_border" \
    "$(layout_repeat "$BOX_H" "$w")" \
    "${C_RESET:-}"
}

# --------------------------------------------------
# Headers & Section Headings
# --------------------------------------------------

layout_header() {
  local title="$1"
  local right="${2:-}"
  local title_len=${#title}
  local right_len=${#right}
  local pad

  pad=$(( LAYOUT_WIDTH - title_len - right_len ))
  (( pad < 1 )) && pad=1

  printf '\n%s%s%s%s%s%*s%s%s%s\n' \
    "$LAYOUT_MARGIN" \
    "${C_BOLD:-}${C_ACCENT:-}" \
    "$title" \
    "${C_RESET:-}" \
    "" \
    "$pad" '' \
    "${C_MUTED:-${C_DIM:-}}" \
    "$right" \
    "${C_RESET:-}"

  layout_separator
}

# Reusable section heading for interior screens (About, Career, Skills, etc.)
layout_section_title() {
  local title="$1"
  local icon="${2:-}"
  local c_cyan="${C_CYAN:-${C_ACCENT:-}}"
  local c_white="${C_WHITE:-${C_BOLD:-}}"
  local c_border="${C_BORDER:-${C_DIM:-}}"
  local c_reset="${C_RESET:-}"

  if [[ -z "$icon" || "$icon" == "◆" ]]; then
    if [[ "${PLATFORM_UTF8:-0}" == 1 ]]; then
      icon="▎"
    else
      icon="|"
    fi
  fi

  local title_len=${#title}
  local icon_len=${#icon}
  # Calculate full terminal width dynamically to span edge-to-edge
  local avail_width=${PLATFORM_WIDTH:-$LAYOUT_WIDTH}
  (( avail_width > 80 )) && avail_width=80
  local pad=$(( avail_width - title_len - icon_len - ${#LAYOUT_MARGIN} - 4 ))
  (( pad < 3 )) && pad=3

  local rule
  rule="$(layout_repeat "$BOX_H" "$pad")"

  printf '\n%s%s%s %s%s %s%s%s\n\n' \
    "$LAYOUT_MARGIN" \
    "$c_cyan" "$icon" \
    "$c_white" "$title" \
    "$c_border" "$rule" \
    "$c_reset"
}

# Reusable technical badge tag list: layout_tag_pills "Git" "Docker" "AWS" ...
layout_tag_pills() {
  local -a tags=("$@")
  local c_cyan="${C_CYAN:-${C_ACCENT:-}}"
  local c_reset="${C_RESET:-}"
  local prefix="$LAYOUT_MARGIN  "
  local line="$prefix"
  local line_len=4
  local t pill pill_len

  for t in "${tags[@]}"; do
    [[ -z "$t" ]] && continue
    pill="${c_cyan}[${c_reset}${t}${c_cyan}]${c_reset} "
    pill_len=$(( ${#t} + 3 ))

    if (( line_len + pill_len > LAYOUT_WIDTH && line_len > 4 )); then
      printf '%s\n' "$line"
      line="${prefix}${pill}"
      line_len=$(( 4 + pill_len ))
    else
      line="${line}${pill}"
      line_len=$(( line_len + pill_len ))
    fi
  done
  [[ -n "$line" && "$line" != "$prefix" ]] && printf '%s\n' "$line"
}

# --------------------------------------------------
# Text wrapping
# --------------------------------------------------

# layout_wrap TEXT [FIRST_INDENT] [REST_INDENT] [COLOR]
# Backward compatible: If 3rd arg starts with ANSI escape or looks like color, treats as: text indent color
layout_wrap() {
  local text="$1"
  local indent="${2:-}"
  local rest_indent="${3:-$indent}"
  local color="${4:-}"
  local line=""
  local word
  local current_indent="$indent"

  # Backward compatibility if only 3 arguments and arg 3 is color
  if [[ $# -eq 3 && "$3" =~ ^(\x1b|\\033|$) ]]; then
    color="$3"
    rest_indent="$indent"
  fi

  local width=$(( LAYOUT_WIDTH - ${#indent} ))
  local -a words=()
  IFS=' ' read -r -a words <<< "$text"

  for word in ${words[@]+"${words[@]}"}; do
    if [[ -z "$line" ]]; then
      line="$word"
    elif (( ${#line} + 1 + ${#word} > width )); then
      printf '%s%s%s%s%s\n' \
        "$LAYOUT_MARGIN" \
        "$current_indent" \
        "$color" \
        "$line" \
        "${C_RESET:-}"

      current_indent="$rest_indent"
      width=$(( LAYOUT_WIDTH - ${#rest_indent} ))
      line="$word"
    else
      line="$line $word"
    fi
  done

  if [[ -n "$line" ]]; then
    printf '%s%s%s%s%s\n' \
      "$LAYOUT_MARGIN" \
      "$current_indent" \
      "$color" \
      "$line" \
      "${C_RESET:-}"
  fi

  return 0
}

# --------------------------------------------------
# Key / value display
# --------------------------------------------------

# layout_kv LABEL VALUE [LABEL_WIDTH] [LABEL_COLOR] [VAL_COLOR]
layout_kv() {
  local label="$1"
  local value="$2"
  local label_width="${3:-14}"
  local l_col="${4:-${C_CYAN:-${C_ACCENT:-}}}"
  local v_col="${5:-${C_WHITE:-}}"
  local max=$(( LAYOUT_WIDTH - label_width ))

  if (( max > 1 )) && (( ${#value} > max )); then
    value="${value:0:$(( max - 1 ))}…"
  fi

  printf '%s%s%-*s%s%s%s%s\n' \
    "$LAYOUT_MARGIN" \
    "$l_col" \
    "$label_width" \
    "$label" \
    "${C_RESET:-}" \
    "$v_col" \
    "$value" \
    "${C_RESET:-}"
}

# --------------------------------------------------
# Box primitives
# --------------------------------------------------

layout_box_top() {
  local c_border="${C_BORDER:-${C_DIM:-}}"
  printf '%s%s%s%s%s%s\n' \
    "$LAYOUT_MARGIN" \
    "$c_border" \
    "$BOX_TL" \
    "$(layout_repeat "$BOX_H" "$(( LAYOUT_WIDTH - 2 ))")" \
    "$BOX_TR" \
    "${C_RESET:-}"
}

layout_box_bottom() {
  local c_border="${C_BORDER:-${C_DIM:-}}"
  printf '%s%s%s%s%s%s\n' \
    "$LAYOUT_MARGIN" \
    "$c_border" \
    "$BOX_BL" \
    "$(layout_repeat "$BOX_H" "$(( LAYOUT_WIDTH - 2 ))")" \
    "$BOX_BR" \
    "${C_RESET:-}"
}

# Full-width section divider.
layout_box_separator() {
  local c_border="${C_BORDER:-${C_DIM:-}}"
  printf '%s%s%s%s%s%s\n' \
    "$LAYOUT_MARGIN" \
    "$c_border" \
    "$BOX_ML" \
    "$(layout_repeat "$BOX_H" "$(( LAYOUT_WIDTH - 2 ))")" \
    "$BOX_MR" \
    "${C_RESET:-}"
}

# --------------------------------------------------
# Box content line
# --------------------------------------------------

# layout_box_line TEXT [COLOR]
layout_box_line() {
  local text="$1"
  local color="${2:-}"
  local c_border="${C_BORDER:-${C_DIM:-}}"
  local inner=$(( LAYOUT_WIDTH - 6 ))
  local len=${#text}
  local pad

  if (( len > inner )); then
    text="${text:0:$(( inner - 1 ))}…"
    len=$inner
  fi

  pad=$(( inner - len ))
  (( pad < 0 )) && pad=0

  printf '%s%s%s%s  %s%s%s%*s  %s%s%s\n' \
    "$LAYOUT_MARGIN" \
    "$c_border" "$BOX_V" "${C_RESET:-}" \
    "$color" "$text" "${C_RESET:-}" \
    "$pad" '' \
    "$c_border" "$BOX_V" "${C_RESET:-}"
}

# --------------------------------------------------
# Box key/value row
# --------------------------------------------------

# layout_box_kv LABEL VALUE [VALUE_COLOR] [LABEL_WIDTH]
layout_box_kv() {
  local label="$1"
  local value="$2"
  local val_color="${3:-${C_WHITE:-}}"
  local label_width="${4:-13}"
  local c_border="${C_BORDER:-${C_DIM:-}}"
  local c_label="${C_CYAN:-${C_ACCENT:-}}"

  local inner=$(( LAYOUT_WIDTH - 6 ))
  local val_max=$(( inner - label_width - 2 ))
  local len=${#value}
  local pad

  if (( len > val_max )); then
    value="${value:0:$(( val_max - 1 ))}…"
    len=$val_max
  fi

  pad=$(( val_max - len ))
  (( pad < 0 )) && pad=0

  printf '%s%s%s%s  %s%-*s%s  %s%s%s%*s  %s%s%s\n' \
    "$LAYOUT_MARGIN" \
    "$c_border" "$BOX_V" "${C_RESET:-}" \
    "$c_label" "$label_width" "$label" "${C_RESET:-}" \
    "$val_color" "$value" "${C_RESET:-}" \
    "$pad" '' \
    "$c_border" "$BOX_V" "${C_RESET:-}"
}

# --------------------------------------------------
# Miscellaneous
# --------------------------------------------------

# layout_split VAR STRING
layout_split() {
  local -a parts=()

  IFS='|' read -r -a parts <<< "$2"

  eval "$1=(\${parts[@]+\"\${parts[@]}\"})"
}

layout_title_right() {
  local left="$1"
  local right="$2"
  local left_len=${#left}
  local right_len=${#right}
  local pad

  pad=$(( LAYOUT_WIDTH - left_len - right_len ))

  if (( pad < 2 )); then
    printf '%s%s%s%s\n%s%s%s%s\n' \
      "$LAYOUT_MARGIN" \
      "${C_BOLD:-}" "$left" "${C_RESET:-}" \
      "$LAYOUT_MARGIN" \
      "${C_MUTED:-${C_DIM:-}}" "$right" "${C_RESET:-}"
  else
    printf '%s%s%s%s%*s%s%s%s\n' \
      "$LAYOUT_MARGIN" \
      "${C_BOLD:-}" "$left" "${C_RESET:-}" \
      "$pad" '' \
      "${C_MUTED:-${C_DIM:-}}" "$right" "${C_RESET:-}"
  fi
}

layout_empty() {
  printf '%s%sNothing listed yet.%s\n' \
    "$LAYOUT_MARGIN" \
    "${C_MUTED:-${C_DIM:-}}" \
    "${C_RESET:-}"
}

# Consistent, predictable navigation footer across every screen
layout_footer() {
  local c_accent="${C_ACCENT:-}"
  local c_dim="${C_DIM:-}"
  local c_bold="${C_BOLD:-}"
  local c_reset="${C_RESET:-}"
  printf '%s%s[b]%s %sBack%s     %s[q]%s %sQuit%s\n' \
    "$LAYOUT_MARGIN" \
    "$c_accent$c_bold" "$c_reset" "$c_dim" "$c_reset" \
    "${C_ERR:-}$c_bold" "$c_reset" "$c_dim" "$c_reset"
}
