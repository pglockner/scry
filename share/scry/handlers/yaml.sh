# shellcheck shell=bash
scry_register yaml "yaml yml" "bat --language=yaml"

scry_view_yaml() {
    scry_require bat "brew install bat"
    scry_bat_view --language=yaml -- "$1"
}
