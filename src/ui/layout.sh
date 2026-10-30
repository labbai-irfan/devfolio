# shellcheck shell=bash
# Layout primitives: content width, box drawing, headers, separators, word wrap, rows.
# Box content is padded from plain-text length, so colors are applied per line, never mixed inside padding.

[[ -n "${_LAYOUT_SH:-}" ]] && return 0
_LAYOUT_SH=1

readonly LAYOUT_MARGIN="  "
readonly LAYOUT_MAX_WIDTH=68
readonly LAYOUT_MIN_BOX_WIDTH=60

LAYOUT_WIDTH=68
BOX_TL="+" BOX_TR="+" BOX_BL="+" BOX_BR="+" BOX_H="-" BOX_V="|"
ICON_OK="OK" ICON_WARN="!" ICON_ERR="X" ICON_PROMPT=">" ICON_DOT="-"

layout_init() {
  local w=$(( PLATFORM_WIDTH - ${#LAYOUT_MARGIN} * 2 ))
  (( w > LAYOUT_MAX_WIDTH )) && w=$LAYOUT_MAX_WIDTH
  (( w < 20 )) && w=20
  LAYOUT_WIDTH=$w

  if [[ "$PLATFORM_UTF8" == 1 ]]; then
    BOX_TL="╭" BOX_TR="╮" BOX_BL="╰" BOX_BR="╯" BOX_H="─" BOX_V="│"
    ICON_OK="✔" ICON_WARN="!" ICON_ERR="✖" ICON_PROMPT="›" ICON_DOT="·"
  fi
}

layout_has_box() { (( PLATFORM_WIDTH >= LAYOUT_MIN_BOX_WIDTH )); }

# layout_repeat CHAR COUNT
layout_repeat() {
  local s
  printf -v s '%*s' "$2" ''
  printf '%s' "${s// /$1}"
}

# layout_header TITLE [RIGHT_TEXT]
layout_header() {
  local title="$1" right="${2:-}" pad
  pad=$(( LAYOUT_WIDTH - ${#title} - ${#right} ))
  (( pad < 1 )) && pad=1
  printf '\n%s%s%s%s%s%*s%s%s%s\n' "$LAYOUT_MARGIN" "$C_BOLD" "$C_ACCENT" "$title" "$C_RESET" "$pad" '' "$C_DIM" "$right" "$C_RESET"
  layout_separator
}

layout_separator() {
  printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "$C_DIM" "$(layout_repeat "$BOX_H" "$LAYOUT_WIDTH")" "$C_RESET"
}

# layout_wrap TEXT [INDENT] — word-wraps TEXT to the content width, prefixing each line with the margin and INDENT.
layout_wrap() {
  local text="$1" indent="${2:-}" line="" word
  local width=$(( LAYOUT_WIDTH - ${#indent} ))
  local -a words
  IFS=' ' read -r -a words <<<"$text"
  for word in ${words[@]+"${words[@]}"}; do
    if [[ -z "$line" ]]; then
      line="$word"
    elif (( ${#line} + 1 + ${#word} > width )); then
      printf '%s%s%s\n' "$LAYOUT_MARGIN" "$indent" "$line"
      line="$word"
    else
      line="$line $word"
    fi
  done
  [[ -n "$line" ]] && printf '%s%s%s\n' "$LAYOUT_MARGIN" "$indent" "$line"
  return 0
}

# layout_kv LABEL VALUE [LABEL_WIDTH] — dim label column followed by the value.
layout_kv() {
  local label="$1" value="$2" lw="${3:-12}"
  printf '%s%s%-*s%s%s\n' "$LAYOUT_MARGIN" "$C_DIM" "$lw" "$label" "$C_RESET" "$value"
}

layout_box_top()    { printf '%s%s%s%s%s%s\n' "$LAYOUT_MARGIN" "$C_DIM" "$BOX_TL" "$(layout_repeat "$BOX_H" $(( LAYOUT_WIDTH - 2 )))" "$BOX_TR" "$C_RESET"; }
layout_box_bottom() { printf '%s%s%s%s%s%s\n' "$LAYOUT_MARGIN" "$C_DIM" "$BOX_BL" "$(layout_repeat "$BOX_H" $(( LAYOUT_WIDTH - 2 )))" "$BOX_BR" "$C_RESET"; }

# layout_box_line TEXT [COLOR] — one padded line inside the box; TEXT is truncated if too long.
layout_box_line() {
  local text="$1" color="${2:-}" inner=$(( LAYOUT_WIDTH - 6 )) pad
  (( ${#text} > inner )) && text="${text:0:$(( inner - 1 ))}…"
  pad=$(( inner - ${#text} ))
  printf '%s%s%s%s   %s%s%s%*s %s%s%s\n' "$LAYOUT_MARGIN" "$C_DIM" "$BOX_V" "$C_RESET" "$color" "$text" "$C_RESET" "$pad" '' "$C_DIM" "$BOX_V" "$C_RESET"
}

# layout_box_kv LABEL VALUE — dim label (11 cols) + value inside the box.
layout_box_kv() {
  local label="$1" value="$2" inner=$(( LAYOUT_WIDTH - 6 )) pad
  printf -v label '%-11s' "$label"
  (( ${#label} + ${#value} > inner )) && value="${value:0:$(( inner - ${#label} - 1 ))}…"
  pad=$(( inner - ${#label} - ${#value} ))
  printf '%s%s%s%s   %s%s%s%s%*s %s%s%s\n' "$LAYOUT_MARGIN" "$C_DIM" "$BOX_V" "$C_RESET" "$C_DIM" "$label" "$C_RESET" "$value" "$pad" '' "$C_DIM" "$BOX_V" "$C_RESET"
}

# layout_split VAR STRING — splits a "|"-joined build value into the array VAR (Bash 3.2: no namerefs, so eval).
layout_split() {
  local -a parts=()
  IFS='|' read -r -a parts <<<"$2"
  eval "$1=(\${parts[@]+\"\${parts[@]}\"})"
}

# layout_title_right LEFT RIGHT — bold left text with dim right-aligned text on the same line.
layout_title_right() {
  local left="$1" right="$2" pad
  pad=$(( LAYOUT_WIDTH - ${#left} - ${#right} ))
  if (( pad < 2 )); then
    printf '%s%s%s%s\n%s%s%s%s\n' "$LAYOUT_MARGIN" "$C_BOLD" "$left" "$C_RESET" "$LAYOUT_MARGIN" "$C_DIM" "$right" "$C_RESET"
  else
    printf '%s%s%s%s%*s%s%s%s\n' "$LAYOUT_MARGIN" "$C_BOLD" "$left" "$C_RESET" "$pad" '' "$C_DIM" "$right" "$C_RESET"
  fi
}

layout_empty() { printf '%s%sNothing listed yet.%s\n' "$LAYOUT_MARGIN" "$C_DIM" "$C_RESET"; }

layout_footer() {
  printf '%s%sb%s  Back     %sq%s  Quit\n' "$LAYOUT_MARGIN" "$C_ACCENT" "$C_RESET" "$C_ACCENT" "$C_RESET"
}
