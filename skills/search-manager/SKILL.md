---
name: search-manager
description: Kelola urutan search engine (Serper/Tavily), locale default, dan fallback key untuk pencarian.
---

# Search Manager

Skill ini mengelola pencarian web dengan urutan engine yang bisa diatur.

## Lokasi script
- `skills/search-manager/scripts/search_manager`
- `skills/search-manager/scripts/serper_search`

## Konfigurasi
- Engine order + locale: `~/.config/search-manager/config.json`
- API keys: `~/.openclaw/search_keys.json`

## Perintah utama
```bash
skills/search-manager/scripts/search_manager status
skills/search-manager/scripts/search_manager set-order serper,tavily
skills/search-manager/scripts/search_manager set-order tavily,serper
skills/search-manager/scripts/search_manager set-default-locale id id
skills/search-manager/scripts/serper_search "query"
```

## Catatan
- Tidak menyimpan API key di repo.
- Gunakan file user-local (`~/.openclaw/search_keys.json`) untuk key.
