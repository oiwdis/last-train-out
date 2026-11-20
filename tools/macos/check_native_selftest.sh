#!/usr/bin/env bash
# Launch the selected, shipped native Metal executable with normal system audio.
set -euo pipefail
app="${1:?supply a downloaded app}"
out="${2:?supply a report directory}"
root="$(cd "$(dirname "$0")/../.." && pwd)"
mkdir -p "$out"
"$app/Contents/MacOS/choose-renderer" metal res://scenes/main/self_test.tscn -- \
  --selftest-report="$out/native-metal.json" --selftest-screenshot="$out/native-metal.png" > "$out/native-metal.log" 2>&1
python3 "$root/tools/macos/check_selftest.py" "$out/native-metal.json" --exit-code 0 --expect-window --expect-arch arm64 --label fresh-metal
python3 "$root/tools/macos/renderer_diagnostics.py" "$out/native-metal.log"
python3 - "$out/native-metal.json" <<'PY'
import json
import sys
from pathlib import Path
r = json.loads(Path(sys.argv[1]).read_text())
assert (r['runtime_binary'], r['rendering_method'], r['rendering_driver']) == ('LastTrainOutMetal','forward_plus','metal')
PY
