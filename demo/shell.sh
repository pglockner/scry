#!/bin/bash
# The demo's shell: a clean bash 3.2 running the scry in this checkout, with
# a bare prompt. demo/record.sh starts Ghostty with this as its command.
cd "$(dirname "$0")/files" || exit 1
unset NO_COLOR
export PATH="$PWD/../../bin:$PATH" COLORTERM=truecolor GLAMOUR_STYLE=dark PS1='$ '
export BASH_SILENCE_DEPRECATION_WARNING=1
clear
exec /bin/bash --noprofile --norc -i
