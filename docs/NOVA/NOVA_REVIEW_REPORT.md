# NOVA — Laporan Review Bug & Gap
**Tanggal:** 2026-07-07  
**Reviewer:** Claude  
**Scope:** SPEC.md v1.2 + semua prompt Fase 1–7 + Audit + Log

---

## RINGKASAN EKSEKUTIF

| Kategori | Jumlah |
|---|---|
| Bug (inkonsistensi antar file) | 7 |
| Gap (fitur/logika yang hilang) | 9 |
| Minor (perlu klarifikasi/perbaikan kecil) | 5 |

---

## BUG — INKONSISTENSI ANTAR FILE

### BUG 1 — Fase 5 Prompt: Sisa Konten Lama (KRITIS)
**File:** `NOVA_PHASE5_PROMPT.md` — Langkah 2  
**Masalah:** Langkah 2 masih berisi sisa SQL lama dari tabel `messages` versi sebelumnya (sebelum revisi sistem pesan terpadu). Teks berbunyi "Buat sistem notifikasi in-app untuk semua role. Buat migration file untuk tabel `messages`:" diikuti SQL lama yang sudah tidak relevan.  
**Dampak:** Claude Code akan bingung — ada dua definisi tabel `messages` yang berbeda di file yang sama.  
**Perbaikan:** Hapus sisa SQL lama di Langkah 2, ganti dengan instruksi notifikasi yang bersih.

---

### BUG 2 — SPEC.md: Dua Section "11" (KRITIS)
**File:** `SPEC.md`  
**Masalah:** Ada dua heading `## 11.` — satu untuk "HIERARKI REKAP ABSENSI" dan satu untuk "RIWAYAT REVISI". Ini terjadi karena update v1.2 menyisipkan section baru tanpa menomor ulang.  
**Dampak:** Dokumen tidak konsisten, bisa membingungkan Claude Code saat membaca SPEC.md.  
**Perbaikan:** Renomor — Hierarki Rekap Absensi tetap §11, Riwayat Revisi menjadi §12.

---

### BUG 3 — Fase 1 CLAUDE.md: Menyebut Workbox (MINOR-KRITIS)
**File:** `NOVA_PHASE1_PROMPT.md` — Langkah 7 (isi CLAUDE.md yang akan dibuat)  
**Masalah:** Template CLAUDE.md yang akan dibuat di repository menyebut "Stack: React + Vite + Tailwind, Supabase, Claude API, **Workbox**, IndexedDB" — padahal Workbox sudah dihapus dari stack dan SW ditunda ke Fase 7.  
**Dampak:** CLAUDE.md di repository akan menyebut Workbox, Claude Code di Fase 2+ akan terkecoh.  
**Perbaikan:** Ganti "Workbox" dengan "IndexedDB + sync queue (SW aktif di Fase 7)".

---

### BUG 4 — SPEC.md Fase 7: Menyebut "WhatsApp OTP" di Hardening
**File:** `SPEC.md` — Section 8, deskripsi Fase 7  
**Masalah:** Deskripsi Fase 7 masih menyebut "notifikasi WhatsApp OTP" sebagai fokus hardening — padahal WhatsApp OTP adalah metode login ortu (Fase 1), bukan bagian hardening. Fase 7 fokusnya Web Push.  
**Dampak:** Bisa membuat Claude Code mengimplementasi ulang WhatsApp OTP di Fase 7.  
**Perbaikan:** Ganti "notifikasi WhatsApp OTP" dengan "Web Push notification".

---

### BUG 5 — Fase 2: Field `is_homeroom_teacher` di Tabel `classes` vs `users`
**File:** `NOVA_PHASE2_PROMPT.md`  
**Masalah:** Tabel `classes` punya kolom `homeroom_teacher_id uuid references users(id)`. Tapi di catatan tambahan (yang diinsert setelah revisi) juga ada field `homeroom_class_id uuid references classes(id)` di tabel `users`. Relasi ini dua arah (circular reference) dan tidak ada yang mendefinisikan mana yang jadi source of truth.  
**Dampak:** Inkonsistensi data — jika admin update wali kelas di tabel `classes`, field `is_homeroom_teacher` dan `homeroom_class_id` di `users` tidak otomatis terupdate.  
**Perbaikan:** Tetapkan satu source of truth: `classes.homeroom_teacher_id` adalah yang utama. Field `is_homeroom_teacher` dan `homeroom_class_id` di `users` adalah derived field yang di-sync via trigger atau computed di aplikasi.

---

### BUG 6 — Fase 4: Generate Modul Disebutkan "7 Langkah" tapi Ada 8
**File:** `NOVA_PHASE4_PROMPT.md`  
**Masalah:** Header langkah di Fase 4 menyebut "Buat `src/pages/teacher/GenerateModule.jsx` dengan **7 langkah**" tapi langkah yang dijabarkan ada 8 (1: Kelas, 2: Mapel, 3: Semester & Minggu, 4: Topik, 5: Durasi, 6: Metode, 7: Konfirmasi & Generate, 8: Review & Simpan).  
**Dampak:** Claude Code bisa berhenti di langkah 7, melewatkan langkah Review & Simpan.  
**Perbaikan:** Update header menjadi "8 langkah".

---

### BUG 7 — Fase 2 Dashboard: Kepsek Disamakan dengan Admin
**File:** `NOVA_PHASE2_PROMPT.md` — Langkah 5  
**Masalah:** Dashboard update Fase 2 menulis "Dashboard Admin/Kepsek" dalam satu section, seolah keduanya sama. Padahal berdasarkan keputusan revisi, Admin dan Kepala Sekolah adalah role yang berbeda dengan akses berbeda.  
**Dampak:** Claude Code akan membuat satu dashboard untuk keduanya, tidak sesuai klasifikasi role yang sudah direvisi.  
**Perbaikan:** Pisahkan menjadi "Dashboard Admin" dan "Dashboard Kepala Sekolah" dengan deskripsi masing-masing.

---

## GAP — FITUR/LOGIKA YANG HILANG

### GAP 1 — Tidak Ada Field `region` di Tabel `schools` atau `users`
**Ditemukan di:** SPEC.md §9 Alur Autentikasi, Fase 6, Fase 7  
**Masalah:** Banyak bagian menyebut Dinas Pendidikan difilter berdasarkan `region`, tapi tidak ada satu pun prompt yang mendefinisikan di mana field `region` ini disimpan dan bagaimana strukturnya.  
**Pertanyaan yang belum terjawab:** Apakah `region` ada di tabel `schools`? Di tabel `users` untuk akun Dinas? Bagaimana format nilainya (kode wilayah, nama kota, dll)?  
**Perbaikan yang dibutuhkan:** Tambahkan field `region text` di tabel `schools` (Fase 1) dan field `region text` di tabel `users` untuk role `dinas` — sehingga RLS bisa filter `schools.region = dinas_user.region`.

---

### GAP 2 — Tidak Ada Mekanisme Ganti Password
**Ditemukan di:** Fase 1  
**Masalah:** Auth dibangun (login, logout, session) tapi tidak ada langkah untuk ganti password, reset password lupa, atau ganti PIN siswa.  
**Dampak:** Guru/siswa yang lupa password tidak bisa recovery sendiri — harus minta admin, dan admin tidak punya UI untuk ini.  
**Perbaikan yang dibutuhkan:** Tambahkan di Fase 1: (1) halaman lupa password untuk email-based login, (2) admin bisa reset password/NIS siswa dari dashboard.

---

### GAP 3 — Siswa Tidak Memiliki Relasi ke Kelas di Skema Database
**Ditemukan di:** Fase 1 (tabel `users`) dan Fase 2  
**Masalah:** Tabel `users` tidak punya field `class_id` untuk siswa. Tapi banyak fitur bergantung pada "siswa di kelas ini" — absensi, jadwal, tugas, modul. Tidak ada yang mendefinisikan bagaimana sistem tahu siswa masuk kelas mana.  
**Dampak:** Query "ambil semua siswa di kelas X" tidak bisa dilakukan tanpa relasi ini.  
**Perbaikan yang dibutuhkan:** Tambahkan tabel `class_members` atau field `class_id` di `users` untuk siswa.

---

### GAP 4 — Tidak Ada Relasi Orang Tua ke Siswa
**Ditemukan di:** Fase 1  
**Masalah:** Tidak ada tabel atau field yang mendefinisikan "ortu A adalah orang tua dari siswa B". Banyak fitur bergantung pada relasi ini — notifikasi absensi ke ortu, ortu lihat nilai anak, ortu lihat jadwal anak.  
**Dampak:** Seluruh fitur ortu tidak bisa berjalan tanpa relasi ini.  
**Perbaikan yang dibutuhkan:** Tambahkan tabel `parent_student` di Fase 1: `parent_id uuid references users(id)`, `student_id uuid references users(id)`, `school_id uuid references schools(id)`.

---

### GAP 5 — Guru Absensi Hanya Siswa, Bagaimana Absensi Guru?
**Ditemukan di:** SPEC.md dan Fase 2  
**Masalah:** SPEC.md menyebut "absensi siswa & guru" di skema database, tapi prompt Fase 2 hanya membangun absensi siswa. Tidak ada mekanisme untuk absensi guru.  
**Dampak:** Dashboard Wali Kelas dan Wakil Kepala menyebut "rekap kehadiran guru" tapi datanya tidak ada.  
**Perbaikan yang dibutuhkan:** Tentukan: apakah absensi guru masuk tabel `attendances` yang sama (dengan flag berbeda) atau tabel terpisah `teacher_attendances`? Dan siapa yang input — guru sendiri (self check-in) atau admin?

---

### GAP 6 — Tidak Ada Mekanisme Tahun Ajaran Aktif
**Ditemukan di:** Fase 2, 3, 4  
**Masalah:** Banyak tabel punya field `academic_year text` tapi tidak ada mekanisme untuk menetapkan tahun ajaran aktif secara global. Setiap query harus tahu tahun ajaran yang sedang berjalan.  
**Dampak:** Fitur "jadwal hari ini", "absensi semester ini", "nilai semester aktif" tidak tahu harus query tahun ajaran berapa.  
**Perbaikan yang dibutuhkan:** Tambahkan tabel `school_settings` atau field `active_academic_year` dan `active_semester` di tabel `schools`.

---

### GAP 7 — Tidak Ada Pembatasan Akses Fitur Berdasarkan Tier
**Ditemukan di:** SPEC.md §4 Model Bisnis  
**Masalah:** SPEC.md mendefinisikan fitur gratis vs berbayar per role, tapi tidak ada satu pun prompt yang menjelaskan bagaimana tier ini di-enforce di kode. Apakah via RLS? Via middleware di frontend? Via field di tabel `licenses`?  
**Dampak:** Platform bisa jalan tanpa enforcement tier — semua fitur berbayar bisa diakses gratis.  
**Perbaikan yang dibutuhkan:** Tambahkan di Fase 1: mekanisme gate fitur berdasarkan `licenses.tier` — bisa berupa hook `useFeatureAccess(featureName)` yang dicek sebelum render fitur berbayar.

---

### GAP 8 — Tidak Ada Penanganan Konflik Jadwal
**Ditemukan di:** Fase 2  
**Masalah:** Admin bisa membuat jadwal tanpa validasi konflik — guru bisa dijadwalkan dua kelas di waktu yang sama, atau satu kelas bisa punya dua mapel di jam yang sama.  
**Dampak:** Data jadwal tidak valid, absensi dan laporan akan kacau.  
**Perbaikan yang dibutuhkan:** Tambahkan validasi di Fase 2: sebelum simpan jadwal, cek apakah guru atau kelas sudah punya jadwal di hari + jam yang sama.

---

### GAP 9 — Tidak Ada Mekanisme Backup/Ekspor Data Sekolah
**Ditemukan di:** Fase 7  
**Masalah:** Platform menyimpan semua data sekolah di Supabase, tapi tidak ada mekanisme bagi admin untuk backup atau ekspor data lengkap sekolahnya (misal saat ingin migrasi atau arsip akhir tahun ajaran).  
**Dampak:** Sekolah tidak punya kontrol atas datanya sendiri — risiko vendor lock-in.  
**Rekomendasi:** Tambahkan di backlog: fitur ekspor data lengkap per sekolah ke CSV/JSON oleh admin.

---

## MINOR — PERLU KLARIFIKASI

### MINOR 1 — Deteksi Role Login: Ambiguitas Siswa vs Email
**File:** `NOVA_PHASE1_PROMPT.md` — Langkah 4  
**Masalah:** "Satu halaman login, deteksi role otomatis" — tapi siswa login dengan NIS (bukan email), sementara role lain dengan email. Bagaimana sistem tahu apakah input adalah NIS atau email sebelum query?  
**Rekomendasi:** Tambahkan instruksi: sistem deteksi berdasarkan format input — jika numerik → coba sebagai NIS (siswa), jika mengandung "@" → coba sebagai email (role lain), jika numerik panjang → coba sebagai no HP (ortu).

---

### MINOR 2 — `curriculum_topics` Tidak Punya `school_id` untuk RLS
**File:** `NOVA_PHASE4_PROMPT.md`  
**Masalah:** Tabel `curriculum_topics` punya `school_id` yang nullable (null = bawaan sistem). Tapi RLS tidak didefinisikan untuk tabel ini — apakah data bawaan sistem bisa diakses semua sekolah? Apakah topik custom sekolah A bisa dilihat sekolah B?  
**Rekomendasi:** Definisikan RLS eksplisit: bisa baca jika `school_id IS NULL` (bawaan) ATAU `school_id = user.school_id` (custom sekolah sendiri).

---

### MINOR 3 — `lesson_modules` Tidak Punya Status Published
**File:** `NOVA_PHASE4_PROMPT.md`  
**Masalah:** Tabel `lesson_modules` tidak punya field `is_published` atau `status`. Tapi Fase 4 menyebut "Bagikan ke Siswa" sebagai aksi di langkah 8. Tidak ada yang mendefinisikan state modul sebelum dan sesudah dibagikan.  
**Rekomendasi:** Tambahkan field `is_published boolean default false` di tabel `lesson_modules`.

---

### MINOR 4 — Fase 3: Siapa yang Bisa Publish Rapor?
**File:** `NOVA_PHASE3_PROMPT.md`  
**Masalah:** RLS menyebut "Admin/Kepsek bisa buat dan publish rapor" tapi UI hanya dibangun untuk admin (`src/pages/admin/ReportCards.jsx`). Kepala Sekolah tidak punya UI untuk ini.  
**Rekomendasi:** Klarifikasi — apakah Kepsek bisa publish rapor atau hanya Admin? Jika Kepsek juga bisa, tambahkan `src/pages/principal/ReportCards.jsx`.

---

### MINOR 5 — Fase 6: Dashboard Wali Kelas File Salah Nama
**File:** `NOVA_PHASE6_PROMPT.md` — Langkah 4A  
**Masalah:** File dashboard wali kelas ditulis sebagai `src/pages/teacher/HomroomReport.jsx` — typo "Homroom" seharusnya "Homeroom".  
**Perbaikan:** Ganti menjadi `src/pages/teacher/HomeroomReport.jsx`.

---

## PRIORITAS PERBAIKAN

| Prioritas | Item | Dampak |
|---|---|---|
| 🔴 KRITIS | GAP 3 — Siswa tidak ada relasi ke kelas | Seluruh fitur akademik rusak |
| 🔴 KRITIS | GAP 4 — Ortu tidak ada relasi ke siswa | Seluruh fitur ortu rusak |
| 🔴 KRITIS | BUG 1 — Sisa SQL lama di Fase 5 | Claude Code akan error |
| 🔴 KRITIS | GAP 1 — Field `region` tidak terdefinisi | RLS Dinas tidak bisa diimplementasi |
| 🟠 TINGGI | GAP 7 — Tidak ada enforcement tier | Semua fitur bisa diakses gratis |
| 🟠 TINGGI | GAP 5 — Absensi guru tidak terdefinisi | Dashboard rekap tidak akurat |
| 🟠 TINGGI | GAP 6 — Tidak ada tahun ajaran aktif | Query waktu tidak bisa berjalan |
| 🟠 TINGGI | BUG 5 — Circular reference wali kelas | Data inkonsisten |
| 🟡 SEDANG | GAP 2 — Tidak ada reset password | UX buruk untuk pengguna |
| 🟡 SEDANG | GAP 8 — Tidak ada validasi konflik jadwal | Data jadwal tidak valid |
| 🟡 SEDANG | BUG 2 — Dua section §11 di SPEC.md | Dokumen tidak konsisten |
| 🟡 SEDANG | BUG 3 — Workbox di CLAUDE.md template | Claude Code terkecoh |
| 🟡 SEDANG | BUG 4 — WhatsApp OTP di Fase 7 | Implementasi salah di Fase 7 |
| 🟡 SEDANG | BUG 6 — "7 langkah" padahal 8 | Langkah 8 bisa terlewat |
| 🟡 SEDANG | BUG 7 — Admin & Kepsek digabung di Fase 2 | Dashboard role tidak sesuai |
| 🟢 RENDAH | MINOR 1 — Deteksi format login | UX login kurang jelas |
| 🟢 RENDAH | MINOR 2 — RLS curriculum_topics | Kebocoran topik antar sekolah |
| 🟢 RENDAH | MINOR 3 — lesson_modules tidak ada status | Modul selalu "published" |
| 🟢 RENDAH | MINOR 4 — Siapa yang publish rapor | Ambiguitas role |
| 🟢 RENDAH | MINOR 5 — Typo "HomroomReport" | Nama file salah |

---

## REKOMENDASI TINDAKAN

**Sebelum eksekusi Claude Code:**
Perbaiki semua item 🔴 KRITIS dan 🟠 TINGGI terlebih dahulu — terutama GAP 3 dan GAP 4 yang menyentuh skema database Fase 1. Jika Fase 1 dieksekusi tanpa relasi siswa-kelas dan ortu-siswa, seluruh platform akan cacat dari fondasi.

**Yang perlu keputusan Anda (bukan teknis semata):**
- GAP 5: Siapa yang absensi guru, dan bagaimana mekanismenya?
- GAP 6: Format tahun ajaran aktif — apakah admin sekolah yang set, atau otomatis dari tanggal?
- GAP 7: Bagaimana enforcement tier — frontend gate, backend middleware, atau RLS?
- MINOR 4: Apakah Kepala Sekolah bisa publish rapor?
