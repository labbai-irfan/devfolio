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
  printf '%s%s%s%s\n' \
    "$LAYOUT_MARGIN" \
    "${C_DIM:-}" \
    "$(layout_repeat "$BOX_H" "$LAYOUT_WIDTH")" \
    "${C_RESET:-}"
}

# --------------------------------------------------
# Headers
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
    "${C_DIM:-}" \
    "$right" \
    "${C_RESET:-}"

  layout_separator
}

# --------------------------------------------------
# Text wrapping
# --------------------------------------------------

# layout_wrap TEXT [INDENT] [COLOR]
layout_wrap() {
  local text="$1"
  local indent="${2:-}"
  local color="${3:-}"
  local line=""
  local word

  local width=$(( LAYOUT_WIDTH - ${#indent} ))
  local -a words=()
  IFS=' ' read -r -a words <<< "$text"

  for word in ${words[@]+"${words[@]}"}; do
    if [[ -z "$line" ]]; then
      line="$word"
    elif (( ${#line} + 1 + ${#word} > width )); then
      printf '%s%s%s%s%s\n' \
        "$LAYOUT_MARGIN" \
        "$indent" \
        "$color" \
        "$line" \
        "${C_RESET:-}"

      line="$word"
    else
      line="$line $word"
    fi
  done

  if [[ -n "$line" ]]; then
    printf '%s%s%s%s%s\n' \
      "$LAYOUT_MARGIN" \
      "$indent" \
      "$color" \
      "$line" \
      "${C_RESET:-}"
  fi

  return 0
}

# --------------------------------------------------
# Key / value display
# --------------------------------------------------

# layout_kv LABEL VALUE [LABEL_WIDTH]
layout_kv() {
  local label="$1"
  local value="$2"
  local label_width="${3:-12}"

  printf '%s%s%-*s%s%s\n' \
    "$LAYOUT_MARGIN" \
    "${C_DIM:-}" \
    "$label_width" \
    "$label" \
    "${C_RESET:-}" \
    "$value"
}

# --------------------------------------------------
# Box primitives
# --------------------------------------------------

layout_box_top() {
  printf '%s%s%s%s%s%s\n' \
    "$LAYOUT_MARGIN" \
    "${C_DIM:-}" \
    "$BOX_TL" \
    "$(layout_repeat "$BOX_H" "$(( LAYOUT_WIDTH - 2 ))")" \
    "$BOX_TR" \
    "${C_RESET:-}"
}

layout_box_bottom() {
  printf '%s%s%s%s%s%s\n' \
    "$LAYOUT_MARGIN" \
    "${C_DIM:-}" \
    "$BOX_BL" \
    "$(layout_repeat "$BOX_H" "$(( LAYOUT_WIDTH - 2 ))")" \
    "$BOX_BR" \
    "${C_RESET:-}"
}

# Full-width section divider.
layout_box_separator() {
  printf '%s%s%s%s%s%s\n' \
    "$LAYOUT_MARGIN" \
    "${C_DIM:-}" \
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
    "${C_DIM:-}" "$BOX_V" "${C_RESET:-}" \
    "$color" "$text" "${C_RESET:-}" \
    "$pad" '' \
    "${C_DIM:-}" "$BOX_V" "${C_RESET:-}"
}

# --------------------------------------------------
# Box key/value row
# --------------------------------------------------

# layout_box_kv LABEL VALUE [VALUE_COLOR]
layout_box_kv() {
  local label="$1"
  local value="$2"
  local val_color="${3:-${C_WHITE:-}}"

  local inner=$(( LAYOUT_WIDTH - 6 ))
  local label_width=13
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
    "${C_DIM:-}" "$BOX_V" "${C_RESET:-}" \
    "${C_ACCENT:-}" "$label_width" "$label" "${C_RESET:-}" \
    "$val_color" "$value" "${C_RESET:-}" \
    "$pad" '' \
    "${C_DIM:-}" "$BOX_V" "${C_RESET:-}"
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
      "${C_DIM:-}" "$right" "${C_RESET:-}"
  else
    printf '%s%s%s%s%*s%s%s%s\n' \
      "$LAYOUT_MARGIN" \
      "${C_BOLD:-}" "$left" "${C_RESET:-}" \
      "$pad" '' \
      "${C_DIM:-}" "$right" "${C_RESET:-}"
  fi
}

layout_empty() {
  printf '%s%sNothing listed yet.%s\n' \
    "$LAYOUT_MARGIN" \
    "${C_DIM:-}" \
    "${C_RESET:-}"
}

layout_footer() {
  printf '%s%sb%s  Back     %sq%s  Quit\n' \
    "$LAYOUT_MARGIN" \
    "${C_ACCENT:-}" "${C_RESET:-}" \
    "${C_ACCENT:-}" "${C_RESET:-}"
}
