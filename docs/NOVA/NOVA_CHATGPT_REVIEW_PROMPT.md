# Prompt Review NOVA untuk ChatGPT

---

Saya telah mengupload sejumlah dokumen perencanaan sebuah platform pendidikan bernama **NOVA (Next-gen One-stop Virtual Academy)**. Platform ini adalah sistem informasi sekolah multi-tenant berbasis PWA untuk jenjang SD-SMP-SMA di Indonesia.

Saya meminta Anda melakukan **review menyeluruh dan kritis** terhadap semua dokumen yang diupload.

---

## KONTEKS PLATFORM

**NOVA** adalah platform PWA multi-tenant yang melayani sekolah SD-SMP-SMA di Indonesia yang belum memiliki sistem digital apapun. Platform ini dibangun dengan:

- **Stack:** React + Vite + Tailwind CSS, Supabase (PostgreSQL + RLS), Anthropic Claude API, IndexedDB
- **Model bisnis:** Freemium + beli putus per jumlah siswa
- **9 aktor:** Guru, Wali Kelas, Wakil Kepala, Kepala Sekolah, Admin, Siswa, Orang Tua, Komite, Dinas Pendidikan
- **7 fase pembangunan** dengan 1 checkpoint audit setelah Fase 3

---

## DOKUMEN YANG DIUPLOAD

| File | Isi |
|---|---|
| `SPEC.md` | Spesifikasi master platform (v1.3) |
| `NOVA_PHASE1_PROMPT.md` | Prompt Claude Code Fase 1 — Foundation |
| `NOVA_PHASE2_PROMPT.md` | Prompt Claude Code Fase 2 — Core Akademik |
| `NOVA_PHASE3_PROMPT.md` | Prompt Claude Code Fase 3 — Penilaian |
| `NOVA_AUDIT_PHASE1-3_PROMPT.md` | Prompt Checkpoint Audit Fase 1–3 |
| `NOVA_PHASE4_PROMPT.md` | Prompt Claude Code Fase 4 — Pembelajaran + AI |
| `NOVA_PHASE5_PROMPT.md` | Prompt Claude Code Fase 5 — Komunikasi |
| `NOVA_PHASE6_PROMPT.md` | Prompt Claude Code Fase 6 — Laporan & Dashboard |
| `NOVA_PHASE7_PROMPT.md` | Prompt Claude Code Fase 7 — Hardening |
| `NOVA_USER_SCENARIOS.md` | Skenario penggunaan nyata per aktor |
| `NOVA_REVIEW_REPORT.md` | Laporan bug & gap yang sudah diidentifikasi sebelumnya |
| `NOVA_CONVERSATION_LOG.md` | Log seluruh keputusan perencanaan |

---

## INSTRUKSI REVIEW

Lakukan review dari **empat sudut pandang** berikut:

---

### SUDUT PANDANG 1 — Kelengkapan & Konsistensi Dokumen

- Apakah ada inkonsistensi antar dokumen? (misal: sesuatu didefinisikan berbeda di dua file berbeda)
- Apakah ada fitur yang disebutkan di satu dokumen tapi tidak ada implementasinya di prompt fase manapun?
- Apakah urutan fase build sudah logis dan tidak ada dependency yang terbalik?
- Apakah SPEC.md sudah mencerminkan semua keputusan yang ada di log percakapan?

---

### SUDUT PANDANG 2 — Kelayakan Teknis

- Apakah skema database yang dirancang sudah cukup untuk mendukung semua fitur yang dijanjikan?
- Apakah ada potensi masalah performa yang belum diantisipasi (query berat, data besar, concurrent users)?
- Apakah arsitektur multi-tenant via RLS sudah cukup aman untuk konteks data pendidikan anak?
- Apakah strategi offline (IndexedDB + sync queue tanpa SW di Fase 1–6) realistis untuk pengguna di daerah dengan koneksi tidak stabil?
- Apakah integrasi Claude API untuk generate modul ajar sudah dirancang dengan baik dari sisi keamanan dan biaya?

---

### SUDUT PANDANG 3 — Kesesuaian dengan Konteks Indonesia

- Apakah alur dan fitur platform sudah sesuai dengan struktur dan budaya kerja sekolah SD-SMP-SMA di Indonesia?
- Apakah ada asumsi yang terlalu "ideal" dan tidak realistis untuk kondisi sekolah di daerah (koneksi internet, literasi digital guru, dll)?
- Apakah hierarki rekap absensi (Guru → Wali Kelas → Wakil Kepala → Kepala Sekolah) sudah sesuai dengan struktur organisasi sekolah Indonesia pada umumnya?
- Apakah tipe penilaian yang dipilih (harian, tengah semester, observasi perilaku) sudah sesuai dengan Kurikulum Merdeka?
- Apakah ada regulasi atau kebijakan pendidikan Indonesia yang perlu dipertimbangkan tapi belum tercantum?

---

### SUDUT PANDANG 4 — Pengalaman Pengguna (UX)

- Berdasarkan skenario di `NOVA_USER_SCENARIOS.md`, apakah alur penggunaan setiap aktor sudah masuk akal dan tidak membingungkan?
- Apakah ada friction point yang tidak perlu dalam alur pengguna?
- Apakah batasan akses per aktor sudah tepat — tidak terlalu ketat sehingga menghambat pekerjaan, dan tidak terlalu longgar sehingga membocorkan data?
- Khusus untuk guru SD dengan literasi teknologi minim — apakah alur 8 langkah generate modul ajar sudah cukup sederhana?
- Apakah sistem komunikasi satu arah (guru → orang tua, tanpa reply) sudah cukup atau justru menciptakan frustasi bagi orang tua?

---

## FORMAT LAPORAN YANG DIHARAPKAN

Sajikan hasil review dalam format berikut:

```
## RINGKASAN EKSEKUTIF
[Penilaian keseluruhan singkat — kekuatan dan kelemahan utama]

## TEMUAN PER SUDUT PANDANG

### 1. Kelengkapan & Konsistensi
[Temuan dan rekomendasi]

### 2. Kelayakan Teknis
[Temuan dan rekomendasi]

### 3. Kesesuaian Konteks Indonesia
[Temuan dan rekomendasi]

### 4. Pengalaman Pengguna
[Temuan dan rekomendasi]

## RISIKO UTAMA
[Top 5 risiko yang paling kritis jika tidak ditangani]

## REKOMENDASI PRIORITAS
[Apa yang harus diperbaiki sebelum eksekusi pembangunan dimulai]
```

---

## CATATAN PENTING

- Dokumen `NOVA_REVIEW_REPORT.md` berisi bug dan gap yang **sudah diidentifikasi dan diperbaiki** sebelumnya. Fokus review Anda pada hal-hal yang **belum** tercantum di laporan itu.
- Jika menemukan sesuatu yang sudah ada di `NOVA_REVIEW_REPORT.md`, cukup sebut "sudah diidentifikasi sebelumnya" tanpa perlu elaborasi.
- Berikan pendapat yang jujur dan kritis — tidak perlu memuji dokumen jika ada kelemahan yang signifikan.
- Jika ada sesuatu yang ambigu atau tidak jelas di dokumen, sebutkan sebagai "ambiguitas" dan beri rekomendasi cara mengklarifikasinya.

---

Silakan mulai review.
