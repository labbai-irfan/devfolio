#!/usr/bin/env bash
# Validates the profile JSON files in src/data/.
# Usage: validate-data.sh [--release] [data-dir]
#   --release  treat leftover <placeholder> values as errors instead of warnings.
set -euo pipefail

release=false
if [[ "${1:-}" == "--release" ]]; then release=true; shift; fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA="${1:-$ROOT/src/data}"
FILES=(profile skills projects experience education certifications)

if ! command -v jq >/dev/null 2>&1; then
  printf 'error: jq is required (https://jqlang.org/download/)\n' >&2
  exit 3
fi

for f in "${FILES[@]}"; do
  if [[ ! -f "$DATA/$f.json" ]]; then
    printf 'error: %s.json is missing in %s\n' "$f" "$DATA" >&2
    exit 1
  fi
  if ! jq empty "$DATA/$f.json"; then
    printf 'error: %s.json is not valid JSON\n' "$f" >&2
    exit 1
  fi
done

read -r -d '' PROGRAM <<'JQ' || true
def ph: type == "string" and test("^<.*>$");
def blank: . == null or . == "";
def err(m): "error: \(m)";
def warn(m): "warn: \(m)";
def req(p; v): if (v | blank) then err("\(p) is required") else empty end;
def url(p; v):
  if (v | blank) or (v | ph) then empty
  elif (v | type == "string" and test("^https://\\S+$")) then empty
  else err("\(p) must be an https:// URL") end;
def date(p; v):
  if (v | blank) or (v | ph) then empty
  elif (v | type == "string" and test("^([0-9]{4}(-(0[1-9]|1[0-2]))?|present)$")) then empty
  else err("\(p) must be YYYY, YYYY-MM or present") end;
def maxlen(p; v; n):
  if (v | type == "string") and (v | length) > n then warn("\(p) is longer than \(n) characters") else empty end;
def arr(f; x): if (x | type) == "array" then empty else err("\(f) must be a JSON array") end;

$profile[0] as $p | $skills[0] as $sk | $projects[0] as $pr
| $experience[0] as $ex | $education[0] as $ed | $certifications[0] as $ce
| ( if ($p | type) != "object" then err("profile.json must be a JSON object") else
      req("profile.json: name"; $p.name),
      req("profile.json: title"; $p.title),
      req("profile.json: tagline"; $p.tagline),
      req("profile.json: location"; $p.location),
      req("profile.json: links.portfolio"; $p.links.portfolio),
      req("profile.json: contact.email"; $p.contact.email),
      req("profile.json: resume.pdf_url"; $p.resume.pdf_url),
      (($p.links // {}) | to_entries[] | url("profile.json: links.\(.key)"; .value)),
      url("profile.json: resume.pdf_url"; $p.resume.pdf_url),
      url("profile.json: resume.view_url"; $p.resume.view_url),
      ( $p.contact.email as $e
        | if ($e | blank) or ($e | ph) or ($e | type == "string" and test("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) then empty
          else err("profile.json: contact.email is not a valid email address") end ),
      ( $p.contact.whatsapp as $w
        | if ($w | blank) or ($w | ph) or ($w | tostring | test("^[0-9]{8,15}$")) then empty
          else err("profile.json: contact.whatsapp must be 8-15 digits (country code + number)") end ),
      maxlen("profile.json: tagline"; $p.tagline; 60)
    end )
, arr("skills.json"; $sk), arr("projects.json"; $pr), arr("experience.json"; $ex)
, arr("education.json"; $ed), arr("certifications.json"; $ce)
, ( ($sk | arrays | to_entries[]) as {key: $i, value: $x}
    | req("skills.json[\($i)].category"; $x.category) )
, ( ($pr | arrays | to_entries[]) as {key: $i, value: $x}
    | req("projects.json[\($i)].name"; $x.name),
      url("projects.json[\($i)].url"; $x.url),
      maxlen("projects.json[\($i)].description"; $x.description; 140) )
, ( ($ex | arrays | to_entries[]) as {key: $i, value: $x}
    | req("experience.json[\($i)].role"; $x.role),
      req("experience.json[\($i)].company"; $x.company),
      req("experience.json[\($i)].start"; $x.start),
      date("experience.json[\($i)].start"; $x.start),
      date("experience.json[\($i)].end"; $x.end) )
, ( ($ed | arrays | to_entries[]) as {key: $i, value: $x}
    | req("education.json[\($i)].degree"; $x.degree),
      req("education.json[\($i)].institution"; $x.institution),
      date("education.json[\($i)].start"; $x.start),
      date("education.json[\($i)].end"; $x.end) )
, ( ($ce | arrays | to_entries[]) as {key: $i, value: $x}
    | req("certifications.json[\($i)].name"; $x.name),
      date("certifications.json[\($i)].date"; $x.date),
      url("certifications.json[\($i)].url"; $x.url) )
, ( ([$p, $sk, $pr, $ex, $ed, $ce] | [.. | select(ph)] | length) as $n
    | if $n == 0 then empty
      elif $release then err("\($n) <placeholder> value(s) remain; replace them before releasing")
      else warn("\($n) <placeholder> value(s) remain; replace them before releasing") end )
JQ

report="$(
  jq -n -r --argjson release "$release" \
    --slurpfile profile "$DATA/profile.json" \
    --slurpfile skills "$DATA/skills.json" \
    --slurpfile projects "$DATA/projects.json" \
    --slurpfile experience "$DATA/experience.json" \
    --slurpfile education "$DATA/education.json" \
    --slurpfile certifications "$DATA/certifications.json" \
    "$PROGRAM" | tr -d '\r'
)"

if [[ -n "$report" ]]; then printf '%s\n' "$report" >&2; fi
if grep -q '^error:' <<<"$report"; then
  printf 'Profile data is invalid.\n' >&2
  exit 1
fi
printf 'Profile data OK.\n'
