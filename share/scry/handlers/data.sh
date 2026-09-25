# shellcheck shell=bash
scry_register data "csv tsv psv" "visidata (vd)"
scry_helper vd "csv/tsv/psv" "$SCRY_INSTALL visidata"

scry_view_data() {
    scry_require vd "$SCRY_INSTALL visidata"
    vd "$1"
}

# First rows as aligned columns, cut to the pane width. Splits on the raw
# delimiter, so quoted commas in a CSV will misalign; fine for a glance.
scry_preview_data() {
    local file="$1" sep="," w
    case "$file" in
        *.[tT][sS][vV]) sep=$'\t' ;;
        *.[pP][sS][vV]) sep="|" ;;
    esac
    w="$(scry_term_width)"
    if [ -n "$w" ]; then
        head -n 30 < "$file" | column -t -s "$sep" | cut -c "1-$w"
    else
        head -n 30 < "$file" | column -t -s "$sep"
    fi
}
