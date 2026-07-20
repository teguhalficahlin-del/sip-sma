# AUDIT TOTAL — REFERENTIAL INTEGRITY & CHANGE IMPACT ANALYSIS

**Tanggal:** 2026-07-04
**Sifat:** Read-only. Tidak ada perubahan kode/skema/data. Satu-satunya tulisan = dokumen ini.
**Pertanyaan inti yang diuji:**
> "Kalau saya ubah satu data induk, apakah seluruh platform ikut berubah dengan benar — tanpa ada bagian yang masih menampilkan data lama?"

**Metode:** Setiap kesimpulan berasal dari implementasi nyata (migrasi SQL, edge functions, JS portal), bukan dokumentasi/komentar. Staleness diuji terhadap **2 sumber fisik**:
- **Sumber 1 — salinan saat menulis** (denormalisasi di database) → menguji Single Source of Truth + Referential Integrity.
- **Sumber 2 — snapshot di klien** (cache/offline yang tidak di-fetch ulang) → menguji Change Propagation.

---

## RINGKASAN EKSEKUTIF

Fondasi relasional platform ini **kuat**: seluruh tabel transaksi (attendance, observations, cases, teaching_schedules, journals, achievements, parent_messages) menyimpan relasi **hanya via `*_id`**, dan semua view/query membaca nama master lewat **JOIN saat baca** — bukan salinan. Offline hanya menyimpan outbox tulis ber-ID, tidak menyimpan salinan master yang bisa basi.

Namun ditemukan **2 duplikasi nyata** yang melanggar Single Source of Truth dan **dapat menampilkan data usang**, plus 1 masalah desain "tahun berjalan" dan 1 hardcode fallback:

| Kode | Temuan | Prioritas |
|---|---|---|
| TEMUAN-1 | Nama sekolah tersimpan ganda: `schools.name` vs `school_config.school_name`. Edit hanya menyentuh salah satu → dua nama berbeda di satu layar. | **High** |
| TEMUAN-2 | Nama siswa tersimpan ganda: `students.full_name` vs `users.full_name` (akun SISWA). Dua jalur edit terpisah, tanpa sinkronisasi. | **Medium-High** |
| TEMUAN-3 | `academic_year` string ter-denormalisasi + "tahun berjalan" dilacak di 3 tempat; sudah pernah memicu bug 600 baris jadwal gagal. | **Medium** |
| TEMUAN-4 | Hardcode `"SMK Harapan Rokan"` sebagai fallback di beberapa dashboard HTML (bocor nama sekolah salah bila branding gagal load). | **Low** |

**Kesimpulan: BAIK.** (Bukan "Sangat Baik" karena 2 duplikasi nyata; bukan sekadar "Cukup" karena arsitektur relasi inti benar dan konsisten.)

---

## 1. INVENTARISASI MODUL

| Modul | Status | Lokasi Implementasi |
|---|---|---|
| Setup Wizard (onboarding 11 langkah) | Implemented | `admin/js/wizard.js`, `admin/wizard.html` |
| Dashboard Admin | Implemented | `admin/js/dashboard.js` |
| Dashboard Superadmin | Implemented | `superadmin/js/dashboard.js` + edge `provision-school`, `list-schools`, `platform-stats` |
| Portal Guru (absensi/observasi/jurnal/kasus) | Implemented | `guru/js/*.js` |
| Portal Siswa | Implemented | `student/js/*.js`, view `v_student_portal_*` |
| Portal Orang Tua | Implemented | `parent/js/*.js` |
| Portal DUDI (PKL) | Implemented | `dudi/js/*.js` |
| Portal Stakeholder | Implemented | `stakeholder/js/*.js`, RPC `stakeholder_summary` |
| Program Keahlian / Kelas / Rombel | Implemented | tabel `programs`, `classes`, `class_enrollments` |
| Jadwal (visual + CSV) | Implemented | `schedule-builder.js`, edge `bulk-import-schedules`, `apply-schedule-templates` |
| Absensi | Implemented | tabel `attendance`, edge `sync-attendance-batch` |
| Observasi | Implemented | tabel `observations`, edge `sync-observation` |
| Kasus / Eskalasi + Notifikasi | Implemented | tabel `cases`/`case_events`/`notifications`, edge `sync-case` |
| PKL (placement + attendance) | Implemented | `pkl_placements`, `pkl_attendance` |
| Semester / Tutup Tahun | Implemented | `admin/js/semester.js`, `tutup-tahun.js`, fn `buka_tahun_ajaran` |
| Import (users/students/parents/classes/programs/dudi/schedules/pkl) | Implemented | `supabase/functions/bulk-import-*` |
| Branding per sekolah | Implemented | `shared/branding.js`, fn `fn_update_school_branding` |
| Notifikasi lonceng | Implemented (Guru) / Missing (DUDI) | `notifications`, `guru/js/dashboard.js` |
| Offline write queue | Partially Implemented (Guru saja) | `guru/js/offline.js` (IndexedDB) |
| Dashboard Kepala Sekolah | Implemented | view `v_kepsek_exception_dashboard`, RPC kepsek_monitoring |
| eRapor / Nilai numerik | **Not Applicable** | Tidak ditemukan tabel nilai/rapor. Platform berfokus kehadiran+observasi+kasus. |
| Export / PDF | **Not Applicable** | Tidak ditemukan modul export/PDF. |
| Cache aplikasi server (Redis/memory) | **Not Applicable** | Tidak ada cache sisi server. |
| Cache klien (localStorage snapshot) | **Implemented** | `guru/student/dudi/parent` — stale-while-revalidate (lihat §2 Cache/Offline). |
| Sync dua-arah / replikasi | **Not Applicable** | Offline hanya outbox tulis satu-arah. |
| Konsentrasi / Kurikulum / CP / TP | **Missing/Planned** | Tidak ada tabel; hanya `programs` & `subjects`. |

> Audit berikut hanya menilai modul **Implemented / Partially Implemented**. Modul Not Applicable tidak diberi temuan negatif.

---

## 2. DATA MASTER & ANALISIS PER-MASTER

Ringkasan per data master. Kolom "Sumber Kebenaran" = tabel/kolom kanonik. "FK by ID" = apakah dependensi menunjuk via ID. "Propagasi baca" = apakah pembaca mengambil nilai terbaru.

| Data Master | Sumber Kebenaran | FK by ID | Propagasi baca | Duplikasi? |
|---|---|---|---|---|
| Sekolah | `schools.name` **dan** `school_config.school_name` | ✅ (`school_id`) | ⚠️ dua jalur | **YA → TEMUAN-1** |
| Program Keahlian | `programs.name` | ✅ (`program_id`) | ✅ JOIN | Tidak |
| Mata Pelajaran | `subjects.name` | ✅ (`subject_id`) | ✅ JOIN | Tidak |
| Guru/Staf | `users.full_name` | ✅ (`user_id`) | ✅ JOIN/view | Tidak |
| Siswa | `students.full_name` (+ salinan di `users.full_name` bila punya akun) | ✅ (`student_id`) | ⚠️ dua jalur | **YA → TEMUAN-2** |
| Orang Tua | `users.full_name` | ✅ (`student_parents.parent_user_id`) | ✅ JOIN | Tidak |
| DUDI | `users.dudi_org_name` | ✅ (`pkl_placements.dudi_user_id`) | ✅ JOIN | Tidak |
| Kelas/Rombel | `classes.name` | ✅ (`class_id`) | ✅ JOIN/view | Tidak |
| Tahun Ajaran/Semester | `academic_periods` + `school_config.current_*` + string `academic_year` tersebar | ⚠️ string, bukan FK | ⚠️ multi-lokasi | **Sebagian → TEMUAN-3** |
| Jadwal | `teaching_schedules` (ref `class_id`,`subject_id`,`scheduled_teacher_id`) | ✅ | ✅ JOIN/view | Tidak |
| Teaching Assignment | `teaching_assignments` (ref id semua) | ✅ | ✅ | Tidak |

### Update Mechanism (bukti nyata)
- **Relasi:** FK dengan `ON DELETE RESTRICT`/`SET NULL` di seluruh skema (`contracts/01_reference_identity_org.sql`).
- **`ON UPDATE CASCADE`:** tidak ada — dan **tidak diperlukan**, karena semua PK adalah UUID immutable. Nama berubah tanpa mengubah ID, jadi relasi tidak perlu cascade.
- **Propagasi baca:** dilakukan lewat **JOIN saat baca** di view (`contracts/07_indexes_views.sql`: `c.name AS class_name`, `u.full_name AS teacher_name`) dan di klien (`guru/js/api.js:178`: `class_name: ta.class?.name`). Ini mekanisme propagasi yang benar — nilai selalu diambil dari master hidup.

### Cache / Offline / Sync
> **KOREKSI (audit lanjutan Fase 4, 2026-07-04):** pernyataan awal "Cache aplikasi: Not Applicable" **KELIRU**. Ada lapisan cache localStorage di 4 portal — lihat rincian di bawah.
- **Cache klien (localStorage `smkhr:*` / `dudi:*`):** ADA di `guru/js/dashboard.js:141`, `student/js/dashboard.js:31`, `dudi/js/dashboard.js:62`, `parent/js/portal.js:47`. Menyimpan snapshot server termasuk **nama turunan** (class_name, subject_name, student full_name). Pola **stale-while-revalidate** konsisten: render cache → `await` fetch fresh → overwrite cache + render ulang (bukti: `guru/js/dashboard.js:348-358`, `student:213`, `parent:259`; DUDI diberi label "Category B — stale-while-revalidate" di baris 61). **Verdict:** basi hanya **transien** (sampai fetch balik, sub-detik saat online); saat offline sengaja menahan data terakhir (perilaku offline yang benar). **Risiko: Rendah.** Catatan minor: `ts` timestamp disimpan tapi tidak dipakai (tak ada max-age guard) — vestigial, tak berdampak karena selalu revalidate.
- **Offline write queue (`guru/js/offline.js`):** IndexedDB hanya menyimpan **outbox tulis** (absensi/observasi/jurnal/kasus) sebagai payload idempoten ber-ID. **Tidak** menyimpan salinan nama master untuk tampilan → **tidak ada stale master dari offline.** Antrian dibersihkan saat logout.
- **Sync:** satu-arah (klien→server via edge `sync-*`). Not Applicable untuk propagasi master.

### Verifikasi tuntas Fase 3–5 (audit lanjutan 2026-07-04)
- **Fase 3 (jalur baca server) — TUNTAS, 0 temuan:** seluruh RPC/edge pembaca diaudit, bukan sampel. Yang mengembalikan nama membacanya dari master hidup: `fn_get_stale_staff` (`users.full_name`), `fn_school_branding` (`schools.name`), `list-schools` (`schools`+`users` live). Yang lain hanya agregat tanpa nama: `fn_kepsek_monitoring`, `fn_stakeholder_summary`, `platform-stats`. 7 view semua JOIN by ID. **Tak ada satu pun jalur baca server yang membaca salinan.**
- **Fase 4 (Sumber 2 klien) — TUNTAS:** temuan = lapisan cache localStorage di atas (stale-while-revalidate, risiko rendah). Ini koreksi atas vonis awal.
- **Fase 5 (integrasi) — TUNTAS:** **Import** semua resolve kunci (nama/nis/kode) → ID di batas impor lalu simpan ID; nama hanya di tabel-rumahnya (`programs.name` upsert by `school_id,code`; `student_parents` link murni ID — komentar `bulk-import-parents:14-19`). **Export** = N/A (tak ada kode blob/pdf/xlsx). **Search** = filter klien atas daftar yang baru di-fetch (data hidup). **API** = Supabase REST/RPC, baris hidup ber-RLS.

---

## 3. PENCARIAN GLOBAL & HARDCODE

**Kolom nama di tabel transaksi:** hanya `cases.title` & `achievements.title` — itu **atribut asli entitas**, bukan salinan nama master. **Tidak ada** `teacher_name`/`student_name`/`class_name` yang disimpan permanen di tabel transaksi. ✅

**Kemunculan `*_name` di kode** semuanya sah:
- Di **view**: alias hasil JOIN (`c.name AS class_name`) — dihitung saat baca. ✅
- Di **import**: `nama_kelas`/`nama_guru` dipakai sebagai **kunci lookup** untuk di-resolve → `class_id`/`teacher_id`, lalu yang disimpan adalah ID (`bulk-import-schedules/index.ts:266-308`). ✅
- Di **klien**: `class_name: ta.class?.name` (`guru/js/api.js:178`) — properti turunan saat fetch, tidak disimpan. ✅

**Hardcode** (→ TEMUAN-4): string `"SMK Harapan Rokan"` tertanam sebagai teks fallback di `student/dashboard.html:21`, `guru/dashboard.html:22`, `stakeholder/dashboard.html:20`, `guru/index.html:18`, `student/index.html:18`, `stakeholder/index.html:18`. Ditimpa runtime oleh `applyBrandingById` (dari `schools.name`), tapi bocor bila JS/branding gagal.

---

## 4. TEMUAN RINCI (dengan rekomendasi Sebelum → Sesudah)

### TEMUAN-1 — Nama sekolah tersimpan ganda (Prioritas: HIGH)

**Lokasi:**
- Sumber A: `schools.name` (`supabase/migrations/20260701100000_create_schools_table.sql:7`)
- Sumber B: `school_config.school_name` (`contracts/01_reference_identity_org.sql:332`)
- Jalur edit: `fn_update_school_branding` (`...20260701410000...:42-51`) meng-update **hanya `schools.name`**.
- Jalur baca yang basi: `admin/js/dashboard.js:1552` mengisi `<h2 id="dashboard-school-name">` dari `school_config.school_name`.
- Jalur baca yang segar: `shared/branding.js` mengisi `[data-brand="school-name"]` dari `schools.name`.

**Penyebab:** Multi-tenant menambah tabel `schools` dengan kolom `name`, tetapi `school_config.school_name` lama tidak dihapus. Panel Branding hanya menulis ke `schools`.

**Reproduksi:**
1. Admin buka Branding → ubah nama sekolah → simpan (`schools.name` berubah).
2. Refresh dashboard admin.
3. **Sidebar (baris 17 HTML)** menampilkan nama BARU; **H2 sambutan (baris 58 HTML)** menampilkan nama LAMA. Dua nama untuk satu sekolah, di satu layar.

**Dampak lintas-modul:** Inkonsistensi identitas sekolah pada dashboard admin. Risiko multi-tenant: `school_config` bersifat singleton per-DB, sedangkan `schools` per-tenant — sumber kebenaran ganda memperbesar risiko salah tampil.

**Rekomendasi — jadikan `schools.name` satu-satunya sumber, hapus jalur baca ke `school_config.school_name`:**

Sebelum (`admin/js/dashboard.js:1552`):
```js
const config = await getSchoolConfig();
document.getElementById('dashboard-school-name').textContent = config?.school_name ?? 'Sekolah';
```
Sesudah (baca dari branding/`schools`, satu sumber):
```js
const branding = await getSchoolBranding();          // sudah ada di admin/js/api.js:300
document.getElementById('dashboard-school-name').textContent = branding?.name ?? 'Sekolah';
```
Atau lebih ringkas — beri H2 atribut branding dan hapus baris JS, biar `applyBrandingById` yang mengisinya dari `schools.name`:
```html
<!-- admin/dashboard.html:58 -->
<h2 id="dashboard-school-name" data-brand="school-name">Memuat...</h2>
```
Langkah lanjutan (opsional, membersihkan akar): berhenti menulis `school_config.school_name` di wizard (`admin/js/wizard.js:541`) dan tandai kolom itu deprecated, sisakan `schools.name` sebagai satu-satunya sumber nama sekolah.

---

### TEMUAN-2 — Nama siswa tersimpan ganda (students vs users) (Prioritas: MEDIUM-HIGH)

**Lokasi:**
- Sumber A: `students.full_name` (`contracts/01_reference_identity_org.sql:117`).
- Sumber B (salinan): `users.full_name` untuk akun SISWA, disalin saat provisioning: `supabase/functions/provision-student-accounts/index.ts:155` (`full_name: s.full_name`).
- Jalur edit A: `updateStudent` → `students.full_name` saja (`admin/js/api.js:531-533`).
- Jalur edit B: edge `update-user-identifier` → `users.full_name` saja (`.../index.ts:68`).
- Tidak ada trigger sinkronisasi (grep `full_name` di `contracts/05_triggers_functions.sql` = nihil).

**Penyebab:** Siswa yang punya akun portal memiliki nama di dua tabel; kedua tabel diedit lewat jalur berbeda tanpa penghubung.

**Reproduksi:**
1. Siswa "Budi" sudah punya akun portal (baris `users` dengan `full_name='Budi'`, dan `students.full_name='Budi'`).
2. Admin perbaiki nama di roster siswa → `updateStudent` → `students.full_name='Budi Santoso'`.
3. Baris `users` siswa itu **tetap** `'Budi'`. Tampilan yang membaca `users.full_name` (mis. daftar akun, notifikasi ber-user) menunjukkan nama lama; tampilan berbasis `students` menunjukkan nama baru.

**Dampak lintas-modul:** Divergensi nama siswa antara data akademik (students) dan akun login (users). Surface tampilan kecil hari ini, tetapi merupakan bom-waktu SSoT saat fitur berbasis akun siswa bertambah.

**Rekomendasi — buat `students.full_name` sumber tunggal, sinkronkan `users` via trigger DB (satu transaksi, anti-lupa):**

Sebelum: dua UPDATE terpisah, tanpa penghubung.

Sesudah (tambah trigger — konsep, untuk migrasi baru):
```sql
CREATE OR REPLACE FUNCTION trg_sync_student_name_to_user()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.full_name IS DISTINCT FROM OLD.full_name AND NEW.user_id IS NOT NULL THEN
    UPDATE users SET full_name = NEW.full_name, updated_at = NOW()
    WHERE user_id = NEW.user_id;
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER student_name_sync
  AFTER UPDATE OF full_name ON students
  FOR EACH ROW EXECUTE FUNCTION trg_sync_student_name_to_user();
```
Alternatif lebih "murni SSoT" (tanpa salinan sama sekali): jangan salin `full_name` ke `users` saat provisioning; sebagai gantinya baca nama siswa selalu via JOIN `students` di setiap tampilan berbasis akun siswa. Trigger di atas dipilih sebagai rekomendasi utama karena paling kecil perubahannya dan langsung menutup divergensi.

---

### TEMUAN-3 — "Tahun berjalan" & `academic_year` ter-denormalisasi (Prioritas: MEDIUM)

**Lokasi:** String `academic_year VARCHAR(9)` disalin ke `classes`, `class_enrollments`, `teaching_assignments`, `teaching_schedules`, `academic_periods`; sedangkan "tahun berjalan" dilacak terpisah di `school_config.current_academic_year` **dan** ditentukan ulang oleh `academic_periods.status='ACTIVE'`.

**Bukti dampak nyata:** Migrasi `20260703170000_sync_classes_to_current_year.sql` dibuat justru untuk menambal inkonsistensi ini — kelas XI/XII masih `2026/2027` sementara `school_config.current_academic_year` sudah `2027/2028`, menyebabkan **600 baris impor jadwal gagal** karena lookup `classes.name + academic_year` tak ketemu.

**Penyebab:** Tidak ada tabel master `academic_years` tunggal; "tahun berjalan" adalah nilai yang disalin/ditebak di beberapa tempat, bukan satu sumber yang diturunkan.

**Dampak lintas-modul:** Impor jadwal, enrolment, dan lookup kelas rapuh terhadap ketidakcocokan string tahun. Bukan "stale display", melainkan **kegagalan referensial diam-diam** saat tahun berpindah.

**Rekomendasi — jadikan `academic_periods` (status=ACTIVE) satu-satunya penentu "tahun berjalan"; `school_config.current_*` cukup sebagai cache yang di-set dalam transaksi yang sama saat buka/tutup tahun.**

Sebelum (dua sumber "tahun berjalan" bisa berbeda):
```
school_config.current_academic_year = '2027/2028'   ← dibaca import
academic_periods(status=ACTIVE).academic_year = '2027/2028'
classes.academic_year masih '2026/2027'             ← tidak ikut → import gagal
```
Sesudah (turunkan dari satu sumber saat rollover, dalam satu fungsi transaksional):
```sql
-- di dalam fn_buka_tahun_ajaran / tutup tahun, satu transaksi:
-- 1) academic_periods: tutup periode lama, buka periode baru (ACTIVE)  ← SUMBER
-- 2) school_config.current_academic_year := (periode ACTIVE).academic_year  ← cache
-- 3) naikkan kelas ke tahun baru sekaligus (hindari sisa string lama)
```
Prinsip: pembaca yang butuh "tahun berjalan" mengambil dari `academic_periods` ACTIVE (atau cache `school_config` yang dijamin sinkron oleh fungsi rollover), bukan dari asumsi masing-masing modul.

---

### TEMUAN-4 — Hardcode nama sekolah fallback (Prioritas: LOW)

**Lokasi:** `student/dashboard.html:21`, `guru/dashboard.html:22`, `stakeholder/dashboard.html:20`, `guru/index.html:18`, `student/index.html:18`, `stakeholder/index.html:18` → teks `"SMK Harapan Rokan"`.

**Penyebab:** Placeholder era single-tenant. Ditimpa `applyBrandingById` saat runtime, tetapi jika branding gagal load (offline/slug salah), pengguna tenant lain melihat nama sekolah yang salah.

**Rekomendasi — kosongkan placeholder agar tidak pernah menampilkan nama tenant lain:**

Sebelum:
```html
<h2 data-brand="school-name">SMK Harapan Rokan</h2>
```
Sesudah:
```html
<h2 data-brand="school-name">Memuat…</h2>
```

---

## 5. CHANGE IMPACT MAP (dependency nyata)

```
users.full_name (guru/ortu)  ──JOIN──> v_attendance_daily_summary (teacher_name)
                             ──JOIN──> v_kepsek_exception_dashboard
                             ──JOIN──> v_case_timeline (author_name)
                             ──JOIN──> observations/achievements views (author/recorded_by)
   → Edit sekali → SEMUA pembaca segar (via ID). ✅

classes.name  ──JOIN──> v_attendance_daily_summary, v_offline_sync_manifest_*, guru/api.js
   → Edit sekali → segar. ✅

students.full_name ──JOIN──> attendance/observation/PKL/manifest (via student_id)
                   ──COPY──> users.full_name (akun SISWA)   ← TITIK BOCOR (TEMUAN-2)

schools.name ──> [data-brand] topbar/logo/title  (segar)
school_config.school_name ──> admin dashboard H2  ← TITIK BOCOR (TEMUAN-1)

academic_year (string) ──> classes/enrollments/assignments/schedules + school_config.current_*
   → Berpindah tahun tidak otomatis selaras  ← TITIK RAPUH (TEMUAN-3)
```

---

## STATUS PERBAIKAN (2026-07-04)

| Temuan | Status | Keterangan |
|---|---|---|
| TEMUAN-1 (High) | ✅ FIXED | `dashboard.js` H2 baca `getSchoolBranding().name` dari `schools.name` (mig `20260704000000`) |
| TEMUAN-2 (Med-High) | ✅ FIXED | Trigger `students.full_name → users.full_name` + rekonsiliasi 1x (mig `20260704000000`) |
| TEMUAN-3 (Medium) | ✅ FIXED | `fn_current_academic_year(school_id)` dibuat sebagai SSoT (prioritas `academic_periods` ACTIVE, fallback `school_config`). **Langkah-2 (2026-07-04):** 5 edge function yang menulis data kini menggunakan `fn_current_academic_year` via RPC, bukan `school_config.current_academic_year` langsung — `bulk-import-classes`, `bulk-import-schedules`, `bulk-import-students`, `bulk-import-users`, `apply-schedule-templates`. Verifikasi live: `v_academic_year_drift` semua 3 sekolah `config_vs_period_drift=false`, `active_classes_lagging=0`. |
| TEMUAN-4 (Low) | ✅ FIXED | Hardcode "SMK Harapan Rokan" diganti placeholder "Memuat…" di 6 file HTML |

---

## 6. TEST CASE

| Data Master | Lokasi Edit | Modul Terdampak | Status | Bukti |
|---|---|---|---|---|
| Nama Guru | edge `update-user-identifier` | jadwal, absensi, kasus, dashboard kepsek | ✅ Propagasi benar | view JOIN `u.full_name` (`07_indexes_views.sql:79,99,156,243`) |
| Nama Kelas | `updateClass` | jadwal, absensi, manifest offline | ✅ Propagasi benar | `c.name AS class_name` (`07_indexes_views.sql:77,281,337`) |
| Nama Program | `updateProgram` | kelas, siswa | ✅ Propagasi benar (via `program_id`) | FK `programs` |
| Nama Sekolah | panel Branding (`fn_update_school_branding`) | dashboard admin | ❌ **Stale** di H2 dashboard | `dashboard.js:1552` baca `school_config`; fn hanya update `schools` |
| Nama Siswa | `updateStudent` | akun portal siswa / daftar users | ❌ **Stale** di `users.full_name` | `api.js:531` vs `provision-student-accounts:155`; tak ada trigger |
| Pindah Tahun Ajaran | Tutup/Buka Tahun | impor jadwal, kelas | ✅ **FIXED** — 5 edge function baca `fn_current_academic_year` (SSoT) | Langkah-2 2026-07-04 |
| Nama DUDI | edge `update-user-identifier` (`dudi_org_name`) | PKL placement, observasi | ✅ Propagasi benar (via `dudi_user_id`) | FK `pkl_placements` |
| Nama Ortu | edge `update-user-identifier` | relasi siswa | ✅ Propagasi benar (via `student_parents`) | FK `student_parents` |

---

## 7. PENILAIAN (0–100)

| Dimensi | Skor | Catatan |
|---|---|---|
| Single Source of Truth | 72 | Kuat, kecuali 2 duplikasi (sekolah, siswa). |
| Referential Integrity | 90 | FK by ID konsisten di seluruh transaksi. |
| Foreign Key Design | 92 | `ON DELETE RESTRICT`/`SET NULL`, UUID PK. |
| Data Consistency | 74 | Dua titik divergensi + kerapuhan tahun ajaran. |
| Dependency Management | 85 | Dependensi lewat ID; view terpusat. |
| Change Propagation | 78 | Baca DB via JOIN (bagus); klien perlu refresh manual; 2 salinan bocor. |
| Architecture | 85 | Normalisasi baik; multi-tenant konsisten. |
| Maintainability | 80 | Migrasi tertata; sisa kolom warisan (`school_config`). |
| Offline Consistency | 88 | Outbox tulis-saja, tak menyimpan master → tak stale. |
| Synchronization | 80 | Satu-arah idempoten; solid untuk cakupannya. |
| Scalability | 82 | Skema per-`school_id` siap multi-tenant. |
| Production Readiness | 80 | Siap pilot; tutup TEMUAN-1 & 2 sebelum scaling. |

---

## 8. KESIMPULAN

**Penilaian keseluruhan: ✅ BAIK.**

1. **Single Source of Truth?** — **Sebagian besar ya.** Untuk guru, kelas, program, mapel, ortu, DUDI, jadwal: satu sumber, dibaca via ID. **Pengecualian:** nama sekolah (`schools` vs `school_config`) dan nama siswa (`students` vs `users`) tersimpan ganda.

2. **Perubahan master otomatis tercermin?** — **Ya untuk mayoritas** (mekanisme JOIN saat baca membuat pembaca selalu segar). **Tidak** untuk nama sekolah (H2 dashboard basi) dan nama siswa berakun (baris `users` basi).

3. **Masih ada duplicated data?** — **Ya, dua:** `school_config.school_name` dan `users.full_name` (salinan dari `students.full_name`). Tidak ada duplikasi nama di tabel transaksi.

4. **Ada modul menampilkan data usang?** — **Ya, dua permukaan konkret:** (a) `admin/dashboard.html:58` (H2) setelah rename sekolah; (b) tampilan berbasis `users.full_name` setelah rename siswa. Sisanya segar.

5. **Layak jadi fondasi skala besar?** — **Ya, dengan syarat.** Fondasi relasional (FK by ID, view JOIN, offline outbox) sudah benar dan skalabel per-tenant. Sebelum scaling ke banyak sekolah, **tutup TEMUAN-1 dan TEMUAN-2** (menghapus dua sumber kebenaran ganda) dan **konsolidasikan "tahun berjalan" (TEMUAN-3)** agar rollover tahun tidak lagi butuh tambalan manual.

> Semua kesimpulan di atas berbasis implementasi nyata yang dikutip (file:baris). Tidak ada penilaian yang bergantung pada dokumentasi atau niat desain.
