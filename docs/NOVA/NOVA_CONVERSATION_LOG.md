# NOVA — Log Percakapan
## Sesi Perencanaan Platform
**Tanggal:** 2026-07-07  
**Peserta:** Teguh + Claude  
**Topik:** Perencanaan dan persiapan pembangunan platform NOVA dari nol

---

## BAGIAN 1 — DISKUSI AWAL: SKENARIO IDEAL

**Teguh:** Saya membayangkan claude code melakukan pembangunan sebuah platform dari nol - 100% dan siap pakai.

**Claude:** Apakah ini skenario ideal atau pertanyaan tentang realita kemampuan Claude Code?

**Teguh:** Skenario ideal. Berhubung pengalaman sebelumnya, untuk membangun sebuah platform dibutuhkan waktu berbulan-bulan untuk selesai.

**Claude:** Bottleneck di mana — perencanaan, coding, debugging, atau koordinasi antar sesi? Dan platform yang dimaksud seperti Student Growth PWA/FLAF atau sesuatu yang baru?

**Teguh:** Semuanya. Lebih dari sekadar itu.

**Claude:** Lebih kompleks secara fitur atau lebih luas secara scope?

**Teguh:** Lebih kompleks secara fitur dan lebih luas secara scope - multi-tenant.

**Claude:** Tanggapan jujur — Claude Code hari ini belum bisa 0→100% tanpa intervensi manusia untuk platform sekompleks itu. Keterbatasan utama: konteks terpotong antar sesi, keputusan arsitektur ambigu, integrasi eksternal butuh konfigurasi manual, validasi bisnis tidak bisa dilakukan Claude. Solusi paling realistis: fase otonom berantai dengan checkpoint per fase.

**Teguh:** Saya bisa pahami keterbatasan itu, lalu apa solusinya?

**Claude:** Memecah "0→100%" menjadi fase otonom berantai: Fase 1 Spesifikasi → Fase 2 Scaffold → Fase 3 Build per modul → Fase 4 Integrasi → Fase 5 Hardening. Kunci: SPEC.md presisi di awal dan prompt per fase yang self-contained.

**Teguh:** Bukankah yang pertama sekali harus fix adalah tujuan?

**Claude:** Benar sekali. Tujuan dulu — karena semua fase dan keputusan arsitektur harus bisa diukur terhadap tujuan yang sudah ditetapkan.

---

## BAGIAN 2 — PENETAPAN TUJUAN

**Teguh:** Platform ini untuk sekolah SD-SMP-SMA (multi-tenant).

**Claude:** Itu scope, bukan tujuan. Platform ini hadir untuk menyelesaikan masalah apa?

*(Sesi tanya jawab pilihan ganda)*

**Stakeholder:** Guru, Siswa, Orang tua, Kepala sekolah/Admin, Komite, Dinas Pendidikan

**Masalah utama:**
- Administrasi sekolah masih manual / tidak efisien
- Guru kesulitan mengelola pembelajaran
- Orang tua tidak tahu perkembangan anak

**Hasil yang diinginkan:**
- Hemat waktu kerja harian
- Komunikasi sekolah-orang tua lebih lancar
- Guru bisa fokus mengajar, bukan administrasi

**Kondisi sekolah target:** Belum punya sistem apapun — mulai dari nol

**TUJUAN YANG DITETAPKAN:**
> Membangun sistem informasi sekolah multi-tenant (SD-SMP-SMA) yang menjadi satu-satunya sistem operasional bagi sekolah yang belum punya sistem apapun — mencakup administrasi, pengelolaan pembelajaran, dan komunikasi sekolah-orang tua — sehingga guru bisa fokus mengajar, administrasi berjalan efisien, dan orang tua tahu perkembangan anak secara real-time.

**Status:** ✅ Disetujui Teguh

---

## BAGIAN 3 — PEMETAAN FITUR PER STAKEHOLDER

### Guru
- Absensi siswa digital *(Gratis)*
- Jurnal mengajar harian *(Berbayar)*
- Input nilai & rapor *(Berbayar)*
- Jadwal pelajaran *(Gratis)*
- Komunikasi dengan orang tua *(Berbayar)*
- **Modul ajar otomatis AI per mapel** *(Berbayar)* — ditambahkan Teguh, ditetapkan sebagai fitur INTI

### Siswa
- Lihat jadwal pelajaran *(Gratis)*
- Lihat nilai & rapor *(Gratis)*
- Akses materi & modul ajar *(Berbayar)*
- Tugas & pengumpulan tugas *(Berbayar)*

### Orang Tua
- Lihat nilai & perkembangan anak *(Gratis)*
- Notifikasi absensi real-time *(Berbayar)*
- Komunikasi langsung dengan guru *(Berbayar)*
- Jadwal anak *(Gratis)*

### Kepala Sekolah / Admin
- Dashboard statistik sekolah *(Berbayar)*
- Manajemen data guru & siswa *(Gratis — basic)*
- Laporan kehadiran & nilai *(Berbayar)*
- Pengumuman sekolah *(Gratis)*

### Komite
- Pantau kehadiran rapat & kegiatan *(Gratis)*
- Pantau kehadiran guru dan siswa *(Gratis)*

### Dinas Pendidikan
- Rekap data seluruh sekolah dalam wilayah *(Berbayar)*
- Laporan kehadiran guru & siswa *(Gratis)*

---

## BAGIAN 4 — PENAMAAN PLATFORM

**Teguh:** Minta nama platform dengan 2 suku kata, berupa akronim dari Bahasa Inggris.

**Pilihan yang diusulkan Claude:**
- SIMS — School Information Management System
- EDUS — Education Digital Unified System
- AXIS — Academic Excellence Information System
- NOVA — Network of Virtual Academia
- SAGE — School Administration & Growth Engine
- SPARK — School Platform for Academic Records & Knowledge

**Teguh:** Nova

**Kepanjangan akhir yang dipilih:** Next-gen One-stop Virtual Academy

**NAMA RESMI: NOVA — Next-gen One-stop Virtual Academy** ✅

---

## BAGIAN 5 — STACK TEKNOLOGI

**Kekhawatiran Teguh:**
1. Apakah offline + realtime bisa bersamaan?
2. Biaya cloud jangka panjang

**Jawaban Claude:**
1. Ya bisa — online: sync Supabase realtime; offline: simpan di IndexedDB; kembali online: sync queue berjalan otomatis
2. Perlu dihitung serius — terhubung ke model bisnis

**Skenario yang diusulkan:**

**Skenario A — Cloud Murni**
Biaya ~$25–100/bulan untuk 10–50 sekolah aktif. Risiko: biaya tidak terkontrol.

**Skenario B — Hybrid** *(Dipilih Teguh)*
Supabase untuk MVP → migrasi ke VPS setelah revenue stabil. Biaya ~$25/bulan di awal, turun setelah migrasi.

**STACK FINAL:**
| Layer | Teknologi |
|---|---|
| Frontend | React + Vite + Tailwind CSS |
| PWA | manifest.json (SW diaktifkan di Fase 7) |
| Backend & DB | Supabase (PostgreSQL + RLS) |
| AI | Anthropic Claude API |
| Offline | IndexedDB + sync queue |
| Deployment | Vercel → Coolify (VPS) |

**Status:** ✅ Disetujui Teguh

---

## BAGIAN 6 — MODEL BISNIS

**Model:** Freemium + beli putus (one-time license)
- Tier Gratis: fitur dasar selamanya
- Tier Berbayar: upgrade satu kali, semua fitur terbuka permanen
- Harga: per jumlah siswa (makin besar sekolah, makin mahal)

**Skala tier harga (rekomendasi awal):**
- 1–100 siswa: Tier S
- 101–300 siswa: Tier M
- 301–600 siswa: Tier L
- 601+ siswa: Tier XL

**Status:** ✅ Disetujui Teguh

---

## BAGIAN 7 — ARSITEKTUR MULTI-TENANT

**Pendekatan A:** Satu database, isolasi via `school_id` + RLS *(Dipilih)*
**Pendekatan B:** Schema terpisah per sekolah

**Alasan pilih A:** Murah, mudah dikelola, terbukti di Student Growth PWA, migration path ke B tersedia jika dibutuhkan.

**Status:** ✅ Disetujui Teguh

---

## BAGIAN 8 — SKEMA DATABASE HIGH-LEVEL

### CORE
- `schools` — data sekolah, jenjang, lisensi
- `users` — semua pengguna lintas role
- `roles` — guru, siswa, ortu, kepsek, admin, komite, dinas

### AKADEMIK
- `classes` — kelas per sekolah per tahun ajaran
- `subjects` — mata pelajaran
- `schedules` — jadwal pelajaran
- `attendances` — absensi siswa & guru
- `grades` — nilai siswa
- `report_cards` — rapor

### PEMBELAJARAN
- `teaching_journals` — jurnal mengajar harian
- `lesson_modules` — modul ajar (manual + AI-generated)
- `assignments` — tugas
- `submissions` — pengumpulan tugas siswa

### KOMUNIKASI
- `announcements` — pengumuman sekolah
- `messages` — komunikasi guru-ortu

### SISTEM
- `licenses` — lisensi per sekolah, jumlah siswa, status
- `audit_logs` — jejak aktivitas seluruh pengguna

**Status:** ✅ Disetujui Teguh

---

## BAGIAN 9 — DEPENDENCY MAP & URUTAN BUILD

**Urutan yang dipilih:** Opsi A — urutan teknis murni

| Fase | Entitas | Prasyarat |
|---|---|---|
| Fase 1 | schools, users, roles, licenses | Tidak ada |
| Fase 2 | classes, subjects, schedules, attendances | Fase 1 |
| Fase 3 | grades, report_cards | Fase 2 |
| Fase 4 | teaching_journals, lesson_modules, assignments, submissions | Fase 2 + Claude API |
| Fase 5 | announcements, messages | Fase 1 |
| Fase 6 | Laporan & Dashboard (agregasi) | Fase 1–5 |
| Fase 7 | Hardening: RLS audit, SW, offline sync, notifikasi, security | Fase 1–6 |

**Status:** ✅ Disetujui Teguh

---

## BAGIAN 10 — ALUR AUTENTIKASI

| Role | Metode |
|---|---|
| Admin / Kepala Sekolah | Email + password |
| Guru | Email + password |
| Siswa | NIS + password |
| Orang Tua | No. HP + OTP WhatsApp |
| Komite | Email + password |
| Dinas Pendidikan | Email + password |

**Alur onboarding sekolah baru:**
1. Admin daftar → input data sekolah → sistem generate `school_id`
2. Admin input data guru & siswa (manual atau import CSV)
3. Sistem generate akun otomatis per guru & siswa
4. Orang tua diundang via WhatsApp OTP

**Status:** ✅ Disetujui Teguh

---

## BAGIAN 11 — KEPUTUSAN TEKNIS TAMBAHAN

**Service Worker:**
- Tidak diaktifkan di Fase 1–6
- Diaktifkan di Fase 7 (Hardening) setelah platform stabil
- Alasan: menghindari bug SW yang sulit di-debug di fase awal development

**Status:** ✅ Disetujui Teguh

---

## BAGIAN 12 — OUTPUT YANG DIHASILKAN

| File | Keterangan |
|---|---|
| `SPEC.md` | Dokumen spesifikasi master platform NOVA |
| `NOVA_PHASE1_PROMPT.md` | Prompt Claude Code untuk Fase 1 Foundation |
| `NOVA_PHASE2_PROMPT.md` | Prompt Claude Code untuk Fase 2 Core Akademik |
| `NOVA_CONVERSATION_LOG.md` | File ini — log lengkap percakapan sesi ini |

---

## RINGKASAN KEPUTUSAN FINAL

| Aspek | Keputusan |
|---|---|
| Nama | NOVA — Next-gen One-stop Virtual Academy |
| Jenis | PWA multi-tenant |
| Target | SD-SMP-SMA yang belum punya sistem |
| Stakeholder | Guru, Siswa, Ortu, Admin/Kepsek, Komite, Dinas |
| Fitur unggulan | Modul ajar otomatis AI (fitur inti, bukan opsional) |
| Stack | React + Vite + Tailwind, Supabase, Claude API, Vercel |
| Multi-tenant | school_id + RLS |
| Model bisnis | Freemium + beli putus per jumlah siswa |
| SW | Diaktifkan di Fase 7 |
| Fase build | 7 fase dengan checkpoint per fase |

---

---

## BAGIAN 13 — CHECKPOINT AUDIT FASE 1–3

**Claude:** Setelah Fase 3, direkomendasikan checkpoint audit terstruktur lintas fase sebelum masuk Fase 4 — karena Fase 4 menyentuh Claude API dan logika lebih kompleks. Lebih baik fondasi Fase 1–3 bersih terlebih dahulu.

**Teguh:** Setuju.

**5 area audit yang ditetapkan:**
1. RLS Lintas Fase — 4 skenario isolasi antar sekolah dan antar role
2. Data Integrity — orphan records, duplikasi, rapor tanpa nilai
3. Konsistensi Kode — error handling, loading state, mobile 320px
4. Keamanan — env variables, auth check, input validation
5. Performa — missing index, N+1 query

**Output audit:** `AUDIT_REPORT.md` tersimpan di repository sebagai jejak tertulis.

**Status:** ✅ Disetujui Teguh

---

## BAGIAN 14 — FASE 4: PEMBELAJARAN + CLAUDE API

### Diskusi Biaya Claude API

**Estimasi biaya per generate modul:**
- Input: ~500–800 token
- Output: ~1.000–2.000 token
- Total per generate: ~1.500–2.800 token
- Biaya per generate: di bawah $0.01

**Estimasi biaya bulanan per skala:**
| Skenario | Generate/bulan | Estimasi biaya |
|---|---|---|
| 10 sekolah, 5 guru aktif | ~500 | ~$1–2 |
| 50 sekolah, 5 guru aktif | ~2.500 | ~$5–10 |
| 200 sekolah, 5 guru aktif | ~10.000 | ~$20–40 |

**Risiko yang diantisipasi:**
- Guru spam generate → rate limiting
- Prompt injection → input sanitization
- Output tidak relevan → system prompt ketat

**Solusi yang dibangun di Fase 4:**
- Rate limiting: maksimal 10x generate per guru per hari
- Input sanitization sebelum dikirim ke API
- System prompt ketat dalam konteks Kurikulum Merdeka SD-SMP-SMA
- Cache modul: topik sama tidak generate ulang → hemat biaya

### Alur Generate Modul — Keputusan UX

**Target pengguna terburuk:** Guru SD yang hanya familiar dengan WhatsApp.

**Prinsip UX yang ditetapkan:**
- Setiap langkah hanya satu keputusan
- Semua input via pilihan (tap/klik) — bukan ketik bebas
- Bahasa Indonesia sehari-hari, tidak ada istilah teknis
- Progress indicator jelas
- Bisa kembali ke langkah sebelumnya

**Langkah tidak dibatasi 3** — boleh sepanjang yang dibutuhkan untuk hasil presisi, asal setiap langkah sederhana.

**Alur generate modul final (8 langkah):**
1. Pilih Kelas (dari jadwal guru — otomatis tersedia)
2. Pilih Mata Pelajaran (dari jadwal kelas dipilih)
3. Pilih Semester & Minggu
4. Pilih Topik (bawaan Kurikulum Merdeka + bisa tambah sendiri)
5. Pilih Durasi (1/2/3/4 JP)
6. Pilih Metode Mengajar (bawaan + bisa tambah sendiri)
7. Konfirmasi & Generate (cek cache dulu, baru API call)
8. Review & Simpan (edit, buat ulang, atau bagikan ke siswa)

**Keputusan topik & metode:**
- Bawaan sistem dari Kurikulum Merdeka sebagai titik awal
- Guru bisa tambah topik sendiri → tersimpan per sekolah
- Guru bisa tambah metode sendiri → tersimpan per sekolah

**Metode bawaan (8 metode):**
Ceramah, Diskusi, Praktik Langsung, Permainan, Tanya Jawab, Demonstrasi, Kerja Kelompok, Bercerita.

**Status:** ✅ Disetujui Teguh

---

## BAGIAN 15 — OUTPUT YANG DIHASILKAN (UPDATE)

| File | Keterangan |
|---|---|
| `SPEC.md` | Dokumen spesifikasi master platform NOVA |
| `NOVA_PHASE1_PROMPT.md` | Prompt Claude Code untuk Fase 1 Foundation |
| `NOVA_PHASE2_PROMPT.md` | Prompt Claude Code untuk Fase 2 Core Akademik |
| `NOVA_PHASE3_PROMPT.md` | Prompt Claude Code untuk Fase 3 Penilaian |
| `NOVA_AUDIT_PHASE1-3_PROMPT.md` | Prompt Checkpoint Audit Fase 1–3 |
| `NOVA_PHASE4_PROMPT.md` | Prompt Claude Code untuk Fase 4 Pembelajaran |
| `NOVA_CONVERSATION_LOG.md` | File ini — log lengkap percakapan sesi ini |

---

## RINGKASAN KEPUTUSAN FINAL (UPDATE)

| Aspek | Keputusan |
|---|---|
| Nama | NOVA — Next-gen One-stop Virtual Academy |
| Jenis | PWA multi-tenant |
| Target | SD-SMP-SMA yang belum punya sistem |
| Stakeholder | Guru, Siswa, Ortu, Admin/Kepsek, Komite, Dinas |
| Fitur unggulan | Modul ajar otomatis AI (fitur inti, bukan opsional) |
| Stack | React + Vite + Tailwind, Supabase, Claude API, Vercel |
| Multi-tenant | school_id + RLS |
| Model bisnis | Freemium + beli putus per jumlah siswa |
| SW | Diaktifkan di Fase 7 |
| Fase build | 7 fase + 1 checkpoint audit (setelah Fase 3) |
| Generate modul | 8 langkah, semua via pilihan, ramah guru SD |
| Rate limiting | Max 10x generate per guru per hari |
| Cache | Topik sama tidak generate ulang |
| Topik & metode | Bawaan sistem + bisa ditambah guru |

---

*Log ini dibuat dan diupdate dari sesi percakapan 2026-07-07.*
*Simpan file ini sebagai referensi untuk sesi Claude Code berikutnya.*

---

## BAGIAN 16 — REVISI STRUKTUR ROLE & SISTEM PESAN

### Keputusan baru yang ditetapkan:

**Sistem pesan diperluas:**
- Pengirim bukan hanya guru — semua aktor internal bisa kirim pesan
- Penerima bisa diseleksi bebas sesuai kebutuhan pengirim
- `announcements` dihapus sebagai entitas terpisah — digabung ke sistem pesan terpadu

**Klasifikasi aktor final:**

Aktor Internal (bisa kirim & terima pesan):
- Guru: mengajar (tercatat di jadwal), bisa punya jabatan tambahan wali kelas / wakil kepala
- Admin: tidak mengajar, kelola data sekolah
- Kepala Sekolah: tidak mengajar, akses data akademik read-only, bisa kirim pesan

Aktor Eksternal (hanya terima pesan & read-only):
- Siswa: akses data diri sendiri
- Orang Tua: akses data anak
- Komite: pantau kehadiran & kegiatan
- Dinas Pendidikan: rekap data wilayah

**Aturan edit pesan:** bisa diedit maksimal 24 jam setelah dikirim. Setelah itu terkunci. Penerima yang sudah membaca mendapat notifikasi "Pesan telah diperbarui".

**Dokumen yang diupdate:**
- SPEC.md → versi 1.1
- NOVA_PHASE5_PROMPT.md → sistem pesan terpadu

**Status:** ✅ Disetujui Teguh

---

## BAGIAN 17 — HIERARKI REKAP ABSENSI

**Keputusan baru yang ditetapkan:**

Rekap absensi memiliki 4 level hierarki:

| Level | Role | Cakupan |
|---|---|---|
| 1 | Guru | Absensi kelas & mapel yang dia ajar sendiri |
| 2 | Wali Kelas | Absensi seluruh mapel di kelas yang dia wali |
| 3 | Wakil Kepala | Absensi seluruh kelas di sekolah |
| 4 | Kepala Sekolah | Sama dengan Wakil Kepala — read-only |

**Field tambahan di tabel `users`:**
- `is_homeroom_teacher` — menandai wali kelas
- `homeroom_class_id` — kelas yang dia wali
- `is_vice_principal` — menandai wakil kepala

**Dokumen yang diupdate:**
- SPEC.md → versi 1.2
- NOVA_PHASE2_PROMPT.md → migration field tambahan users
- NOVA_PHASE6_PROMPT.md → tambah Langkah 4A (Wali Kelas) dan 4B (Wakil Kepala)

**Status:** ✅ Disetujui Teguh

---

## BAGIAN 18 — FASE 7: HARDENING

**7 area hardening yang ditetapkan:**

| Area | Fokus |
|---|---|
| 1 | Audit RLS final seluruh platform (semua tabel Fase 1–6) |
| 2 | Service Worker aktif — offline fallback + sync queue |
| 3 | Web Push — VAPID keys, push subscription, Edge Function |
| 4 | Performa — index database, N+1 query, bundle size |
| 5 | Keamanan — input validation, auth security, dependency audit |
| 6 | UX Polish — empty state, error state, loading state, onboarding checklist admin |
| 7 | Dokumen final — CLAUDE.md, BACKLOG.md, DEPLOYMENT.md |

**Event yang trigger Web Push:**
- Absensi diinput → ortu siswa terkait
- Pesan baru → penerima pesan
- Pesan diedit → penerima yang sudah baca
- Tugas baru → siswa di kelas
- Tugas H-1 deadline → siswa belum kumpul
- Rapor published → siswa & ortu

**Target akhir Fase 7:**
- Lighthouse Performance > 70 di mobile
- `npm audit` tidak ada vulnerability high/critical
- Platform PRODUCTION READY

**Output akhir platform:**
- URL production di Vercel
- AUDIT_REPORT.md final
- BACKLOG.md
- DEPLOYMENT.md

**Status:** ✅ Prompt selesai disusun

---

## RINGKASAN SEMUA OUTPUT SESI INI

| File | Keterangan | Status |
|---|---|---|
| `SPEC.md` (v1.2) | Spesifikasi master platform NOVA | ✅ |
| `NOVA_PHASE1_PROMPT.md` | Prompt Claude Code Fase 1 — Foundation | ✅ |
| `NOVA_PHASE2_PROMPT.md` | Prompt Claude Code Fase 2 — Core Akademik | ✅ |
| `NOVA_PHASE3_PROMPT.md` | Prompt Claude Code Fase 3 — Penilaian | ✅ |
| `NOVA_AUDIT_PHASE1-3_PROMPT.md` | Prompt Checkpoint Audit Fase 1–3 | ✅ |
| `NOVA_PHASE4_PROMPT.md` | Prompt Claude Code Fase 4 — Pembelajaran | ✅ |
| `NOVA_PHASE5_PROMPT.md` | Prompt Claude Code Fase 5 — Komunikasi | ✅ |
| `NOVA_PHASE6_PROMPT.md` | Prompt Claude Code Fase 6 — Laporan & Dashboard | ✅ |
| `NOVA_PHASE7_PROMPT.md` | Prompt Claude Code Fase 7 — Hardening | ✅ |
| `NOVA_CONVERSATION_LOG.md` | Log lengkap seluruh percakapan sesi ini | ✅ |

---

*Sesi perencanaan NOVA selesai — 2026-07-07.*
*Seluruh prompt siap digunakan di Claude Code secara berurutan.*

---

## BAGIAN 19 — REVIEW & PERBAIKAN BUG/GAP

**Review menyeluruh dilakukan** atas semua file — ditemukan 7 bug, 9 gap, 5 minor.

### Keputusan yang ditetapkan dari review:

**GAP 5 (Absensi Guru):** Dikoreksi — "rekap kehadiran guru" = rekap apakah guru sudah absensi siswanya atau belum, bukan kehadiran fisik guru. Tidak perlu tabel baru.

**Rekap kehadiran** = rekap status siswa: hadir / sakit / izin / alpha.

**GAP 6 (Tahun Ajaran Aktif):** Admin sekolah yang set via field `active_academic_year` dan `active_semester` di tabel `schools`.

**GAP 7 (Enforcement Tier):** Frontend gate via hook `useFeatureAccess(featureName)`. Fitur berbayar terkunci tapi terlihat di tier gratis.

**MINOR 4 (Rapor):** Rapor TIDAK masuk platform. Penilaian yang masuk: harian, tengah semester, observasi perilaku. Tidak ada akhir semester dan tidak ada rapor.

### Perbaikan yang dilakukan di semua file:
- SPEC.md → versi 1.3
- Semua prompt Fase 1–7 diupdate
- Tambah tabel `class_members` (relasi siswa-kelas) di Fase 1
- Tambah tabel `parent_student` (relasi ortu-siswa) di Fase 1
- Tambah field `region` di `schools` dan `users` untuk Dinas
- Tambah `active_academic_year` dan `active_semester` di `schools`
- Tambah hook `useFeatureAccess` di Fase 1
- Hapus `report_cards` dan `report_card_subjects` dari seluruh scope
- Update `assessment_type`: harian | tengah_semester | observasi_perilaku
- Fix BUG 1: sisa SQL lama di Fase 5
- Fix BUG 2: duplikat section §11 di SPEC.md
- Fix BUG 3: Workbox di CLAUDE.md template Fase 1
- Fix BUG 4: WhatsApp OTP di deskripsi Fase 7
- Fix BUG 5: circular reference wali kelas — source of truth di classes.homeroom_teacher_id
- Fix BUG 6: "7 langkah" → "8 langkah" di Fase 4
- Fix BUG 7: Dashboard Admin dan Kepsek dipisah di Fase 2
- Fix MINOR 1: deteksi format login (NIS/email/HP)
- Fix MINOR 2: RLS curriculum_topics
- Fix MINOR 3: tambah is_published di lesson_modules
- Fix MINOR 5: typo HomeroomReport

**Status:** ✅ Semua perbaikan selesai

---

## BAGIAN 20 — PROMPT REVIEW UNTUK CHATGPT

**Permintaan:** Siapkan prompt untuk ChatGPT melakukan review seluruh dokumen NOVA secara independen.

**Pendekatan yang dipilih:** Upload semua file ke ChatGPT Plus, paste prompt instruksi.

**File yang akan diupload ke ChatGPT:**
SPEC.md, NOVA_PHASE1–7_PROMPT.md, NOVA_AUDIT_PHASE1-3_PROMPT.md, NOVA_USER_SCENARIOS.md, NOVA_REVIEW_REPORT.md, NOVA_CONVERSATION_LOG.md

**4 sudut pandang review yang diminta:**
1. Kelengkapan & Konsistensi Dokumen
2. Kelayakan Teknis
3. Kesesuaian Konteks Indonesia
4. Pengalaman Pengguna (UX)

**Output:** `NOVA_CHATGPT_REVIEW_PROMPT.md`

**Status:** ✅ Selesai

---

## RINGKASAN SELURUH OUTPUT SESI INI (FINAL)

| File | Keterangan |
|---|---|
| `SPEC.md` (v1.3) | Spesifikasi master platform NOVA |
| `NOVA_PHASE1_PROMPT.md` | Prompt Claude Code Fase 1 — Foundation |
| `NOVA_PHASE2_PROMPT.md` | Prompt Claude Code Fase 2 — Core Akademik |
| `NOVA_PHASE3_PROMPT.md` | Prompt Claude Code Fase 3 — Penilaian |
| `NOVA_AUDIT_PHASE1-3_PROMPT.md` | Prompt Checkpoint Audit Fase 1–3 |
| `NOVA_PHASE4_PROMPT.md` | Prompt Claude Code Fase 4 — Pembelajaran |
| `NOVA_PHASE5_PROMPT.md` | Prompt Claude Code Fase 5 — Komunikasi |
| `NOVA_PHASE6_PROMPT.md` | Prompt Claude Code Fase 6 — Laporan & Dashboard |
| `NOVA_PHASE7_PROMPT.md` | Prompt Claude Code Fase 7 — Hardening |
| `NOVA_USER_SCENARIOS.md` | Skenario penggunaan nyata 9 aktor |
| `NOVA_REVIEW_REPORT.md` | Laporan 7 bug + 9 gap + 5 minor |
| `NOVA_CHATGPT_REVIEW_PROMPT.md` | Prompt review untuk ChatGPT |
| `NOVA_CONVERSATION_LOG.md` | Log lengkap seluruh percakapan sesi ini |

*Sesi perencanaan NOVA selesai — 2026-07-07.*

---

## BAGIAN 21 — VISI EKOSISTEM BELAJAR RUMAH-SEKOLAH

**Visi yang ditetapkan:**
Guru menyusun CP dan ATP secara khusus dan modul ajar dalam satu tahun pelajaran. Informasi ini bisa dibaca orang tua di rumah melalui HP. Orang tua bisa tanya ke AI tentang materi. Manfaat: siswa bisa belajar di rumah dibantu orang tua.

**Keputusan yang ditetapkan:**

| Aspek | Keputusan |
|---|---|
| CP & ATP | AI generate otomatis berdasarkan jenjang & mapel, guru review & approve |
| Akses orang tua | Baca materi + tanya AI tentang materi |
| Kontrol materi | Guru yang menentukan materi mana yang dibagikan (toggle per modul) |
| Perilaku AI | Jawab berdasarkan konten guru; pertanyaan pengembangan dalam konteks topik; pertanyaan di luar konteks ditolak ramah |
| Tone AI | Formal untuk orang tua, santai untuk siswa |
| Rate limit AI tutor | 20 pertanyaan per pengguna per hari |

**Repositioning NOVA:**
Dari "sistem informasi sekolah + Teaching Assistant" menjadi **"platform ekosistem belajar"** yang menghubungkan guru di sekolah, siswa, dan orang tua di rumah dalam satu alur pembelajaran yang kohesif.

**Dokumen yang diupdate:**
- SPEC.md → versi 1.4
- NOVA_PHASE4_PROMPT.md → tambah Langkah 0A (CP) dan 0B (ATP)
- NOVA_PHASE4B_PROMPT.md → prompt baru Fase 4B Ekosistem Belajar

**Status:** ✅ Disetujui Teguh
