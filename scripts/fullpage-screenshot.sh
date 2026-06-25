#!/usr/bin/env bash
#
# fullpage-screenshot.sh — Full-page screenshot via SuperDuck by scrolling + stitching.
#
# SuperDuck's `screenshot` only captures the viewport. This script scrolls the
# page in viewport-sized increments, captures each, and stitches them vertically
# with ImageMagick into a single full-page image.
#
# Usage:
#   bash scripts/fullpage-screenshot.sh <tab_id> <width> <output_path> [viewport_height]
#
# Arguments:
#   tab_id          SuperDuck tab ID (from `superduck tab_group new`)
#   width           Target viewport width in px (e.g. 1440 desktop, 390 mobile)
#   output_path     Final stitched image path (extension may be rewritten to .jpg)
#   viewport_height Viewport height in px (default 900; use 844 for mobile)
#
# Requires:
#   - superduck CLI (npm install -g superduck-cli && superduck setup)
#   - ImageMagick (`convert` — brew install imagemagick / apt install imagemagick)
#
# Examples:
#   bash scripts/fullpage-screenshot.sh "$TAB" 1440 docs/design-references/site-desktop.png
#   bash scripts/fullpage-screenshot.sh "$TAB" 390 docs/design-references/site-mobile.png 844
#
# Known limitation: sticky/fixed elements (e.g. a header that stays pinned) will
# appear in every viewport capture, so they repeat in the stitched output. This
# is inherent to scroll-and-stitch. For section-accurate references, capture
# individual sections with `superduck zoom` instead.

set -euo pipefail

TAB="${1:?Usage: $0 <tab_id> <width> <output_path> [viewport_height]}"
WIDTH="${2:?missing width}"
OUTPUT="${3:?missing output_path}"
VH="${4:-900}"

command -v convert >/dev/null 2>&1 || { echo "Error: ImageMagick 'convert' not found. Install: brew install imagemagick" >&2; exit 1; }
command -v superduck >/dev/null 2>&1 || { echo "Error: superduck CLI not found. Install: npm install -g superduck-cli" >&2; exit 1; }

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

strip_tc() { awk '/^Tab Context:/{exit} {print}'; }

superduck --tab "$TAB" resize "$WIDTH" "$VH" >/dev/null
sleep 1

TOTAL_HEIGHT=$(superduck --tab "$TAB" exec 'document.documentElement.scrollHeight' | strip_tc | tr -dc '0-9')
[ -n "$TOTAL_HEIGHT" ] && [ "$TOTAL_HEIGHT" -gt 0 ] || { echo "Error: could not read page height (got '$TOTAL_HEIGHT'). Is the tab on a real https:// page?" >&2; exit 1; }

superduck --tab "$TAB" exec 'window.scrollTo(0, 0)' >/dev/null
sleep 0.5

NUM_SHOTS=$(( (TOTAL_HEIGHT + VH - 1) / VH ))
echo "Capturing $NUM_SHOTS viewport shots for ${WIDTH}x${VH} (page height: ${TOTAL_HEIGHT}px)" >&2

for i in $(seq 0 $((NUM_SHOTS - 1))); do
  OFFSET=$((i * VH))
  superduck --tab "$TAB" exec "window.scrollTo(0, ${OFFSET})" >/dev/null
  sleep 0.8
  superduck --tab "$TAB" screenshot --output "${TMPDIR}/fp_${i}.jpg" >/dev/null
  echo "  shot $((i + 1))/$NUM_SHOTS @ offset ${OFFSET}" >&2
done

echo "Stitching ${NUM_SHOTS} images vertically..." >&2
convert "${TMPDIR}"/fp_*.jpg -append "${TMPDIR}/stitched.jpg"

if [ "$TOTAL_HEIGHT" -ne $((NUM_SHOTS * VH)) ]; then
  convert "${TMPDIR}/stitched.jpg" -crop "${WIDTH}x${TOTAL_HEIGHT}+0+0" +repage "$OUTPUT"
else
  cp "${TMPDIR}/stitched.jpg" "$OUTPUT"
fi

echo "Done: $OUTPUT (${WIDTH}x${TOTAL_HEIGHT})" >&2
