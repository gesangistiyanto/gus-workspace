# TOOLS.md — Catatan Lokal

Simpan detail setup lokal yang berguna cepat (non-rahasia), misalnya:
- nama device/kamera
- host/label mesin
- preferensi TTS/ruangan

Prinsip: singkat, praktis, aman.

## Setup aktif
- Search helper tersedia: `serper_search "<query>" [gl] [hl]`
- Urutan engine: Serper (primary) -> Tavily (fallback)
- Env var yang dipakai helper: `SERPER_API_KEY`, `TAVILY_API_KEY` (jangan ditulis nilainya di file)