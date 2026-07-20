# Fase 2.1 — RLS Coverage Audit Report
**Tanggal audit:** 2026-07-06  
**Project:** smk-platform (`xovvuuwexoweoqyltepq`), Singapore  
**Scope:** semua tabel di schema `public`  
**Metode:** SELECT-only via `supabase db query --linked` (Management API)

---

## Query yang Dijalankan

1. `pg_tables JOIN pg_class` — daftar tabel + `relrowsecurity` / `relforcerowsecurity`  
2. `pg_policies WHERE schemaname='public'` — semua policy: nama, cmd, roles, USING, WITH CHECK  
3. `information_schema.role_table_grants WHERE grantee IN ('anon','authenticated')` — grant level tabel  
4. `pg_proc WHERE prosecdef=true AND prorettype<>trigger` — inventarisasi SECURITY DEFINER functions + `has_function_privilege`

---

## Temuan Awal: Semua 33 Tabel RLS Enabled

`relrowsecurity = true` untuk semua tabel. `relforcerowsecurity = false` semua (artinya owner/superuser tidak dipaksa RLS). Tidak ada tabel dengan status 🔴 CRITICAL.

Semua tabel mendapat `GRANT ALL` (SELECT, INSERT, UPDATE, DELETE, REFERENCES, TRIGGER, TRUNCATE) ke `anon` dan `authenticated` — bersumber dari Supabase default `ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated`. Tidak ada satu pun migration yang memberikan grant eksplisit per tabel ke anon/authenticated.

---

## Tabel per Tabel

| Tabel | RLS | Policies ada | Grants anon/auth | Status | Catatan |
|---|---|---|---|---|---|
| `academic_periods` | ✅ | SELECT, INSERT, UPDATE | ALL | 🟠 HIGH | Tidak ada DELETE policy |
| `achievements` | ✅ | SELECT, INSERT, UPDATE | ALL | 🟠 HIGH | Tidak ada DELETE policy |
| `attendance` | ✅ | SELECT ×3, ALL ×2 | ALL | 🟢 OK | ALL mencakup INSERT+UPDATE+DELETE untuk guru/substitute |
| `audit_log` | ✅ | SELECT only | ALL | 🟠 HIGH | INSERT/UPDATE/DELETE granted, tidak ada policy → default deny. Kemungkinan intentional (hanya ditulis via trigger/service_role) |
| `case_audience_members` | ✅ | SELECT, INSERT, DELETE | ALL | 🟠 HIGH | UPDATE granted, tidak ada UPDATE policy (mungkin intentional: junction table) |
| `case_events` | ✅ | SELECT ×3, INSERT ×2, DELETE | ALL | 🟠 HIGH | UPDATE granted, tidak ada UPDATE policy |
| `cases` | ✅ | SELECT ×4, INSERT, UPDATE ×2, DELETE | ALL | 🟢 OK | Semua operasi tercakup |
| `class_enrollments` | ✅ | SELECT ×3, ALL ×2 | ALL | 🟢 OK | |
| `classes` | ✅ | SELECT, ALL | ALL | 🟢 OK | |
| `login_devices` | ✅ | SELECT only | ALL | 🟠 HIGH | INSERT/UPDATE/DELETE granted, tidak ada policy. Intentional: insert via `fn_register_login_device` (service_role) |
| `notifications` | ✅ | SELECT, UPDATE | ALL | 🟠 HIGH | INSERT/DELETE granted, tidak ada policy. INSERT via trigger/service_role (intentional?) |
| `observation_audience_members` | ✅ | SELECT, INSERT, DELETE | ALL | 🟠 HIGH | UPDATE granted, tidak ada UPDATE policy (junction table, mungkin intentional) |
| `observations` | ✅ | SELECT ×4, INSERT ×4, UPDATE ×2, DELETE | ALL | 🟢 OK | |
| `parent_messages` | ✅ | SELECT, INSERT ×2, DELETE | ALL | 🟠 HIGH | UPDATE granted, tidak ada UPDATE policy |
| `pkl_attendance` | ✅ | SELECT ×4, ALL (dudi), DELETE | ALL | 🟡 MEDIUM | `rls_pkl_attendance_read_ortu`: TIDAK ada filter `school_id` — lihat catatan di bawah |
| `pkl_placements` | ✅ | SELECT ×4, ALL ×2 | ALL | 🟡 MEDIUM | `rls_pkl_read_ortu`: TIDAK ada filter `school_id` — lihat catatan di bawah |
| `platform_config` | ✅ | **Tidak ada policy sama sekali** | ALL | 🟠 HIGH | Default deny total untuk anon/authenticated. Intentional? Perlu verifikasi siapa yang nulis |
| `programs` | ✅ | SELECT, ALL | ALL | 🟢 OK | |
| `schedule_templates` | ✅ | SELECT (staff), ALL (administrative) | ALL | 🟢 OK | ORTU/SISWA/DUDI tidak bisa baca — disengaja |
| `schedule_time_slots` | ✅ | SELECT (`school_id` only, tanpa role filter), ALL | ALL | 🟡 MEDIUM | SELECT policy tidak memfilter berdasarkan role, hanya `school_id = fn_current_school_id()`. Semua role (termasuk ORTU, SISWA) bisa baca. Perlu verifikasi apakah ini disengaja |
| `school_config` | ✅ | SELECT, ALL | ALL | 🟢 OK | |
| `schools` | ✅ | SELECT (subquery ke users) | ALL | 🟠 HIGH | INSERT/UPDATE/DELETE granted, tidak ada policy. Hanya dimodifikasi via service_role/superadmin. Roles policy hanya `{authenticated}` (bukan public) |
| `student_parents` | ✅ | SELECT ×2, ALL | ALL | 🟢 OK | |
| `student_updates` | ✅ | SELECT ×2, INSERT | ALL | 🟠 HIGH | UPDATE/DELETE granted, tidak ada policy. Tabel ini mungkin intentional append-only |
| `students` | ✅ | SELECT ×5, ALL ×2 | ALL | 🟢 OK | |
| `subjects` | ✅ | SELECT, ALL | ALL | 🟢 OK | |
| `substitute_schedules` | ✅ | SELECT, ALL ×2 | ALL | 🟢 OK | |
| `sync_idempotency` | ✅ | **Tidak ada policy sama sekali** | ALL | 🟠 HIGH | Default deny total. Intentional: hanya service_role (edge functions) yang menulis |
| `teacher_attendance_log` | ✅ | SELECT only | ALL | 🟠 HIGH | INSERT/UPDATE/DELETE granted, tidak ada policy. Kemungkinan intentional (ditulis via trigger/service_role) |
| `teacher_journals` | ✅ | ALL (owner + school_id) | ALL | 🟢 OK | |
| `teaching_assignments` | ✅ | SELECT ×3, ALL ×2 | ALL | 🟢 OK | |
| `teaching_schedules` | ✅ | SELECT ×5, ALL ×2 | ALL | 🟢 OK | |
| `users` | ✅ | SELECT ×5, UPDATE, ALL | ALL | 🟢 OK | Column-guard via trigger (mig 20260706180000, belum push) |

---

## Ringkasan Status

| Status | Jumlah | Tabel |
|---|---|---|
| 🔴 CRITICAL | 0 | — |
| 🟠 HIGH | 14 | `academic_periods`, `achievements`, `audit_log`, `case_audience_members`, `case_events`, `login_devices`, `notifications`, `observation_audience_members`, `parent_messages`, `platform_config`, `schools`, `student_updates`, `sync_idempotency`, `teacher_attendance_log` |
| 🟡 MEDIUM | 3 | `pkl_attendance`, `pkl_placements`, `schedule_time_slots` |
| 🟢 OK | 16 | `attendance`, `cases`, `class_enrollments`, `classes`, `observations`, `programs`, `schedule_templates`, `school_config`, `student_parents`, `students`, `subjects`, `substitute_schedules`, `teacher_journals`, `teaching_assignments`, `teaching_schedules`, `users` |

---

## Catatan Detail: Tabel 🟡 MEDIUM

### `pkl_attendance` — `rls_pkl_attendance_read_ortu`
```sql
QUAL: (fn_current_user_role() = 'ORTU'::role_type)
      AND (EXISTS (
        SELECT 1 FROM student_parents sp
        WHERE sp.student_id = pkl_attendance.student_id
          AND sp.parent_user_id = fn_current_user_id()
      ))
```
**Tidak ada `school_id` filter.** Jika seorang ortu memiliki `student_parents` row yang menghubungkan ke siswa di sekolah lain (data anomali atau bug impor), policy ini tidak akan mencegah cross-tenant read. Semua tabel `pkl_attendance` lain yang memiliki policy menyertakan `school_id = fn_current_school_id()`.

### `pkl_placements` — `rls_pkl_read_ortu`
```sql
QUAL: (fn_current_user_role() = 'ORTU'::role_type)
      AND (EXISTS (
        SELECT 1 FROM student_parents sp
        WHERE sp.student_id = pkl_placements.student_id
          AND sp.parent_user_id = fn_current_user_id()
      ))
```
Masalah identik dengan `pkl_attendance_read_ortu` — tidak ada `school_id` filter.

### `schedule_time_slots` — `rls_time_slots_read`
```sql
QUAL: (school_id = fn_current_school_id())
```
Tidak ada filter role. Semua role yang terautentikasi (SISWA, ORTU, DUDI, dll.) dapat membaca semua time slot sekolahnya. Perlu konfirmasi: apakah ini disengaja (data tidak sensitif, hanya metadata slot waktu)?

---

## Perlu Review Manual — Join-Based Policy

Tabel-tabel di bawah memiliki policy yang menggunakan JOIN atau subquery ke tabel lain. Ini kandidat utama untuk analisis cross-tenant FK/join leakage di Fase 2.2.

| Tabel | Policy | Join ke |
|---|---|---|
| `attendance` | `rls_attendance_read_parent` | `student_parents` |
| `attendance` | `rls_attendance_rw_guru` | `teaching_schedules`, `teaching_assignments` |
| `attendance` | `rls_attendance_rw_substitute` | `substitute_schedules` |
| `case_events` | `rls_case_events_read_parent` | `cases`, `student_parents` |
| `case_events` | `rls_case_events_read_student` | `cases`, `students` |
| `cases` | `rls_cases_read_parent` | `student_parents` |
| `cases` | `rls_cases_insert` | via `fn_student_is_on_pkl(student_id)` |
| `class_enrollments` | `rls_enrollments_read_parent` | `student_parents` |
| `pkl_attendance` | `rls_pkl_attendance_read_kaprodi` | `students` |
| `pkl_attendance` | `rls_pkl_attendance_read_ortu` | `student_parents` (+ **tidak ada school_id**) |
| `pkl_placements` | `rls_pkl_read_ortu` | `student_parents` (+ **tidak ada school_id**) |
| `schools` | `rls_schools_read_own` | `users` (subquery) |
| `student_updates` | `rls_student_updates_read_student` | `cases`, `students` |
| `students` | `rls_students_read_parent` | `student_parents` |
| `teaching_schedules` | `rls_schedules_read_parent` | `class_enrollments`, `student_parents` |
| `teaching_schedules` | `rls_schedules_read_student` | `class_enrollments` |
| `users` | `rls_users_read_own` | `auth.uid()` langsung (no school_id) — seluruh platform bisa baca baris sendiri lintas sekolah |

---

## Inventarisasi SECURITY DEFINER Functions

*(Hanya inventarisasi untuk hand-off ke Fase 2.3 — tidak dianalisis lebih dalam di sini)*

### Callable oleh `anon` (anon_exec = true)

| Function | Args |
|---|---|
| `fn_can_see_case` | `p_case_id uuid` |
| `fn_can_see_student` | `p_student_id uuid` |
| `fn_current_academic_year` | `p_school_id uuid` |
| `fn_current_school_id` | — |
| `fn_current_student_id` | — |
| `fn_current_user_id` | — |
| `fn_current_user_role` | — |
| `fn_dudi_supervises_student` | `p_student_id uuid` |
| `fn_involved_in_case` | `p_case_id uuid` |
| `fn_is_bk` | — |
| `fn_is_internal_case_actor` | — |
| `fn_is_kepsek` | — |
| `fn_is_schoolwide_observer` | — |
| `fn_is_waka_humas` | — |
| `fn_is_waka_kesiswaan` | — |
| `fn_is_waka_kurikulum` | — |
| `fn_kaprodi_of_student` | `p_student_id uuid` |
| `fn_kaprodi_program_id` | — |
| `fn_maintenance_status` | — |
| `fn_matches_case_handler` | `p_handler_role role_type, p_student_id uuid` |
| `fn_resolve_login_email` | `p_identifier text, p_school_id uuid` |
| `fn_school_branding` | `p_slug text` |
| `fn_student_is_on_pkl` | `p_student_id uuid` |
| `fn_teaches_student` | `p_student_id uuid` |
| `fn_user_is_internal_case_actor` | `p_user_id uuid` |
| `fn_wali_kelas_class_id` | — |
| `fn_wali_of_student` | `p_student_id uuid` |

### Callable oleh `authenticated` saja (anon_exec = false)

| Function | Args |
|---|---|
| `fn_confirm_password_changed` | — |
| `fn_count_unread_notifications` | — |
| `fn_deactivate_stale_staff` | — |
| `fn_get_stale_staff` | — |
| `fn_kepsek_monitoring` | `p_period text, p_academic_year text` |
| `fn_register_login_device` | `p_device_hash text, p_user_agent text, p_label text` |
| `fn_stakeholder_summary` | — |
| `fn_sync_case` | `p_idempotency_key text, ...` |
| `fn_update_school_branding` | `p_name text, ...` (2 overloads) |

### Callable oleh `service_role` saja (anon_exec = false, auth_exec = false)

| Function | Args |
|---|---|
| `fn_apply_schedule_templates` | `p_academic_year text, p_semester semester, p_school_id uuid` |
| `fn_batalkan_tahun_ajaran` | `p_config_id uuid` |
| `fn_buka_tahun_ajaran` | `p_config_id uuid, ...` |
| `fn_bulk_import_students` | `p_rows jsonb` |
| `fn_check_identifiers_exist` | `p_identifiers text[], p_school_id uuid` |
| `fn_check_niks_exist` | `p_niks text[], p_school_id uuid` |
| `fn_platform_storage` | — |
| `fn_purge_expired_student` | `p_student_id uuid, p_school_id uuid` |
| `fn_reapply_schedule_templates` | `p_academic_year text, p_semester semester, p_school_id uuid` |
| `fn_school_staff_health` | — |
| `fn_school_student_health` | — |
| `fn_sync_attendance_batch` | `p_schedule_id uuid, ...` |
| `fn_sync_case` | — *(duplikat, variant service_role-only tidak ada, fn_sync_case auth_exec=true)* |
| `fn_sync_journal` | `p_idempotency_key text, ...` |
| `fn_sync_observation` | `p_idempotency_key text, ...` |
