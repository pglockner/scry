# The README's demo. Regenerate it from the repo root with: vhs demo/demo.tape
# (brew install vhs). It runs the scry in this checkout on demo/files/.

Output demo/demo.gif

Require glow
Require viu
Require f3d
Require vd
Require bat
Require fzf

Set Shell bash
Set FontSize 15
Set Width 1100
Set Height 680
Set Padding 18
Set LineHeight 1.0
Set Theme "Catppuccin Mocha"
Set TypingSpeed 45ms

Hide
Type "cd demo/files && unset NO_COLOR && export PATH=$PWD/../../bin:$PATH PS1='$ ' COLORTERM=truecolor GLAMOUR_STYLE=dark && clear"
Enter
Sleep 500ms
Show

Type "scry notes.md"
Sleep 400ms
Enter
Sleep 3.5s
Ctrl+L

Type "scry crystal.png"
Sleep 400ms
Enter
Sleep 3s
Ctrl+L

Type "scry knot.stl"
Sleep 400ms
Enter
Sleep 3.5s
Ctrl+L

Type "scry planets.csv"
Sleep 400ms
Enter
Sleep 1.5s
Down
Sleep 300ms
Down
Sleep 300ms
Right
Sleep 300ms
Right
Sleep 1.5s
Type "q"
Sleep 300ms
Ctrl+L

Type "scry oracle.py"
Sleep 400ms
Enter
Sleep 3s
Ctrl+L

Type "scry --fzf"
Sleep 400ms
Enter
Sleep 2s
Down
Sleep 3.5s
Down
Sleep 2s
Down
Sleep 2s
Down
Sleep 2.5s
Escape
Sleep 500ms
