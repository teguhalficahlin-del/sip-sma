# Audit Fase 2.2 — Kelompok A: Join `student_parents`

**Tanggal audit:** 2026-07-06  
**Auditor:** Claude Code (read-only, tidak ada perubahan skema)  
**Metodologi:** Definisi policy diambil langsung dari `pg_policies` live; skema dan data diambil dari Supabase Management API.

---

## Ringkasan Eksekutif

Seluruh 7 policy di Kelompok A **tidak memiliki celah cross-tenant** yang analog dengan temuan fase 2.1 (`pkl_*`). Perbedaan fundamental dengan `pkl_*`: semua policy ini meletakkan kondisi `primary_table.school_id = fn_current_school_id()` sebagai **guard terdepan dan eksplisit** pada tabel utama yang diakses, sehingga ortu tidak pernah bisa melihat data dari sekolah B — bahkan andaikan ada entri `student_parents` lintas-sekolah. Pada `pkl_*`, guard semacam ini tidak ada; satu-satunya batasan sekolah datang dari join ke `student_parents` itu sendiri, yang membuat celah terbuka.

---

## Tabel Hasil Audit

| # | Policy | Tabel Utama | Rantai Join | Jaminan `school_id` | Status | Skenario Eksploitasi |
|---|--------|-------------|-------------|---------------------|--------|----------------------|
| 1 | `rls_attendance_read_parent` | `attendance` | `attendance` → `student_parents` (1-hop) | Eksplisit: `attendance.school_id = fn_current_school_id()` + implisit: RLS `student_parents` juga mensyaratkan `school_id = fn_current_school_id()` | 🟢 AMAN | — |
| 2 | `rls_case_events_read_parent` | `case_events` | `case_events` → `cases` → `student_parents` (2-hop) | Eksplisit: `case_events.school_id = fn_current_school_id()`. `cases` di subquery punya RLS sendiri dengan guard yang sama | 🟢 AMAN | — |
| 3 | `rls_cases_read_parent` | `cases` | `cases` → `student_parents` (1-hop) | Eksplisit: `cases.school_id = fn_current_school_id()` + implisit: RLS `student_parents` | 🟢 AMAN | — |
| 4 | `rls_enrollments_read_parent` | `class_enrollments` | `class_enrollments` → `student_parents` (1-hop) | Eksplisit: `class_enrollments.school_id = fn_current_school_id()` + implisit: RLS `student_parents` | 🟢 AMAN | — |
| 5 | `rls_student_updates_read_student` | `student_updates` | `student_updates` → `cases` → `students` (tidak lewat `student_parents`) | Eksplisit: `student_updates.school_id = fn_current_school_id()`. Tidak ada join `student_parents` sama sekali | 🟢 AMAN | — |
| 6 | `rls_students_read_parent` | `students` | `students` → `student_parents` (1-hop) | Eksplisit: `students.school_id = fn_current_school_id()` + implisit: RLS `student_parents` | 🟢 AMAN | — |
| 7 | `rls_schedules_read_parent` | `teaching_schedules` | `teaching_schedules` → `class_enrollments` → `student_parents` (2-hop, tanpa filter `school_id` eksplisit pada `class_enrollments` di subquery) | Eksplisit: `teaching_schedules.school_id = fn_current_school_id()`. Implisit dua lapis: RLS `class_enrollments` + RLS `student_parents`, keduanya mensyaratkan `school_id = fn_current_school_id()` | 🟡 PERLU VERIFIKASI | Lihat §7 |

---

## Analisis Per Policy

### 1. `attendance.rls_attendance_read_parent`

**Qual lengkap:**
```sql
(school_id = fn_current_school_id())
AND (fn_current_user_role() = 'ORTU')
AND (is_void = false)
AND (EXISTS (
  SELECT 1 FROM student_parents sp
  WHERE sp.student_id = attendance.student_id
    AND sp.parent_user_id = fn_current_user_id()
))
```

**Rantai join:** `attendance` → `student_parents`  
**Analisis:**  
Guard `attendance.school_id = fn_current_school_id()` adalah kondisi pertama. Ini berarti hanya baris absensi milik sekolah ortu yang lolos ke evaluasi EXISTS. Walaupun `student_parents` dalam subquery tidak disertai filter `sp.school_id = ...` secara eksplisit, **dua lapisan jaminan implisit berlaku**:

1. **RLS `student_parents` (policy `rls_student_parents_read_own`)** mensyaratkan `school_id = fn_current_school_id() AND parent_user_id = fn_current_user_id()`. PostgreSQL menerapkan RLS tabel yang direferensikan dalam subquery EXISTS, sehingga subquery ini hanya "melihat" baris `student_parents` milik sekolah ortu saat ini.
2. **`student_parents.school_id` selalu = `students.school_id`** (diwariskan oleh trigger `trg_auto_school_id` via `SELECT school_id FROM students WHERE student_id = NEW.student_id`).

Andaikan ada entri `student_parents` lintas-sekolah (ortu A dikaitkan dengan siswa sekolah B), `attendance.school_id = sekolah_A` tetap menjadi filter pertama: `attendance` untuk siswa sekolah B akan memiliki `school_id = sekolah_B`, bukan `sekolah_A`, sehingga baris itu tidak pernah lolos.

**Status: 🟢 AMAN**

---

### 2. `case_events.rls_case_events_read_parent`

**Qual lengkap:**
```sql
(school_id = fn_current_school_id())
AND (fn_current_user_role() = 'ORTU')
AND (privacy_level = 'STUDENT_VISIBLE')
AND (EXISTS (
  SELECT 1 FROM cases c
  WHERE c.case_id = case_events.case_id
    AND c.audience = 'RESTRICTED'
    AND (EXISTS (
      SELECT 1 FROM student_parents sp
      WHERE sp.student_id = c.student_id
        AND sp.parent_user_id = fn_current_user_id()
    ))
))
```

**Rantai join:** `case_events` → `cases` → `student_parents`  
**Analisis:**  
Guard `case_events.school_id = fn_current_school_id()` adalah filter terdepan. JOIN ke `cases` via `c.case_id = case_events.case_id` mengunci ke kasus yang sama dengan event. `cases` memiliki RLS sendiri (`rls_cases_read_parent` dan `rls_cases_read_staff`) yang semuanya mensyaratkan `cases.school_id = fn_current_school_id()` — diterapkan implisit ketika subquery EXISTS dieksekusi.

Walaupun tidak ada `c.school_id = fn_current_school_id()` eksplisit di dalam subquery, RLS `cases` memblokir tampilnya kasus sekolah lain. Ditambah `student_parents` RLS sebagai lapisan ketiga.

**Status: 🟢 AMAN**

---

### 3. `cases.rls_cases_read_parent`

**Qual lengkap:**
```sql
(school_id = fn_current_school_id())
AND (fn_current_user_role() = 'ORTU')
AND (audience = 'RESTRICTED')
AND (EXISTS (
  SELECT 1 FROM student_parents sp
  WHERE sp.student_id = cases.student_id
    AND sp.parent_user_id = fn_current_user_id()
))
```

**Rantai join:** `cases` → `student_parents`  
**Analisis:** Pola 1-hop paling sederhana. Guard `cases.school_id = fn_current_school_id()` eksplisit. RLS `student_parents` implisit sebagai lapisan kedua. Identik dengan pola policies AMAN yang sudah diverifikasi.

**Status: 🟢 AMAN**

---

### 4. `rls_enrollments_read_parent`

**Qual lengkap:**
```sql
(school_id = fn_current_school_id())
AND (fn_current_user_role() = 'ORTU')
AND (EXISTS (
  SELECT 1 FROM student_parents sp
  WHERE sp.student_id = class_enrollments.student_id
    AND sp.parent_user_id = fn_current_user_id()
))
```

**Rantai join:** `class_enrollments` → `student_parents`  
**Analisis:** Pola 1-hop, identik dengan #3. Guard eksplisit + RLS `student_parents` implisit.

**Status: 🟢 AMAN**

---

### 5. `rls_student_updates_read_student`

**Qual lengkap:**
```sql
(school_id = fn_current_school_id())
AND (fn_current_user_role() = 'SISWA')
AND (EXISTS (
  SELECT 1 FROM cases c
  WHERE c.case_id = student_updates.case_id
    AND c.student_id = (
      SELECT s.student_id FROM students s
      WHERE s.user_id = fn_current_user_id()
    )
))
```

**Rantai join:** `student_updates` → `cases` → `students`  
**Analisis:** Policy ini untuk **SISWA**, bukan ORTU — tidak melibatkan `student_parents` sama sekali. Guard `student_updates.school_id = fn_current_school_id()` eksplisit. Subquery `SELECT s.student_id FROM students s WHERE s.user_id = fn_current_user_id()` tidak difilter school_id, tetapi:

- Hasilnya digunakan sebagai nilai pembanding di `c.student_id = ...`
- Baris `student_updates` yang lolos hanya yang `school_id` = sekolah siswa saat ini
- Jika secara anomali satu `user_id` terkait dengan dua `student_id` dari sekolah berbeda, subquery mengembalikan keduanya; namun `student_updates.school_id = fn_current_school_id()` tetap memblokir baris sekolah lain
- Data aktual: tidak ada duplikasi `user_id` lintas-sekolah (verifikasi terpisah di data `students`)

**Status: 🟢 AMAN**

---

### 6. `rls_students_read_parent`

**Qual lengkap:**
```sql
(school_id = fn_current_school_id())
AND (fn_current_user_role() = 'ORTU')
AND (EXISTS (
  SELECT 1 FROM student_parents sp
  WHERE sp.student_id = students.student_id
    AND sp.parent_user_id = fn_current_user_id()
))
```

**Rantai join:** `students` → `student_parents`  
**Analisis:** Guard `students.school_id = fn_current_school_id()` eksplisit + RLS `student_parents` implisit. Pola 1-hop standar.

**Status: 🟢 AMAN**

---

### 7. `rls_schedules_read_parent` ← Satu-satunya 🟡

**Qual lengkap:**
```sql
(school_id = fn_current_school_id())
AND (fn_current_user_role() = 'ORTU')
AND (EXISTS (
  SELECT 1
  FROM class_enrollments ce
  JOIN student_parents sp ON sp.student_id = ce.student_id
  WHERE ce.class_id = teaching_schedules.class_id
    AND ce.withdrawn_at IS NULL
    AND sp.parent_user_id = fn_current_user_id()
))
```

**Rantai join:** `teaching_schedules` → `class_enrollments` → `student_parents` (2-hop, JOIN dalam satu EXISTS)  

**Mengapa 🟡:**  
Subquery EXISTS me-JOIN `class_enrollments` dan `student_parents` tanpa filter `school_id` eksplisit di kedua tabel itu. Tidak ada `ce.school_id = fn_current_school_id()` atau `sp.school_id = fn_current_school_id()` yang tertulis dalam query.

**Mekanisme implisit yang menjamin keamanan:**

1. **`teaching_schedules.school_id = fn_current_school_id()`** — guard terdepan dan eksplisit. Hanya jadwal milik sekolah ortu yang dipertimbangkan.
2. **RLS `class_enrollments` (`rls_enrollments_read_parent`)** — mensyaratkan `class_enrollments.school_id = fn_current_school_id()`. Diterapkan implisit oleh PostgreSQL saat EXISTS mengevaluasi `class_enrollments`.
3. **RLS `student_parents` (`rls_student_parents_read_own`)** — mensyaratkan `school_id = fn_current_school_id() AND parent_user_id = fn_current_user_id()`. Diterapkan implisit pada JOIN.
4. **`class_id` adalah UUID globally unique** — tidak ada risiko `class_id` yang sama dipakai oleh dua sekolah berbeda.

**Constraint spesifik yang menjamin jaminan implisit:**
- `teaching_schedules` dan `class_enrollments` keduanya memiliki FK ke `classes(class_id)`, dan `classes.school_id` selalu konsisten
- Trigger `trg_auto_school_id` pada `class_enrollments` menurunkan `school_id` dari `classes WHERE class_id = NEW.class_id`, sehingga `class_enrollments.school_id` selalu = sekolah kelas tersebut

**Skenario eksploitasi teoritis (andaikan mekanisme implisit gagal):**  
Jika RLS `class_enrollments` tidak diterapkan dalam EXISTS subquery (misal karena eksekusi lewat SECURITY DEFINER function yang memanggil policy ini): ortu O di sekolah A bisa melihat `teaching_schedules` sekolah A yang `class_id`-nya kebetulan cocok dengan `class_enrollments` milik siswa sekolah B — **tetapi kondisi ini tidak mungkin terjadi** karena `class_id` adalah UUID yang tidak di-share antar sekolah.

**Skenario yang sebenarnya perlu dipantau:** Import massal `class_enrollments` oleh TU yang secara keliru memasukkan `class_id` dari sekolah yang salah (mirip akar masalah pkl_*). Jika ini terjadi, ortu bisa melihat jadwal kelas yang bukan milik anaknya — meski tetap dibatasi pada sekolah ortu sendiri (tidak lintas-tenant).

**Status: 🟡 PERLU VERIFIKASI** — aman secara praktis, tapi mengandalkan RLS implisit dua tabel sekaligus tanpa satu pun `school_id` eksplisit di dalam subquery.

---

## Analisis Struktural: Mengapa Berbeda dari pkl_*

| Aspek | pkl_* (Fase 2.1 — bercelah) | Kelompok A (Fase 2.2 — aman) |
|-------|----|----|
| Guard `school_id` pada tabel utama | **Tidak ada** atau berasal dari join `student_parents` | **Ada eksplisit**: `primary_table.school_id = fn_current_school_id()` sebagai kondisi pertama |
| Akibat entri `student_parents` lintas-sekolah | Ortu A bisa melihat data sekolah B milik siswa yang dikaitkan lintas-sekolah | Tidak berdampak: data sekolah B tetap diblokir oleh guard tabel utama |
| Lapisan pertahanan | 1 lapis (via student_parents join saja) | 2–3 lapis (tabel utama + RLS student_parents + RLS tabel perantara) |

---

## Anomali Data Existing

**Query yang dijalankan:**
```sql
-- Anomali cross-school di student_parents (parent school ≠ student school)
SELECT COUNT(*) as count_anomali,
  COUNT(DISTINCT sp.parent_user_id) as distinct_parents,
  COUNT(DISTINCT sp.student_id) as distinct_students
FROM student_parents sp
JOIN students s ON s.student_id = sp.student_id
JOIN users u ON u.user_id = sp.parent_user_id
WHERE s.school_id != u.school_id;
```

**Hasil:**

| Metrik | Nilai |
|--------|-------|
| Total baris `student_parents` | **2.235** |
| Anomali cross-school (parent.school ≠ student.school) | **0** |
| Anomali cross-school (sp.school_id ≠ student.school_id) | **0** |
| Anomali cross-school (sp.school_id ≠ parent.school_id) | **0** |
| Duplikasi (student_id, parent_user_id) lintas-sekolah | **0** |

**Kesimpulan:** Tidak ada anomali data yang saat ini mengancam isolasi tenant. Semua 2.235 baris `student_parents` konsisten: `sp.school_id = students.school_id = users.school_id`.

**Catatan tentang trigger `trg_auto_school_id`:** Saat INSERT ke `student_parents`, jika `school_id` tidak diisi eksplisit, trigger menurunkannya dari `students.school_id` (bukan dari `users.school_id` ortu). Artinya `student_parents.school_id` selalu mengikuti sekolah **siswa**, bukan sekolah ortu. Ini relevan: jika TU secara keliru mengimpor relasi ortu-siswa lintas-sekolah, `school_id` akan mengikuti sekolah siswa, bukan sekolah ortu — dan RLS `student_parents` (`school_id = fn_current_school_id()`) akan memblokir ortu dari melihat relasi itu di sekolah mereka sendiri.

---

## Rekomendasi Pasca-Audit (Opsional, bukan bagian dari tugas ini)

1. **`rls_schedules_read_parent` (#7):** Tambahkan `ce.school_id = fn_current_school_id()` eksplisit di dalam subquery EXISTS, untuk menghilangkan ketergantungan pada RLS implisit `class_enrollments`. Ini mengubah status dari 🟡 ke 🟢 dan melindungi dari skenario import massal yang keliru.

2. **Unique constraint `student_parents`:** `UNIQUE (student_id, parent_user_id)` tanpa `school_id` adalah desain yang tepat (satu pasang ortu-siswa hanya boleh ada satu kali secara global). Tidak perlu diubah.

3. **Monitor trigger `trg_auto_school_id`:** Pastikan TU tidak pernah INSERT `student_parents` dengan `student_id` dari sekolah berbeda — prosedur import massal perlu memvalidasi bahwa student_id yang di-link memang milik sekolah yang sedang aktif.

---

*Laporan ini bersifat read-only. Tidak ada migration atau perubahan skema yang dibuat.*
