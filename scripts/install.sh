#!/bin/bash
# Builds a release SLUJ.app and copies it into /Applications, replacing any
# previous copy. Quit SLUJ first so the old copy isn't running.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/make-app.sh" release

BIN_DIR="$(cd "$ROOT" && swift build -c release --show-bin-path)"
rm -rf /Applications/SLUJ.app
ditto "$BIN_DIR/SLUJ.app" /Applications/SLUJ.app

echo "Installed /Applications/SLUJ.app"
