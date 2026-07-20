# NOVA — Prompt Master Claude Code
## Checkpoint Audit: Fase 1–3
**Gunakan prompt ini setelah Fase 3 selesai dan dikonfirmasi, sebelum memulai Fase 4.**

---

## KONTEKS PROJECT

Kamu melakukan audit terstruktur pada **NOVA (Next-gen One-stop Virtual Academy)** setelah tiga fase pertama selesai.

**Fase yang sudah selesai:**
- Fase 1: Foundation (`schools`, `users`, `roles`, `licenses`)
- Fase 2: Core Akademik (`classes`, `subjects`, `schedules`, `attendances`)
- Fase 3: Penilaian (`grades`, `report_cards`, `report_card_subjects`)

**Tujuan audit ini:**
Memastikan fondasi Fase 1–3 bersih, aman, dan konsisten sebelum masuk ke Fase 4 yang lebih kompleks (Pembelajaran + Claude API).

Baca `CLAUDE.md` dan `SPEC.md` di root repository sebelum mulai.

---

## ATURAN AUDIT

1. **Audit dulu, perbaiki kemudian** — identifikasi semua masalah sebelum mulai memperbaiki
2. **Catat semua temuan** — tulis laporan temuan sebelum melakukan perubahan apapun
3. **Tidak ada perubahan fitur** — audit ini hanya memperbaiki bug, keamanan, dan konsistensi
4. **Konfirmasi sebelum perbaikan besar** — jika temuan membutuhkan perubahan arsitektur, laporkan dulu dan tunggu instruksi
5. **Commit per perbaikan** — setiap perbaikan di-commit secara terpisah dengan pesan yang deskriptif

---

## AREA AUDIT

### AUDIT 1 — RLS Lintas Fase

Verifikasi bahwa penambahan kode di Fase 2 dan 3 tidak merusak RLS yang dibangun di Fase 1.

**Yang harus diuji:**

**Skenario A — Isolasi antar sekolah:**
- Login sebagai user Sekolah A
- Coba akses data: `classes`, `subjects`, `schedules`, `attendances`, `grades`, `report_cards` milik Sekolah B
- **Ekspektasi:** Semua query return 0 rows, bukan error

**Skenario B — Isolasi antar role dalam satu sekolah:**
- Login sebagai siswa → coba akses nilai siswa lain di sekolah yang sama
- Login sebagai guru → coba akses nilai di kelas yang bukan miliknya
- Login sebagai ortu → coba akses data anak lain
- **Ekspektasi:** Semua query return 0 rows

**Skenario C — Akses Dinas Pendidikan:**
- Login sebagai dinas → verifikasi hanya bisa akses data agregat, bukan data individual siswa
- **Ekspektasi:** Rekap kehadiran tersedia, nilai individual tidak tersedia

**Skenario D — Akses Komite:**
- Login sebagai komite → verifikasi hanya bisa akses kehadiran, tidak bisa akses nilai
- **Ekspektasi:** Data kehadiran tersedia, data nilai tidak tersedia

**Output yang diharapkan:**
Tabel temuan RLS:
```
| Tabel | Skenario | Status | Catatan |
|---|---|---|---|
| classes | A | PASS/FAIL | ... |
```

---

### AUDIT 2 — Data Integrity

Verifikasi konsistensi data antar tabel lintas fase.

**Yang harus dicek:**

1. **Orphan records:** Apakah ada `attendances` yang merujuk ke `class_id` atau `student_id` yang sudah tidak aktif?
2. **Referential integrity:** Apakah semua foreign key terdefinisi dengan benar di database?
3. **Duplikasi:** Apakah ada duplikasi absensi (kelas + mapel + tanggal + siswa yang sama)?
4. **Nilai tanpa kelas:** Apakah ada `grades` yang merujuk ke kelas yang tidak aktif?
5. **Rapor tanpa nilai:** Apakah ada `report_cards` yang di-publish tanpa semua mapel memiliki nilai?

**Query audit yang harus dijalankan di Supabase:**

```sql
-- Cek orphan attendances
SELECT a.id FROM attendances a
LEFT JOIN classes c ON a.class_id = c.id
WHERE c.id IS NULL OR c.is_active = false;

-- Cek duplikasi absensi
SELECT class_id, subject_id, student_id, date, COUNT(*)
FROM attendances
GROUP BY class_id, subject_id, student_id, date
HAVING COUNT(*) > 1;

-- Cek grades tanpa kelas aktif
SELECT g.id FROM grades g
LEFT JOIN classes c ON g.class_id = c.id
WHERE c.id IS NULL OR c.is_active = false;

-- Cek rapor published tanpa semua nilai
SELECT rc.id, rc.student_id
FROM report_cards rc
LEFT JOIN report_card_subjects rcs ON rc.id = rcs.report_card_id
WHERE rc.status = 'published' AND rcs.final_score IS NULL;
```

**Output yang diharapkan:**
Laporan data integrity dengan jumlah anomali per kategori.

---

### AUDIT 3 — Konsistensi Kode Frontend

Verifikasi bahwa kode React konsisten lintas fase.

**Yang harus dicek:**

1. **Penanganan error:** Apakah semua API call ke Supabase punya try/catch?
2. **Loading state:** Apakah semua halaman menampilkan loading indicator saat fetch data?
3. **Empty state:** Apakah semua halaman menampilkan pesan yang benar saat data kosong?
4. **Mobile responsiveness:** Spot-check 3 halaman kritis di viewport 320px:
   - Halaman input absensi guru
   - Halaman nilai siswa
   - Halaman rapor
5. **Konsistensi naming:** Apakah nama komponen, hooks, dan fungsi konsisten antar fase?

**Output yang diharapkan:**
Daftar file yang perlu diperbaiki beserta masalahnya.

---

### AUDIT 4 — Keamanan Dasar

Verifikasi tidak ada celah keamanan dasar.

**Yang harus dicek:**

1. **Environment variables:** Pastikan tidak ada API key atau secret yang ter-hardcode di kode
2. **`.env` tidak ter-commit:** Verifikasi `.gitignore` sudah mengecualikan `.env`
3. **Supabase anon key:** Verifikasi operasi yang butuh service role key tidak menggunakan anon key
4. **Input validation:** Apakah input nilai (0–100) divalidasi di frontend dan database?
5. **Auth check:** Apakah semua protected route benar-benar mengecek session sebelum render?

**Output yang diharapkan:**
Daftar celah keamanan yang ditemukan beserta tingkat risikonya (Tinggi / Sedang / Rendah).

---

### AUDIT 5 — Performa Dasar

Verifikasi tidak ada query yang berpotensi lambat.

**Yang harus dicek:**

1. **Index database:** Apakah kolom yang sering diquery sudah punya index?
   - `school_id` di semua tabel
   - `student_id` di `attendances` dan `grades`
   - `class_id` di `attendances`, `grades`, `schedules`
   - `date` di `attendances`

2. **N+1 query:** Apakah ada komponen yang melakukan query berulang di dalam loop?

3. **Query yang tidak perlu:** Apakah ada data yang di-fetch tapi tidak ditampilkan?

**Query audit index di Supabase:**
```sql
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename;
```

**Output yang diharapkan:**
Daftar index yang missing dan komponen yang berpotensi N+1.

---

## LAPORAN AUDIT

Setelah semua area diaudit, buat file `AUDIT_REPORT.md` di root repository dengan struktur:

```markdown
# NOVA — Audit Report Fase 1–3
**Tanggal:** [tanggal]
**Status keseluruhan:** PASS / FAIL / PASS WITH WARNINGS

## Ringkasan Temuan
| Area | Status | Jumlah Temuan |
|---|---|---|
| RLS Lintas Fase | | |
| Data Integrity | | |
| Konsistensi Kode | | |
| Keamanan | | |
| Performa | | |

## Detail Temuan
[isi per area]

## Perbaikan yang Sudah Dilakukan
[daftar perbaikan]

## Perbaikan yang Menunggu Konfirmasi
[daftar item yang butuh keputusan arsitektur]
```

---

## ALUR KERJA AUDIT

```
IDENTIFIKASI → CATAT → KLASIFIKASI → PERBAIKI → VERIFIKASI → LAPOR
```

1. Jalankan semua audit → catat semua temuan
2. Klasifikasi: **Perbaiki langsung** (bug, missing index, hardcoded key) vs **Tunggu konfirmasi** (perubahan arsitektur)
3. Perbaiki semua yang bisa diperbaiki langsung
4. Verifikasi perbaikan tidak merusak fungsionalitas yang sudah ada
5. Buat `AUDIT_REPORT.md`
6. Laporkan ke developer

---

## CHECKLIST SELESAI AUDIT

- [ ] Audit RLS selesai — semua skenario diuji
- [ ] Audit Data Integrity selesai — query audit dijalankan
- [ ] Audit Konsistensi Kode selesai — spot-check 3 halaman kritis
- [ ] Audit Keamanan selesai — tidak ada API key hardcoded
- [ ] Audit Performa selesai — index dicek
- [ ] Semua perbaikan langsung sudah dilakukan
- [ ] `AUDIT_REPORT.md` terbuat di root repository
- [ ] Semua perbaikan sudah di-commit ke GitHub

---

## SETELAH AUDIT SELESAI

Laporkan:
1. `AUDIT_REPORT.md` — isi lengkap laporan
2. Checklist di atas — centang semua yang sudah selesai
3. Daftar item yang membutuhkan konfirmasi sebelum bisa diperbaiki

**Jangan mulai Fase 4 sebelum mendapat konfirmasi dari developer.**
