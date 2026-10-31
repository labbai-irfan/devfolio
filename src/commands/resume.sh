# shellcheck shell=bash
# Section 7 — Resume: Direct downloads or online view.

[[ -n "${_CMD_RESUME_SH:-}" ]] && return 0
_CMD_RESUME_SH=1

cmd_resume() { menu_loop resume_render resume_handle; }

resume_render() {
  local c_cyan="${C_CYAN:-${C_ACCENT:-}}"
  local c_white="${C_WHITE:-${C_BOLD:-}}"
  local c_muted="${C_MUTED:-${C_DIM:-}}"

  layout_header "Professional Résumé" "Curriculum Vitae"

  layout_section_title "DOCUMENT TELEMETRY"
  layout_wrap "Directly download the official PDF résumé to your local environment or view it in your browser." "  " "$c_white"
  printf '\n'
  [[ -n "$PROFILE_RESUME_PDF" ]] && layout_kv "PDF Source" "$PROFILE_RESUME_PDF" 14 "$c_cyan" "$c_muted"

  layout_section_title "ACTIONS"
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

  anim_spin_start "Downloading official résumé…"
  path="$(download_pdf "$PROFILE_RESUME_PDF" "${PROFILE_NAME// /-}-Resume.pdf")"
  code=$?
  anim_spin_stop

  if (( code == 0 )); then
    menu_status ok "Resume saved to ${path/#$HOME/~}"
  else
    case "$code" in
      1) menu_status warn "curl is not installed, so the PDF cannot be downloaded. Open online: $online" ;;
      3) menu_status err "The resume link did not return a PDF. Open online: $online" ;;
      *) menu_status err "Download failed (offline or link unavailable). Open online: $online" ;;
    esac
  fi
}
