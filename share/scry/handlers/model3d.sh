# shellcheck shell=bash disable=SC2154
# 3D models are geometry, not pixels -- render with f3d's headless screenshot
# mode, then hand the PNG to the image viewer.
scry_register model3d "stl 3mf obj ply gltf glb step stp" "f3d render, shown as an image"
scry_helper f3d "stl/3mf/obj/ply/gltf/step" "brew install f3d"

# scry_render_model3d FILE -- render FILE to $SCRY_TMP/model.png. f3d exits
# 0 even on a parse failure, so success means the PNG landed.
scry_render_model3d() {
    scry_require f3d "brew install f3d"
    scry_tmp
    f3d --output="$SCRY_TMP/model.png" --resolution=1000,750 -- "$1" >/dev/null 2>&1 || true
    [ -s "$SCRY_TMP/model.png" ]
}

scry_view_model3d() {
    if ! scry_render_model3d "$1"; then
        echo "scry: f3d failed to render '$1' (is it a valid 3D model?)" >&2
        return 1
    fi
    scry_show_image "$SCRY_TMP/model.png"
}

scry_preview_model3d() {
    if scry_render_model3d "$1"; then
        scry_preview_image_file "$SCRY_TMP/model.png"
    else
        scry_info "$1"
        echo "(f3d could not render this file)"
    fi
}
