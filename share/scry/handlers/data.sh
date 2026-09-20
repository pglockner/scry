# shellcheck shell=bash
scry_register data "csv tsv psv" "visidata (vd)"
scry_helper vd "csv/tsv/psv" "brew install visidata"

scry_view_data() {
    scry_require vd "brew install visidata"
    vd "$1"
}
