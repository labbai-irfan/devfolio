# shellcheck shell=bash
# Section 7 — Resume: download the PDF or open it online.

[[ -n "${_CMD_RESUME_SH:-}" ]] && return 0
_CMD_RESUME_SH=1

cmd_resume() { menu_loop resume_render resume_handle; }

resume_render() {
  local host="" i1 i2
  if [[ -n "$PROFILE_RESUME_PDF" ]]; then
    host="${PROFILE_RESUME_PDF#*://}"
    host="${host%%/*}"
  fi
  contact_item i1 1 "Download PDF" "$PROFILE_RESUME_PDF"
  contact_item i2 2 "Open online" "$PROFILE_RESUME_VIEW"
  layout_header "Resume" "${host:+hosted on $host}"
  MENU_DETAILS=("${PROFILE_RESUME_PDF:+Saves the PDF to your Downloads folder}" "${PROFILE_RESUME_VIEW:+Opens the resume in your browser}")
  menu_items "$i1" "$i2"
  menu_prompt
}

resume_handle() {
  case "$1" in
    1) resume_download ;;
    2) action_open "$PROFILE_RESUME_VIEW" "resume link" ;;
    *) return 1 ;;
  esac
}

resume_download() {
  local path online code=0 shown
  if [[ -z "$PROFILE_RESUME_PDF" ]]; then menu_status warn "No resume PDF available."; return 0; fi
  online="${PROFILE_RESUME_VIEW:-$PROFILE_RESUME_PDF}"

  anim_spin_start "Downloading resume"
  path="$(download_pdf "$PROFILE_RESUME_PDF" "${PROFILE_NAME// /-}-Resume.pdf")" || code=$?
  anim_spin_stop

  case "$code" in
    0)
      shown="${path/#$HOME/~}"
      if [[ "$PLATFORM_OS" == gitbash ]] && command -v cygpath >/dev/null 2>&1; then
        shown="$(cygpath -w "$path")"
      fi
      menu_status ok "Resume saved to $shown" ;;
    1) menu_status warn "curl is not installed, so the PDF cannot be downloaded. Open it online: $online" ;;
    3) menu_status err "The link did not return a PDF. Open it online: $online" ;;
    *) menu_status err "Download failed (offline or link unavailable). Open it online: $online" ;;
  esac
}
