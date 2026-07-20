# Audit Fase 2.2 — Kelompok C: Join via Fungsi / Kondisi Khusus Siswa

**Tanggal audit:** 2026-07-07  
**Auditor:** Claude Code (read-only, tidak ada perubahan skema)  
**Metodologi:** Definisi policy diambil dari `pg_policies` live; definisi fungsi dari `pg_get_functiondef`; constraint dan trigger dari `pg_constraint` + `pg_trigger`; anomali data dari COUNT query read-only.

---

## Ringkasan Eksekutif

Kelompok C mengandung **satu temuan 🔴 CELAH** yang secara kelas risiko lebih tinggi dari semua temuan di Kelompok A dan B — bukan kebocoran READ, melainkan **kontaminasi WRITE lintas-tenant**: policy `rls_cases_insert` memungkinkan staff di sekolah A membuat kasus dengan `school_id = sekolah_A` tetapi `student_id` menunjuk ke siswa dari sekolah B. Celah ini terbuka karena kondisi `NOT fn_student_is_on_pkl(student_id)` secara tidak sengaja memberikan jaminan palsu — fungsi itu mengembalikan `false` untuk siswa sekolah B (tidak ada PKL di sekolah A), sehingga kondisi "boleh INSERT" lolos. Tidak ada constraint di level DB yang memvalidasi `cases.school_id = students.school_id`.

Efek samping: trigger `trg_notify_case_created` akan mengirimkan notifikasi ke siswa dan orang tua dari sekolah B atas kasus yang dibuat di sekolah A — ini adalah **side-channel lintas-tenant** via notification.

Dua policy lainnya aman (satu 🟢, satu 🟡 struktural).

Exploit belum pernah terjadi: 0 dari 3 baris `cases` existing menunjukkan cross-school contamination.

---

## Tabel Hasil Audit

| # | Policy | Tabel | CMD | Guard `school_id` | Pola Fungsi/Kondisi | Status | Risiko |
|---|--------|-------|-----|-------------------|---------------------|--------|--------|
| 1 | `rls_case_events_read_student` | `case_events` | SELECT | **Eksplisit**: `case_events.school_id = fn_current_school_id()` | Subquery ke `cases` + inline student lookup | 🟢 AMAN | — |
| 2 | `rls_cases_insert` | `cases` | INSERT | Eksplisit pada `school_id` (WITH CHECK), tetapi **tanpa validasi `student_id ↔ school_id`** | `fn_student_is_on_pkl` SECURITY DEFINER — aman internal, tapi WITH CHECK tidak menutup insert student lintas-tenant | 🔴 CELAH | **WRITE contamination + notifikasi side-channel** |
| 3 | `rls_pkl_attendance_read_kaprodi` | `pkl_attendance` | SELECT | **Eksplisit**: `pkl_attendance.school_id = fn_current_school_id()` | Subquery ke `students` via `fn_kaprodi_program_id()` tanpa `s.school_id` eksplisit | 🟡 PERLU VERIFIKASI | Rendah (program_id UUID unik, implisit aman) |

---

## Analisis Per Policy

### 1. `rls_case_events_read_student` — SELECT

**QUAL (lengkap, dari `pg_policies` live):**
```sql
(school_id = fn_current_school_id())
AND (fn_current_user_role() = 'SISWA')
AND (privacy_level = 'STUDENT_VISIBLE')
AND (EXISTS (
  SELECT 1 FROM cases c
  WHERE c.case_id = case_events.case_id
    AND c.student_id = (
      SELECT s.student_id FROM students s
      WHERE s.user_id = fn_current_user_id()
    )
))
```

**WITH CHECK:** `NULL` (SELECT only).

**Rantai join:** `case_events` → `cases` → `students` (inline scalar subquery)

**Analisis:**  
Guard `case_events.school_id = fn_current_school_id()` adalah kondisi pertama dan eksplisit — identik dengan pola AMAN di Kelompok A/B. Siswa hanya melihat event sekolahnya sendiri.

Subquery `SELECT s.student_id FROM students s WHERE s.user_id = fn_current_user_id()` tidak menyertakan filter `school_id`. Jika secara anomali satu `user_id` terhubung ke dua baris `students` dari sekolah berbeda (mustinya tidak mungkin karena constraint `UNIQUE(user_id)` di `students`), subquery scalar ini akan melempar error "more than one row returned" — bukan kebocoran data. Dalam kondisi normal (1 user = 1 student), ini sepenuhnya aman.

Akses ke `cases` dalam EXISTS: RLS `cases` mensyaratkan `school_id = fn_current_school_id()`, diterapkan implisit oleh PostgreSQL saat subquery dieksekusi.

**Status: 🟢 AMAN** — guard eksplisit terdepan; tidak ada jalur cross-tenant; SELECT only.

---

### 2. `rls_cases_insert` — INSERT (WITH CHECK saja, QUAL=null) ← 🔴 CELAH

**WITH CHECK (lengkap, dari `pg_policies` live):**
```sql
(school_id = fn_current_school_id())
AND (
  (fn_current_user_role() = 'DUDI')
  OR (
    fn_current_user_role() = ANY (ARRAY['GURU','BK','WALI_KELAS','KAPRODI',
                                        'KEPSEK','WAKA_KESISWAAN','WAKA_HUMAS'])
    AND NOT fn_student_is_on_pkl(student_id)
  )
  OR (fn_is_bk()            AND NOT fn_student_is_on_pkl(student_id))
  OR (fn_is_kepsek()        AND NOT fn_student_is_on_pkl(student_id))
  OR (fn_is_waka_kesiswaan() AND NOT fn_student_is_on_pkl(student_id))
)
```

**QUAL:** `NULL` (INSERT-only policy — tidak ada filter baca).

#### Definisi `fn_student_is_on_pkl` (dari `pg_proc` live):

```sql
CREATE OR REPLACE FUNCTION public.fn_student_is_on_pkl(p_student_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM pkl_placements pp
    WHERE pp.student_id = p_student_id
      AND pp.school_id  = fn_current_school_id()   -- ← filter school_id ada di sini
      AND pp.start_date <= CURRENT_DATE
      AND (pp.end_date IS NULL OR pp.end_date >= CURRENT_DATE)
  );
$$;
```

**Apakah fungsi ini aman secara internal?** Ya — fungsi ini memang SECURITY DEFINER (melewati RLS `pkl_placements`), tetapi memiliki `pp.school_id = fn_current_school_id()` yang eksplisit. Artinya: ia hanya mengecek apakah siswa tersebut *sedang PKL di sekolah pemanggil saat ini*, bukan di mana pun.

**Mengapa WITH CHECK tetap bercelah?**

Fungsi ini dirancang untuk menjawab pertanyaan: *"apakah siswa X sedang PKL?"* Tapi ia dipakai dalam konteks yang lebih luas di WITH CHECK: kondisi `NOT fn_student_is_on_pkl(student_id)` bertujuan memblokir INSERT kasus untuk siswa yang sedang PKL (karena track PKL ditangani jalur berbeda). Efek sampingnya: untuk `student_id` dari sekolah lain, fungsi selalu mengembalikan `false` (tidak ada PKL di sekolah pemanggil), sehingga `NOT fn_student_is_on_pkl(student_id)` selalu `true` — membuka insert.

**Skenario eksploitasi konkret (WRITE contamination):**

Prasyarat: Staff GURU di sekolah A mengetahui UUID milik siswa sekolah B (`student_B_UUID`).

```sql
-- Payload INSERT yang melewati semua pemeriksaan WITH CHECK:
INSERT INTO cases (
  school_id,           -- = fn_current_school_id() (sekolah A) ← lolos kondisi 1
  student_id,          -- = student_B_UUID (siswa sekolah B!) ← tidak ada validasi ini
  title, description,
  track, audience,
  created_by_user_id,
  initiated_by_role,
  current_handler_role
)
VALUES (
  '<school_A_UUID>',   -- eksplisit, trigger trg_auto_school_id tidak override (NOT NULL)
  '<student_B_UUID>',
  'Judul kasus', 'Deskripsi kasus minimal dua puluh karakter.',
  'UMUM', 'RESTRICTED',
  '<guru_A_user_id>',
  'GURU',
  'GURU'
);
```

Evaluasi WITH CHECK langkah per langkah:
1. `school_id = fn_current_school_id()` → `school_A = school_A` ✅
2. `fn_current_user_role() = ANY (ARRAY['GURU',...])` → `'GURU' = 'GURU'` ✅
3. `NOT fn_student_is_on_pkl(student_B_UUID)`:
   - Fungsi mencari `pkl_placements WHERE student_id=student_B AND school_id=school_A`
   - Siswa B tidak punya PKL di sekolah A → `EXISTS` = false
   - `NOT false` = **TRUE** ✅
4. **WITH CHECK LULUS — INSERT BERHASIL**

**Mengapa `trg_auto_school_id` tidak mencegah ini?**

```sql
-- Trigger hanya mengisi school_id bila NULL:
IF NEW.school_id IS NOT NULL THEN
    RETURN NEW;  -- ← langsung return, tidak ada validasi cross-school
END IF;
-- ... (fallback: SET school_id FROM students.school_id)
```

Jika `school_id` di-SET eksplisit ke `school_A` oleh attacker, trigger tidak tersentuh. Jika `school_id = NULL`, trigger mengisi dari `students WHERE student_id = student_B_UUID` → `school_B`, dan WITH CHECK lalu gagal (`school_B ≠ school_A`). Jadi trigger TIDAK bisa dieksploitasi untuk auto-set school_id ke school_A — ini justru **mencegah** injeksi via NULL. Tetapi route via explicit `school_id = school_A` tetap terbuka.

**Constraint di `cases` yang TIDAK ada:**
- Tidak ada CHECK constraint `student.school_id = cases.school_id`
- Tidak ada FK yang menghubungkan `cases(school_id, student_id)` ke `students(school_id, student_id)` secara komposit
- Trigger `trg_case_immutable_fields`, `trg_case_guard_denormalized` tidak memvalidasi cross-school saat INSERT

**Efek samping: notifikasi side-channel**

Trigger `trg_notify_case_created` (AFTER INSERT SECURITY DEFINER) membaca `students WHERE student_id = NEW.student_id` tanpa RLS (karena SECURITY DEFINER):

```sql
SELECT user_id INTO v_student_user_id FROM students WHERE student_id = NEW.student_id;
-- → mengambil user_id milik siswa sekolah B

INSERT INTO notifications (school_id, recipient_user_id, ...)
VALUES (NEW.school_id, v_student_user_id, ...); -- school_id=A, recipient=siswa_B
```

Dan untuk orang tua:
```sql
FROM student_parents sp WHERE sp.student_id = NEW.student_id -- orang tua siswa B
-- → INSERT notifikasi ke orang tua sekolah B tentang kasus di sekolah A
```

Akibat: siswa dan orang tua dari **sekolah B menerima notifikasi push** tentang kasus yang dibuat di sekolah A — ini adalah cross-tenant notification side-channel yang dapat dikonfirmasi tanpa melanggar RLS baca.

**Syarat eksploitasi:** attacker harus mengetahui UUID siswa dari sekolah lain. UUID tidak boleh dianggap rahasia dalam sistem yang mengeksposnya via API (misal: link share kasus, export, sync manifest, dll.).

**Status: 🔴 CELAH** — WRITE contamination lintas-tenant via INSERT + notifikasi side-channel. Kelas risiko: lebih tinggi dari semua temuan Kelompok A/B (yang semuanya hanya READ).

---

### 3. `rls_pkl_attendance_read_kaprodi` — SELECT

**QUAL (lengkap, dari `pg_policies` live):**
```sql
(school_id = fn_current_school_id())
AND (fn_kaprodi_program_id() IS NOT NULL)
AND (EXISTS (
  SELECT 1 FROM students s
  WHERE s.student_id = pkl_attendance.student_id
    AND s.program_id = fn_kaprodi_program_id()
))
```

**WITH CHECK:** `NULL` (SELECT only).

#### Definisi `fn_kaprodi_program_id` (dari `pg_proc` live):

```sql
CREATE OR REPLACE FUNCTION public.fn_kaprodi_program_id()
RETURNS uuid
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT COALESCE(kaprodi_program_id,
                  CASE WHEN role_type = 'KAPRODI' THEN program_id END)
  FROM users WHERE auth_user_id = auth.uid();
$$;
```

**Analisis fungsi:** `fn_kaprodi_program_id()` mengembalikan UUID program kaprodi dari `users` tanpa filter `school_id`. Namun ini secara semantik aman: ia mengambil `program_id` dari baris user kaprodi itu sendiri (terikat oleh `auth.uid()`), bukan dari tabel lain. Program_id yang dikembalikan adalah milik sekolah kaprodi — karena satu user hanya bisa berada di satu sekolah.

**Analisis QUAL:**
- Guard `pkl_attendance.school_id = fn_current_school_id()` eksplisit terdepan — hanya attendance sekolah kaprodi yang masuk evaluasi.
- `fn_kaprodi_program_id() IS NOT NULL` — memastikan hanya user dengan role kaprodi yang terpicu.
- Subquery ke `students`: `s.student_id = pkl_attendance.student_id AND s.program_id = fn_kaprodi_program_id()` — tidak ada `s.school_id` eksplisit.

**Mengapa 🟡:**  
Pola ini identik secara struktural dengan policy teaching_schedules sebelum diperkuat — subquery ke tabel sekunder (`students`) tanpa `school_id` eksplisit, bergantung pada:
1. Guard eksplisit di tabel utama (`pkl_attendance.school_id = fn_current_school_id()`)
2. UUID uniqueness `program_id` (setiap sekolah punya UUID program sendiri)
3. RLS implisit `students` (semua policies `rls_students_*` mensyaratkan `students.school_id = fn_current_school_id()`)

**Seberapa aman secara praktis?**  
Lebih aman dari kasus teaching_schedules sebelum fix, karena `program_id` adalah UUID yang secara domain hanya ada satu per program-sekolah. Dua sekolah berbeda tidak bisa berbagi `program_id` yang sama. Namun pola struktural yang sama (tanpa `s.school_id` eksplisit) membuat ini tetap bergantung pada jaminan implisit, bukan pertahanan eksplisit.

**Skenario eksploitasi teoritis (andaikan RLS implisit `students` gagal):**  
Kaprodi sekolah A bisa melihat `pkl_attendance` sekolah A untuk siswa sekolah B jika siswa B punya `program_id` yang sama dengan program kaprodi A — yang mustahil terjadi karena `program_id` adalah UUID unik global.

**Skenario yang perlu dipantau:**  
Data import massal yang keliru memasukkan `program_id` dari sekolah yang salah ke baris `students`. Jika siswa B ter-assign `program_id` milik sekolah A, kaprodi A bisa melihat `pkl_attendance` sekolah A untuk siswa B (meski `pkl_attendance.school_id` tetap membatasi ke sekolah A saja).

**Status: 🟡 PERLU VERIFIKASI** — aman secara praktis; guard eksplisit ada di tabel utama; UUID program memastikan tidak ada kolisi; tetapi subquery `students` tanpa `s.school_id` eksplisit adalah pola yang sama dengan yang sudah diperkuat di teaching_schedules.

---

## Analisis Mendalam: `fn_student_is_on_pkl` sebagai SECURITY DEFINER dalam WITH CHECK

Ini adalah pola baru yang belum muncul di Kelompok A/B: fungsi SECURITY DEFINER dipanggil dari dalam WITH CHECK policy. Analisis terhadap kelas risiko ini:

| Aspek | Status |
|-------|--------|
| Fungsi melewati RLS | Ya — SECURITY DEFINER mengakses `pkl_placements` langsung tanpa RLS |
| Fungsi punya filter `school_id` internal | **Ya** — `pp.school_id = fn_current_school_id()` ada |
| Celah berasal dari fungsi itu sendiri | **Tidak** — fungsi sendiri aman |
| Celah berasal dari cara fungsi dipakai di WITH CHECK | **Ya** — fungsi dipakai sebagai penjaga PKL-track, bukan penjaga cross-tenant student |
| Efek fungsi pada student dari sekolah lain | Selalu mengembalikan `false` → `NOT false = true` → membuka INSERT |

**Kesimpulan:** `fn_student_is_on_pkl` bukan penyebab celah — ia berfungsi sesuai spesifikasinya. Celah ada pada desain WITH CHECK yang tidak menyertakan validasi bahwa `student_id` dari INSERT harus berasal dari sekolah yang sama dengan `school_id` di row tersebut.

---

## Komparasi Antar Kelompok

| Aspek | Kelompok A (ORTU) | Kelompok B (GURU/SUBSTITUTE) | Kelompok C (siswa/fungsi) |
|-------|------|------|------|
| Policy INSERT/WRITE bercelah | Tidak ada | Tidak ada (FOR ALL AMAN) | **1 — rls_cases_insert** |
| Tipe celah | — | — | **WRITE contamination + notif side-channel** |
| Guard school_id tabel utama | Semua eksplisit | Semua eksplisit | 2/3 eksplisit, 1 bercelah via fungsi |
| Penggunaan SECURITY DEFINER dalam policy | Tidak (hanya helper) | Tidak langsung | Ya (`fn_student_is_on_pkl`) |
| 🟡 struktural | 1 (sudah diperkuat) | 1 (sudah diperkuat) | 1 (`rls_pkl_attendance_read_kaprodi`) |

---

## Anomali Data Existing

**Query yang dijalankan (read-only):**
```sql
-- Cases dengan school_id ≠ students.school_id
SELECT COUNT(*) FROM cases ca
JOIN students st ON st.student_id = ca.student_id
WHERE ca.school_id != st.school_id;

-- Case_events dengan school_id ≠ cases.school_id
SELECT COUNT(*) FROM case_events ce
JOIN cases ca ON ca.case_id = ce.case_id
WHERE ce.school_id != ca.school_id;

-- PKL attendance dengan school_id ≠ students.school_id
SELECT COUNT(*) FROM pkl_attendance pa
JOIN students st ON st.student_id = pa.student_id
WHERE pa.school_id != st.school_id;
```

**Hasil:**

| Pemeriksaan | Hasil |
|-------------|-------|
| `cases` cross-school (cases.school_id ≠ students.school_id) | **0** (dari 3 total) |
| `case_events` cross-school (ce.school_id ≠ cases.school_id) | **0** (dari 2 total) |
| `pkl_attendance` cross-school (pa.school_id ≠ students.school_id) | **0** (dari 1 total) |

**Kesimpulan:** Celah di `rls_cases_insert` belum pernah dieksploitasi — semua 3 kasus existing konsisten. Namun data produksi masih sangat tipis (3 kasus), sehingga tidak ada jaminan historis yang bermakna.

---

## Rekomendasi Pasca-Audit (untuk ditangani di tahap berikutnya)

### Prioritas 1 — 🔴 `rls_cases_insert`: tambahkan validasi `student_id ↔ school_id`

Dua pendekatan yang bisa dipilih (belum diimplementasikan di audit ini):

**Opsi A — Tambahkan kondisi eksplisit di WITH CHECK:**
```sql
-- Tambahkan kondisi: school_id = (SELECT school_id FROM students WHERE student_id = cases.student_id)
-- Ini memastikan student_id yang di-INSERT memang milik sekolah yang sama
```

**Opsi B — Tambahkan CHECK CONSTRAINT di tabel `cases`:**
```sql
-- ALTER TABLE cases ADD CONSTRAINT chk_student_same_school
-- CHECK (school_id = (SELECT school_id FROM students WHERE student_id = student_id));
-- (Supabase/PostgreSQL: subquery di CHECK constraint tidak diperbolehkan — perlu ekspresi atau generated column)
```

**Opsi C — Trigger BEFORE INSERT yang validasi:**
```sql
-- Extend trg_auto_school_id atau buat trigger baru yang:
-- IF (SELECT school_id FROM students WHERE student_id = NEW.student_id) != NEW.school_id THEN RAISE EXCEPTION;
```

**Opsi yang paling bersih:** perbaiki WITH CHECK langsung dengan menambahkan:
```sql
AND (school_id = (SELECT s.school_id FROM students s WHERE s.student_id = cases.student_id))
```

### Prioritas 2 — 🟡 `rls_pkl_attendance_read_kaprodi`: tambahkan `s.school_id` eksplisit

Simetris dengan fix yang sudah diterapkan di `rls_schedules_read_student` dan `rls_schedules_read_parent`:
```sql
-- Tambahkan s.school_id = fn_current_school_id() di subquery EXISTS
```

---

*Laporan ini bersifat read-only. Tidak ada migration atau perubahan skema yang dibuat.*
