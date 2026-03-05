---
name: serper-search
description: Gunakan Serper sebagai default untuk pencarian web cepat dengan Tavily sebagai fallback melalui helper `serper_search`.
---

# Serper Search (Default)

## Kapan dipakai
- User minta: cari berita, cari info terbaru, riset cepat, cek top results.

## Perintah utama
```bash
serper_search "<query>" [gl] [hl]
```

Default:
- `gl=id`
- `hl=id`

## Catatan
- Butuh env `SERPER_API_KEY` aktif.
- Jangan tampilkan API key ke output/chat.
- Untuk ringkasan user, ambil 3–10 hasil teratas lalu rangkum singkat.
