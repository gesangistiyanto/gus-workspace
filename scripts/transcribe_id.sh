#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <audio-file> [model]" >&2
  exit 1
fi

AUDIO="$1"
MODEL="${2:-tiny}"
OUT="${AUDIO%.*}.txt"

python3 - <<'PY' "$AUDIO" "$MODEL" "$OUT"
import sys
from faster_whisper import WhisperModel

audio=sys.argv[1]
model_name=sys.argv[2]
out=sys.argv[3]

model=WhisperModel(model_name, device="cpu", compute_type="int8")
segments, info = model.transcribe(audio, language="id", vad_filter=True)
text = "".join(seg.text for seg in segments).strip()
with open(out, "w", encoding="utf-8") as f:
    f.write(text + "\n")
print(out)
PY
