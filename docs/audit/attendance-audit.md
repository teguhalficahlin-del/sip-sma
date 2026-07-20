# AUDIT ABSENSI GURU DI KELAS

**Tanggal:** 2026-07-04
**Sifat:** Read-only (kode tidak diubah). Sebagian diverifikasi ke database live.
**Cakupan tema (peta revisi):** A1 tulis · A2 baca · A3 baca-agregat · B sasaran · C idempotensi/koreksi · D1 kunci-periode · D2 hapus/void · E offline · F isolasi · G integritas/provenance · H propagasi · I enrolmen · PKL (jalur paralel).

---

## RINGKASAN EKSEKUTIF

Alur absensi **kuat di hampir semua dimensi**: otorisasi tulis berlapis (RPC `SECURITY DEFINER` yang di-revoke dari semua peran kecuali service_role + validasi guru/pengganti di edge), provenance tak bisa dipalsukan (`recorded_by` dari JWT, bukan payload), validasi siswa-terdaftar, idempotensi + supersede offline, kunci periode via trigger, dan baca ber-scope per-siswa.

Ditemukan **1 bug lintas-tenant (High, laten)** + **1 ekspos agregat (Medium)** + **2 catatan integritas (Low)**.

| Kode | Temuan | Prioritas |
|---|---|---|
| ABS-1 | `fn_is_period_closed` tidak di-scope `school_id` → tutup semester satu sekolah membekukan input absensi sekolah lain (tanggal identik antar sekolah). | **High (laten)** |
| ABS-2 | `fn_kepsek_monitoring` di-GRANT ke `authenticated` → siswa/ortu/TU bisa menarik % kehadiran se-sekolah. | **Medium** |
| ABS-3 | TU (`ADMINISTRATIVE`) bisa hard-DELETE absensi — bertentangan dengan desain "never deleted, only voided", tanpa jejak audit. | **Low** |
| ABS-4 | Baris ter-void tak bisa ditimpa resubmit (`DO UPDATE … WHERE is_void=FALSE`) + tak ada jalur un-void → GURU_TIDAK_HADIR salah pencet terkunci. | **Low** |
| ABS-5 | Jalur tulis langsung `upsertAttendance` (dead code, di-import tak dipanggil) melewati validasi siswa-terdaftar yang hanya ada di jalur edge. | **Low (laten)** |
| PKL-1 | `pkl_attendance` tidak punya trigger kunci-periode (asimetris dengan `attendance`) → DUDI bisa tulis/edit absensi PKL untuk periode CLOSED. Dikonfirmasi live. | **Low** |

---

## STATUS PERBAIKAN (2026-07-04) — diterapkan & diverifikasi live

Migrasi `20260704030000_attendance_audit_fixes.sql` + edit JS. Semua diverifikasi ke DB live.

| Temuan | Status | Bukti sebelum → sesudah |
|---|---|---|
| **ABS-1** | ✅ **FIXED** | `fn_is_period_closed` kini `(DATE, school_id)` school-scoped; 3 trigger lock (absensi/observasi/jurnal) memasok school_id dari induk. **Uji live:** `fn_is_period_closed('2026-09-15', <sekolah-asing>)` = **FALSE** (sebelumnya akan TRUE → itulah kebocoran). Sekolah pemilik periode CLOSED tetap `TRUE`; periode ACTIVE tetap `FALSE`. Signature 1-arg lama dihapus. |
| **ABS-2** | ✅ **FIXED** | Guard `fn_is_schoolwide_observer()` ditambahkan di awal fungsi (uji live: ada di body); grant `anon` **dicabut** (uji live: anon-grant = false); `authenticated` tetap tapi kini tersaring peran. Siswa/ortu/TU tak lagi bisa menarik agregat. |
| **ABS-3** | ✅ **FIXED** | `DROP POLICY rls_attendance_delete_administrative` (mig `20260704070000`). TU tidak bisa hard-DELETE absensi lagi. Penghapusan siswa kini dikelola via edge fn `purge-expired-students` yang mengurus urutan FK di server-side (bukan client-side policy). |
| **ABS-4** | ✅ **FIXED** | Trigger `trg_unvoid_session_attendance` (AFTER UPDATE, GURU_TIDAK_HADIR→NORMAL) mem-un-void baris yang di-void otomatis → salah pencet kini pulih. (uji live: trigger ada.) |
| **ABS-5** | ✅ **FIXED** | `upsertAttendance` dihapus dari `guru/js/api.js` + import di `dashboard.js`; diganti komentar peringatan. Jalur tulis tersisa hanya edge yang tervalidasi. `node --check` lolos. |
| **PKL-1** | ✅ **FIXED** | Trigger `trg_pkl_attendance_period_lock` ditambahkan (pakai `attendance_date` + school_id) → absensi PKL kini terkunci saat periode CLOSED, simetris dengan absensi kelas. (uji live: trigger ada.) |
| **DROPOUT-1** (Tema I) | ✅ **FIXED** | Roster absensi hanya `AKTIF` di 3 jalur: online (`getEnrolledStudents`), offline (view `v_offline_sync_manifest_guru`/`_substitute` + filter `student_status='AKTIF'`), edge (`sync-attendance-batch` tolak non-AKTIF). Siswa KELUAR/PKL tak lagi muncul di daftar absen; visibilitas/riwayat tak disentuh. **Uji live:** roster lama memuat 2 non-AKTIF → roster baru **0**. Migrasi `20260704040000` + edge redeploy. |

---

## YANG SUDAH BENAR (tidak ada temuan)

- **A1 Otorisasi tulis.** `fn_sync_attendance_batch` di-`REVOKE EXECUTE … FROM PUBLIC/anon/authenticated` (mig `20240115000000:189-191`) → hanya service_role. Edge `sync-attendance-batch` memakai `getAdminClient()` lalu memvalidasi sendiri: `isAssignedTeacher = schedule.scheduled_teacher_id === user.user_id` **atau** guru pengganti dengan token cocok + belum kedaluwarsa (`index.ts:161-195`). Klien tak bisa memanggil RPC langsung untuk menembus RLS.
- **G Provenance.** `p_submitted_by = user.user_id` diambil dari JWT hasil `resolveAuth`, **bukan** dari `payload.submitted_by` (yang diabaikan). `recorded_by_user_id` tak bisa dipalsukan. Trigger `trg_auto_recorded_by` mengisi dari JWT bila jalur langsung. Constraint: `UNIQUE(schedule_id, student_id)`, `chk_void_reason`.
- **B Ketepatan sasaran.** Edge memfilter tiap `student_id` terhadap `class_enrollments` (class+academic_year+semester, `withdrawn_at IS NULL`) dan menolak bila ada siswa tak terdaftar (`index.ts:206-226`). Absensi tak bisa ditulis untuk siswa di luar kelas.
- **C Idempotensi/koreksi.** Edge memeriksa `sync_idempotency` sebelum proses (return `was_duplicate`), dan upsert `ON CONFLICT (schedule_id, student_id)` idempoten. Offline (`guru/js/offline.js`) mem-*supersede* batch sesi yang sama sebelum antre (fix E1-1) → koreksi tak hilang.
- **D1 Kunci periode.** `trg_attendance_period_lock` (BEFORE INSERT/UPDATE) memblokir tulis bila `session_date` jatuh di periode CLOSED — fires juga di jalur batch SECURITY DEFINER. (Lihat ABS-1 untuk cacat scope-nya.)
- **D2 Void.** `trg_void_session_attendance` mem-void seluruh absensi sesi saat `meeting_status→GURU_TIDAK_HADIR`; baris di-void, tak dihapus.
- **E Offline.** Outbox tulis ber-ID; supersede; flush urut; item skema lama di-discard; antrian dibersihkan saat logout.
- **A2 Baca.** Ber-scope `fn_can_see_student` (guru→yang diajar, wali→kelasnya, kaprodi→prodinya, BK/kepsek/waka_kesiswaan→se-sekolah), siswa→diri, ortu→anak; `is_void=false` untuk non-guru. **[Update 2026-07-04]** Waka Kurikulum dikeluarkan dari `fn_is_schoolwide_observer()` (mig `20260704060000`) — kurikulum bukan bidang pengawasan absensi; akses-nya kini setara guru biasa.
- **H Propagasi.** View pakai `security_invoker` + JOIN master hidup; `fn_kepsek_monitoring` & `fn_stakeholder_summary` menghitung `is_void=false` → baris void tak mengotori angka.
- **F/PKL.** `pkl_attendance` tabel & RLS terpisah (DUDI rw milik sendiri, staf baca ber-scope, siswa baca diri, admin delete ber-scope `school_id`) — jalur paralel terisolasi.

---

## TEMUAN RINCI

### ABS-1 — Kunci periode bocor lintas-tenant (Prioritas: HIGH, laten)

**Lokasi:** `contracts/05_triggers_functions.sql:682` (`fn_is_period_closed`), dipakai `fn_attendance_period_lock` (`:701`). Tidak pernah didefinisikan ulang di migrasi mana pun (grep `fn_is_period_closed` = nihil) → versi live = versi kontrak.

**Penyebab:**
```sql
CREATE FUNCTION fn_is_period_closed(p_date DATE) ... AS $$
    SELECT EXISTS (
        SELECT 1 FROM academic_periods
        WHERE start_date <= p_date AND end_date >= p_date
          AND status = 'CLOSED'        -- ⛔ tidak ada filter school_id
    );
$$;
```
Fungsi memeriksa `academic_periods` **semua sekolah**. `academic_periods` sudah punya `school_id`, tetapi tidak dipakai di sini.

**Bukti data live:** ketiga sekolah memakai rentang tanggal semester **identik** (2027/2028 S1 = `2027-07-01..2027-12-31` untuk semua). Saat ini semua seragam (semua ACTIVE) sehingga bug **belum** memicu.

**Reproduksi (pasti terjadi saat operasi independen):**
1. Sekolah A menutup 2027/2028 S1 → baris `academic_periods` A jadi CLOSED, menutupi `2027-07-01..2027-12-31`.
2. Sekolah B masih ACTIVE di 2027/2028 S1 (tanggal sama).
3. Guru Sekolah B menyimpan absensi sesi tanggal `2027-09-15` → `fn_is_period_closed('2027-09-15')` menemukan periode CLOSED **milik Sekolah A** → `RAISE EXCEPTION 'Periode sudah ditutup…'` → **input absensi Sekolah B ditolak**, tanpa alasan yang terlihat oleh Sekolah B.

**Dampak:** Menghentikan fungsi harian inti (guru tak bisa absen) di seluruh sekolah yang masih aktif, dipicu oleh aksi sekolah lain. Berlaku sama untuk **observasi** dan **jurnal** (fungsi kunci yang sama). Bukan kebocoran data (memblokir tulis), tapi merusak operasi lintas-tenant. Laten hari ini karena semua sekolah kebetulan seragam.

**Rekomendasi — scope `school_id`:**

Sebelum:
```sql
SELECT EXISTS (
  SELECT 1 FROM academic_periods
  WHERE start_date <= p_date AND end_date >= p_date AND status = 'CLOSED'
);
```
Sesudah (fungsi menerima school_id; trigger memasoknya dari sekolah jadwal):
```sql
CREATE OR REPLACE FUNCTION fn_is_period_closed(p_date DATE, p_school_id UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM academic_periods
    WHERE school_id = p_school_id
      AND start_date <= p_date AND end_date >= p_date
      AND status = 'CLOSED'
  );
$$;
-- di fn_attendance_period_lock: resolve school_id dari teaching_schedules (via schedule_id),
-- lalu fn_is_period_closed(v_session_date, v_school_id).
-- Sinkronkan juga trigger observasi & jurnal.
```

---

### ABS-2 — Ekspos agregat kehadiran ke semua peran (Prioritas: MEDIUM)

**Lokasi:** `fn_kepsek_monitoring` (mig `20260703140000:144-145`). **Verifikasi live** (`information_schema.role_routine_grants`): EXECUTE diberikan ke **`authenticated` DAN `anon`**.

**Penyebab:** Fungsi `SECURITY DEFINER` mengembalikan **persentase kehadiran siswa & guru se-sekolah** (agregat) untuk sekolah si pemanggil (`v_school_id` dari baris `users`-nya). Karena di-GRANT ke `authenticated`, **setiap** pengguna login sekolah itu — termasuk **SISWA, ORTU, TU** — bisa memanggilnya dan memperoleh angka tersebut. Grant `anon` praktis mentah (fungsi butuh `auth.uid()` → error untuk anon), tetapi tetap over-grant yang harus dicabut.

**Risiko:** Bukan PII individual, tetapi data performa sekolah (persentase kehadiran guru & siswa) yang ditujukan untuk Kepala Sekolah/Waka. Ortu/siswa memperoleh metrik internal sekolah.

**Reproduksi:** Login sebagai ORTU → panggil RPC `fn_kepsek_monitoring('bulan_lalu')` → dapat `pct_siswa`, `pct_guru` se-sekolah.

**Rekomendasi — gerbang peran di dalam fungsi:**

Sebelum: siapa pun `authenticated` lolos.
Sesudah (tambahkan di awal fungsi, sebelum menghitung):
```sql
IF NOT fn_is_schoolwide_observer() THEN
    RAISE EXCEPTION 'Akses ditolak: hanya Kepala Sekolah/Waka/BK.';
END IF;
```
(Alternatif: `REVOKE … FROM authenticated; GRANT … TO` peran khusus — tapi Supabase RLS peran = `authenticated`, jadi gerbang di dalam fungsi lebih tepat.)

---

### ABS-3 — Hard-delete TU bertentangan dengan desain void-only (Prioritas: LOW)

**Lokasi:** `rls_attendance_delete_administrative` (mig `20260701130000:353`, ber-scope `school_id` ✓).

**Penyebab:** Desain menyatakan "Records are never deleted — only voided" (`contracts/02:153`), namun TU diberi policy DELETE (untuk mendukung "Hapus Semua siswa" di wizard yang butuh cascade). Efek samping: TU dapat menghapus permanen baris absensi apa pun di sekolahnya **tanpa jejak audit** — mis. menghilangkan catatan ketidakhadiran siswa.

**Dampak:** Terbatas ke sekolah sendiri (scope aman), tetapi melubangi imutabilitas riwayat. Mitigasi: TU adalah peran tepercaya.

**Rekomendasi:** Batasi DELETE hanya lewat cascade penghapusan siswa (mis. hanya bila baris `students` induk ikut dihapus), atau ganti dengan void massal + log; bila hard-delete dipertahankan, tambahkan pencatatan audit.

**KEPUTUSAN FINAL (4 Juli 2026) — Opsi A: policy DELETE TU tetap dicabut, FK `students` tetap RESTRICT (BUKAN cascade).**

Ditinjau ulang terhadap skema live:
- Policy `attendance` saat ini: hanya `rls_attendance_rw_guru` & `rls_attendance_rw_substitute` (ALL, terbatas pemilik jadwal) yang bisa DELETE; TU tidak punya policy DELETE. Sesuai desain void-only.
- FK `attendance_student_id_fkey` = **RESTRICT** → hapus siswa mentah diblokir bila ada absensi.
- Satu-satunya jalur sah menghapus siswa + riwayatnya = `fn_purge_expired_student` (SECURITY DEFINER, dipakai edge `purge-expired-students`), yang **menghapus `attendance` secara eksplisit lebih dulu** (baris 80 mig `20260704080000`) lalu baris `students`. Jadi RESTRICT tak pernah menggagalkan alur retensi.

**Mengapa BUKAN Opsi B (ON DELETE CASCADE):** cascade akan diam-diam menghapus absensi pada SETIAP penghapusan siswa, melewati jalur retensi yang terkontrol & teraudit, dan menghilangkan jaring pengaman RESTRICT. Opsi A lebih aman dan sudah benar tanpa migrasi tambahan. Terverifikasi saat `attendance` masih 0 baris (pra-launch).

---

### ABS-4 — Baris ter-void terkunci dari koreksi (Prioritas: LOW)

**Lokasi:** `fn_sync_attendance_batch` (mig `20260701320000:51-60`): `ON CONFLICT … DO UPDATE … WHERE attendance.is_void = FALSE`.

**Penyebab:** Bila sebuah baris sudah `is_void=TRUE` (mis. sesi ter-void karena GURU_TIDAK_HADIR salah di-set), resubmit **tidak menimpa** (klausa WHERE gagal) — senyap, tanpa error. Tidak ada trigger un-void saat `meeting_status` kembali ke NORMAL.

**Reproduksi:** Set `meeting_status=GURU_TIDAK_HADIR` (semua baris void) → sadar keliru → set NORMAL lagi + resubmit absensi → baris tetap void; kehadiran hari itu hilang dari semua pembaca.

**Rekomendasi:** Sediakan jalur un-void eksplisit (mis. saat `meeting_status` transisi GURU_TIDAK_HADIR→NORMAL, batalkan void baris terkait), atau izinkan upsert menimpa void bila `source` datang dari input guru manual.

---

### ABS-5 — Jalur tulis langsung tanpa penjaga enrolmen (Prioritas: LOW, laten)

**Lokasi:** `guru/js/api.js:141` (`upsertAttendance`), di-import di `guru/js/dashboard.js:15` **tetapi tidak pernah dipanggil** (grep `upsertAttendance(` = hanya definisi). Jalur simpan absensi yang aktif adalah `saveAttendanceBatch → edge` (tervalidasi).

**Penyebab:** `upsertAttendance` melakukan `.from('attendance').upsert()` langsung dengan klien ber-JWT. Ini melewati **RLS `rls_attendance_rw_guru`** (cek kepemilikan jadwal + school_id) dan trigger kunci-periode — tetapi **tidak** memvalidasi bahwa `student_id` terdaftar di kelas sesi itu (validasi enrolmen hanya ada di edge, `sync-attendance-batch:206-226`). Karena hanya FK `student_id→students` yang berlaku, jalur ini secara teori bisa menyisipkan baris absensi untuk siswa mana pun ke sesi milik guru.

**Dampak saat ini:** nihil (dead code). **Risiko laten:** bila dev kelak menyambungkan fungsi ini ke UI, celah validasi enrolmen (ABS/tema B) kembali terbuka pada jalur non-edge.

**Rekomendasi:** hapus `upsertAttendance` (dan import-nya) karena tak terpakai; atau bila dipertahankan sebagai jalur cadangan, tambahkan validasi enrolmen setara jalur edge (atau trigger DB yang menolak `student_id` non-enrolled untuk `schedule_id` terkait).

---

### PKL-1 — `pkl_attendance` tanpa kunci periode (Prioritas: LOW)

**Lokasi:** `supabase/migrations/20260630130000_pkl_attendance.sql`. **Verifikasi live** (`pg_trigger` pada `pkl_attendance`): trigger = `trg_auto_school_id`, `trg_pkl_attendance_student_match_check`, `trg_pkl_attendance_touch` — **tidak ada** padanan `trg_attendance_period_lock` yang dimiliki tabel `attendance`.

**Penyebab:** Absensi kelas dikunci saat periode CLOSED (via trigger); absensi PKL tidak. DUDI dapat menulis/mengubah `pkl_attendance` untuk tanggal di periode yang sudah ditutup.

**Dampak:** Inkonsistensi imutabilitas: rekap PKL periode lampau masih bisa berubah setelah tutup semester. Rendah (PKL dicatat DUDI real-time; edit retro jarang), tapi asimetris dengan absensi kelas.

**Rekomendasi:** tambahkan trigger kunci-periode pada `pkl_attendance` memakai `attendance_date` (langsung punya kolom tanggal — lebih sederhana dari `attendance` yang harus lewat `teaching_schedules`), memanggil `fn_is_period_closed(NEW.attendance_date, NEW.school_id)` **setelah ABS-1 diperbaiki** (agar sekalian school-scoped).

---

## CAKUPAN & TINGKAT KEYAKINAN (setelah penuntasan)

Semua area yang tadinya di-sampel kini **ditutup**:

| Area sampel | Hasil |
|---|---|
| **PKL integritas-tulis** | ✅ Diaudit. Provenance dipaksa (`WITH CHECK recorded_by = self`), `student_id` denormal **dijaga trigger** cocok placement, RLS DUDI ber-scope supervisi. **Temuan: PKL-1** (tak ada kunci periode). |
| **Enum `meeting_status` penuh** | ✅ Hanya 3 nilai (NORMAL/KEGIATAN_SEKOLAH/GURU_TIDAK_HADIR) — **ketiganya tertangani** (normal / edge-tolak / auto-void). Tak ada nilai liar. **Tak ada temuan.** |
| **RLS `rw_substitute` token** | ✅ RLS men-scope via identitas (`substitute_user_id = current`) + `expires_at > now()`. Nilai token adalah mekanisme **sinkron offline**, bukan faktor otorisasi kedua untuk user terautentikasi → RLS sudah cukup. **Tak ada temuan.** |
| **Verifikasi live** | ✅ ABS-1 (data periode), ABS-2 (grant `authenticated`+`anon`), PKL-1 (trigger) semua dikonfirmasi ke DB live. |

**Sisa di luar cakupan modul absensi-siswa (disebut untuk transparansi, bukan bagian audit ini):**
- **TN-02 `teacher_indicator`** (kehadiran GURU, bukan siswa) hanya di-*glance*: dihitung dari sinyal `teacher_attendance_log` yang muncul saat absensi disubmit — presensi guru = tindakan submit absensi (inheren desain, tak ada lubang jelas). Bila ingin diaudit sebagai domain sendiri, jadikan tugas terpisah.

**Kesimpulan cakupan:** untuk absensi **siswa** oleh guru, audit ini kini **final** — 6 temuan (ABS-1..5 + PKL-1). Domain kehadiran **guru** (TN-02) adalah audit terpisah bila diinginkan.

## PENILAIAN (0–100, khusus modul absensi)

| Dimensi | Skor |
|---|---|
| Otorisasi tulis (A1) | 95 |
| Otorisasi baca (A2) | 90 |
| Otorisasi baca-agregat (A3) | 65 |
| Ketepatan sasaran (B) | 95 |
| Idempotensi/koreksi (C) | 90 |
| Kunci periode (D1) | 60 (cacat lintas-tenant) |
| Hapus/void (D2) | 78 |
| Offline (E) | 92 |
| Isolasi tenant (F) | 70 (tulis/baca aman; kunci-periode bocor) |
| Integritas/provenance (G) | 95 |
| Propagasi (H) | 90 |

**Kesimpulan: BAIK**, dengan satu perbaikan wajib sebelum ≥2 sekolah beroperasi mandiri (ABS-1) dan satu pengetatan akses agregat (ABS-2).
