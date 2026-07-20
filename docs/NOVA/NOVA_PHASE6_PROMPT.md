# NOVA — Prompt Master Claude Code
## Fase 6: Laporan & Dashboard
**Gunakan prompt ini setelah Fase 5 selesai dan dikonfirmasi.**

---

## KONTEKS PROJECT

Kamu melanjutkan pembangunan **NOVA (Next-gen One-stop Virtual Academy)** — platform PWA multi-tenant sistem informasi sekolah SD-SMP-SMA.

**Fase 1–5 sudah selesai dan terverifikasi:**
- Foundation, Core Akademik, Penilaian, Pembelajaran, dan Komunikasi berjalan penuh
- Sistem pesan terpadu aktif — semua aktor internal bisa kirim ke penerima yang diseleksi
- Notifikasi in-app berjalan

**Fase 6 adalah fase agregasi** — tidak membangun entitas baru, melainkan menarik dan menyajikan data dari semua fase sebelumnya dalam bentuk laporan dan dashboard yang informatif per role.

Baca `CLAUDE.md` dan `SPEC.md` di root repository sebelum mulai.

---

## ATURAN KERJA WAJIB

1. **Baca dulu, kode kemudian** — analisis seluruh instruksi sebelum mulai
2. **Satu langkah selesai sebelum lanjut** — jangan overlap antar langkah
3. **Tidak ada placeholder** — semua data harus dari database nyata, bukan mock
4. **RLS tetap berlaku** — semua query agregasi harus tetap terisolasi per `school_id`
5. **Mobile-first wajib** — chart dan tabel harus bisa dibaca di layar 320px
6. **Tidak ada keputusan arsitektur mandiri** — jika ada ambiguitas, tulis pertanyaan dan tunggu konfirmasi
7. **Commit per langkah** — setiap langkah selesai langsung commit
8. **Service Worker tidak disentuh** — SW diaktifkan di Fase 7

---

## PRINSIP DASHBOARD & LAPORAN

- **Data real** — tidak ada angka statis atau demo data
- **Periode fleksibel** — semua laporan bisa difilter: hari ini / minggu ini / bulan ini / semester ini
- **Export** — laporan bisa diexport ke PDF (implementasi sederhana via print stylesheet)
- **Mobile-readable** — tabel horizontal diganti dengan kartu atau scroll horizontal yang jelas
- **Loading state** — semua agregasi query bisa lambat, wajib ada skeleton loader

---

## FASE 6 — LAPORAN & DASHBOARD

### Target Fase 6
- Dashboard per role menampilkan data agregat yang relevan dan actionable
- Kepala Sekolah & Admin punya akses laporan lengkap
- Dinas Pendidikan punya akses rekap lintas sekolah dalam wilayah
- Semua laporan bisa difilter per periode dan diexport

---

### Langkah-langkah

#### LANGKAH 1 — Dashboard Guru (Upgrade)

Dashboard guru saat ini hanya menampilkan data hari ini. Upgrade menjadi dashboard yang lebih informatif.

**Komponen yang dibangun:**

**Kartu Ringkasan Hari Ini:**
- Jadwal mengajar hari ini (kelas & jam)
- Jumlah siswa hadir vs tidak hadir (dari absensi hari ini)
- Tugas yang belum dinilai (jumlah submission masuk)
- Sisa kuota generate modul hari ini

**Kartu Aktivitas Minggu Ini:**
- Jumlah jurnal mengajar yang sudah diisi vs yang seharusnya
- Jumlah kelas yang sudah diabsen vs belum

**Shortcut Aksi Cepat:**
- Absensi sekarang (langsung ke kelas aktif hari ini)
- Buat modul ajar
- Input nilai
- Kirim pesan

**File:** `src/pages/teacher/Dashboard.jsx`

**Verifikasi:**
- Data yang tampil akurat sesuai database
- Shortcut membawa guru ke halaman yang benar
- Tampil baik di 320px

---

#### LANGKAH 2 — Dashboard Siswa (Upgrade)

**Komponen yang dibangun:**

**Kartu Status Hari Ini:**
- Jadwal pelajaran hari ini
- Status kehadiran hari ini (hadir / belum tercatat)

**Kartu Akademik:**
- Nilai terbaru per mapel (semester aktif)
- Status rapor (tersedia / belum)

**Kartu Tugas:**
- Tugas yang belum dikumpulkan + countdown deadline
- Tugas yang sudah dikumpulkan dan sudah dinilai

**File:** `src/pages/student/Dashboard.jsx`

---

#### LANGKAH 3 — Dashboard Orang Tua (Upgrade)

**Komponen yang dibangun:**

**Kartu Anak Hari Ini:**
- Status kehadiran anak hari ini
- Jadwal pelajaran anak hari ini

**Kartu Perkembangan:**
- Nilai terbaru anak per mapel
- Rekap kehadiran anak bulan ini (persentase)

**Kartu Komunikasi:**
- Pesan belum dibaca (jumlah)
- Pesan terbaru

**File:** `src/pages/parent/Dashboard.jsx`

---

#### LANGKAH 4A — Dashboard Wali Kelas

Wali kelas adalah guru dengan `is_homeroom_teacher = true`. Dashboard mereka adalah dashboard guru biasa dengan tambahan satu section rekap kelas.

**Tambahan di `src/pages/teacher/Dashboard.jsx` (conditional render jika `is_homeroom_teacher`):**

**Kartu Rekap Kelas (khusus Wali Kelas):**
- Nama kelas yang dia wali
- Rekap kehadiran seluruh siswa di kelasnya hari ini — dari SEMUA mapel & SEMUA guru yang mengajar di kelas itu
- Persentase kehadiran kelas minggu ini
- Siswa dengan kehadiran terendah bulan ini (top 5)
- Tombol "Lihat Rekap Lengkap" → halaman rekap absensi kelas

**Buat `src/pages/teacher/HomeroomReport.jsx`:**
- Filter: periode (minggu / bulan / semester)
- Tabel: per siswa — Hadir / Sakit / Izin / Alpha / Persentase (agregat dari semua mapel)
- Tombol Export PDF

**Verifikasi:**
- Wali kelas melihat rekap dari SEMUA guru yang mengajar di kelasnya
- Guru biasa tidak melihat section ini
- Export PDF berfungsi

---

#### LANGKAH 4B — Dashboard Wakil Kepala

Wakil kepala adalah guru dengan `is_vice_principal = true`. Mereka punya halaman dashboard tersendiri yang menampilkan rekap seluruh sekolah.

**Buat `src/pages/viceprincipal/Dashboard.jsx`:**

**Kartu Rekap Seluruh Sekolah Hari Ini:**
- Total siswa hadir / tidak hadir / belum tercatat per kelas
- Kelas yang belum ada absensi hari ini (perlu tindak lanjut)

**Kartu Rekap Per Wali Kelas:**
- Tabel: Kelas | Wali Kelas | % Hadir Hari Ini | % Hadir Minggu Ini
- Bisa klik per kelas → lihat detail rekap kelas tersebut

**Buat `src/pages/viceprincipal/AttendanceReport.jsx`:**
- Filter: kelas, periode
- Tabel rekap per siswa lintas kelas
- Export PDF per kelas atau seluruh sekolah

**Verifikasi:**
- Wakil Kepala melihat rekap seluruh sekolah
- Bisa drill-down ke rekap per kelas
- Data terisolasi per `school_id`

---

#### LANGKAH 4 — Dashboard & Laporan Kepala Sekolah

Ini adalah dashboard paling lengkap — semua data sekolah dalam satu tampilan.

**Buat `src/pages/principal/Dashboard.jsx`:**

**Kartu Ringkasan Sekolah Hari Ini:**
- Total siswa hadir / tidak hadir / belum tercatat (seluruh sekolah)
- Total guru hadir / tidak hadir
- Jumlah kelas yang sudah diabsen hari ini

**Kartu Progres Guru (minggu ini):**
- Tabel: Nama Guru | Jurnal Diisi | Absensi Dilakukan | Nilai Diinput
- Indikator: hijau (lengkap), kuning (sebagian), merah (belum sama sekali)

**Kartu Akademik Sekolah:**
- Rata-rata nilai per kelas per mapel (semester aktif)
- Kelas dengan rata-rata tertinggi & terendah

**Kartu Penggunaan Platform:**
- Jumlah modul ajar dibuat bulan ini
- Jumlah pesan dikirim bulan ini
- Jumlah guru aktif (login dalam 7 hari terakhir)

**Filter periode:** Hari ini / Minggu ini / Bulan ini / Semester ini

---

**Buat `src/pages/principal/Reports.jsx` — halaman laporan lengkap:**

**Laporan 1 — Rekap Kehadiran Siswa:**
- Filter: kelas, periode (minggu/bulan/semester)
- Tampilan: tabel per siswa dengan kolom Hadir / Sakit / Izin / Alpha / Persentase
- Export: PDF via print

**Laporan 2 — Rekap Nilai per Kelas:**
- Filter: kelas, mapel, semester
- Tampilan: tabel per siswa dengan kolom nilai per tipe penilaian + rata-rata
- Export: PDF via print

**Laporan 3 — Progres Input Guru:**
- Filter: periode
- Tampilan: tabel per guru dengan status jurnal, absensi, nilai
- Export: PDF via print

**Laporan 4 — Statistik Penggunaan Platform:**
- Filter: periode
- Tampilan: ringkasan angka — modul dibuat, pesan dikirim, login aktif
- Export: PDF via print

**Verifikasi:**
- Semua laporan menampilkan data real dari database
- Filter periode berfungsi dan mengubah data yang ditampilkan
- Export PDF menghasilkan file yang bisa dibaca
- Data terisolasi per `school_id` — tidak ada data sekolah lain

---

#### LANGKAH 5 — Dashboard Admin (Upgrade)

Admin fokus pada operasional — berbeda dari Kepsek yang fokus pada monitoring.

**Buat `src/pages/admin/Dashboard.jsx`:**

**Kartu Data Sekolah:**
- Jumlah guru aktif / total guru
- Jumlah siswa aktif / total siswa
- Jumlah kelas aktif

**Kartu Status Lisensi:**
- Tier saat ini (gratis / berbayar)
- Jumlah siswa terdaftar vs limit lisensi
- Tanggal aktivasi

**Kartu Aktivitas Hari Ini:**
- Jumlah login hari ini per role
- Aksi terakhir di sekolah (dari `audit_logs`)

**Shortcut:**
- Tambah guru
- Tambah siswa
- Kelola kelas
- Kirim pengumuman

---

#### LANGKAH 6 — Dashboard Komite

**Buat `src/pages/committee/Dashboard.jsx`:**

**Kartu Kehadiran (read-only):**
- Rekap kehadiran siswa sekolah bulan ini (persentase)
- Rekap kehadiran guru sekolah bulan ini (persentase)

**Kartu Kegiatan Sekolah:**
- Daftar pengumuman & kegiatan terbaru
- Pesan yang ditujukan ke komite

**Verifikasi:**
- Komite tidak bisa melihat nilai individual siswa
- Komite tidak bisa melihat pesan yang bukan ditujukan ke mereka

---

#### LANGKAH 7 — Dashboard & Laporan Dinas Pendidikan

Dinas melihat data **lintas sekolah** dalam wilayahnya — ini satu-satunya role yang bisa akses data lebih dari satu sekolah.

**RLS khusus Dinas:**
- Dinas punya field `region` yang menentukan wilayah aksesnya
- Query dinas difilter berdasarkan `schools.region = dinas.region`
- Dinas tidak bisa akses data individual siswa — hanya agregat per sekolah

**Buat `src/pages/dinas/Dashboard.jsx`:**

**Kartu Ringkasan Wilayah:**
- Total sekolah dalam wilayah
- Total siswa aktif seluruh wilayah
- Total guru aktif seluruh wilayah

**Kartu Kehadiran Wilayah (hari ini):**
- Persentase kehadiran siswa per sekolah
- Persentase kehadiran guru per sekolah

**Buat `src/pages/dinas/Reports.jsx`:**

**Laporan 1 — Rekap Kehadiran Seluruh Sekolah:**
- Filter: periode
- Tampilan: tabel per sekolah dengan kolom rata-rata kehadiran siswa & guru
- Bisa drill-down ke rekap per kelas (masih read-only)
- Export: PDF

**Laporan 2 — Perbandingan Antar Sekolah:**
- Filter: periode, metrik (kehadiran / nilai rata-rata)
- Tampilan: tabel ranking sekolah berdasarkan metrik yang dipilih
- Export: PDF

**Verifikasi:**
- Dinas hanya bisa lihat sekolah dalam wilayahnya
- Dinas tidak bisa lihat nilai individual siswa
- Data akurat sesuai database

---

#### LANGKAH 8 — Utility: Export PDF

Implementasi export PDF sederhana via print stylesheet — tidak butuh library tambahan.

**Buat `src/utils/printReport.js`:**
```javascript
export function printReport(title) {
  const originalTitle = document.title;
  document.title = title;
  window.print();
  document.title = originalTitle;
}
```

**Buat `src/styles/print.css`:**
- Sembunyikan navigasi, header, tombol saat print
- Tampilkan tabel secara penuh
- Tambahkan header laporan: nama sekolah, judul laporan, tanggal cetak
- Ukuran kertas: A4

Import `print.css` di `index.css` dengan `@media print`.

**Verifikasi:**
- Print dialog muncul saat tombol Export ditekan
- Navigasi dan tombol tidak tampil di hasil print
- Header laporan tampil dengan nama sekolah dan tanggal

---

#### LANGKAH 9 — Update CLAUDE.md

```markdown
## Status Fase
- [x] Fase 1: Foundation
- [x] Fase 2: Core Akademik
- [x] Fase 3: Penilaian
- [x] Fase 4: Pembelajaran
- [x] Fase 5: Komunikasi
- [x] Fase 6: Laporan & Dashboard
- [ ] Fase 7: Hardening

## Keputusan Arsitektur yang Sudah Fix
- [2026-07-07] Multi-tenant: school_id + RLS (bukan schema-per-school)
- [2026-07-07] Stack: Hybrid cloud (Supabase → VPS)
- [2026-07-07] Auth ortu: WhatsApp OTP
- [2026-07-07] Auth siswa: NIS + password
- [2026-07-07] Service Worker: tidak diaktifkan di Fase 1–6, diaktifkan di Fase 7
- [2026-07-07] Absensi: tidak bisa duplikasi per kelas + mapel + tanggal
- [2026-07-07] Rapor: TIDAK masuk platform
- [2026-07-07] Tipe penilaian: harian | tengah_semester | observasi_perilaku
- [2026-07-07] Claude API: rate limit 10x generate per guru per hari
- [2026-07-07] Claude API: cache aktif — topik sama tidak generate ulang
- [2026-07-07] Generate modul: 8 langkah, semua input via pilihan
- [2026-07-07] Topik & metode: bawaan sistem + bisa ditambah guru
- [2026-07-07] Komunikasi: sistem pesan terpadu — semua aktor internal bisa kirim
- [2026-07-07] Aktor eksternal: hanya terima pesan, tidak bisa kirim
- [2026-07-07] Kepala Sekolah: bisa kirim pesan, akses data akademik read-only
- [2026-07-07] Notifikasi: in-app di Fase 5, Web Push + SW di Fase 7
- [2026-07-07] Pesan: bisa diedit maksimal 24 jam setelah dikirim
- [2026-07-07] Export laporan: via print stylesheet (PDF), tanpa library tambahan
- [2026-07-07] Hierarki rekap absensi: Guru → Wali Kelas → Wakil Kepala → Kepala Sekolah
- [2026-07-07] Wali Kelas: rekap seluruh mapel di kelasnya (dari semua guru)
- [2026-07-07] Wakil Kepala: rekap seluruh kelas di sekolah
- [2026-07-07] Dinas: akses lintas sekolah difilter via field region, tidak bisa lihat data individual siswa
```

---

## CHECKLIST SELESAI FASE 6

- [ ] Dashboard Guru diupgrade dengan ringkasan hari ini + aktivitas minggu ini
- [ ] Dashboard Wali Kelas — kartu rekap kelas + halaman rekap lengkap + export PDF
- [ ] Dashboard Wakil Kepala — rekap seluruh sekolah + drill-down per kelas
- [ ] Dashboard Siswa diupgrade dengan status akademik & tugas
- [ ] Dashboard Orang Tua diupgrade dengan perkembangan anak
- [ ] Dashboard Kepala Sekolah lengkap — 4 laporan tersedia & bisa diexport
- [ ] Dashboard Admin diupgrade dengan status operasional
- [ ] Dashboard Komite — kehadiran sekolah tanpa data nilai individual
- [ ] Dashboard Dinas — rekap lintas sekolah dalam wilayah
- [ ] Laporan Dinas — 2 laporan tersedia & bisa diexport
- [ ] Filter periode berfungsi di semua laporan
- [ ] Export PDF via print berfungsi
- [ ] Rekap nilai menampilkan 3 tipe penilaian yang benar
- [ ] RLS Dinas terverifikasi — hanya akses sekolah dalam wilayahnya
- [ ] Data individual siswa tidak bisa diakses Dinas & Komite
- [ ] `CLAUDE.md` diupdate dengan status Fase 6 selesai
- [ ] Semua langkah sudah di-commit ke GitHub

---

## SETELAH FASE 6 SELESAI

Laporkan:
1. Checklist di atas — centang semua yang sudah selesai
2. Deskripsi singkat tampilan Dashboard Kepala Sekolah di mobile (320px)
3. Konfirmasi export PDF berfungsi
4. Jika ada item yang tidak bisa diselesaikan — jelaskan kenapa dan tunggu instruksi

**Jangan mulai Fase 7 sebelum mendapat konfirmasi.**
