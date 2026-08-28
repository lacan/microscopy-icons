#!/bin/bash
# svg2png.sh - rasterise icon SVGs to transparent PNGs.
#
#   tools/svg2png.sh [SIZE] SRC_DIR DEST_DIR
#   e.g. tools/svg2png.sh 364 NC_SVG NC_PNG
#
# Uses headless Edge (or Chrome), so no Inkscape, ImageMagick or Python is needed.
#
# Two traps this works around:
#  * Opening a .svg directly leaves the browser's default 8px body margin, which
#    shifts the image and crops it. Each file is wrapped in a margin-less page.
#  * Every Illustrator-exported icon in this pack declares the same .cls-1,
#    .cls-2 ... class names. Rendering several in one document lets them bleed
#    into each other and silently recolours them, so each file gets its own page.
set -u
SIZE=364
case "${1:-}" in ''|*[!0-9]*) ;; *) SIZE=$1; shift ;; esac
SRC=${1:?usage: svg2png.sh [SIZE] SRC_DIR DEST_DIR}
DEST=${2:?usage: svg2png.sh [SIZE] SRC_DIR DEST_DIR}

BROWSER=
for c in "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" \
         "/c/Program Files/Microsoft/Edge/Application/msedge.exe" \
         "/c/Program Files/Google/Chrome/Application/chrome.exe" \
         "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"; do
  [ -x "$c" ] && { BROWSER=$c; break; }
done
[ -n "$BROWSER" ] || { echo "no Edge/Chrome found" >&2; exit 1; }

mkdir -p "$DEST"; n=0; fail=0
for svg in "$SRC"/*.svg; do
  [ -e "$svg" ] || continue
  name=$(basename "$svg" .svg); out="$DEST/$name.png"; d=$(mktemp -d)
  { printf '<!doctype html><meta charset="utf-8"><style>html,body{margin:0;padding:0;background:transparent;overflow:hidden}svg{display:block;width:%spx;height:%spx}</style>\n' "$SIZE" "$SIZE"
    awk '{gsub(/<\?xml[^>]*>/,""); print}' "$svg"
  } > "$d/p.html"
  "$BROWSER" --headless=new --disable-gpu --no-first-run --no-default-browser-check \
    --user-data-dir="$(cygpath -m "$d/ud")" --force-device-scale-factor=1 --hide-scrollbars \
    --default-background-color=00000000 --window-size=$SIZE,$SIZE \
    --screenshot="$(cygpath -m "$d/s.png")" "file:///$(cygpath -m "$d/p.html")" >/dev/null 2>&1
  if [ -s "$d/s.png" ]; then cp "$d/s.png" "$out"; n=$((n+1)); echo "  $name.png"
  else echo "  FAILED: $name" >&2; fail=$((fail+1)); fi
  rm -rf "$d"
done
echo "$n written to $DEST/${SIZE}px${fail:+, $fail failed}"
