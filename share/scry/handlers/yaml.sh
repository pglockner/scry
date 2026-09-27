# shellcheck shell=bash
scry_register yaml "yaml yml" "bat --language=yaml"

scry_view_yaml() {
    scry_require "$SCRY_BAT" "$SCRY_INSTALL bat"
    scry_bat_view --language=yaml -- "$1"
}

# scry_bat_view already adapts to preview mode, so it's the same call.
scry_preview_yaml() {
    scry_view_yaml "$1"
}
