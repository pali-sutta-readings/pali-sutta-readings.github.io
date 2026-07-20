#!/usr/bin/env bash
#
# Watch a Pāli reading .org file and live-render it to a styled PDF.
#
# Usage:
#   ./scripts/org_to_pdf_watch.sh ./sessions/2026-07-22.org
#
# On every save it:
#   1. converts the .org file to Typst with pandoc (src-typst/<name>.typ),
#      applying the gloss template in src-typst/gloss-template.typ,
#   2. lets a background `typst watch` process rebuild the PDF, and
#   3. opens the PDF in evince (once) — evince reloads it automatically.
#
# Ctrl+C stops both this watcher and the background `typst watch` process.
# The evince viewer is left open.
#
# Requires: pandoc, typst, evince, inotifywait (inotify-tools).

set -euo pipefail

# --- Resolve paths --------------------------------------------------------

if [ $# -lt 1 ]; then
    echo "Usage: $0 <session.org>" >&2
    exit 1
fi

ORG="$1"
if [ ! -f "$ORG" ]; then
    echo "Error: file not found: $ORG" >&2
    exit 1
fi

# Run relative to the project root (the directory containing this script's ..).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

ORG_DIR="$(cd "$(dirname "$ORG")" && pwd)"
ORG_BASE="$(basename "$ORG")"
ORG_PATH="$ORG_DIR/$ORG_BASE"
NAME="${ORG_BASE%.org}"

SRC_TYPST_DIR="$ROOT_DIR/src-typst"
TEMPLATE="$SRC_TYPST_DIR/gloss-template.typ"
FONT_PATH="$ROOT_DIR/docs/assets/fonts"
TYP="$SRC_TYPST_DIR/$NAME.typ"
PDF="$SRC_TYPST_DIR/$NAME.pdf"

mkdir -p "$SRC_TYPST_DIR"

# --- Conversion -----------------------------------------------------------

# org -> typst, then patch pandoc's output to match the print stylesheet:
#   * unwrap tables from pandoc's #figure(align(...)[#table]) so they are bare
#     #table() elements (figures can't break across pages)
#   * gloss tables are 2-column: headword (auto) + gloss (fills width)
#   * the org "&ast;" entity is a literal asterisk (reconstructed forms)
convert() {
    pandoc -f org -t typst --template "$TEMPLATE" "$ORG_PATH" -o "$TYP"
    perl -0pi -e '
        s/#figure\(\s*\n\s*align\([a-z]+\)\[#table\(/#table(/g;
        s/\)\]\s*\n\s*,\s*kind:\s*table\s*\n\s*\)/)/g;
        s/columns: 2,/columns: (auto, 1fr),/g;
        s/&ast;/\\*/g;
    ' "$TYP"
    echo "[$(date +%H:%M:%S)] converted $ORG_BASE -> $(basename "$TYP")"
}

# --- Cleanup on exit ------------------------------------------------------

TYPST_PID=""
cleanup() {
    if [ -n "$TYPST_PID" ] && kill -0 "$TYPST_PID" 2>/dev/null; then
        kill "$TYPST_PID" 2>/dev/null || true
        wait "$TYPST_PID" 2>/dev/null || true
    fi
    echo
    echo "Stopped."
}
trap cleanup EXIT INT TERM

# --- Initial build --------------------------------------------------------

convert

# Start the Typst watcher, which rebuilds the PDF whenever the .typ changes.
typst watch --font-path "$FONT_PATH" --root "$ROOT_DIR" "$TYP" "$PDF" &
TYPST_PID=$!

# Wait for the first PDF, then open evince if it isn't already showing this file.
for _ in $(seq 1 50); do
    [ -f "$PDF" ] && break
    sleep 0.1
done

if [ -f "$PDF" ] && ! pgrep -f "evince .*$PDF" >/dev/null 2>&1; then
    # Detach so Ctrl+C on this script doesn't close the viewer.
    setsid evince "$PDF" >/dev/null 2>&1 &
fi

# --- Watch loop -----------------------------------------------------------

echo "Watching $ORG_PATH  (Ctrl+C to stop)"

# Watch the containing directory so atomic saves (write-to-temp + rename,
# as Emacs and many editors do) are still picked up.
inotifywait -m -e close_write -e moved_to --format '%f' "$ORG_DIR" \
    | while read -r changed; do
        if [ "$changed" = "$ORG_BASE" ]; then
            convert
        fi
    done
