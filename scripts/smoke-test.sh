#!/usr/bin/env bash
# shellcheck disable=SC2015  # "check && pass || fail" is safe: pass only prints, so it never falls through to fail.
# Smoke tests for the built CLI: static output at several widths and modes, the flags, and a scripted
# walk through every interactive screen (offline). Run after `npm run build`.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT/bin/labbai-irfan"
failed=0

pass() { printf 'ok    %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1" >&2; failed=1; }

# --plain output is ASCII-only, so byte length is display width.
for w in 30 40 60 80 120; do
  out="$(COLUMNS=$w bash "$CLI" --card --plain)"
  max="$(awk '{ if (length($0) > m) m = length($0) } END { print m + 0 }' <<<"$out")"
  if (( max <= w )); then pass "card fits $w columns (widest line $max)"; else fail "card is $max wide at $w columns"; fi
  if LC_ALL=C grep -q '[^ -~]' <<<"$out"; then fail "--plain card has non-ASCII at $w columns"; else pass "--plain card is ASCII at $w columns"; fi
done

if NO_COLOR=1 bash "$CLI" --card | grep -q $'\033'; then fail "NO_COLOR output has escape codes"; else pass "NO_COLOR output has no escape codes"; fi
grep -q "Labbai Irfan" <<<"$(bash "$CLI" --card --plain)" && pass "card shows the name" || fail "card is missing the name"

if command -v node >/dev/null 2>&1; then
  if bash "$CLI" --json | node -e 'JSON.parse(require("fs").readFileSync(0, "utf8"))'; then pass "--json is valid JSON"; else fail "--json is not valid JSON"; fi
fi
[[ "$(bash "$CLI" --version)" == "labbai-irfan "* ]] && pass "--version" || fail "--version"
code=0; bash "$CLI" --no-such-flag 2>/dev/null || code=$?
(( code == 2 )) && pass "unknown flag exits 2" || fail "unknown flag exited $code"

# Interactive walk: every screen, then quit. Keys are piped all at once.
keys='1b2b31bfab41b4bb5b6b7b8bq'
err="$(mktemp)"
out="$(printf '%s' "$keys" | LABBAI_OFFLINE=1 bash "$CLI" --interactive --plain --no-animation 2>"$err")" && code=0 || code=$?
if (( code == 0 )) && [[ ! -s "$err" ]]; then pass "interactive walk through every screen"; else fail "interactive walk (exit $code): $(cat "$err")"; fi
grep -q "Thanks for your time" <<<"$out" && pass "goodbye message on quit" || fail "no goodbye message"

# Mouse wheel must not move the selection: wheel events, then Enter, must open item 1 (About).
out="$(printf '\033[<65;5;5M\033[<65;5;5M\033[<64;5;5M\nbq' | LABBAI_OFFLINE=1 bash "$CLI" --interactive --plain --no-animation 2>"$err")"
grep -q "CURRENT FOCUS" <<<"$out" && pass "mouse wheel leaves the selection alone" || fail "mouse wheel moved the selection"

# Arrows clamp at the top instead of wrapping to Quit.
out="$(printf '\033[A\033[A\033[A\nbq' | LABBAI_OFFLINE=1 bash "$CLI" --interactive --plain --no-animation 2>"$err")"
grep -q "CURRENT FOCUS" <<<"$out" && pass "up arrow at the top does not wrap to Quit" || fail "up arrow wrapped"
rm -f "$err"

if (( failed )); then printf 'smoke-test: FAILED\n' >&2; exit 1; fi
printf 'smoke-test: OK\n'
