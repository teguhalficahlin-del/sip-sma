# docs/ — Dokumen Penghubung (Titik Masuk Tunggal)

**Diperbarui & direkonsiliasi dengan kode:** 12 Juli 2026.
**Tujuan:** satu halaman ini cukup untuk tahu *ada dokumen apa saja, apa isinya, mana yang masih akurat, dan status platform terkini* — tanpa perlu membuka dokumen satu per satu.

> ## 📌 Dokumen kanonik
> **File ini (`docs/README.md`) adalah SATU-SATUNYA sumber status terkini.** Semua dokumen lain di `docs/` kini berstatus **rujukan rinci** (masih akurat, sudah direkonsiliasi) atau **arsip historis (USANG)**. Bila isi dokumen lain berbeda dengan README ini atau dengan **source code**, maka **README + kode yang menang**.
> - **Rujukan rinci terkini** (boleh dibaca untuk detail): `kemungkinan_buruk.md`, `service-worker-status.md`, `konsep/*`, dan 4 audit bertarget (`attendance`, `audit-multi-tenant`, `referential-integrity`, `temuan-total`).
> - **USANG / arsip historis** (jangan dipakai sebagai status): `audit/00-master-summary.md` + `audit/level-a … level-g` + `audit/level-f2` (basis Juni 2025, hanya console Admin). Sudah diberi stempel USANG di masing-masing file.

> ## ⚖️ Aturan emas kebenaran
> **Kode → Test → Dokumen.** Sumber kebenaran adalah **source code + migrasi + edge functions**, dibuktikan oleh **test/guard-rail**. Dokumen di folder ini **memandu**, tetapi bisa tertinggal dari kode. Bila dokumen dan kode berbeda, **kode yang benar** — perbaiki dokumennya, jangan sebaliknya.
> Tanggal "diverifikasi" di tiap baris menunjukkan kapan terakhir dokumen itu dicocokkan ke kode.

---

## 1. Status Platform Terkini (snapshot terverifikasi 4 Jul 2026)

**Kondisi umum:** pra-launch (3 sekolah data uji: smkhr, smkhb, smkkb). Boleh migrasi skema agresif; belum ada data operasional nyata.

**Sudah live & terverifikasi di kode:**
- **Semua portal aktor** dibangun: `admin/`, `guru/` (Guru/Wali/BK/Kaprodi/Kepsek/Waka Kurikulum/Kesiswaan/Humas), `student/`, `parent/`, `dudi/`, `stakeholder/`, `superadmin/`.
- **Isolasi multi-tenant:** RLS di semua tabel; guard-rail `tests/tenant-isolation.mjs` **CHECK 1–15 LULUS — 93/93 ✓** (per 12 Jul 2026). Audit keamanan Fase 1–3 selesai (Juli 7–12 2026).
- **Absensi/observasi/jurnal/kasus offline:** antrean IndexedDB di `guru/js/offline.js` (bukan sekadar rancangan) — **diperbaiki 4 Jul** (regresi `6ded3e5` yang membuat submit gagal senyap; fix `427e866`).
- **Notifikasi:** lonceng in-app DB + poll 60 dtk (portal guru & DUDI) + **peringatan login perangkat baru** (`fn_register_login_device`, mig `20260704110000`, dibangun 4 Jul).
- **Keamanan login:** rate-limit message, idle-timeout 15 mnt (`shared/idle-timeout.js`), deteksi sesi ganda (`shared/login-guard.js`).
- **Siklus data sekolah:** wizard onboarding, tutup semester/tahun, batalkan tahun, Recycle Bin (`restore-user`/`purge-user`), retensi purge alumni 6 bulan (`fn_purge_expired_student`).
- **Alumni:** blokir login alumni, cetak rekap, **update karir alumni** (`updateAlumniCareer`) & **re-enroll siswa KELUAR** (`reEnrollStudent`) — SUDAH ADA di `admin/`.

**Risiko terbuka yang nyata (per kode):**
- **Push notification (device offline) TERBLOKIR** — service worker sengaja dinonaktifkan (`sw.js` self-destruct). Lihat `service-worker-status.md`.
- **Admin utama lupa password** — hanya superadmin bisa reset; mitigasi parsial: Kepsek bisa buat admin baru.
- **Infrastruktur down** (Supabase / GitHub Pages) — tak ada fallback (inheren).
- **Perangkat hancur sebelum sync** — data offline di IndexedDB hilang (tak bisa dicegah sisi-server).
- **2FA penuh** belum ada (keputusan: cukup peringatan perangkat baru untuk audiens sekolah).

---

## 2. Peta Dokumen

### 2a. Status & operasional (paling sering dibaca)
| File | Isi | Status akurasi |
|---|---|---|
| [kemungkinan_buruk.md](kemungkinan_buruk.md) | Katalog skenario buruk di lapangan + status penanganan (10 kategori) | ✅ **Direkonsiliasi ke kode 4 Jul 2026** (lihat §3) |
| [service-worker-status.md](service-worker-status.md) | Status service worker (dinonaktifkan) & implikasi push | Otoritatif untuk keputusan SW/push |
| [panduan-superadmin.md](panduan-superadmin.md) | Panduan operasional superadmin platform | Referensi |

### 2b. Konsep & kesiapan (`konsep/`)
| File | Isi | Sifat |
|---|---|---|
| [konsep/go-live-10-sekolah-checklist.md](konsep/go-live-10-sekolah-checklist.md) | Checklist Go-Live ≤10 sekolah (blocker/should + gerbang Go/No-Go) | ✅ **Direkonsiliasi ke kode 4 Jul** (A2 regresi, E1, D1) |
| [konsep/runbook-rilis-aman.md](konsep/runbook-rilis-aman.md) | Prosedur migrasi & restore aman (1 DB dipakai bersama) | ✅ **Direkonsiliasi 4 Jul** (metode apply CLI; C1/C2 belum kebiasaan; B2 kosong) |
| [konsep/qa-fungsional-e2e.md](konsep/qa-fungsional-e2e.md) | Temuan QA fungsional per peran (E1–E7) + SEC-1 | ✅ **Direkonsiliasi 4 Jul** (E1-2, upsertAttendance, E3 Langkah A/B selesai) |
| [konsep/thousands-of-schools-readiness-guideline.md](konsep/thousands-of-schools-readiness-guideline.md) | Kerangka acuan skala ribuan sekolah (G-ISO/PERF/REL/OPS/SEC/SAAS/COST) | DRAFT masa depan — bukan status |

### 2c. Audit (`audit/`)
| File | Cakupan | Otoritatif? |
|---|---|---|
| [audit/00-master-summary.md](audit/00-master-summary.md) | Rangkuman audit awal 7-level (32 sub-audit) | ⚠️ **Basis Juni 2025 (console Admin) — JANGAN dipakai sebagai status terkini** |
| [audit/level-a … level-g, level-f2](audit/) | Audit awal per-dimensi (kebutuhan, aktor, data, tata kelola, teknologi, UX, visual, konsistensi) | ⚠️ Basis Juni 2025, sebagian di-update 1 Jul 2026 |
| [audit/level-h-mobile-first.md](audit/level-h-mobile-first.md) | Prinsip desain portal mobile (Draft) | Pedoman desain (bukan status) |
| [audit/temuan-total.md](audit/temuan-total.md) | Temuan gabungan portal aktor + local-first + PWA (1 Jul 2026) | ✅ Lebih baru; menelaah portal aktor |
| [audit/audit-multi-tenant.md](audit/audit-multi-tenant.md) | Isolasi tenant adversarial via DB live (3 Jul 2026) | ✅ Otoritatif isolasi |
| [audit/referential-integrity-audit.md](audit/referential-integrity-audit.md) | Integritas referensial & propagasi (4 Jul 2026) | ✅ Otoritatif |
| [audit/attendance-audit.md](audit/attendance-audit.md) | Audit absensi ABS-1..5 + PKL-1 (4 Jul 2026) | ✅ Otoritatif absensi |

**Kesimpulan membaca audit:** untuk **status terkini**, rujuk §1 di atas + 4 audit bertarget (temuan-total, multi-tenant, referential-integrity, attendance). Audit level A–H & master-summary adalah **konteks historis console Admin**, bukan status.

---

## 3. Rekonsiliasi 4 Jul 2026 — dokumen vs kode

Item yang dokumennya melenceng dari kode telah diperbaiki. Ringkas (detail sebelum/sesudah ada di riwayat sesi + di `kemungkinan_buruk.md`):

| Item | Dulu ditulis | Faktanya di kode |
|---|---|---|
| 1.1 / 1.5 / 3.4 | Input offline tak bisa disimpan / write queue belum ada | Antrean offline ADA & berfungsi (fix 4 Jul); sisa risiko hanya perangkat hancur sebelum sync |
| 5.3 / 7.2 | Tak ada auto-deactivate mantan staf | ADA deteksi + nonaktifkan (`fn_get_stale_staff` + `deactivateStaff`); belum terjadwal otomatis |
| 7.1 | Tak ada alert login perangkat baru | ADA (dibangun 4 Jul) |
| 7.6 | Tak ada deteksi concurrent login | ADA deteksi sesi ganda (`shared/login-guard.js`) |
| 10.4 / 10.5 / 10.6 | Tak ada tracking karir / re-enroll / retensi | SEMUA ADA di `admin/` (`updateAlumniCareer`, `reEnrollStudent`, `purgeExpiredStudents`) |
| 2.6 | Sekolah bisa terkunci total | Mitigasi parsial: Kepsek bisa buat admin baru |

---

*Dokumen ini adalah indeks. Kepatuhan status apa pun di sini dibuktikan lewat kode + `tests/`, bukan oleh dokumen ini.*
