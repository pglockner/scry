# shellcheck shell=bash
scry_register document "rtf doc docx odt" "$SCRY_DOC_DESC"

scry_view_document() {
    scry_doc_to_text "$1"
}

scry_preview_document() {
    scry_doc_to_text "$1" | head -n 200
}
