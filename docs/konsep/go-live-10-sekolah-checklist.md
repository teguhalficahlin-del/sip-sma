# Checklist Go-Live — 10 Sekolah

**Versi:** v0.1
**Tanggal:** 3 Juli 2026
**Ruang lingkup:** Menyiapkan platform **saat ini** untuk dipakai **hingga 10 sekolah** dengan data siswa nyata.
**Status awal:** 2 sekolah sudah live (SMK Harapan Rokan, SMK Karya Bangsa); isolasi tenant sudah diaudit & diperbaiki (3 Juli 2026).

> **🔄 REKONSILIASI KE KODE — 4 Juli 2026.** Diselaraskan dengan source code (kode = sumber kebenaran). Perubahan utama: (a) **A2 sempat REGRESI** 4 Jul — 2 fungsi SECURITY DEFINER (`fn_purge_expired_student`, `fn_reapply_schedule_templates`) ternyata bisa dieksekusi anon → sudah ditutup (commit `e8f8a6b`), guard-rail hijau lagi; (b) **guard-rail kini CHECK 1–7** (bukan 1–6) — CHECK 7 = kunci eskalasi kasus; (c) **E1 offline** sempat rusak total (regresi `6ded3e5`) → diperbaiki `427e866` + **diverifikasi di browser**; (d) sekolah live kini **3** (+smkhb). Lihat [`docs/README.md`](../README.md) §1. Item operasional (B/C/F) tak bisa diverifikasi dari kode — tetap tergantung tindakan Anda.

> **Cara pakai.** Setiap item punya **Kriteria Selesai (DoD)** yang objektif. Item **[BLOCKER]** wajib hijau sebelum Go-Live; **[SHOULD]** sangat disarankan tapi tak memblokir pilot.
> **Skala 10 sekolah ≈ 12 juta baris `attendance`/tahun — remeh untuk Postgres.** Jangan over-engineer (lihat §G).

---

## A. Keamanan & Isolasi Tenant  *(sebagian besar SUDAH — tinggal verifikasi)*

- [x] **[BLOCKER] A1 — Isolasi RLS terbukti**
  DoD: 28/28 tabel RLS enabled; 103/103 policy filter `school_id`.
  Verifikasi: `tests/tenant-isolation.mjs` CHECK 1 hijau. **Status: SELESAI.**

- [x] **[BLOCKER] A2 — Tak ada RPC penulis terekspos anon**
  DoD: 0 fungsi VOLATILE SECURITY DEFINER executable oleh anon (di luar allowlist).
  Verifikasi: `tenant-isolation.mjs` CHECK 2 & 4 hijau. **Status: SELESAI (hijau lagi per 4 Jul 2026).**
  ⚠️ **Catatan regresi (4 Jul 2026):** guard-rail menangkap 2 fungsi baru yang lolos REVOKE — `fn_purge_expired_student` (mig 080000, MENGHAPUS siswa, tanpa cek pemanggil) & `fn_reapply_schedule_templates` (mig 050000) — keduanya executable anon. Ditutup mig `20260704120000` (REVOKE PUBLIC → GRANT service_role), commit `e8f8a6b`. **Pelajaran: kelas bug ini berulang tiap ada fungsi SECDEF baru → A4 (CI wajib) makin penting agar tertangkap otomatis.**

- [x] **[BLOCKER] A2b — Tak ada VIEW publik yang bocor ke anon (SEC-1)**
  DoD: semua view public `security_invoker=true` (menegakkan RLS penanya); anon tak bisa membaca barisnya.
  Verifikasi: `tenant-isolation.mjs` **CHECK 6** hijau (struktural + perilaku). **Status: SELESAI** — SEC-1 ditemukan & ditutup 3 Juli (mig `20260703230000`, 7 view); anon `[]`, authenticated tetap lihat sekolahnya. Detail: `qa-fungsional-e2e.md` §SEC-1. *(4 Jul: full run CHECK 1–7 LULUS.)*

- [x] **[BLOCKER] A3 — Cross-Tenant Test nyata**
  DoD: uji dengan 2 akun (Sekolah A & B) membuktikan A **tidak** membaca baris B di seluruh tabel inti → 0 baris.
  Verifikasi: `tenant-isolation.mjs` CHECK 5 (simulasi konteks RLS admin tiap sekolah). **Status: SELESAI** — diverifikasi live: admin smkhr melihat 0 baris smkkb & sebaliknya, masing-masing tetap melihat sekolahnya (1296 & 447 siswa). Commit `2bfd08c`.

- [~] **[SHOULD] A4 — Guard-rail berjalan otomatis sebelum deploy**
  DoD: `tenant-isolation.mjs` dijalankan (CI) dan **memblokir** rilis jika gagal.
  Verifikasi: `.github/workflows/tenant-isolation.yml` (push/PR ke main). **Status: MEKANISME SIAP** (commit `2bfd08c`) — file workflow **terkonfirmasi ada di repo (cek 4 Jul)**; perlu 2 langkah manual Anda yang **tak bisa diverifikasi dari kode** (setelan GitHub):
  (1) tambah repo secret `SUPABASE_ACCESS_TOKEN`; (2) jadikan check "Tenant Isolation Guard-Rail" sebagai **required status check** di branch protection agar benar-benar memblokir merge.
  *(Relevansi naik: regresi A2 hari ini justru contoh nyata yang akan tertangkap gerbang ini bila sudah aktif.)*

---

## B. Data & Pemulihan  *(paling kritis — data anak nyata)*

- [ ] **[BLOCKER] B1 — Backup aktif**
  DoD: backup otomatis DB aktif (Supabase daily/PITR sesuai tier), terkonfirmasi menyala.
  Verifikasi: cek dashboard Supabase → Database → Backups.

- [ ] **[BLOCKER] B2 — Restore TERUJI**
  DoD: satu latihan restore ke lingkungan uji **berhasil** dan datanya utuh — bukan sekadar "backup ada".
  Verifikasi: catatan latihan restore (tanggal, hasil, RPO teramati). **Prosedur siap:** `runbook-rilis-aman.md` §3 (langkah + tabel catatan hasil). Tinggal dieksekusi.

- [ ] **[SHOULD] B3 — Ekspor per-sekolah**
  DoD: mampu mengekspor data satu sekolah bila diminta (portabilitas/keluar tenant).
  Verifikasi: uji ekspor 1 sekolah.

---

## C. Rilis & Operasional  *(DB bersama = 1 kesalahan kena 10 sekolah)*

- [ ] **[BLOCKER] C1 — Backup sebelum tiap migrasi**
  DoD: prosedur wajib: ambil/verifikasi backup **sebelum** menjalankan migrasi ke live.
  Verifikasi: checklist rilis + jejak `schema_migrations`. **Prosedur siap:** `runbook-rilis-aman.md` §1 (konfirmasi backup otomatis + snapshot bertarget 1b + checklist pra-apply). Tinggal dijadikan kebiasaan.

- [ ] **[BLOCKER] C2 — Setiap migrasi punya rencana rollback**
  DoD: tiap migrasi menyertakan cara membalik (down-path atau langkah pemulihan).
  Verifikasi: template PR/rilis memuat bagian rollback. **Prosedur siap:** `runbook-rilis-aman.md` §2 (tabel rollback per jenis + template header migrasi). Terapkan mulai migrasi berikutnya.

- [ ] **[SHOULD] C3 — Alerting error dasar**
  DoD: notifikasi bila error rate/5xx melonjak atau Edge Function gagal.
  Verifikasi: 1 alert uji terpicu.

- [ ] **[SHOULD] C4 — Cek kesehatan harian sederhana**
  DoD: cara cepat melihat platform sehat (login jalan, absensi tersimpan).
  Verifikasi: prosedur/monitor ringan.

---

## D. Onboarding & Kredensial  *(ulangi untuk tiap sekolah baru)*

- [~] **[BLOCKER] D1 — Provisioning sekolah teruji**
  DoD: `provision-school` membuat tenant + admin lengkap dalam 1 langkah, idempoten.
  Verifikasi: uji provisioning 1 sekolah dummy lalu hapus.
  **Status (cek kode 4 Jul 2026): SEBAGIAN.** Edge fn `provision-school` ada & sudah dipakai nyata untuk meng-onboard **3 sekolah** (smkhr, smkhb, smkkb) end-to-end — bukti praktik kuat. **Sisa formal:** uji dummy-provision-lalu-hapus terdokumentasi (bukti idempoten + `delete-school` bersih) belum dicatat.

- [x] **[BLOCKER] D2 — Tak ada password default aktif**
  DoD: admin tiap sekolah **wajib ganti password** saat login pertama; tidak ada default seragam tersisa.
  Verifikasi (TERVERIFIKASI 3 Juli 2026, telusur kode): rantai penegakan admin utuh —
  (1) `provision-school` memberi **password acak unik per sekolah** via `randomPassword()` (bukan default seragam) + set `school_config.password_changed=false`;
  (2) `admin/js/wizard.js:1994` menggerbang: `if (!config?.password_changed) { showPasswordModal(true); return; }` — `return` memblokir `goToStep(1)` sampai password diganti (`api.js:312` set `password_changed=true`);
  (3) sabuk pengaman: modal menolak `<8` karakter **dan** literal `Admin1234` (`wizard.js:1909`).
  **Status: SELESAI.** *(Akun Admin smkhr — kasus default legacy — sudah direset 3 Juli.)*
  **Catatan:** dua mekanisme paralel — admin pakai `school_config.password_changed`, aktor lain (guru/siswa/ortu/dudi/stakeholder) pakai `users.must_change_password`. Keduanya bekerja; penegakan bersifat **sisi-klien** (memadai untuk 10 sekolah, lihat `G-SEC` di guideline untuk penegakan sisi-server pada skala besar).

- [ ] **[SHOULD] D3 — Panduan admin sekolah**
  DoD: dokumen singkat cara admin menyiapkan sekolahnya (impor, tahun ajaran, jadwal).
  Verifikasi: `docs/panduan-superadmin.md` + panduan admin tersedia & terbaca.

---

## E. QA Fungsional End-to-End  *(RISIKO TERBESAR — belum diaudit)*

> Audit sebelumnya menguji **keamanan/isolasi**, bukan apakah alur harian benar-benar mulus. Uji tiap alur inti dengan akun peran nyata di 1 sekolah uji.

- [~] **[BLOCKER] E1 — Alur Guru**: absensi sesi tersimpan (termasuk saat offline lalu sync), observasi tercatat.
  **DIAUDIT (telusur-kode) — 1 temuan medium `E1-1` DIPERBAIKI**: koreksi absensi saat offline bisa hilang senyap (antrean akumulatif + flush urut-UUID). Fix diterapkan di `guru/js/offline.js` (`idbPurgeAttSession` — supersede per sesi). Detail: `qa-fungsional-e2e.md` §E1. Sisa perlu uji manusia (round-trip rekap + siklus offline nyata 🧪).
  🔴 **TEMUAN BARU 4 Jul 2026 (`E1-2`, CRITICAL) — DIPERBAIKI + DIVERIFIKASI BROWSER:** SELURUH submit guru (absensi/observasi/jurnal/kasus) **gagal senyap** sejak 2 Jul (regresi `6ded3e5` menghapus `SUPABASE_URL`/`SUPABASE_ANON_KEY` yg masih dipakai `postEdgeFn`) → tak pernah mencapai server, mengantre selamanya, terhapus saat logout. Fix `427e866` (ekspor konstanta dari api.js). **Diverifikasi di browser** (localhost, login nyata): siklus offline → reload (data bertahan) → online → flush → antrean bersih; POST ke `sync-case` terkonfirmasi. Ini **menutup sebagian 🧪 E1** (round-trip offline kini terbukti otomatis; uji perangkat fisik nyata belum). Tanpa fix ini, E1 sebenarnya GAGAL total, bukan hijau.
- [~] **[BLOCKER] E2 — Alur Wali Kelas / Kaprodi**: hanya melihat siswa tanggung jawabnya; rekap benar.
  **DIAUDIT (telusur-kode)** — scoping UI dari identitas server ✓, rekap pakai session_date + exclude void ✓. **Temuan `E2-1` DISELESAIKAN** (keputusan 3 Juli: EKSKUL dihapus, dihitung HADIR) — dilebur di rekap/tampilan semua portal + spec diperbarui. Detail: `qa-fungsional-e2e.md` §E2. Sisa perlu uji manusia (round-trip angka rekap 🧪).
- [~] **[BLOCKER] E3 — Alur BK**: buat & tangani kasus, eskalasi antar peran.
  **DIAUDIT (telusur-kode)** — otorisasi server kuat: hanya handler saat ini/KEPSEK bisa insert event, `author_user_id` = user asli, append-only, no-event-on-closed, isolasi sekolah ✓. **3 temuan** — `E3-1` (medium): rantai eskalasi & transisi status hanya di klien, server terima peran/status sembarang (perlu keputusan: kodekan rantai di trigger); `E3-2` (low): `author_role_at_time` tak diverifikasi → label peran bisa dipalsukan di timeline (fix aman 1 baris RLS); `E3-3` (low kosmetik). Detail: `qa-fungsional-e2e.md` §E3.
- [ ] **[BLOCKER] E4 — Alur Siswa & Orang Tua**: melihat data sendiri saja; jadwal/kehadiran tampil benar.
- [ ] **[SHOULD] E5 — Alur DUDI & PKL**: pembimbing melihat siswa PKL binaannya saja.
- [ ] **[SHOULD] E6 — Alur Kepsek/Waka/Stakeholder**: dashboard/monitoring hanya sekolah sendiri.
- [ ] **[BLOCKER] E7 — Setup sekolah**: impor massal (siswa/guru/ortu), tahun ajaran, jadwal→penugasan→absensi tersambung.

  DoD tiap item: alur berhasil dari awal-akhir tanpa error mentah, data konsisten antar-portal.
  Verifikasi: skenario uji terdokumentasi + hasil.

---

## F. Dukungan & Legal Ringan

- [ ] **[SHOULD] F1 — Jalur dukungan**: cara 10 admin melapor masalah + runbook masalah umum.
- [ ] **[SHOULD] F2 — Dasar privasi (UU PDP)**: pemberitahuan/persetujuan pemrosesan data siswa + kebijakan retensi minimal.
  DoD: dokumen kebijakan singkat tersedia untuk sekolah.

---

## G. JANGAN dikerjakan dulu  *(over-engineering untuk 10 sekolah)*

Tunda semua ini sampai skala **ratusan–ribuan** sekolah:
partisi tabel · sharding / read-replica · uji beban 500 juta baris ·
feature-flags/tier/billing · kuota per-tenant · biaya sub-linear ·
custom domain/SMTP/WhatsApp per tenant.
→ Lihat `thousands-of-schools-readiness-guideline.md` untuk fase-fase besar.

---

## H. Gerbang Go / No-Go

**GO** hanya bila **semua [BLOCKER] hijau**:

```
  A1 ✅  A2 ✅  A3 ✅
  B1 ☐   B2 ☐
  C1 ☐   C2 ☐
  D1 ☐   D2 ✅
  E1 ☐   E2 ☐   E3 ☐   E4 ☐   E7 ☐
```

**Status ringkas per 3 Juli 2026:** isolasi (A1–A3) **selesai** + A4 mekanisme CI siap (perlu set secret) + D2 (no default password) **terverifikasi**; sisanya (backup/rilis/onboarding-provisioning/QA) **belum**.
Perkiraan penutupan realistis: **hitungan hari–minggu** (bukan bulan), karena hampir semuanya operasional/QA, bukan re-arsitektur.

**Pembaruan 4 Juli 2026 (rekonsiliasi kode):** guard-rail **CHECK 1–7 LULUS** setelah menutup regresi A2 (2 fungsi anon-exec, commit `e8f8a6b`). **E1 naik dari "gagal senyap" ke terverifikasi-browser** setelah fix `427e866` (regresi submit offline `E1-2`). **D1 → SEBAGIAN** (3 sekolah ter-provisioning nyata). Sekolah live kini **3**. Blok B/C/F (backup/rilis/support) tetap **belum** — operasional, di luar jangkauan verifikasi kode.

**Aturan main:** platform dinyatakan **layak untuk 10 sekolah** saat seluruh [BLOCKER] hijau **dan** dibuktikan (backup restore teruji + QA fungsional lulus) — bukan diasumsikan.

---

*Dokumen konsep. Sumber kebenaran tetap kode + test; checklist ini memandu kesiapan operasional, kepatuhannya dibuktikan lewat verifikasi tiap item, bukan oleh dokumen ini.*
