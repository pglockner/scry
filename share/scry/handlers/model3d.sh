# shellcheck shell=bash disable=SC2154
# STL/3MF are geometry, not pixels -- render with f3d's headless screenshot
# mode, then hand the PNG to the image viewer.
scry_register model3d "stl 3mf" "f3d render, shown as an image"
scry_helper f3d "stl/3mf" "brew install f3d"

scry_view_model3d() {
    local file="$1" tmpdir preview
    scry_require f3d "brew install f3d"
    tmpdir="$(mktemp -d)"
    preview="$tmpdir/preview.png"
    # f3d exits 0 even on a parse failure, so check the file landed.
    f3d --output="$preview" --resolution=1000,750 -- "$file" >/dev/null 2>&1 || true
    if [ ! -s "$preview" ]; then
        rm -rf "$tmpdir"
        echo "scry: f3d failed to render '$file' (is it a valid STL/3MF?)" >&2
        exit 1
    fi
    scry_show_image "$preview"
    # In -f mode, scry_qlmanage_preview backgrounds the window and returns
    # immediately -- deleting the tmpdir here would race its open, often
    # winning and leaving a generic icon. Leave it for macOS's periodic
    # temp cleanup instead. imgcat/viu render synchronously, so it's safe
    # to clean up right away in the non-window path.
    if [ "$FORCE_WINDOW" != "1" ]; then
        rm -rf "$tmpdir"
    fi
}

# Renders like scry_view_model3d, but always inline at the pane width, and
# cleans up its tmpdir even if fzf kills the preview mid-render.
scry_preview_model3d() {
    local file="$1"
    scry_require f3d "brew install f3d"
    SCRY_3D_TMP="$(mktemp -d)"
    trap 'rm -rf "$SCRY_3D_TMP"' EXIT
    f3d --output="$SCRY_3D_TMP/preview.png" --resolution=1000,750 -- "$file" >/dev/null 2>&1 || true
    if [ ! -s "$SCRY_3D_TMP/preview.png" ]; then
        scry_info "$file"
        echo "(f3d could not render this file)"
        return
    fi
    scry_preview_image_file "$SCRY_3D_TMP/preview.png"
}
