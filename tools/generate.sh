#!/bin/bash
#
# Regenerate the per-flavor screenshots in screenshots/.
#
# Launches a throwaway GUI Emacs per flavor, renders tools/sample.el against
# the theme, and captures just that window.  macOS only (uses screencapture
# and the ns title-bar parameters).  Requires ImageMagick (`magick`) for the
# capture verification.
#
# Usage:
#   tools/generate.sh                 # all flavors, bundled sample
#   tools/generate.sh SAMPLE_FILE     # all flavors, a sample of your choice
#
set -euo pipefail

TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$TOOLS_DIR/.." && pwd)"
SAMPLE="${1:-$TOOLS_DIR/sample.el}"
OUT_DIR="$REPO_DIR/screenshots"
EMACS="${EMACS:-emacs}"

GEOM=/tmp/batppuccin-shot-geom.txt
BG=/tmp/batppuccin-shot-bg.txt
READY=/tmp/batppuccin-shot-ready.txt

mkdir -p "$OUT_DIR"

# Discover the flavors from the theme wrapper files.
variants=()
for f in "$REPO_DIR"/*-theme.el; do
  variants+=("$(basename "$f" -theme.el)")
done

shoot() {
  local theme="$1" out="$2"
  pkill -i emacs 2>/dev/null || true
  sleep 1
  rm -f "$GEOM" "$BG" "$READY"

  SHOT_THEME="$theme" SHOT_THEMEDIR="$REPO_DIR" SHOT_FILE="$SAMPLE" \
    "$EMACS" -Q --eval "(load \"$TOOLS_DIR/screenshot.el\")" >/dev/null 2>&1 &

  local i
  for ((i = 0; i < 40; i++)); do
    [ -f "$READY" ] && break
    sleep 0.25
  done
  if [ ! -f "$READY" ]; then
    echo "ERROR: $theme frame never became ready" >&2
    pkill -i emacs 2>/dev/null || true
    return 1
  fi

  local L T R B W H bg br bgc bb
  read -r L T R B < "$GEOM"
  W=$((R - L)); H=$((B - T))
  bg=$(tr -d ' \n' < "$BG")           # #rrggbb
  br=$((16#${bg:1:2})); bgc=$((16#${bg:3:2})); bb=$((16#${bg:5:2}))

  # Capture, and only accept the shot if the corner pixel matches the theme
  # background -- otherwise we grabbed some other window and should retry.
  local tmp="$out.try.png" attempt px pr pg pb d
  for ((attempt = 1; attempt <= 15; attempt++)); do
    screencapture -x -R "$L,$T,$W,$H" "$tmp" 2>/dev/null || true
    px=$(magick "$tmp" -crop 1x1+24+420 +repage -depth 8 \
         -format '%[fx:int(255*r)] %[fx:int(255*g)] %[fx:int(255*b)]' info: 2>/dev/null || true)
    read -r pr pg pb <<<"$px"
    if [ -n "${pr:-}" ]; then
      d=$(((pr - br) * (pr - br) + (pg - bgc) * (pg - bgc) + (pb - bb) * (pb - bb)))
      if [ "$d" -le 60 ]; then
        magick "$tmp" -strip "$out"
        rm -f "$tmp"
        pkill -i emacs 2>/dev/null || true
        echo "  $theme -> $(basename "$out")"
        return 0
      fi
    fi
    sleep 0.5
  done

  rm -f "$tmp"
  pkill -i emacs 2>/dev/null || true
  echo "ERROR: $theme never matched theme background $bg" >&2
  return 1
}

echo "Sample: $SAMPLE"
for v in "${variants[@]}"; do
  shoot "$v" "$OUT_DIR/$v.png"
done
echo "Done. Wrote ${#variants[@]} screenshots to $OUT_DIR/"
