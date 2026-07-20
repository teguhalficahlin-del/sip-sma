# QA Fungsional End-to-End — Catatan & Temuan

**Versi:** v0.1 · **Tanggal:** 3 Juli 2026
**Menutup checklist:** `go-live-10-sekolah-checklist.md` → **Bagian E** (QA fungsional alur harian).
**Metode:** telusur-kode statis alur per peran (menemukan celah logika sebelum uji manusia). Temuan yang perlu uji manusia ditandai eksplisit.

> **Batas metode.** Telusur-kode menemukan celah logika & integritas data; ia **tidak** membuktikan UX mulus di perangkat nyata. Item ber-tanda 🧪 tetap butuh uji manual sebelum E dinyatakan hijau.

> **🔄 REKONSILIASI KE KODE — 4 Juli 2026.** Diselaraskan dgn source code. Perubahan: (a) **E1 temuan baru CRITICAL `E1-2`** — submit guru gagal senyap (regresi `6ded3e5`), diperbaiki `427e866` + diverifikasi browser; (b) **E1 catatan kebersihan** — `upsertAttendance` sudah DIHAPUS (bukan lagi kandidat); (c) **E2 sisa kecil** — `validate.ts` sudah buang EKSKUL; pemetaan defensif EKSKUL→Hadir masih ada di frontend (dead-but-harmless); (d) **E3 Langkah A-frontend & Langkah B-notifikasi in-app SUDAH SELESAI** (bukan lagi "sisa"). Lihat [`docs/README.md`](../README.md) §1.

---

## 🔴 TEMUAN KEAMANAN SEC-1 (HIGH) — View publik bocor lintas-tenant ke anon
*(Ditemukan 3 Juli 2026 saat kerja hapus-EKSKUL; pra-ada, bukan diperkenalkan oleh perubahan itu.)*

**Fakta terbukti (uji live):** dengan **anon key** (tanpa login), `GET /rest/v1/v_attendance_daily_summary` mengembalikan baris nyata lintas-sekolah — mis. `{"class_name":"X TKR 2","hadir":0,"total_students":0}`. Sebagai pembanding, tabel dasar `students` mengembalikan `[]` (RLS tabel bekerja).

**Akar masalah:** semua view di `public` (mis. `v_attendance_daily_summary`, `v_offline_sync_manifest_guru`, `v_offline_sync_manifest_substitute`, `v_kepsek_exception_dashboard`, kemungkinan `v_case_timeline`, `v_student_portal_*`) ber-**owner `postgres`** dan **tanpa `security_invoker`** → view berjalan sebagai owner, **melewati RLS** tabel di bawahnya. Sementara `anon` (dan `authenticated`) memegang `SELECT` pada view-view itu (default privileges Supabase). Hasilnya: siapa pun dengan anon key bisa membaca **agregat kehadiran + nama kelas semua sekolah** sekarang, dan **PII siswa (nama, NIS) + jadwal** via manifest offline begitu ada jadwal di jendela 7-hari (`v_offline_sync_manifest_guru` kini `[]` hanya karena 0 baris di jendela, bukan karena terblokir).

**Dampak:** kebocoran lintas-tenant **dan** ke publik tak terautentikasi. Belum ada data nyata (pra-launch), tapi **wajib ditutup sebelum go-live**.

**Gap guard-rail:** `tests/tenant-isolation.mjs` CHECK 3 hanya menguji **tabel** inti, bukan **view**. Karena itu kelas bug ini lolos audit sebelumnya.

**Status: ✅ DIPERBAIKI & DIVERIFIKASI LIVE (3 Juli 2026).**
- Migrasi `20260703230000_views_security_invoker.sql`: `security_invoker=true` pada **ke-7 view** public → view menegakkan RLS penanya.
- **Bukti live pasca-fix:** anon → `[]` pada ketujuh view (sebelumnya bocor baris nyata). Simulasi authenticated admin SMK Harapan Rokan → **34.883 baris sekolahnya, 0 baris SMK Karya Bangsa** via `v_attendance_daily_summary` (akses sah tetap jalan, lintas-tenant tertutup).
- **Guard-rail CHECK 6** ditambahkan ke `tenant-isolation.mjs`: struktural (semua view wajib `security_invoker=true`) + perilaku (anon tak dapat baris). **Full run CHECK 1–6 LULUS (exit 0).**
- Repo diselaraskan: `contracts/07_indexes_views.sql` (7 view + `WITH (security_invoker=true)`).
- Tak ada code path live yang mengkueri view ini, jadi tak ada regresi fungsional.

---

## E1 — Alur Guru (absensi + observasi)   Status: **DIAUDIT — 1 temuan (medium)**

### Yang TERVERIFIKASI benar (telusur-kode)
- **Jalur simpan absensi tunggal & idempoten.** Dashboard memakai `saveAttendanceBatch` → edge `sync-attendance-batch` → RPC `fn_sync_attendance_batch` (bukan tulis-langsung PostgREST). Idempotensi dijaga tabel `sync_idempotency` + UPSERT `ON CONFLICT (schedule_id, student_id)`. Kirim-ulang aman (`was_duplicate`).
- **Isolasi & otorisasi absensi.** Edge fn memverifikasi pemanggil = guru terjadwal **atau** guru pengganti bertoken valid+belum kedaluwarsa; menolak sesi `KEGIATAN_SEKOLAH`; memvalidasi tiap `student_id` benar-benar terdaftar di kelas+periode jadwal (`class_enrollments`). Siswa luar-kelas ditolak 400.
- **Keying per-tanggal benar.** `teaching_schedules` = satu baris per sesi bertanggal (punya `session_date`), sehingga `(schedule_id, student_id)` efektif per-hari — hari berbeda **tidak** saling menimpa.
- **Observasi.** `insertObservation` → `saveObservation` (offline-capable) → edge `sync-observation`; validasi siswa-satu-sekolah sudah diperbaiki (audit Temuan 5). Observasi = event diskret, jadi antrean akumulatif memang benar (tiap simpan = record baru).

### 🐞 TEMUAN E1-1 (medium) — Koreksi absensi offline bisa hilang senyap
**Lokasi:** `guru/js/offline.js` — store `att_queue` (`keyPath: 'idempotency_key'`), `flushStore()`; `guru/js/dashboard.js:421` (`idempotency_key: crypto.randomUUID()` per simpan).

**Akar masalah:** batch absensi adalah **snapshot satu sesi utuh** yang seharusnya *menggantikan* simpanan sebelumnya, tetapi antrean offline **mengakumulasi** tiap simpan sebagai item baru (kunci = UUID acak), lalu `flushStore` mengirim dalam urutan `getAll()` = **urut kunci (UUID acak)**, bukan urutan waktu. Tak ada timestamp untuk mengurutkan.

**Skenario gagal (offline lalu koreksi):**
1. Guru offline → semua HADIR → Simpan → batch `K1` masuk antrean.
2. Sadar 1 siswa sebenarnya ALPA → ubah → Simpan lagi (masih offline) → batch `K2` (UUID baru, data terkoreksi).
3. Keduanya tersimpan. Saat online, urutan flush = urutan UUID. Bila `K1 > K2` secara leksikografis, `K2` (benar) terkirim dulu lalu `K1` (semua-HADIR, basi) **menimpanya** → koreksi hilang; siswa ALPA tercatat HADIR.

**Dampak:** data kehadiran salah senyap (sulit disadari). Hanya muncul bila **offline + sesi sama disimpan ≥2×** dengan data berbeda. Untuk 10 sekolah yang mayoritas online = kasus tepi, tapi merusak integritas data anak → layak diperbaiki sebelum mengandalkan mode offline.

**PERBAIKAN DITERAPKAN (3 Juli 2026, commit menyusul):** semantik *supersede* via dedup-saat-antre, **tanpa** mengubah `keyPath` store (menghindari bump versi IndexedDB yang berisiko membuang item pending saat upgrade). `guru/js/offline.js`: fungsi baru `idbPurgeAttSession(scheduleId, sessionDate)` menghapus batch absensi tertunda untuk sesi yang sama sebelum `saveAttendanceBatch` mengantre yang baru → paling banyak **satu** snapshot per `(schedule_id, session_date)` di antrean. Karena tak ada lagi duplikat sesi-sama, urutan flush antar-sesi menjadi tak relevan; koreksi terakhir selalu menang. Observasi/jurnal/kasus **tidak** diubah (event diskret, akumulatif memang benar). Syntax `node --check` lulus.

*Alternatif yang dipertimbangkan & ditolak:* (A) ganti `keyPath` store → butuh migrasi store IndexedDB (risiko buang pending); (B) tambah `queued_at` lalu urutkan flush → hanya memperbaiki urutan, menyisakan batch redundan. Pendekatan terpilih menghapus **akar** (akumulasi) sekaligus.

**🧪 Verifikasi lanjutan (perlu perangkat/manusia):** matikan jaringan → Simpan (semua HADIR) → koreksi 1 siswa ke ALPA → Simpan lagi → nyalakan jaringan → pastikan hasil server = koreksi terakhir (siswa itu ALPA), bukan HADIR.

### 🔴 TEMUAN E1-2 (CRITICAL) — Semua submit guru gagal senyap (regresi) — ✅ DIPERBAIKI + DIVERIFIKASI BROWSER (4 Jul 2026)
**Lokasi:** `guru/js/offline.js` `postEdgeFn()`; `guru/js/api.js`.
**Akar masalah:** commit `6ded3e5` (2 Jul, "hapus duplikat GoTrueClient") menghapus `const SUPABASE_URL` & `SUPABASE_ANON_KEY` di `offline.js` bersama client duplikat, **tetapi `postEdgeFn` masih mereferensikannya** → `ReferenceError` yang tertangkap sebagai `networkError`. Akibat: SETIAP submit lewat edge function (absensi, observasi, jurnal, kasus) **tak pernah mencapai server** — bahkan saat ONLINE jatuh ke antrean — lalu terhapus saat logout. Rusak senyap sejak 2 Jul, live di main.
**Dampak:** ini membuat E1 (dan sebagian E3) sebenarnya **GAGAL TOTAL**, bukan hijau. Tidak ada data guru NYATA hilang hanya karena pra-launch (0 data operasional).
**Perbaikan (`427e866`):** ekspor kedua konstanta dari `api.js`, impor di `offline.js` (tanpa client duplikat).
**✅ Diverifikasi di browser (localhost, login Waka Humas nyata):** sebelum = 0 request ke `sync-case` saat flush; sesudah = POST terkirim; siklus **offline → reload (data bertahan) → online → flush → antrean bersih**. Ini menutup **sebagian 🧪 E1** (round-trip offline kini terbukti otomatis; uji perangkat fisik nyata masih perlu).
**Pelajaran:** tak ada guard-rail yang menangkap ini → pertimbangkan smoke-test jalur submit.

### 🧪 Perlu uji manusia (belum tertutup telusur-kode)
- E1-a: absensi sesi tersimpan & tampil benar di rekap wali/kaprodi (round-trip antar-portal).
- E1-b: siklus offline nyata di perangkat (matikan jaringan → simpan → nyalakan → flush otomatis pada event `online`), termasuk skenario TEMUAN E1-1 setelah perbaikan.
- E1-c: banner status jujur ("menunggu sinkron" vs "tersimpan") sesuai hasil.

### Catatan kebersihan (non-blok)
- ~~`upsertAttendance` kandidat dead code~~ → ✅ **SUDAH DIHAPUS** (ABS-5, 4 Jul 2026; kini `guru/js/api.js:190` hanya komentar penanda). Tak ada lagi dua jalur tulis absensi yang membingungkan.
- Payload `session_date` dari klien (`dashboard.js:424`) **diabaikan** server (server pakai `schedule.session_date`). Tidak salah, tapi menyesatkan — pertimbangkan hapus dari payload atau dokumentasikan bahwa server otoritatif.

---

## E2 — Alur Wali Kelas / Kaprodi (rekap)   Status: **DIAUDIT — 1 temuan minor (butuh keputusan produk)**

### Yang TERVERIFIKASI benar (telusur-kode)
- **Scoping UI dari identitas server, bukan input user.** Rekap wali memakai `currentUser.wali_kelas_class_id`, kaprodi memakai `kaprodi_program_id` — keduanya diambil dari baris `users` milik pemanggil (`getCurrentUserRow`, difilter `auth_user_id` server-side). Wali/kaprodi **tidak bisa** memilih kelas/program lain lewat UI → "hanya melihat siswa tanggung jawabnya" terpenuhi di lapisan aplikasi.
- **Rekap pakai tanggal sesi, bukan waktu input.** `getWaliAttendanceSummary` mengagregasi via `teaching_schedules.session_date` (range benar), `!inner` ke `attendance`, dan **mengecualikan `is_void=false`** → sesi yang dibatalkan (guru tidak hadir) tak ikut terhitung. Sama untuk rekap Waka (`getAttendanceRecapPerClass`).
- **Cakupan status lengkap.** Enum `attendance_status` = {HADIR, TIDAK_HADIR, IZIN, SAKIT, EKSKUL} — semua punya bucket di agregator; tak ada status yang jatuh ke `total` tanpa terhitung.

### 🐞 TEMUAN E2-1 (minor — butuh keputusan produk) — EKSKUL mengencerkan % & angka tak rekonsiliasi
**Lokasi:** `guru/js/api.js:260-269` (agregasi) + `guru/js/dashboard.js:644-655` (tabel wali).
**Masalah:** `total` (penyebut persentase) mencakup **EKSKUL**, tetapi tabel wali hanya menampilkan kolom HADIR/IZIN/SAKIT/TIDAK_HADIR (EKSKUL **tidak** ditampilkan). Akibatnya bila EKSKUL > 0:
1. `pct = HADIR/total` **turun** karena sesi ekstrakurikuler dihitung sebagai "bukan hadir" — padahal siswa sebenarnya di sekolah/kegiatan resmi.
2. Empat kolom yang tampak **tidak menjumlah ke `total`** → wali tak bisa merekonsiliasi angka ("kenapa % lebih rendah dari HADIR÷(jumlah kolom terlihat)?").

**Dampak:** bukan korupsi data — tapi rekap **menyesatkan** (persen kehadiran tampak lebih buruk dari kenyataan; angka tak konsisten). Muncul hanya bila ada sesi EKSKUL.
**KEPUTUSAN (3 Juli 2026):** EKSKUL **dihapus dari absensi**; siswa yang ikut ekskul **dihitung HADIR**. (Catatan: spec lama `requirements-final.md` justru meminta EKSKUL *dikecualikan dari denominator* — kode yang menaruhnya di denominator melanggar spec-nya sendiri; keputusan ini menggantikan spec lama.)

**PERBAIKAN DITERAPKAN (frontend, live via push Pages):** EKSKUL dilebur → HADIR di semua rekap & tampilan:
- `guru/js/api.js` — `getWaliAttendanceSummary` & `getAttendanceRecapPerClass`: normalisasi `EKSKUL→HADIR`, bucket EKSKUL dibuang → % kini rekonsiliasi (kolom terlihat menjumlah ke total).
- `parent/js/portal.js`, `student/js/dashboard.js` — count di-fold + label/badge EKSKUL dipetakan ke Hadir.
- `admin/js/dashboard.js` — rekap alumni: `att.EKSKUL` dilebur ke HADIR sebelum dijumlah/cetak.
- Form absensi guru sudah tidak menawarkan EKSKUL sejak sebelumnya (tak ada perubahan).
- Spec `requirements-final.md` §6 diperbarui (EKSKUL ditandai DIHAPUS).
Semua lolos `node --check`.

**HAPUS TOTAL DI DB — SELESAI (keputusan lanjutan 3 Juli: EKSKUL dihapus total; platform pra-launch, 0 data → tanpa risiko):** migrasi `20260703220000_drop_ekskul_status.sql` diterapkan & diverifikasi live — enum `attendance_status` kini `HADIR/TIDAK_HADIR/IZIN/SAKIT` (introspeksi: 0 baris EKSKUL). 4 view dependen di-recreate (kolom `ekskul` dibuang dari summary; grant anon/authenticated/service_role utuh). File repo diselaraskan: `contracts/00_extensions_enums.sql`, `contracts/07_indexes_views.sql`, `contracts/09_event_schema.js`, `contracts/11_api_contract_reference.md`, `_shared/validate.ts`.
**Sisa kecil:** (a) `_shared/validate.ts` sudah dibuang 'EKSKUL' tapi **edge fn `sync-attendance-batch` perlu redeploy** agar berlaku (non-urgent — UI tak pernah kirim EKSKUL & enum DB kini menolaknya); (b) pemetaan defensif `EKSKUL→Hadir` di frontend (parent/student/guru) kini **dead-but-harmless** — boleh dibersihkan kapan saja.
*(Dikonfirmasi ke kode 4 Jul 2026: `validate.ts` memang sudah `['HADIR','TIDAK_HADIR','IZIN','SAKIT']` tanpa EKSKUL; pemetaan `EKSKUL→Hadir` masih ada di `guru/js/api.js`, `parent/js/portal.js`, `student/js/dashboard.js`, `admin/js/dashboard.js` — tetap dead-but-harmless, belum dibersihkan.)*

### Catatan isolasi (low, kemungkinan by-design)
Query rekap mengandalkan **RLS school-scoped** untuk penegakan server; pembatasan "hanya kelas sendiri" bersifat **UI**. Dalam satu sekolah, staf teknis bisa saja mengkueri kelas lain (bukan lintas-tenant). Ini konsisten dengan desain peran pengawas (Waka Kesiswaan `getAttendanceRecapPerClass` & tab BK memang menampilkan data se-sekolah). Untuk wali murni, ini gap least-privilege ringan yang lazim diterima di konteks sekolah. Bila kebijakan menuntut wali benar-benar terkurung ke kelasnya di level server, perlu policy RLS berbasis `wali_kelas_class_id` — catat sebagai keputusan, bukan bug.

---

## E3 — Alur BK (kasus & eskalasi)   Status: **DIAUDIT — 3 temuan (1 medium, 2 low)**

### Yang TERVERIFIKASI benar (telusur-kode)
- **Buat kasus** lewat edge idempoten `sync-case` (offline-capable via `saveCase`); validasi student-satu-sekolah sudah ada (mig `20260703200000`).
- **Otorisasi tindakan kasus kuat di server (RLS `case_events`):**
  - `author_user_id = fn_current_user_id()` → **tak bisa memalsukan SIAPA** yang bertindak.
  - Insert event hanya oleh **handler saat ini** (`c.current_handler_role = fn_current_user_role()`, role dari DB) **atau KEPSEK**; `FINAL_DECISION_MADE` khusus KEPSEK. Staf acak tak bisa menyentuh kasus yang bukan tanggungannya.
  - Tak ada event pada kasus `CLOSED` (INV-1); `case_events` **append-only** (UPDATE/DELETE diblokir trigger); `cases.current_handler_role/is_locked` hanya berubah via trigger (guard memblokir UPDATE langsung).
  - Isolasi sekolah: `cases` dijaga CHECK 5; `case_events` lewat RLS cases.

### TEMUAN E3-1 (medium) — target eskalasi tak divalidasi server — ✅ DISELESAIKAN (3 Juli 2026, Langkah A)
**Keputusan desain (disepakati user):** rantai eskalasi BUKAN gembok — eskalasi antar-internal **bebas** (arah mana pun, boleh lompat), server hanya beri pemberitahuan + peringatan tak-memblokir. Yang dikunci KERAS hanya **batas**: target wajib salah satu 6 peran internal kasus (GURU, BK, WALI_KELAS, KAPRODI, WAKA_KESISWAAN, KEPSEK), dan **DUDI hanya boleh → KAPRODI**.
**Perbaikan (mig `20260703250000`, applied+verified live):** trigger `trg_case_validate_escalate` (`fn_case_validate_escalate`) BEFORE INSERT pada `case_events` menolak DECISION_ESCALATE bila `new_handler_role` bukan peran internal, atau DUDI menargetkan selain KAPRODI. Bukti perilaku: guard-rail **CHECK 7** (SISWA ditolak, DUDI→KEPSEK ditolak, WAKA_KESISWAAN & DUDI→KAPRODI lolos). Rantai diselaraskan `…→WAKA_KESISWAAN→KEPSEK` di 3 tempat (dashboard.js, contracts, requirements).
**Terkait:** bagian dari desain kasus/eskalasi + audiens (ala-FB) — lihat memory `project-case-escalation-design`.
✅ **DIKOREKSI 4 Jul 2026 — "Sisa" SUDAH SELESAI:** Langkah A-frontend (UI eskalasi-bebas + selektor audiens PRIVATE/RESTRICTED/PUBLIC + `updateCaseAudience`/`escalateCase` di `guru/js/`) dan Langkah B-notifikasi **in-app** (tabel `notifications` + trigger 2-kanal + lonceng 🔔 portal guru & DUDI + poll 60 dtk) semuanya LIVE. **Sisa sebenarnya tinggal:** notifikasi **push** ke device offline (FCM/Web Push) — TERBLOKIR service worker dinonaktifkan (lihat `service-worker-status.md`), ditunda atas keputusan user.

### TEMUAN E3-2 (low) — authorship jejak audit — ✅ DISELESAIKAN (3 Juli 2026)
**Koreksi penting:** temuan awal saya (RLS tak cek `author_role_at_time`) berasal dari **`contracts/06` yang BASI**. Introspeksi LIVE menunjukkan policy handler **sudah** menegakkan `author_user_id = fn_current_user_id()` **dan** `author_role_at_time = fn_current_user_role()` (mig pengetatan 330000/340000) — jadi jalur handler biasa **sudah aman**.
**Residual nyata (kini ditutup):** hanya `rls_case_events_insert_kepsek` yang longgar — cek `school_id + fn_is_kepsek()` saja, **tanpa** verifikasi authorship → seorang KEPSEK bisa memalsukan SIAPA/peran di timeline. Severity low (KEPSEK tepercaya, dalam sekolahnya).
**Perbaikan (mig `20260703240000`, applied+verified live):** policy KEPSEK kini juga wajib `author_user_id = fn_current_user_id() AND author_role_at_time = fn_current_user_role()`. Nol dampak ke KEPSEK sah (call-site kirim identitasnya sendiri). `contracts/06` diselaraskan ke live (handler flag-aware via `fn_matches_case_handler` + authorship di kedua policy).
**Pelajaran:** audit enforcement HARUS ke live, bukan `contracts/` (kontrak bisa tertinggal dari migrasi). Lihat juga [[project-audit-rpc-exposure]].

### 🐞 TEMUAN E3-3 (low, kosmetik) — `previous_status`/`previous_handler_role` dari klien, bisa salah
`escalateCase` meng-hardcode `previous_status:'OPEN'`; trigger mengabaikan `previous_*` (pakai `new_*`). Fungsional aman, tapi timeline bisa menampilkan transisi "sebelumnya" yang keliru. Cukup: isi `previous_*` dari state kasus sebenarnya (klien) atau hentikan menyimpannya.

### Catatan UX (low) — klien menawarkan aksi yang ditolak server
`dashboard.js:1559` memberi tombol ubah-status ke `WAKA_KESISWAAN`/BK meski bukan handler, padahal RLS memblokir insert-nya (mereka bukan handler & bukan KEPSEK) → error mentah membingungkan. Selaraskan gating klien dengan RLS (hanya handler/KEPSEK).

---

## E4–E7 — belum diaudit
Menyusul: E4 (siswa & ortu lihat data sendiri), E7 (setup sekolah: impor → tahun ajaran → jadwal → absensi). E5/E6 [SHOULD].

---

*Dokumen konsep/QA. Sumber kebenaran = kode + test. Temuan di sini menandai gap; penutupannya dibuktikan lewat perbaikan kode + uji, bukan oleh dokumen ini.*
