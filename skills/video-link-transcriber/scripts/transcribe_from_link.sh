#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  transcribe_from_link.sh <url> [options]

Options:
  --out <path>           Output transcript path (default: ./transcript.txt)
  --model <name>         Model for transcription (default: whisper-1)
  --lang <code>          Force language code (default: id / Indonesia)
  --prompt <text>        Optional transcription prompt/context
  --format <fmt>         Transcript format: text|json (default: text)
  --chunk-seconds <n>    Audio split length per chunk in seconds (default: 900)
  --summary              Create summary markdown beside transcript
  --summary-model <m>    Chat model for summary (default: gpt-4o-mini)
  --keep-audio           Keep converted full audio file
  -h, --help             Show help

Notes:
  - Requires: yt-dlp, ffmpeg, curl, OPENAI_API_KEY
  - Long video is handled by chunking audio automatically.
EOF
}

URL=""
OUT="./transcript.txt"
MODEL="whisper-1"
LANG="id"
PROMPT=""
FORMAT="text"
CHUNK_SECONDS="900"
DO_SUMMARY="false"
SUMMARY_MODEL="gpt-4o-mini"
KEEP_AUDIO="false"

if [[ $# -lt 1 ]]; then
  usage; exit 1
fi

if [[ "${1:-}" != --* ]]; then
  URL="$1"
  shift
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out) OUT="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --lang) LANG="$2"; shift 2 ;;
    --prompt) PROMPT="$2"; shift 2 ;;
    --format) FORMAT="$2"; shift 2 ;;
    --chunk-seconds) CHUNK_SECONDS="$2"; shift 2 ;;
    --summary) DO_SUMMARY="true"; shift ;;
    --summary-model) SUMMARY_MODEL="$2"; shift 2 ;;
    --keep-audio) KEEP_AUDIO="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

[[ -n "$URL" ]] || { echo "Error: URL is required" >&2; exit 1; }
[[ -n "${OPENAI_API_KEY:-}" ]] || { echo "Error: OPENAI_API_KEY is not set" >&2; exit 1; }
[[ "$FORMAT" =~ ^(text|json)$ ]] || { echo "Error: --format must be text or json" >&2; exit 1; }
[[ "$CHUNK_SECONDS" =~ ^[0-9]+$ ]] || { echo "Error: --chunk-seconds must be integer" >&2; exit 1; }

for cmd in yt-dlp ffmpeg curl; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Error: $cmd not found" >&2; exit 1; }
done

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

RAW_AUDIO="$TMP_DIR/raw_audio"
AUDIO_FILE="$TMP_DIR/audio.m4a"
CHUNK_DIR="$TMP_DIR/chunks"
mkdir -p "$CHUNK_DIR"

mkdir -p "$(dirname "$OUT")"

echo "[1/4] Downloading audio..."
yt-dlp -f bestaudio --no-playlist -o "$RAW_AUDIO.%(ext)s" "$URL" >/dev/null
DOWNLOADED_FILE="$(ls "$TMP_DIR"/raw_audio.* 2>/dev/null | head -n1 || true)"
[[ -n "$DOWNLOADED_FILE" ]] || { echo "Error: failed to download audio" >&2; exit 1; }

echo "[2/4] Converting audio..."
ffmpeg -y -i "$DOWNLOADED_FILE" -vn -ac 1 -ar 16000 -b:a 96k "$AUDIO_FILE" >/dev/null 2>&1

echo "[3/4] Splitting audio into chunks (${CHUNK_SECONDS}s)..."
ffmpeg -y -i "$AUDIO_FILE" -f segment -segment_time "$CHUNK_SECONDS" -c copy "$CHUNK_DIR/chunk_%04d.m4a" >/dev/null 2>&1

mapfile -t CHUNKS < <(ls "$CHUNK_DIR"/chunk_*.m4a 2>/dev/null | sort)
[[ ${#CHUNKS[@]} -gt 0 ]] || { echo "Error: no chunks generated" >&2; exit 1; }

TEXT_OUT="$TMP_DIR/transcript_full.txt"
: > "$TEXT_OUT"
JSON_OUT="$TMP_DIR/transcript_chunks.jsonl"
: > "$JSON_OUT"

echo "[4/4] Transcribing ${#CHUNKS[@]} chunk(s)..."
INDEX=0
for chunk in "${CHUNKS[@]}"; do
  INDEX=$((INDEX+1))
  echo "  - chunk ${INDEX}/${#CHUNKS[@]}"

  FORM_ARGS=(
    -sS
    -X POST "https://api.openai.com/v1/audio/transcriptions"
    -H "Authorization: Bearer ${OPENAI_API_KEY}"
    -F "file=@${chunk}"
    -F "model=${MODEL}"
    -F "response_format=json"
  )

  [[ -n "$LANG" ]] && FORM_ARGS+=( -F "language=${LANG}" )
  [[ -n "$PROMPT" ]] && FORM_ARGS+=( -F "prompt=${PROMPT}" )

  RESPONSE="$(curl "${FORM_ARGS[@]}")"

  if command -v jq >/dev/null 2>&1; then
    CHUNK_TEXT="$(printf '%s\n' "$RESPONSE" | jq -r '.text // empty')"
  else
    CHUNK_TEXT="$(printf '%s\n' "$RESPONSE" | sed -n 's/.*"text"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p')"
  fi

  printf '%s\n\n' "$CHUNK_TEXT" >> "$TEXT_OUT"
  printf '%s\n' "$RESPONSE" >> "$JSON_OUT"
done

if [[ "$FORMAT" == "text" ]]; then
  cp "$TEXT_OUT" "$OUT"
else
  if command -v jq >/dev/null 2>&1; then
    jq -s '.' "$JSON_OUT" > "$OUT"
  else
    cp "$JSON_OUT" "$OUT"
  fi
fi

if [[ "$KEEP_AUDIO" == "true" ]]; then
  cp "$AUDIO_FILE" "${OUT%.*}.m4a"
fi

echo "Saved transcript: $OUT"

if [[ "$DO_SUMMARY" == "true" ]]; then
  SUMMARY_OUT="${OUT%.*}-summary.md"

  if command -v jq >/dev/null 2>&1; then
    PAYLOAD="$(jq -Rs --arg model "$SUMMARY_MODEL" '{model:$model,messages:[{role:"system",content:"Anda merangkum transkrip ke markdown bahasa Indonesia dengan section: Ringkasan, Poin Kunci, Action Items, Kutipan Penting."},{role:"user",content:("Ringkas transkrip berikut:\n\n" + .)}],temperature:0.2}' "$TEXT_OUT")"
  else
    echo "Summary butuh jq untuk membangun payload dengan aman. Install jq lalu ulangi --summary." >&2
    exit 1
  fi

  SUMMARY_RAW="$(curl -sS https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")"

  if command -v jq >/dev/null 2>&1; then
    printf '%s\n' "$SUMMARY_RAW" | jq -r '.choices[0].message.content // .error.message // "(summary failed)"' > "$SUMMARY_OUT"
  else
    printf '%s\n' "$SUMMARY_RAW" > "$SUMMARY_OUT"
  fi

  echo "Saved summary: $SUMMARY_OUT"
fi
