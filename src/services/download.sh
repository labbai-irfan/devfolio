# shellcheck shell=bash
# Downloads a PDF with curl. Prints the saved path on success.
# Returns 0 saved, 1 curl missing, 2 download failed (offline / HTTP error / timeout), 3 response was not a PDF.

[[ -n "${_DOWNLOAD_SH:-}" ]] && return 0
_DOWNLOAD_SH=1

# download_pdf URL FILENAME
download_pdf() {
  local url="$1" name="$2" dir tmp dest base n=1
  validate_has_command curl || return 1
  [[ "${LABBAI_OFFLINE:-}" == 1 ]] && return 2

  # Save to ~/Downloads when it exists, otherwise the current directory.
  dir="$PWD"
  [[ -d "$HOME/Downloads" ]] && dir="$HOME/Downloads"

  tmp="$(mktemp)" || return 2
  if ! curl -fsSL --retry 2 --max-time 30 -o "$tmp" "$url" 2>/dev/null; then
    rm -f "$tmp"
    return 2
  fi
  if [[ "$(head -c 4 "$tmp" 2>/dev/null)" != "%PDF" ]]; then
    rm -f "$tmp"
    return 3
  fi

  # Never overwrite: resume.pdf → resume-1.pdf → resume-2.pdf …
  base="${name%.pdf}"
  dest="$dir/$base.pdf"
  while [[ -e "$dest" ]]; do dest="$dir/$base-$n.pdf"; n=$(( n + 1 )); done

  mv "$tmp" "$dest" || { rm -f "$tmp"; return 2; }
  printf '%s' "$dest"
}
