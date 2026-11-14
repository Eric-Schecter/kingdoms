#!/bin/zsh
cd "${0:A:h}"
if [[ -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then
  exec /Applications/Godot.app/Contents/MacOS/Godot --path "$PWD"
elif command -v godot >/dev/null 2>&1; then
  exec godot --path "$PWD"
else
  print '请先安装 Godot 4，再用 Godot 打开 project.godot。'
  read -k 1
fi
