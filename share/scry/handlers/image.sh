# shellcheck shell=bash
scry_register image "png jpg jpeg gif bmp tiff tif webp heic ico" \
    "imgcat in iTerm2, viu elsewhere (-f: Quick Look window)"
scry_helper viu "images (non-iTerm2 terminals)" "brew install viu"
if [ "${TERM_PROGRAM:-}" = "iTerm.app" ]; then
    scry_helper imgcat "sharper inline images in iTerm2" \
        "iTerm2 > Install Shell Integration"
fi

scry_view_image() {
    scry_show_image "$1"
}
