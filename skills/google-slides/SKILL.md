---
name: google-slides
description: Buat, edit, dan rapikan deck Google Slides dari brief/outline. Gunakan saat user minta bikin presentasi, struktur slide, perbaikan copy per slide, atau ekspor final.
---

# Google Slides

Ikuti alur ini:
1. Ambil brief: tujuan, audiens, tone, jumlah slide.
2. Buat outline: judul deck + urutan slide.
3. Tulis isi per slide ringkas (3-5 bullet maksimal).
4. Tambahkan speaker notes jika diminta.
5. Cek konsistensi: style, istilah, CTA, dan alur narasi.

## Resources
- Template input: `references/outline-template.json`
- Script helper:
  - `scripts/build_slides_from_outline`
  - `scripts/rewrite_slide_copy`

## Catatan
- Jangan masukkan rahasia/token ke deck.
- Jika butuh integrasi API Google Slides/Drive, minta kredensial yang valid dulu.
