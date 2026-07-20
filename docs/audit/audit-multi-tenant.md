# Audit Multi-Tenant — Platform Sekolah SMK

**Tanggal audit & remediasi: 3 Juli 2026.**
**Project:** `xovvuuwexoweoqyltepq` (`smk-platform`, ACTIVE_HEALTHY).
**Metode:** adversarial, **berbasis bukti implementasi nyata** — introspeksi **database LIVE** via Supabase Management API (`pg_policies`, `pg_proc`, `pg_class`, privilege katalog) + **probe PostgREST nyata** dengan anon key. **Tidak** menilai dari dokumentasi, komentar kode, atau niat desain.

> **Sikap audit.** Anggap auditor independen yang berusaha membuktikan sistem **belum** multi-tenant. Hanya dinyatakan lulus jika seluruh bukti implementasi menunjukkan isolasi tenant konsisten di semua lapisan. Satu kemungkinan kebocoran tenant = tidak lulus production-ready.

---

## Ringkasan Eksekutif

| Metrik | Hasil |
|---|---|
| Tabel dengan RLS enabled | **28/28 (100%)** |
| RLS policy memfilter tenant (`school_id`/baris-sendiri) | **103/103 (100%)** |
| `school_id` diturunkan dari DB (anti-spoof), bukan input klien | ✅ `_shared/auth.ts` |
| **Lapisan RLS** | ✅ **BERSIH sejak awal** |
| **Lapisan RPC (fungsi SECURITY DEFINER)** | ❌ **Bocor saat audit** → ✅ **FIXED & terverifikasi live** |

**Verdict awal (sebelum remediasi):** *Multi-Tenant, tetapi belum Production-Ready* — arsitektur benar-benar multi-tenant, tetapi ditemukan kebocoran tenant terkonfirmasi di lapisan RPC.
**Verdict akhir (setelah remediasi):** **Isolasi multi-tenant terbukti utuh di semua lapisan dan dijaga test regresi otomatis.** Tidak ada jalur kebocoran tenant yang diketahui tersisa.

Severitas temuan: **1 Critical, 2 High, 3 Medium, 2 Low** — **semua** yang menyangkut isolasi sudah ditutup.

---

## Apa yang sudah benar (bukan sekadar klaim)

- **Tenant = root entity.** Tabel `schools`; setiap tabel operasional punya kolom `school_id`.
- **RLS 100%.** Seluruh 28 tabel `public` memiliki `relrowsecurity = true`. Dua tabel RLS-on tanpa policy (`platform_config`, `sync_idempotency`) = deny-all ke anon (aman by default).
- **Policy konsisten.** 103/103 policy memuat `school_id = fn_current_school_id()` atau kepemilikan baris (`auth_user_id = auth.uid()`). **Nol** policy berbasis-peran tanpa filter tenant. Peran schoolwide (kepsek/waka/BK) **selalu** di-AND dengan `school_id`.
- **Anti-spoof.** `fn_current_school_id()` mengambil `school_id` dari baris `users` via `auth.uid()` (server-side), bukan dari input. Edge Function (`_shared/auth.ts`) juga meresolusi `school_id` dari DB, bukan dari body.
- **Bulk-import ikat tenant.** Semua `bulk-import-*` memakai `user.school_id` (dari DB), tak pernah percaya `school_id` dari body.
- **Superadmin gate fail-closed.** `if (!superadminKey || reqKey !== superadminKey) → 401`.
- **Storage.** 0 bucket & 0 storage policy di live — tidak ada file storage bersama (branding via kolom DB), jadi bukan permukaan bocor.

---

## Akar Masalah (kelas bug — WASPADA berulang)

Fungsi `SECURITY DEFINER` yang **melewati RLS** mewarisi default Supabase `GRANT EXECUTE TO PUBLIC`. Bila `REVOKE` terlewat, fungsi bisa dipanggil **anon langsung via PostgREST** (`/rest/v1/rpc/…`), **melewati seluruh pemeriksaan auth di Edge Function**.

Pola benar **sudah diterapkan** untuk fungsi generasi 2024 (`fn_sync_attendance_batch`, `fn_bulk_import_students` — ada `REVOKE … FROM anon`), tetapi **tidak diterapkan** pada fungsi yang ditambahkan Juni–Juli 2026. Ini kelalaian sistemik, bukan ketidaktahuan.

**Dua jebakan penting untuk perbaikan:**
1. `REVOKE … FROM anon` **saja tidak cukup** selama grant `PUBLIC` masih ada — anon tetap lolos lewat `PUBLIC`. Harus `REVOKE … FROM PUBLIC` lalu `GRANT … TO authenticated/service_role` sesuai pemanggil.
2. Guard internal harus **service_role-safe**: Edge Function memanggil via service_role (`auth.uid()` = NULL). Tegakkan cek hanya `IF auth.uid() IS NOT NULL`, agar jalur edge yang sah tidak rusak.

---

## Temuan & Resolusi

| # | Sev | Temuan | Bukti (live) | Resolusi |
|---|---|---|---|---|
| 1 | 🔴 Critical | `fn_batalkan_tahun_ajaran(uuid)` — pembatalan tahun ajaran destruktif, anon-executable, tenant dari parameter | probe anon → `P0001` (body jalan) | mig `190000`: REVOKE + guard admin/kepsek |
| 2 | 🟠 High | `fn_sync_observation/case/journal` — injeksi observasi/kasus/jurnal lintas tenant, anon-executable | probe anon → `P0004` (body jalan) | mig `190000`: REVOKE + guard penulis=akun-login |
| 3 | 🟠 High | `fn_apply_schedule_templates(…, p_school_id)` — manipulasi jadwal sekolah mana pun, tenant dari parameter | anon-exec di katalog | mig `190000`: REVOKE + guard sekolah+peran |
| 4 | 🟡 Med→Low | `provision-admin` — edge legacy tanpa gate peran, buat admin non-namespaced `Admin/Admin1234` tanpa `school_id`. **Koreksi live:** `verify_jwt=true` (bukan `--no-verify-jwt` spt komentar) → bukan anon, jadi Low | daftar fungsi live | **dihapus dari repo + live** |
| 5 | 🟡 Med | `fn_sync_observation/case` tak memvalidasi `student_id` milik sekolah penulis → referensi student lintas tenant | telaah badan fungsi | mig `200000`: tolak `student_id` beda sekolah (`P0005`) |
| 6 | 🟡 Med | `fn_deactivate_stale_staff()` — user login non-admin (mis. siswa) bisa menonaktifkan staf sekolahnya | anon-exec + tanpa cek peran | mig `190000`: REVOKE PUBLIC/anon + GRANT authenticated + guard peran |
| 7 | 🔵 Low | GRANT tabel sangat luas ke `anon`/`authenticated` (default Supabase). Aman **hanya karena** RLS aktif di semua tabel → RLS = titik tunggal kegagalan | grant katalog | Observasi (di-guard oleh test CHECK 1) |
| 8 | 🔵 Low | `fn_stakeholder_summary()` merespons anon (struktur nol, bukan data lintas tenant) | probe anon | mig `190000`: REVOKE PUBLIC/anon + GRANT authenticated |
| + | 🔵 Low | *(ditemukan guard-rail)* `fn_update_school_branding` VOLATILE masih anon-exec (aman via guard internal, tetap tak boleh terekspos) | test CHECK 2 | mig `210000`: REVOKE PUBLIC/anon + GRANT authenticated |

---

## Bukti Sebelum vs Sesudah (probe anon nyata terhadap live)

| Fungsi (dipanggil anon) | Sebelum | Sesudah |
|---|---|---|
| `fn_sync_observation` | `P0004` (body jalan → bisa inject) | **`42501 permission denied`** |
| `fn_batalkan_tahun_ajaran` | `P0001` (body jalan → bisa rollback) | **`42501 permission denied`** |
| `fn_apply_schedule_templates` | terjangkau | **`42501 permission denied`** |
| `fn_deactivate_stale_staff` | terjangkau | **`42501 permission denied`** |
| `fn_stakeholder_summary` | balas struktur data | **`42501 permission denied`** |
| `fn_update_school_branding` | anon-exec | **`42501 permission denied`** |
| Baca tabel inti (`students` dll) sbg anon | `[]` (sudah aman) | `[]` (tetap aman) |
| `provision-admin` (edge) | ACTIVE di live | **terhapus** |

Privilege katalog akhir untuk semua RPC privileged: `anon=false`, `authenticated` sesuai pemanggil, `service_role=true` (jalur edge tetap hidup).

---

## Perubahan yang diterapkan (repo + live)

| Artefak | Isi |
|---|---|
| `supabase/migrations/20260703190000_revoke_privileged_rpc_execute.sql` | REVOKE + guard internal service_role-safe (Temuan 1–3, 6, 8) |
| `supabase/migrations/20260703200000_sync_validate_student_school.sql` | Validasi student satu-sekolah (Temuan 5) |
| `supabase/migrations/20260703210000_revoke_branding_update_anon.sql` | REVOKE `fn_update_school_branding` dari anon |
| `supabase/functions/provision-admin/` | **Dihapus** (repo + live) |
| `tests/tenant-isolation.mjs` | Guard-rail otomatis (lihat di bawah) |
| Kredensial | Password default `Admin/Admin1234` (SMK Harapan Rokan) **direset** ke acak kuat + `must_change_password=true` |

**Commit:** `0a1b04f`, `bf78a83`, `ba15ffd` (branch `main`).
**Cara apply migrasi ke live:** Management API query endpoint (lihat memory `project-ops-deploy`), dicatat ke `supabase_migrations.schema_migrations`.

---

## Guard-rail otomatis (cegah regresi)

`tests/tenant-isolation.mjs` (Node ≥18, `fetch` bawaan). Jalankan:

```bash
SUPABASE_ACCESS_TOKEN=sbp_xxx node tests/tenant-isolation.mjs
# exit 0 = lulus; exit ≠ 0 = ada pelanggaran (cocok untuk CI)
```

Empat invarian terhadap DB **live**:
1. **RLS coverage** — semua tabel `public` RLS enabled.
2. **RPC exposure** — tak ada `fn_*` SECURITY DEFINER **VOLATILE** (menulis, non-trigger) yang executable oleh `anon`, kecuali allowlist branding-publik (`fn_school_branding`). *(Predikat read-only STABLE seperti `fn_is_kepsek` dikecualikan — RLS memanggilnya, jadi memang harus anon-callable.)*
3. **Anon read baseline** — anon tak bisa membaca tabel inti.
4. **Regresi RPC** — 9 RPC yang pernah bocor tetap `anon`-tanpa-EXECUTE + satu probe live harus ditolak.

Status terakhir: **LULUS (exit 0).** Guard-rail ini yang menemukan Temuan `+` (branding) — persis fungsinya menangkap sisa yang manual terlewat.

---

## Penilaian (0–100)

| Dimensi | Skor | Catatan |
|---|---|---|
| Architecture | 88 | Tenant-root + RLS-centric solid |
| **Isolation** | **90** | RLS 100% + lapisan RPC ditutup + guard-rail (naik dari 70) |
| Security | 82 | Semua Critical/High ditutup; sisa hygiene kredensial beres |
| Scalability | 72 | RLS terindeks; belum diuji skala nyata (>2 sekolah) |
| Maintainability | 82 | Pola konsisten, helper terpusat |
| Production Readiness (isolasi) | 88 | Tinggal wire test ke CI |
| SaaS Readiness | 68 | Branding per-sekolah ada; SMTP/WA/domain per-tenant belum |
| Testing | 62 | Guard-rail isolasi ada (naik dari 40); coverage lain minim |
| Documentation | 80 | Dokumen ini + memory |

---

## Kesimpulan

> ## Untuk pertanyaan "benarkah sudah multi-tenant & tenant terisolasi?" → **YA, terbukti di semua lapisan.**

Seluruh kebocoran tenant yang terkonfirmasi telah **ditutup, diverifikasi di live, dan dijaga test regresi otomatis**. Residual kredensial (password default admin) sudah beres.

Yang tersisa untuk **SaaS production-ready penuh** **bukan** lagi soal isolasi, melainkan pematangan produk (bukan kebocoran):
- Wire `tests/tenant-isolation.mjs` ke pipeline CI.
- Uji skala nyata (ratusan–ribuan sekolah).
- Fitur per-tenant (SMTP/WhatsApp/domain/kurikulum/workflow berbeda) — roadmap.

Referensi silang: memory `project-audit-rpc-exposure`, `project-ops-deploy`, `project-rls-audit`; `temuan-total.md`.
