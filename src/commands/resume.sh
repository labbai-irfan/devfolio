# shellcheck shell=bash
# Section 7 — Resume submenu: download the PDF or open it online.

[[ -n "${_CMD_RESUME_SH:-}" ]] && return 0
_CMD_RESUME_SH=1

cmd_resume() { menu_loop resume_render resume_handle; }

resume_render() {
  layout_header "Resume"
  menu_items \
    "$(contact_item 1 "Download PDF" "$PROFILE_RESUME_PDF")" \
    "$(contact_item 2 "Open online" "$PROFILE_RESUME_VIEW")"
  menu_prompt
  layout_footer
}

resume_handle() {
  case "$1" in
    1) resume_download ;;
    2) action_open "$PROFILE_RESUME_VIEW" "resume link" ;;
    *) return 1 ;;
  esac
}

resume_download() {
  local path online code
  if [[ -z "$PROFILE_RESUME_PDF" ]]; then menu_status warn "No resume PDF available."; return 0; fi
  online="${PROFILE_RESUME_VIEW:-$PROFILE_RESUME_PDF}"

  anim_spin_start "Downloading résumé…"
  path="$(download_pdf "$PROFILE_RESUME_PDF" "${PROFILE_NAME// /-}-Resume.pdf")"
  code=$?
  anim_spin_stop

  if (( code == 0 )); then
    menu_status ok "Resume saved to ${path/#$HOME/~}"
  else
    case "$code" in
      1) menu_status warn "curl is not installed, so the PDF cannot be downloaded. Open it online instead: $online" ;;
      3) menu_status err "The resume link did not return a PDF. Open it online instead: $online" ;;
      *) menu_status err "Download failed (offline or link unavailable). Open it online instead: $online" ;;
    esac
  fi
}
