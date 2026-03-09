---
name: video-link-transcriber
description: Transcribe video/audio directly from a public link (YouTube and other yt-dlp supported URLs) into text/json, with optional Indonesian summary output. Use when user shares a URL and asks for transcript, notes, highlights, or action items from spoken content.
---

# Video Link Transcriber

Transcribe spoken content from a URL tanpa download manual. Skill ini memakai `yt-dlp` untuk ekstraksi audio, memecah audio jadi beberapa chunk (aman untuk video panjang), lalu kirim ke OpenAI transcription API.

## Quick start

```bash
{baseDir}/scripts/transcribe_from_link.sh "https://www.youtube.com/watch?v=VIDEO_ID"
```

Default output:
- `./transcript.txt`
- model: `whisper-1`
- language: `id` (Indonesia)

## Common commands

Transcribe in Indonesian and save to custom file:

```bash
{baseDir}/scripts/transcribe_from_link.sh "<video-url>" --lang id --out /tmp/transcript.txt
```

JSON output:

```bash
{baseDir}/scripts/transcribe_from_link.sh "<video-url>" --format json --out /tmp/transcript.json
```

Generate transcript + summary:

```bash
{baseDir}/scripts/transcribe_from_link.sh "<video-url>" --summary
```

Untuk video sangat panjang (mis. webinar 2-4 jam), pakai chunk lebih kecil:

```bash
{baseDir}/scripts/transcribe_from_link.sh "<video-url>" --chunk-seconds 600
```

Use prompt for names/terms:

```bash
{baseDir}/scripts/transcribe_from_link.sh "<video-url>" --prompt "Nama pembicara: Gesang, Dika"
```

## Requirements

- `yt-dlp`
- `ffmpeg`
- `curl`
- `OPENAI_API_KEY`
- optional: `jq` (better parsing)

## Outputs

- Transcript: `--out <path>` (default `./transcript.txt`)
- If `--summary` used: `<out-without-extension>-summary.md`
- If `--keep-audio` used: `<out-without-extension>.m4a`

## Notes

- For long videos, transcription can take longer and may need chunking improvements in future iteration.
- Prefer `--lang id` for Indonesian-only videos to reduce language drift.
