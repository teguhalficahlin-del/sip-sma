# Thousands-of-Schools Readiness Guideline

**Versi:** v0.1 (konsep masa depan)
**Tanggal:** 3 Juli 2026
**Status dokumen:** DRAFT — kerangka acuan, bukan status. Diturunkan dari deskripsi 7-dimensi kesiapan "ribuan sekolah".

> **Tujuan.** Mengubah pertanyaan kabur "apakah platform siap ribuan sekolah?" menjadi **kumpulan aturan ber-ambang, dapat diverifikasi, dan ditegakkan mesin**. Guideline ini adalah **kontrak rekayasa**, bukan deskripsi aspiratif.

---

## 0. Cara membaca guideline ini

Setiap aturan ditulis dengan format tetap:

```
G-<DIMENSI>-<NN>  Judul aturan
  Aturan    : apa yang WAJIB dipenuhi
  Ambang    : kriteria terukur (angka), bukan kata sifat
  Verifikasi: bagaimana dibuktikan
  Gerbang   : penegak — idealnya MESIN (CI/test); jika manual, tandai + pemilik
  Prioritas : P0 (fondasi, sebelum onboarding massal) · P1 · P2
  Status    : Belum · Sebagian · Selesai   (kondisi per 3 Jul 2026)
```

**Prinsip emas (pelajaran audit):** setiap aturan **harus** dipasangkan gerbang otomatis. Aturan tanpa gerbang otomatis akan diam-diam dianggap terpenuhi lalu melenceng — persis seperti klaim "SELESAI" yang ternyata benar sebagian. Hirarki kebenaran tetap: **kode → test → dokumen**.

**Skala acuan:** ~2.000 sekolah × ~1.000 siswa ⇒ ~2 juta siswa, ~4 juta akun, dan `attendance` ~**2,4 miliar baris/tahun**. Semua ambang di bawah mengasumsikan orde besaran ini.

---

## 1. G-ISO — Isolasi Tenant (Correctness at scale)

```
G-ISO-01  RLS wajib di semua tabel operasional
  Aturan    : Setiap tabel public bertenant WAJIB RLS enabled + minimal satu
              policy yang memfilter school_id (atau kepemilikan baris).
  Ambang    : 100% tabel operasional RLS enabled; 0 policy tanpa filter tenant.
  Verifikasi: query katalog pg_class.relrowsecurity + telaah pg_policies.
  Gerbang   : tests/tenant-isolation.mjs CHECK 1 di CI.
  Prioritas : P0     Status: Selesai (28/28 tabel; 103/103 policy)

G-ISO-02  Tidak ada RPC penulis yang terekspos anon
  Aturan    : Tak boleh ada fungsi SECURITY DEFINER VOLATILE (non-trigger)
              yang EXECUTE-nya dipegang anon, kecuali allowlist branding-publik.
  Ambang    : 0 pelanggaran.
  Verifikasi: has_function_privilege('anon', …) atas fungsi fn_* VOLATILE.
  Gerbang   : tests/tenant-isolation.mjs CHECK 2 di CI.
  Prioritas : P0     Status: Selesai

G-ISO-03  Cross-Tenant Test (uji positif dua tenant)
  Aturan    : WAJIB ada uji: login sebagai user Sekolah A → 0 baris milik
              Sekolah B pada seluruh tabel inti.
  Ambang    : 0 baris lintas-tenant terbaca.
  Verifikasi: 2 akun uji (school A & B) + assert kosong.
  Gerbang   : test baru di CI (belum ada).
  Prioritas : P0     Status: Belum  ← gap kritis

G-ISO-04  school_id selalu dari DB, tak pernah dari klien
  Aturan    : Tenant resolver WAJIB menurunkan school_id dari auth.uid()
              (server-side). Input school_id dari body/klien dilarang dipercaya.
  Ambang    : 0 jalur yang memakai school_id dari input klien.
  Verifikasi: telaah kode edge + review PR.
  Gerbang   : review manual (Pemilik: reviewer keamanan) + lint pola.
  Prioritas : P0     Status: Selesai (_shared/auth.ts + fn_current_school_id)

G-ISO-05  Edge Function service_role wajib validasi tenant
  Aturan    : Operasi service_role (bypass RLS) WAJIB memvalidasi bahwa objek
              target ber-school_id = school_id pemanggil.
  Ambang    : 0 operasi service_role tanpa cek school_id.
  Verifikasi: checklist review + guard internal RPC.
  Gerbang   : review manual (Pemilik: tim backend).
  Prioritas : P0     Status: Sebagian (bulk-import ✅; guard RPC ✅ pasca-audit)
```

## 2. G-PERF — Performa & Kapasitas Data (Scale)

```
G-PERF-01  Indeks tenant wajib
  Aturan    : Setiap tabel operasional WAJIB punya indeks komposit dipimpin
              school_id (school_id, <kolom filter/urut panas>).
  Ambang    : 0 tabel operasional tanpa indeks school_id-leading.
  Verifikasi: telaah pg_indexes + EXPLAIN query panas.
  Gerbang   : test katalog di CI (belum ada) menolak tabel tanpa indeks.
  Prioritas : P0     Status: Belum (perlu audit indeks menyeluruh)

G-PERF-02  Latensi query berfilter-RLS terjaga
  Aturan    : Query panas (absensi, dashboard) tetap cepat saat data besar.
  Ambang    : p95 < 200 ms pada dataset uji 500 juta baris attendance.
  Verifikasi: uji beban (k6/pgbench) di dataset skala.
  Gerbang   : gate uji beban terjadwal (nightly) (belum ada).
  Prioritas : P0     Status: Belum (baru 2 sekolah; belum diuji beban)

G-PERF-03  Partisi tabel volume-tinggi
  Aturan    : attendance & observations WAJIB dipartisi (per tahun ajaran
              dan/atau hash school_id) agar data panas tetap kecil.
  Ambang    : ukuran partisi aktif < ambang yang ditetapkan tim DB.
  Verifikasi: telaah skema partisi + EXPLAIN partition pruning.
  Gerbang   : review DB.
  Prioritas : P1     Status: Belum

G-PERF-04  Retensi & arsip tahun ajaran lama
  Aturan    : Data tahun ajaran non-aktif diarsip/dipisah dari tabel panas.
  Ambang    : hanya N tahun ajaran aktif di tabel panas.
  Verifikasi: job arsip + query ukuran.
  Gerbang   : job terjadwal + monitoring.
  Prioritas : P1     Status: Belum

G-PERF-05  Sub-query helper RLS terindeks
  Aturan    : Kolom yang dipakai EXISTS di helper (class_enrollments,
              teaching_assignments, pkl_placements) WAJIB terindeks.
  Ambang    : semua join predikat helper kena indeks.
  Verifikasi: EXPLAIN atas fn_teaches_student / fn_wali_of_student dll.
  Gerbang   : review DB.
  Prioritas : P1     Status: Belum

G-PERF-06  Skala koneksi
  Aturan    : Pooler (Supavisor) aktif; batas koneksi & saturasi termonitor;
              PostgREST diskalakan sesuai beban.
  Ambang    : utilisasi koneksi < 80% pada beban puncak uji.
  Verifikasi: uji beban + metrik pooler.
  Gerbang   : alerting utilisasi koneksi.
  Prioritas : P1     Status: Belum
```

## 3. G-REL — Keandalan & Ketersediaan (Reliability)

```
G-REL-01  SLO ketersediaan
  Aturan    : Target uptime & error budget ditetapkan dan dipantau.
  Ambang    : uptime ≥ 99,9%/bulan; error rate 5xx < 0,1%.
  Verifikasi: uptime monitor + dashboard error.
  Gerbang   : alerting SLO breach.
  Prioritas : P1     Status: Belum

G-REL-02  Backup teruji + DR
  Aturan    : Backup berkala + UJI RESTORE terjadwal; RPO/RTO ditetapkan.
  Ambang    : RPO ≤ 15 mnt; RTO ≤ 1 jam; uji restore lulus tiap kuartal.
  Verifikasi: latihan restore terdokumentasi.
  Gerbang   : jadwal + laporan uji restore (Pemilik: ops).
  Prioritas : P0     Status: Belum (backup mungkin ada; restore belum diuji)

G-REL-03  Observability
  Aturan    : Monitoring slow-query, error rate, metrik per-tenant.
  Ambang    : slow-query > X ms ter-alert; dashboard per-tenant tersedia.
  Verifikasi: konfigurasi monitoring aktif.
  Gerbang   : alerting.
  Prioritas : P1     Status: Belum

G-REL-04  Tanpa SPOF menjatuhkan semua tenant
  Aturan    : Tidak ada komponen tunggal yang jika jatuh menghentikan seluruh
              tenant tanpa mitigasi (mis. read-replica, failover).
  Ambang    : failover teruji.
  Verifikasi: uji chaos/failover.
  Gerbang   : review arsitektur + latihan.
  Prioritas : P2     Status: Belum (satu Postgres bersama)
```

## 4. G-OPS — Operasional & Rilis (Ops readiness)

```
G-OPS-01  Rilis migrasi aman lintas-tenant
  Aturan    : DB bersama = satu migrasi buruk menimpa SEMUA tenant. Migrasi
              WAJIB lewat staging + review; DDL langsung ke live tanpa review
              dilarang.
  Ambang    : 100% migrasi lewat staging + lolos test isolasi sebelum live.
  Verifikasi: pipeline migrasi + catatan schema_migrations.
  Gerbang   : CI (test isolasi) sebelum promote ke live.
  Prioritas : P0     Status: Belum (saat ini apply langsung via Mgmt API)

G-OPS-02  Onboarding sekolah otomatis & idempoten
  Aturan    : Provisioning sekolah baru tanpa langkah DB manual, aman diulang.
  Ambang    : 1 panggilan provision-school → tenant siap; idempoten.
  Verifikasi: uji provisioning berulang.
  Gerbang   : test e2e provisioning.
  Prioritas : P1     Status: Sebagian (provision-school ada)

G-OPS-03  Tenant lifecycle (suspend/delete/arsip)
  Aturan    : Suspend/delete/arsip tenant idempoten + tercatat audit.
  Ambang    : operasi lifecycle idempoten; jejak audit ada.
  Verifikasi: uji lifecycle.
  Gerbang   : test + audit log.
  Prioritas : P1     Status: Sebagian (update-school-status, delete-school ada)

G-OPS-04  Runbook & incident response
  Aturan    : Runbook insiden + on-call + eskalasi terdokumentasi.
  Ambang    : runbook untuk skenario umum tersedia & diuji.
  Verifikasi: latihan tabletop.
  Gerbang   : review berkala (Pemilik: ops).
  Prioritas : P2     Status: Belum

G-OPS-05  Rollback plan tiap migrasi
  Aturan    : Setiap migrasi punya rencana rollback (blast radius = semua tenant).
  Ambang    : 100% migrasi punya rollback/down-path.
  Verifikasi: review PR migrasi.
  Gerbang   : template PR wajib bagian rollback.
  Prioritas : P0     Status: Belum
```

## 5. G-SEC — Keamanan & Kepatuhan (Security/Compliance)

```
G-SEC-01  Audit log akses data
  Aturan    : Akses/perubahan data sensitif tercatat (siapa akses data siapa).
  Ambang    : cakupan audit atas tabel sensitif (students/cases/observations).
  Verifikasi: uji jejak audit.
  Gerbang   : test + review.
  Prioritas : P1     Status: Belum

G-SEC-02  Rate-limit & anti-abuse
  Aturan    : Rate-limit per akun/IP; proteksi DDoS/brute-force.
  Ambang    : batas laju ditetapkan & aktif.
  Verifikasi: uji lonjakan permintaan.
  Gerbang   : konfigurasi gateway.
  Prioritas : P1     Status: Belum

G-SEC-03  Kepatuhan UU PDP (data anak)
  Aturan    : Retensi, hak hapus, dan dasar pemrosesan data pribadi anak
              dipenuhi sesuai UU PDP.
  Ambang    : kebijakan retensi + mekanisme hapus + consent tercatat.
  Verifikasi: audit kepatuhan.
  Gerbang   : review hukum + fitur hapus/retensi.
  Prioritas : P0     Status: Belum  ← wajib sebelum skala nasional

G-SEC-04  Tanpa kredensial default
  Aturan    : Tidak ada password default aktif; wajib ganti saat login pertama.
  Ambang    : 0 akun berpassword default.
  Verifikasi: audit akun + must_change_password.
  Gerbang   : test/scan kredensial.
  Prioritas : P0     Status: Sebagian (kasus Admin smkhr sudah direset)

G-SEC-05  Manajemen & rotasi secret
  Aturan    : service_role key / superadmin key dikelola aman + rotasi berkala;
              tak pernah masuk repo.
  Ambang    : rotasi terjadwal; 0 secret di repo.
  Verifikasi: secret scanning + jadwal rotasi.
  Gerbang   : secret-scan di CI.
  Prioritas : P1     Status: Belum
```

## 6. G-SAAS — Kapabilitas SaaS per-tenant

```
G-SAAS-01  Konfigurasi per-tenant tanpa ubah kode
  Aturan    : Branding, domain, SMTP, WhatsApp, profil kurikulum/workflow
              dapat berbeda per tenant lewat konfigurasi, bukan kode.
  Ambang    : item roadmap terimplementasi sebagai konfigurasi tenant.
  Verifikasi: uji per-tenant.
  Gerbang   : test konfigurasi.
  Prioritas : P2     Status: Sebagian (baru branding)

G-SAAS-02  Feature flags / tier per tenant
  Aturan    : Fitur dapat diaktifkan per tenant/paket.
  Ambang    : sistem flag/tier aktif.
  Verifikasi: uji flag.
  Gerbang   : test.
  Prioritas : P2     Status: Belum

G-SAAS-03  Metering / billing (bila komersial)
  Aturan    : Pemakaian terukur per tenant untuk penagihan.
  Ambang    : metrik pemakaian akurat per tenant.
  Verifikasi: rekonsiliasi metering.
  Gerbang   : laporan billing.
  Prioritas : P2     Status: Belum
```

## 7. G-COST — Ekonomi & Efisiensi

```
G-COST-01  Biaya per tenant sub-linear
  Aturan    : Biaya per sekolah terprediksi dan menurun per unit saat skala naik.
  Ambang    : model biaya/tenant diproyeksikan & dipantau.
  Verifikasi: analisis biaya vs jumlah tenant.
  Gerbang   : review biaya berkala.
  Prioritas : P2     Status: Belum

G-COST-02  Kuota per-tenant (anti noisy-neighbor)
  Aturan    : Batas sumber daya per tenant agar satu sekolah tak meledakkan
              biaya/performa bersama.
  Ambang    : kuota ditetapkan & ditegakkan.
  Verifikasi: uji beban satu tenant vs lainnya.
  Gerbang   : enforcement kuota.
  Prioritas : P2     Status: Belum
```

---

## 8. Prioritas & Urutan (fase)

Tidak semua dikerjakan sekaligus. Urutan yang disarankan:

**Fase 0 — Fondasi (WAJIB sebelum onboarding massal):**
G-ISO-01..05 · G-PERF-01, G-PERF-02 · G-OPS-01, G-OPS-05 · G-REL-02 · G-SEC-03, G-SEC-04 · **semua gerbang CI aktif.**

**Fase 1 — Kesiapan operasi & performa:**
G-PERF-03..06 · G-REL-01, G-REL-03 · G-OPS-02..04 · G-SEC-01, G-SEC-02, G-SEC-05.

**Fase 2 — Kematangan SaaS & ekonomi:**
G-REL-04 · G-SAAS-01..03 · G-COST-01..02.

> **Gerbang kelulusan fase:** sebuah fase dianggap selesai hanya bila **semua aturannya berstatus Selesai dan gerbang otomatisnya hijau** — bukan bila "sudah dikerjakan".

---

## 9. Tata kelola dokumen

- **Living document.** Ditinjau tiap kuartal atau saat arsitektur berubah.
- **Pemilik:** (isi) — arsitektur/DB/ops/keamanan sesuai dimensi.
- **Aturan emas:** tiap `G-*` yang bisa diotomasi WAJIB punya gerbang mesin; yang manual WAJIB punya pemilik + cadence review.
- **Sumber kebenaran tetap kode + test.** Guideline ini memandu; kepatuhan dibuktikan mesin, bukan oleh dokumen ini.

---

*Ringkas: kesiapan "ribuan sekolah" = seluruh aturan P0 berstatus Selesai dengan gerbang hijau, dibuktikan lewat uji beban pada skala target — bukan diasumsikan dari arsitektur yang benar.*
