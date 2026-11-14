#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
GODOT_BIN=${GODOT_BIN:-godot}
if [ ! -f .export_templates/web_nothreads_release.zip ]; then
    python3 tools/fetch_web_template.py
fi
mkdir -p build/web
"$GODOT_BIN" --headless --editor --import --quit
"$GODOT_BIN" --headless --export-release Web build/web/index.html
cp assets/cover/kingdoms-cover.webp build/web/cover.webp
cp assets/ui/combat/guard.svg build/web/favicon.svg
cp assets/audio/sources/CREDITS.md build/web/AUDIO-CREDITS.md
python3 tools/package_web.py
