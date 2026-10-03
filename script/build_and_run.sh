#!/bin/bash
# Local native-app development loop. Only SLUJ itself is restarted.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
MODE="${1:-run}"
case "$MODE" in
  run|--verify|--debug|--logs|--telemetry) if [ "$#" -gt 0 ]; then shift; fi ;;
  *) echo "usage: $0 [run|--verify|--debug|--logs|--telemetry] [app arguments]" >&2; exit 2 ;;
esac
pkill -x SLUJ || true
./scripts/make-app.sh debug
APP="$(swift build --show-bin-path)/SLUJ.app"
if [ "$MODE" = "--debug" ]; then
  exec lldb -- "$APP/Contents/MacOS/SLUJ" "$@"
fi
open -n "$APP" --args "$@"
case "$MODE" in
  --verify) sleep 1; pgrep -x SLUJ >/dev/null ;;
  --logs|--telemetry) exec /usr/bin/log stream --info --style compact --predicate 'process == "SLUJ"' ;;
esac
