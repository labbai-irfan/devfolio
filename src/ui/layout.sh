# shellcheck shell=bash
# Layout primitives: content width, glyphs, box drawing, headers, separators, word wrap, rows.
# Everything is sized from LAYOUT_WIDTH so all screens share the same edges.

[[ -n "${_LAYOUT_SH:-}" ]] && return 0
_LAYOUT_SH=1

readonly LAYOUT_MARGIN="  "
readonly LAYOUT_MAX_WIDTH=78
readonly LAYOUT_MIN_BOX_WIDTH=60
readonly LAYOUT_COMPACT_HEIGHT=32   # below this many rows the card drops its decorative rows

LAYOUT_WIDTH=76
LAYOUT_COMPACT=0
LAYOUT_HLINE=""      # BOX_H repeated LAYOUT_WIDTH times
LAYOUT_BOX_HLINE=""  # BOX_H repeated LAYOUT_WIDTH - 2 times (between box corners)

# ASCII defaults; layout_init swaps in Unicode when the terminal supports it.
BOX_TL="+" BOX_TR="+" BOX_BL="+" BOX_BR="+" BOX_H="-" BOX_V="|" BOX_ML="+" BOX_MR="+"
ICON_OK="OK" ICON_WARN="!" ICON_ERR="X" ICON_PROMPT=">" ICON_DOT="-"
ICON_BULLET="*" ICON_BAR="|" ICON_STAR="*" ICON_NODE="o" ICON_RULE="|"
QUOTE_OPEN='"' QUOTE_CLOSE='"' KEYS_UPDOWN="up/down" KEYS_ARROWS="arrows" KEYS_LEFTRIGHT="left/right" ICON_ELLIPSIS="..."

layout_init() {
  local w=$(( ${PLATFORM_WIDTH:-80} - ${#LAYOUT_MARGIN} * 2 ))
  (( w > LAYOUT_MAX_WIDTH )) && w=$LAYOUT_MAX_WIDTH
  (( w < 20 )) && w=20
  LAYOUT_WIDTH=$w

  LAYOUT_COMPACT=0
  (( ${PLATFORM_HEIGHT:-40} < LAYOUT_COMPACT_HEIGHT )) && LAYOUT_COMPACT=1

  if [[ "${PLATFORM_UTF8:-0}" == 1 ]]; then
    BOX_TL="╭" BOX_TR="╮" BOX_BL="╰" BOX_BR="╯" BOX_H="─" BOX_V="│" BOX_ML="├" BOX_MR="┤"
    ICON_OK="✔" ICON_WARN="!" ICON_ERR="✖" ICON_PROMPT="❯" ICON_DOT="·"
    ICON_BULLET="●" ICON_BAR="▎" ICON_STAR="★" ICON_NODE="●" ICON_RULE="│"
    QUOTE_OPEN=$'\xe2\x80\x9c' QUOTE_CLOSE=$'\xe2\x80\x9d' KEYS_UPDOWN="↑↓" KEYS_ARROWS="↑↓←→" KEYS_LEFTRIGHT="←→" ICON_ELLIPSIS="…"
  fi

  layout_repeat_v LAYOUT_HLINE "$BOX_H" "$LAYOUT_WIDTH"
  layout_repeat_v LAYOUT_BOX_HLINE "$BOX_H" "$(( LAYOUT_WIDTH - 2 ))"
}

layout_has_box() { (( PLATFORM_WIDTH >= LAYOUT_MIN_BOX_WIDTH )); }

# layout_repeat_v VAR CHAR COUNT — CHAR repeated COUNT times into VAR, without a subshell.
layout_repeat_v() {
  local _s=""
  (( $3 > 0 )) && printf -v _s '%*s' "$3" ''
  printf -v "$1" '%s' "${_s// /$2}"
}

# layout_visible_len VAR TEXT — length of TEXT without ANSI color codes (SGR sequences).
layout_visible_len() {
  local _t="$2" _pre _rest
  while [[ "$_t" == *$'\033['* ]]; do
    _pre="${_t%%$'\033['*}"
    _rest="${_t#*$'\033['}"
    _rest="${_rest#*m}"
    _t="$_pre$_rest"
  done
  printf -v "$1" '%s' "${#_t}"
}

layout_separator() {
  printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "${C_BORDER:-${C_DIM:-}}" "$LAYOUT_HLINE" "${C_RESET:-}"
}

# layout_header TITLE [RIGHT_TEXT]
layout_header() {
  local title="$1" right="${2:-}" pad
  pad=$(( LAYOUT_WIDTH - ${#title} - ${#right} ))
  (( pad < 1 )) && pad=1
  printf '\n%s%s%s%s%*s%s%s%s\n' "$LAYOUT_MARGIN" "${C_BOLD:-}${C_ACCENT:-}" "$title" "${C_RESET:-}" \
    "$pad" '' "${C_MUTED:-${C_DIM:-}}" "$right" "${C_RESET:-}"
  layout_separator
}

# layout_section_title TITLE — "▎ TITLE ─────" heading inside a screen.
layout_section_title() {
  local title="$1" rule pad
  pad=$(( LAYOUT_WIDTH - ${#title} - 3 ))
  (( pad < 3 )) && pad=3
  layout_repeat_v rule "$BOX_H" "$pad"
  printf '%s%s%s %s%s %s%s%s\n' "$LAYOUT_MARGIN" "${C_CYAN:-${C_ACCENT:-}}" "$ICON_BAR" \
    "${C_WHITE:-${C_BOLD:-}}" "$title" "${C_BORDER:-${C_DIM:-}}" "$rule" "${C_RESET:-}"
}

# layout_list LABEL_WIDTH LABEL "a|b|c" [HIGHLIGHT] — a label column and a dot-separated list wrapped
# beside it by whole item. LABEL_WIDTH 0 puts the label on its own line with the list indented below.
# Items found in HIGHLIGHT ("|a|b|") are bold green; without colors they get the ICON_BULLET mark.
layout_list() {
  local lw="$1" label="$2" hl="${4:-}" item c row="" len=0 width prefix mark=""
  local sep=" $ICON_DOT " sc="${C_BORDER:-${C_DIM:-}}" ic="${C_WHITE:-}" hc="${C_GREEN:-${C_OK:-}}${C_BOLD:-}"
  local lc="${C_CYAN:-${C_ACCENT:-}}${C_BOLD:-}" r="${C_RESET:-}"
  local -a items=()
  [[ -z "$r" ]] && mark="$ICON_BULLET"
  layout_split items "$3"

  if (( lw )); then
    printf -v prefix '%s%s%-*s%s' "$LAYOUT_MARGIN" "$lc" "$lw" "$label" "$r"
    width=$(( LAYOUT_WIDTH - lw ))
  else
    printf '%s%s%s%s\n' "$LAYOUT_MARGIN" "$lc" "$label" "$r"
    prefix="$LAYOUT_MARGIN  " width=$(( LAYOUT_WIDTH - 2 ))
  fi

  for item in ${items[@]+"${items[@]}"}; do
    c="$ic"
    if [[ -n "$hl" && "$hl" == *"|$item|"* ]]; then c="$hc"; item="$item$mark"; fi
    if (( len > 0 && len + ${#sep} + ${#item} > width )); then
      printf '%s%s\n' "$prefix" "$row"
      printf -v prefix '%s%*s' "$LAYOUT_MARGIN" "$(( lw ? lw : 2 ))" ''
      row="" len=0
    fi
    if (( len > 0 )); then row="$row$sc$sep$r"; len=$(( len + ${#sep} )); fi
    row="$row$c$item$r"
    len=$(( len + ${#item} ))
  done
  printf '%s%s\n' "$prefix" "$row"
}

# layout_wrap TEXT [INDENT] [REST_INDENT] [COLOR]
# Word-wraps TEXT to the content width. Three-argument form TEXT INDENT COLOR is also accepted
# (the third argument is a color when it is empty or starts with ESC). Indents may contain colors;
# only their visible width counts.
layout_wrap() {
  local text="$1" indent="${2:-}" rest="${3:-${2:-}}" color="${4:-}"
  if (( $# == 3 )) && [[ -z "$3" || "$3" == $'\033'* ]]; then
    color="$3" rest="$indent"
  fi

  local cur="$indent" vis width line="" word
  layout_visible_len vis "$cur"
  width=$(( LAYOUT_WIDTH - vis ))
  local -a words=()
  IFS=' ' read -r -a words <<<"$text"

  for word in ${words[@]+"${words[@]}"}; do
    if [[ -z "$line" ]]; then
      line="$word"
    elif (( ${#line} + 1 + ${#word} > width )); then
      printf '%s%s%s%s%s\n' "$LAYOUT_MARGIN" "$cur" "$color" "$line" "${C_RESET:-}"
      cur="$rest"
      layout_visible_len vis "$cur"
      width=$(( LAYOUT_WIDTH - vis ))
      line="$word"
    else
      line="$line $word"
    fi
  done
  [[ -n "$line" ]] && printf '%s%s%s%s%s\n' "$LAYOUT_MARGIN" "$cur" "$color" "$line" "${C_RESET:-}"
  return 0
}

# layout_kv LABEL VALUE [LABEL_WIDTH] [LABEL_COLOR] [VALUE_COLOR] — value is truncated, never wrapped.
layout_kv() {
  local label="$1" value="$2" lw="${3:-14}" lc="${4:-${C_CYAN:-${C_ACCENT:-}}}" vc="${5:-${C_WHITE:-}}"
  local max=$(( LAYOUT_WIDTH - lw ))
  (( max > 1 && ${#value} > max )) && value="${value:0:$(( max - ${#ICON_ELLIPSIS} ))}$ICON_ELLIPSIS"
  printf '%s%s%-*s%s%s%s%s\n' "$LAYOUT_MARGIN" "$lc" "$lw" "$label" "${C_RESET:-}" "$vc" "$value" "${C_RESET:-}"
}

layout_box_rule() {
  printf '%s%s%s%s%s%s\n' "$LAYOUT_MARGIN" "${C_BORDER:-${C_DIM:-}}" "$1" "$LAYOUT_BOX_HLINE" "$2" "${C_RESET:-}"
}
layout_box_top()       { layout_box_rule "$BOX_TL" "$BOX_TR"; }
layout_box_bottom()    { layout_box_rule "$BOX_BL" "$BOX_BR"; }
layout_box_separator() { layout_box_rule "$BOX_ML" "$BOX_MR"; }

# layout_box_line TEXT [COLOR] — one padded line inside the box; TEXT is truncated if too long.
layout_box_line() {
  local text="$1" color="${2:-}" b="${C_BORDER:-${C_DIM:-}}" r="${C_RESET:-}" inner=$(( LAYOUT_WIDTH - 6 ))
  (( ${#text} > inner )) && text="${text:0:$(( inner - ${#ICON_ELLIPSIS} ))}$ICON_ELLIPSIS"
  printf '%s%s%s%s  %s%s%s%*s  %s%s%s\n' "$LAYOUT_MARGIN" "$b" "$BOX_V" "$r" "$color" "$text" "$r" \
    "$(( inner - ${#text} ))" '' "$b" "$BOX_V" "$r"
}

# layout_box_kv LABEL VALUE [VALUE_COLOR] [LABEL_WIDTH]
layout_box_kv() {
  local label="$1" value="$2" vc="${3:-${C_WHITE:-}}" lw="${4:-13}"
  local b="${C_BORDER:-${C_DIM:-}}" lc="${C_CYAN:-${C_ACCENT:-}}" r="${C_RESET:-}"
  local max=$(( LAYOUT_WIDTH - 6 - lw - 2 ))
  (( ${#value} > max )) && value="${value:0:$(( max - ${#ICON_ELLIPSIS} ))}$ICON_ELLIPSIS"
  printf '%s%s%s%s  %s%-*s%s  %s%s%s%*s  %s%s%s\n' "$LAYOUT_MARGIN" "$b" "$BOX_V" "$r" \
    "$lc" "$lw" "$label" "$r" "$vc" "$value" "$r" "$(( max - ${#value} ))" '' "$b" "$BOX_V" "$r"
}

# layout_split VAR STRING — splits a "|"-joined build value into the array VAR (Bash 3.2: no namerefs).
layout_split() {
  local -a parts=()
  IFS='|' read -r -a parts <<<"$2"
  eval "$1=(\${parts[@]+\"\${parts[@]}\"})"
}

# layout_title_right LEFT RIGHT — bold left text with muted right-aligned text on the same line.
layout_title_right() {
  local left="$1" right="$2" pad
  pad=$(( LAYOUT_WIDTH - ${#left} - ${#right} ))
  if (( pad < 2 )); then
    printf '%s%s%s%s\n%s%s%s%s\n' "$LAYOUT_MARGIN" "${C_BOLD:-}" "$left" "${C_RESET:-}" \
      "$LAYOUT_MARGIN" "${C_MUTED:-${C_DIM:-}}" "$right" "${C_RESET:-}"
  else
    printf '%s%s%s%s%*s%s%s%s\n' "$LAYOUT_MARGIN" "${C_BOLD:-}" "$left" "${C_RESET:-}" \
      "$pad" '' "${C_MUTED:-${C_DIM:-}}" "$right" "${C_RESET:-}"
  fi
}

layout_empty() { printf '%s%sNothing listed yet.%s\n' "$LAYOUT_MARGIN" "${C_MUTED:-${C_DIM:-}}" "${C_RESET:-}"; }

# layout_keys "KEY:Action" ... [RIGHT_TEXT via LAYOUT_KEYS_RIGHT] — the one key-hint footer used by every screen.
layout_keys() {
  local a="${C_ACCENT:-}" m="${C_MUTED:-${C_DIM:-}}" r="${C_RESET:-}" out="" plain="" item k hint
  for item in "$@"; do
    k="${item%%:*}"
    hint="$k ${item#*:}"
    # Wrap onto another line rather than overflow narrow terminals.
    if [[ -n "$plain" ]] && (( ${#plain} + ${#hint} > LAYOUT_WIDTH )); then
      printf '%s%s\n' "$LAYOUT_MARGIN" "$out"
      out="" plain=""
    fi
    out="$out$a$k$r $m${item#*:}$r   "
    plain="$plain$hint   "
  done
  local right="${LAYOUT_KEYS_RIGHT:-}" pad
  pad=$(( LAYOUT_WIDTH - ${#plain} - ${#right} ))
  if [[ -n "$right" ]] && (( pad >= 1 )); then
    printf '%s%s%*s%s%s%s\n' "$LAYOUT_MARGIN" "$out" "$pad" '' "$m" "$right" "$r"
  else
    printf '%s%s\n' "$LAYOUT_MARGIN" "$out"
  fi
}
