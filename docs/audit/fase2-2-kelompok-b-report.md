# Audit Fase 2.2 — Kelompok B: Join Penugasan Guru / Jadwal

**Tanggal audit:** 2026-07-07  
**Auditor:** Claude Code (read-only, tidak ada perubahan skema)  
**Metodologi:** Definisi policy diambil langsung dari `pg_policies` live; RLS tabel yang di-join juga diambil dari live; anomali data dicek via COUNT query read-only.

---

## Ringkasan Eksekutif

Dua dari tiga policy Kelompok B (**🟢 AMAN**) — keduanya adalah policy FOR ALL (baca + tulis) untuk guru dan substitute yang memiliki guard `school_id` eksplisit pada tabel utama (`attendance`) sekaligus didukung oleh RLS implisit pada tabel yang di-join. Satu policy (**🟡 PERLU VERIFIKASI**) untuk akses SISWA membaca jadwal — hanya SELECT, bukan FOR ALL — yang memiliki guard eksplisit pada tabel utama (`teaching_schedules`) tetapi subquery ke `class_enrollments` tidak menyertakan filter `ce.school_id` eksplisit. Pola ini identik dengan kelemahan struktural pada `rls_schedules_read_parent` yang sudah diperkuat di Kelompok A; versi ORTU sudah diperbaiki (commit 524d97f menambahkan `ce.school_id = fn_current_school_id()`), tetapi versi SISWA belum mendapat perlakuan yang sama.

Tidak ada celah cross-tenant yang memungkinkan guru menulis absensi ke sekolah lain. Risiko tertinggi (policy FOR ALL) justru merupakan yang paling aman secara struktural karena QUAL dan WITH CHECK identik dan keduanya menempatkan guard eksplisit sebagai kondisi pertama.

---

## Tabel Hasil Audit

| # | Policy | Tabel Utama | CMD | Rantai Join | Guard `school_id` QUAL | Guard `school_id` WITH CHECK | Status | Catatan |
|---|--------|-------------|-----|-------------|------------------------|-------------------------------|--------|---------|
| 1 | `rls_attendance_rw_guru` | `attendance` | FOR ALL | `attendance` → `teaching_schedules` → `teaching_assignments` | **Eksplisit**: `attendance.school_id = fn_current_school_id()` + implisit RLS `teaching_schedules` + RLS `teaching_assignments` | **Identik dengan QUAL** — eksplisit + implisit sama | 🟢 AMAN | QUAL = WITH CHECK; tidak ada asimetri |
| 2 | `rls_attendance_rw_substitute` | `attendance` | FOR ALL | `attendance` → `substitute_schedules` | **Eksplisit**: `attendance.school_id = fn_current_school_id()` + implisit RLS `substitute_schedules` + guard waktu `sync_token_expires_at` | **Identik dengan QUAL** — eksplisit + implisit sama | 🟢 AMAN | Guard waktu kadaluarsa menambah lapisan keamanan aktif |
| 3 | `rls_schedules_read_student` | `teaching_schedules` | SELECT | `teaching_schedules` → `class_enrollments` | **Eksplisit**: `teaching_schedules.school_id = fn_current_school_id()` — tetapi `ce.school_id` tidak eksplisit di subquery | `NULL` (SELECT only) | 🟡 PERLU VERIFIKASI | Pola identik dengan `rls_schedules_read_parent` sebelum diperkuat (commit 524d97f) |

---

## Analisis Per Policy

### 1. `rls_attendance_rw_guru` — FOR ALL

**QUAL (lengkap, dari `pg_policies` live):**
```sql
(school_id = fn_current_school_id())
AND (EXISTS (
  SELECT 1
  FROM teaching_schedules ts
  WHERE ts.schedule_id = attendance.schedule_id
    AND (
      ts.scheduled_teacher_id = fn_current_user_id()
      OR (EXISTS (
        SELECT 1 FROM teaching_assignments ta
        WHERE ta.assignment_id = ts.assignment_id
          AND ta.user_id = fn_current_user_id()
          AND ta.is_active = true
      ))
    )
))
```

**WITH CHECK:** identik dengan QUAL di atas.

**Rantai join:** `attendance` → `teaching_schedules` (via `schedule_id`) → `teaching_assignments` (via `assignment_id`)

**Analisis QUAL (READ):**  
Guard `attendance.school_id = fn_current_school_id()` adalah kondisi pertama dan eksplisit. Hanya baris absensi milik sekolah guru yang dievaluasi. Subquery EXISTS ke `teaching_schedules` dijalankan dengan RLS aktif: `rls_schedules_read_staff` mensyaratkan `ts.school_id = fn_current_school_id()`, sehingga guru tidak bisa "melihat" schedule sekolah lain di dalam subquery. `teaching_assignments` juga memiliki RLS (`rls_assignments_read_all_staff`) yang mensyaratkan `ta.school_id = fn_current_school_id()`.

**Analisis WITH CHECK (WRITE):**  
WITH CHECK identik dengan QUAL — tidak ada asimetri. Skenario INSERT/UPDATE berbahaya:

*Percobaan:* Guru sekolah A mencoba INSERT `attendance` dengan `school_id = sekolah_A` (lolos cek pertama) dan `schedule_id = <UUID jadwal sekolah B>`.

Evaluasi WITH CHECK:
1. `school_id = fn_current_school_id()` → lolos (guru memset `school_id = sekolah_A`)
2. EXISTS ke `teaching_schedules ts WHERE ts.schedule_id = <UUID sekolah B>`:  
   — RLS `rls_schedules_read_staff` pada `teaching_schedules` membatasi ke `ts.school_id = fn_current_school_id()` (= sekolah A)  
   — UUID jadwal sekolah B memiliki `ts.school_id = sekolah_B` → **tidak terlihat** oleh guru sekolah A  
   — EXISTS mengembalikan false → INSERT ditolak

Guru tidak dapat memalsukan `schedule_id` lintas-sekolah karena RLS pada `teaching_schedules` memblokir referensi ke jadwal luar.

**Jaminan implisit tambahan:** `attendance.schedule_id` adalah FK ke `teaching_schedules.schedule_id`. FK constraint tidak bisa dieksploitasi untuk cross-school write karena FK hanya memvalidasi keberadaan baris, bukan kepemilikan sekolah — tetapi eksploitasi tetap gagal di WITH CHECK EXISTS sebelum FK-check berjalan.

**Status: 🟢 AMAN** — guard eksplisit terdepan + RLS implisit dua lapisan (teaching_schedules + teaching_assignments); QUAL = WITH CHECK (tidak ada asimetri baca vs tulis).

---

### 2. `rls_attendance_rw_substitute` — FOR ALL

**QUAL (lengkap, dari `pg_policies` live):**
```sql
(school_id = fn_current_school_id())
AND (EXISTS (
  SELECT 1 FROM substitute_schedules ss
  WHERE ss.schedule_id = attendance.schedule_id
    AND ss.substitute_user_id = fn_current_user_id()
    AND ss.sync_token_expires_at > now()
))
```

**WITH CHECK:** identik dengan QUAL di atas.

**Rantai join:** `attendance` → `substitute_schedules` (via `schedule_id`)

**Analisis QUAL (READ):**  
Guard `attendance.school_id = fn_current_school_id()` eksplisit sebagai kondisi pertama. Subquery EXISTS ke `substitute_schedules` difilter oleh RLS `rls_substitute_read_own`: `ss.school_id = fn_current_school_id() AND ss.substitute_user_id = fn_current_user_id()`. Guard waktu `ss.sync_token_expires_at > now()` adalah lapisan keamanan aktif yang menghalangi akses setelah sesi penggantian berakhir.

**Analisis WITH CHECK (WRITE):**  
WITH CHECK identik dengan QUAL.

*Percobaan:* Substitute sekolah A mencoba INSERT dengan `school_id = sekolah_A` dan `schedule_id = <UUID jadwal sekolah B>`.

Evaluasi:
1. `school_id = fn_current_school_id()` → lolos
2. EXISTS ke `substitute_schedules ss WHERE ss.schedule_id = <UUID sekolah B>`:  
   — RLS `rls_substitute_read_own` membatasi ke `ss.school_id = fn_current_school_id()` (sekolah A)  
   — Entri `substitute_schedules` untuk jadwal sekolah B memiliki `ss.school_id = sekolah_B` → **tidak terlihat**  
   — EXISTS false → INSERT ditolak

**Catatan khusus `sync_token_expires_at`:** Substitute mendapat akses menulis absensi hanya selama token aktif (terikat waktu). Ini lebih ketat dari `rls_attendance_rw_guru` karena ada lapisan tambahan temporal — bahkan jika ada anomali data, akses substitute berakhir otomatis.

**Status: 🟢 AMAN** — guard eksplisit terdepan + RLS implisit `substitute_schedules` + guard waktu; QUAL = WITH CHECK (tidak ada asimetri).

---

### 3. `rls_schedules_read_student` — SELECT

**QUAL (lengkap, dari `pg_policies` live):**
```sql
(school_id = fn_current_school_id())
AND (fn_current_user_role() = 'SISWA')
AND (EXISTS (
  SELECT 1 FROM class_enrollments ce
  WHERE ce.class_id = teaching_schedules.class_id
    AND ce.student_id = fn_current_student_id()
    AND ce.withdrawn_at IS NULL
))
```

**WITH CHECK:** `NULL` (SELECT only — tidak ada operasi tulis).

**Rantai join:** `teaching_schedules` → `class_enrollments` (via `class_id`)

**Mengapa 🟡:**  
Struktur ini identik dengan `rls_schedules_read_parent` **sebelum** commit 524d97f. Subquery EXISTS ke `class_enrollments` tidak menyertakan `ce.school_id = fn_current_school_id()` secara eksplisit. Satu-satunya filter di dalam subquery adalah `ce.class_id` (match ke jadwal), `ce.student_id` (via `fn_current_student_id()`), dan `ce.withdrawn_at IS NULL`.

Sebagai perbandingan, `rls_schedules_read_parent` yang sudah diperkuat (live saat ini) menggunakan:
```sql
-- rls_schedules_read_parent (setelah commit 524d97f) — versi DIPERKUAT:
...AND (ce.school_id = fn_current_school_id())...   -- ← eksplisit, tidak ada di versi siswa
```

Versi siswa tidak mendapat perkuatan yang sama.

**Mekanisme implisit yang menjamin keamanan saat ini:**

1. **`teaching_schedules.school_id = fn_current_school_id()`** — guard terdepan dan eksplisit. Hanya jadwal milik sekolah siswa yang dipertimbangkan.
2. **RLS `class_enrollments` (berbagai policy `rls_enrollments_*`)** — semua mensyaratkan `school_id = fn_current_school_id()`. Diterapkan implisit saat EXISTS mengevaluasi `class_enrollments`.
3. **`class_id` adalah UUID globally unique** — tidak ada dua sekolah berbeda yang dapat memiliki `class_id` yang sama.
4. **`fn_current_student_id()`** — mengembalikan `student_id` yang terikat ke satu siswa tertentu (tidak lintas-sekolah dalam kondisi normal).

**Skenario eksploitasi teoritis:**  
Jika RLS `class_enrollments` tidak diterapkan dalam EXISTS (misal bug PostgreSQL yang tidak dikenal, atau eksekusi via SECURITY DEFINER yang memanggil policy ini): siswa S di sekolah A bisa melihat `teaching_schedules` sekolah A yang `class_id`-nya kebetulan cocok dengan `class_enrollments` siswa di sekolah B. Dalam kondisi normal ini tidak mungkin karena `class_id` adalah UUID unik global. Namun, berbeda dari kasus `rls_schedules_read_parent` yang sudah diperkuat, policy ini masih bergantung sepenuhnya pada jaminan implisit.

**Skenario yang perlu dipantau:** Import massal `class_enrollments` yang keliru memasukkan `class_id` dari sekolah yang salah (mirip akar masalah `pkl_*` di Fase 2.1). Jika siswa A ter-enroll di kelas sekolah B (karena import salah), siswa A bisa melihat jadwal kelas sekolah B — meski tetap dibatasi pada jadwal sekolah siswa sendiri (tidak lintas-tenant murni, tapi masih bocor antara kelas dalam sekolah).

**Asimetri dengan policy ORTU (kritis untuk dicatat):**  
`rls_schedules_read_parent` (akses ORTU) telah diperkuat dengan `ce.school_id = fn_current_school_id()` eksplisit, tetapi `rls_schedules_read_student` (akses SISWA) belum. Kedua policy mengakses tabel `teaching_schedules` dengan pola join yang sama ke `class_enrollments`. Asimetri ini mengindikasikan bahwa perkuatan Kelompok A (commit 524d97f) tidak diterapkan secara simetris ke policy SISWA.

**Status: 🟡 PERLU VERIFIKASI** — aman secara praktis karena UUID + RLS implisit `class_enrollments`, tetapi bergantung pada jaminan implisit tanpa `ce.school_id` eksplisit di subquery, sementara policy ORTU yang setara sudah diperkuat.

---

## Analisis Struktural: Perbandingan Kelompok B vs Kelompok A dan pkl_*

| Aspek | `pkl_*` (Fase 2.1 — bercelah) | Kelompok A (Fase 2.2 — aman) | Kelompok B #1/#2 (FOR ALL — aman) | Kelompok B #3 (SELECT — 🟡) |
|-------|------|------|------|------|
| Guard `school_id` tabel utama | **Tidak ada** | **Eksplisit, kondisi pertama** | **Eksplisit, kondisi pertama** | **Eksplisit, kondisi pertama** |
| Guard `school_id` di subquery | Satu-satunya perlindungan (via join) | Implisit via RLS tabel join | Implisit via RLS tabel join | **Tidak ada** |
| Operasi tulis (FOR ALL) | Tidak berlaku | Tidak berlaku | Ada — QUAL=WITH CHECK (tidak ada asimetri) | Tidak berlaku (SELECT only) |
| Risiko cross-tenant aktual | **🔴 Terbukti** | 🟢 Tidak ada | 🟢 Tidak ada | 🟡 Tidak ada saat ini |
| Risiko import massal keliru | Kritis | Rendah | Rendah | Sedang |

---

## Anomali Data Existing

**Query yang dijalankan (read-only):**
```sql
-- Anomali: teaching_assignments lintas-sekolah (ta.school_id ≠ user.school_id)
SELECT COUNT(*) FROM teaching_assignments ta
JOIN users u ON u.user_id = ta.user_id
WHERE ta.school_id != u.school_id;

-- Anomali: substitute_schedules lintas-sekolah (ss.school_id ≠ user.school_id)
SELECT COUNT(*) FROM substitute_schedules ss
JOIN users u ON u.user_id = ss.substitute_user_id
WHERE ss.school_id != u.school_id;

-- Anomali: ta.school_id ≠ ts.school_id (assignment dan jadwal beda sekolah)
SELECT COUNT(*) FROM teaching_assignments ta
JOIN teaching_schedules ts ON ts.assignment_id = ta.assignment_id
WHERE ta.school_id != ts.school_id;

-- Anomali: ss.school_id ≠ ts.school_id (substitute dan jadwal beda sekolah)
SELECT COUNT(*) FROM substitute_schedules ss
JOIN teaching_schedules ts ON ts.schedule_id = ss.schedule_id
WHERE ss.school_id != ts.school_id;
```

**Hasil:**

| Pemeriksaan | Hasil |
|-------------|-------|
| `teaching_assignments` cross-school (ta.school_id ≠ user.school_id) | **0** |
| `substitute_schedules` cross-school (ss.school_id ≠ user.school_id) | **0** |
| assignment ≠ jadwal (ta.school_id ≠ ts.school_id) | **0** |
| substitute ≠ jadwal (ss.school_id ≠ ts.school_id) | **0** |
| Total `teaching_assignments` | **742** |
| Total `substitute_schedules` | **0** (belum ada data ganti mengajar) |
| Total `teaching_schedules` | **50.723** |

**Kesimpulan:** Tidak ada anomali data yang saat ini mengancam isolasi tenant. Semua 742 entri `teaching_assignments` konsisten: `ta.school_id = users.school_id = teaching_schedules.school_id`. `substitute_schedules` masih kosong (0 baris) — fitur belum pernah dipakai, sehingga tidak ada risiko historical.

**Catatan penting tentang `substitute_schedules = 0`:** Karena belum ada data substitute, policy `rls_attendance_rw_substitute` belum pernah dieksekusi dalam kondisi nyata. Ketika fitur ganti mengajar mulai dipakai, integritas `ss.school_id` perlu diverifikasi (apakah trigger `trg_auto_school_id` menginherit `school_id` dari `teaching_schedules` atau dari `users` penugasnya).

---

## Rekomendasi Pasca-Audit (Opsional, bukan bagian dari tugas ini)

1. **`rls_schedules_read_student` (#3):** Tambahkan `ce.school_id = fn_current_school_id()` eksplisit di dalam subquery EXISTS, simetris dengan perkuatan yang sudah diterapkan pada `rls_schedules_read_parent` (commit 524d97f). Ini mengubah status dari 🟡 ke 🟢 dan menghilangkan asimetri perlindungan antara akses SISWA dan akses ORTU.

2. **Monitor `substitute_schedules` saat go-live:** Saat fitur ganti mengajar pertama kali dipakai, verifikasi bahwa `ss.school_id` ter-inherit dengan benar dari `teaching_schedules` (bukan dari penugasnya). Tambahkan CHECK constraint atau trigger jika belum ada.

3. **`rls_attendance_rw_guru` — kelengkapan cek `ts.school_id`:** Walaupun RLS implisit sudah melindungi, pertimbangkan menambahkan `ts.school_id = fn_current_school_id()` eksplisit di subquery EXISTS sebagai defense-in-depth (konsistensi pola dengan policy lain yang sudah eksplisit).

---

## Ringkasan Status Kelompok B

| Policy | Status | Kelas Risiko | Prioritas Perbaikan |
|--------|--------|--------------|---------------------|
| `rls_attendance_rw_guru` | 🟢 AMAN | — | Tidak perlu |
| `rls_attendance_rw_substitute` | 🟢 AMAN | — | Monitor saat go-live |
| `rls_schedules_read_student` | 🟡 PERLU VERIFIKASI | READ only, tidak ada WRITE | Rendah-Sedang (simetriskan dengan versi ORTU) |

**Perbandingan dengan Kelompok A:** Kelompok B memiliki profil risiko lebih baik dari Kelompok A untuk policy FOR ALL karena `rls_attendance_rw_*` menempatkan guard eksplisit SEKALIGUS memiliki QUAL = WITH CHECK (tidak ada asimetri baca vs tulis). Satu-satunya 🟡 di Kelompok B (policy SELECT saja) justru lebih rendah risikonya dari 🟡 di Kelompok A yang melibatkan JOIN dua tabel tanpa satu pun `school_id` eksplisit di subquery.

---

*Laporan ini bersifat read-only. Tidak ada migration atau perubahan skema yang dibuat.*
