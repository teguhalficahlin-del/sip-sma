# Daftar Kemungkinan Buruk di Lapangan

Dokumen ini mencatat semua skenario buruk yang mungkin terjadi saat platform dipakai di sekolah nyata,
beserta status penanganannya. Diperbarui: 3 Juli 2026 — sesi impor SMK Karya Bangsa (sekolah kedua/multi-tenant). Perbaikan: (1) impor jadwal 600 baris kena `WORKER_RESOURCE_LIMIT` → di-chunk; (2) bug multi-tenant email-login NIP/NIK tak ber-namespace per sekolah → guru/ortu sekolah kedua ber-identifier sama senyap gagal terbuat → difix namespace `{id}@{schoolPrefix}.{domain}`; (3) jebakan "hapus semua lalu impor ulang" tak memulihkan baris di Recycle Bin → difix auto-revive; (4) 4.1 dikoreksi (recycle bin sudah ada sejak sesi 2 Juli).

> **🔄 REKONSILIASI KE KODE — 4 Juli 2026.** Dokumen ini diselaraskan dengan source code (kode = sumber kebenaran). Beberapa item yang sebelumnya ditandai ❌ ternyata **sudah ada di kode**: antrean offline (1.1/1.5/3.4), auto-deactivate staf (5.3/7.2), deteksi sesi ganda (7.6), tracking karir + re-enroll + retensi alumni (10.4/10.5/10.6). Item 7.1 (alert perangkat baru) baru dibangun 4 Jul. Status di bawah sudah dikoreksi. Untuk snapshot lengkap lihat [`docs/README.md`](README.md) §1.

**Legenda status:**
- ✅ Sudah ditangani — platform menangani secara otomatis
- ⚠️ Sebagian — ada workaround tapi perlu tindakan manual
- ❌ Belum — belum ada solusi, perlu dikerjakan

---

## 1. Internet Mati / Koneksi Buruk

| # | Skenario | Status | Keterangan |
|---|----------|--------|------------|
| 1.1 | Internet mati, guru butuh isi absensi | ✅ | **DIKOREKSI 4 Jul 2026 (vs kode).** Input absensi/observasi/jurnal/kasus offline diantre ke IndexedDB (`guru/js/offline.js` `saveAttendanceBatch` dkk) dengan status jujur "Menunggu sinkron", lalu terkirim otomatis saat koneksi kembali (event `online`). Bertahan walau halaman ditutup/refresh. *(Antrean ini sempat rusak senyap sejak 2 Jul karena regresi `6ded3e5`; diperbaiki 4 Jul commit `427e866` + diverifikasi browser.)* |
| 1.2 | Internet putus di tengah impor massal (ratusan siswa/staf) | ⚠️ | Impor idempoten — data yang sudah masuk sebelum putus tidak duplikat saat diulang. Tapi tidak ada laporan baris mana yang berhasil sebelum timeout. |
| 1.3 | Internet lambat, form loading sangat lama | ⚠️ | Ada spinner. Tapi tidak ada timeout + pesan jelas. User mungkin klik tombol berkali-kali dan mengirim request berulang. |
| 1.4 | Sinyal sangat lemah di lokasi PKL / industri | ⚠️ | Halaman portal DUDI bisa dibaca dari cache. Tapi input absensi PKL tidak bisa offline. DUDI harus tunggu ada sinyal. |
| 1.5 | HP rusak atau hilang saat ada data yang belum ter-sync | ⚠️ | **DIKOREKSI 4 Jul 2026 (vs kode).** Write queue SUDAH ada (`guru/js/offline.js`) — data offline aman di IndexedDB & terkirim saat online. Sisa risiko: bila perangkat **hancur fisik / hilang** sebelum sempat sync, data di IndexedDB ikut hilang (tak bisa dicegah sisi-server). Mitigasi: dorong sync begitu ada sinyal. |

---

## 2. Password / Login Bermasalah

| # | Skenario | Status | Keterangan |
|---|----------|--------|------------|
| 2.1 | Guru / staf lupa password | ⚠️ | Admin bisa reset manual via konsol → menu staf → edit. Tidak ada "Lupa Password" self-service. Guru harus hubungi admin. |
| 2.2 | Siswa lupa password | ⚠️ | Sama, admin yang reset. Tidak ada alur mandiri untuk siswa. |
| 2.3 | Orang tua (ORTU) lupa password | ⚠️ | Admin reset manual. Password awal adalah `{NIK}!SMK` — admin bisa derive dari NIK. |
| 2.4 | DUDI lupa password | ⚠️ | Password awal adalah `{slug-nama-usaha}!SMK`. Admin bisa derive dari nama usaha. Tidak ada UI yang menampilkannya langsung. |
| 2.5 | Stakeholder lupa kode akses | ✅ | Kode akses = `login_identifier` yang terlihat di daftar stakeholder admin. Admin tinggal buka daftar dan beritahu ulang. |
| 2.6 | Admin utama lupa password | ⚠️ | **DIKOREKSI 4 Jul 2026 (vs kode).** Tak ada "lupa password" mandiri untuk admin. Namun **Kepala Sekolah kini bisa membuat akun admin baru** dari Portal Guru (edge `manage-admin-account`, sejak 2 Jul) → sekolah tidak lagi terkunci total. Superadmin platform juga tetap bisa reset. Sisa gap: bila admin DAN kepsek sama-sama kehilangan akses, baru bergantung superadmin. |
| 2.7 | Salah password berkali-kali — akun terkunci | ✅ | **FIXED (2 Juli 2026, commit b0bdb3b).** Error 429/rate-limit dideteksi di 6 portal dan menampilkan pesan jelas: "Terlalu banyak percobaan login. Tunggu ±15 menit lalu coba lagi." |
| 2.8 | Salah ketik identifier satu digit → masuk ke akun orang lain | ✅ | **FIXED (2 Juli 2026).** Kode stakeholder dan password kini dipisah — salah ketik kode tidak bisa cocok dengan password orang lain karena password adalah string acak. Lihat bagian 9. |

---

## 3. Ganti HP / Perangkat

| # | Skenario | Status | Keterangan |
|---|----------|--------|------------|
| 3.1 | Guru ganti HP, harus login ulang | ✅ | Login normal di HP baru. Data tetap di server, tidak ada yang hilang. |
| 3.2 | HP guru dipinjam siswa, guru lupa logout | ✅ | **FIXED (2 Juli 2026, commit e84a504).** Auto-logout idle 15 menit di semua portal (`shared/idle-timeout.js`): setelah tak ada aktivitas, muncul peringatan hitung mundur 60 detik lalu logout otomatis. |
| 3.3 | Satu tablet dipakai bergantian oleh banyak guru | ✅ | **FIXED (2 Juli 2026, commit e84a504).** Sesi idle otomatis berakhir (15 menit), jadi tablet yang ditinggalkan tidak tetap login sebagai guru sebelumnya. |
| 3.4 | HP rusak, data offline belum ter-sync | ⚠️ | **DIKOREKSI 4 Jul 2026.** Sama dengan 1.5: antrean offline ada & berfungsi; sisa risiko hanya bila perangkat hancur/hilang sebelum sync. |
| 3.5 | Siswa pakai browser berbeda di komputer sekolah | ✅ | Login baru di browser baru, session tersimpan di browser tersebut. Tidak ada konflik. |

---

## 4. Admin Salah Input / Salah Hapus

| # | Skenario | Status | Keterangan |
|---|----------|--------|------------|
| 4.1 | Admin hapus guru yang salah | ✅ | **FIXED (2 Juli 2026).** Hapus = soft-delete ke Recycle Bin (deleted_at + ban Auth), bisa dipulihkan ≤30 hari via `restore-user`. Data historis (jurnal, absensi) tetap. |
| 4.9 | Admin "hapus semua" lalu impor/tambah ulang untuk reset, tapi data tak muncul | ✅ | **FIXED (3 Juli 2026, commit dff2749).** Dulu re-impor/tambah-ulang identifier yang sedang di Recycle Bin hanya meng-update baris terhapus secara senyap (tetap tersembunyi + Auth ter-ban) lalu lapor "berhasil" — sangat membingungkan. Kini `bulk-import-users` mendeteksi baris soft-deleted dan otomatis membangkitkannya (deleted_at=null + is_active=true + unban Auth). Diuji end-to-end. |
| 4.2 | Admin impor file dengan nama/NIP yang keliru | ✅ | Ada fitur update identifier dan edit nama. Bisa dikoreksi. |
| 4.3 | Admin membuka tahun ajaran dengan semester yang salah | ✅ | **FIXED (2 Juli 2026, commit 8785661).** Menu admin "Tahun Ajaran" > "Batalkan Tahun Ajaran Terakhir" (konfirmasi ketik BATALKAN). fn_batalkan_tahun_ajaran() transaksional: pulihkan enrollment lama utk siswa naik kelas, hapus periode+enrollment baru, kembalikan school_config. Status LULUS tak berubah. |
| 4.4 | Guru salah input absensi | ✅ | Absensi punya flag `is_void`. Admin atau waka bisa void entri yang salah. |
| 4.5 | Guru salah submit observasi siswa | ✅ | **FIXED (2 Juli 2026, commit ee88354).** Admin/kepsek bisa "Batalkan" (void) observasi via konsol admin > Log Aktivitas. Soft-delete: baris tetap untuk audit (is_void + void_reason + voided_by), disembunyikan dari siswa/ortu/DUDI. |
| 4.6 | Kasus siswa dieskalasi ke level yang salah | ⚠️ | Tidak ada tombol "tarik eskalasi". Admin bisa update status kasus tapi tidak ada alur formal roll-back. |
| 4.7 | Siswa diimpor ke program keahlian yang salah | ✅ | Admin bisa edit class_enrollment dan pindah program. |
| 4.8 | Jadwal diimpor salah | ⚠️ | Harus hapus semua jadwal lama dan impor ulang. Tidak ada edit per baris jadwal di UI. |

---

## 5. Pergantian Personil Sekolah

| # | Skenario | Status | Keterangan |
|---|----------|--------|------------|
| 5.1 | Guru baru masuk di tengah tahun | ✅ | Impor CSV kapan saja bisa. Langsung aktif. |
| 5.2 | Guru resign, akun harus dinonaktifkan | ⚠️ | Admin bisa set `is_active = false` atau hapus. Tidak ada alur offboarding, tidak ada reminder otomatis. |
| 5.3 | Mantan guru lupa dinonaktifkan, masih bisa login | ⚠️ | **DIKOREKSI 4 Jul 2026 (vs kode).** ADA mekanisme deteksi: panel admin "Cek Staf Tanpa Jadwal Aktif" (`fn_get_stale_staff`) menampilkan guru aktif tanpa jadwal di tahun ajaran berjalan; admin bisa nonaktifkan massal (`fn_deactivate_stale_staff`) atau per-orang (`deactivateStaff` — mencabut semua jabatan). **Belum** ada penonaktifan otomatis terjadwal (masih perlu admin memicu). Jabatan struktural (kepsek/waka/wali/kaprodi) dikecualikan dari deteksi. |
| 5.4 | Wali kelas diganti di tengah semester | ✅ | Admin update `wali_kelas_class_id` via impor ulang atau edit. |
| 5.5 | Kaprodi berganti, akses ke program perlu dipindah | ✅ | Admin update `kaprodi_program_id`. |
| 5.6 | Admin utama sekolah resign, perlu diganti | ✅ | **FIXED (2 Juli 2026, Tahap 2).** Kepsek bisa tambah/hapus akun admin dari tab Kepala Sekolah di Portal Guru (edge fn `manage-admin-account`, guard: tak bisa hapus admin terakhir / diri sendiri). Diverifikasi E2E. |
| 5.7 | Siswa pindah sekolah (mutasi keluar) | ⚠️ | Status siswa bisa diubah ke NONAKTIF, tapi tidak ada alur formal mutasi. Data historis tetap tersimpan. |

---

## 6. Sistem / Server Down

| # | Skenario | Status | Keterangan |
|---|----------|--------|------------|
| 6.1 | Supabase down total | ❌ | Platform lumpuh sepenuhnya. Read cache browser membantu untuk halaman yang sudah terbuka, tapi semua write gagal. Tidak ada notifikasi status di platform. |
| 6.2 | GitHub Pages down | ❌ | Portal tidak bisa dibuka sama sekali. Tidak ada mirror atau fallback hosting. |
| 6.3 | Edge function timeout saat impor besar | ⚠️ | Impor idempoten — data yang masuk sebelum timeout aman dan tidak duplikat jika diulang. Tapi tidak ada laporan progres. |
| 6.6 | Impor jadwal ratusan baris kena `WORKER_RESOURCE_LIMIT` | ✅ | **FIXED (3 Juli 2026, commit e341048).** 600 template × ~26 tanggal/semester ≈ 15.000+ baris `teaching_schedules` dulu dibuat dalam satu upsert raksasa → worker kehabisan CPU/memori (HTTP 546). Kini insert dipecah per 500 baris + dedup template. Provisioning akun siswa massal juga sudah batched (150/panggilan, loop di UI). |
| 6.4 | Supabase dalam maintenance window | ✅ | **FIXED (2 Juli 2026, commit 7fd4187).** Superadmin bisa menyalakan banner "pemeliharaan" (platform_config + edge fn set-maintenance) yang muncul di semua portal via shared/branding.js. |
| 6.5 | Database hampir penuh | ✅ | **FIXED (2 Juli 2026, commit f864428).** Konsol superadmin > "Penyimpanan Database": ukuran DB + tabel terbesar + indikator ambang (fn_platform_storage + edge fn platform-stats). |

---

## 7. Keamanan & Kebocoran Kredensial

| # | Skenario | Status | Keterangan |
|---|----------|--------|------------|
| 7.1 | Guru screenshot password lalu share di grup WA | ⚠️ | **DIKOREKSI 4 Jul 2026 (vs kode).** ADA **alert "login dari perangkat baru"** di lonceng portal guru (`fn_register_login_device`, mig `20260704110000`) — pemilik akun tahu bila akunnya dipakai dari perangkat asing dan bisa segera ganti password. 2FA penuh (OTP) sengaja TIDAK dibangun (gesekan terlalu besar untuk audiens sekolah — keputusan 4 Jul). Sisa: alert baru ada di portal guru, belum di semua portal. |
| 7.2 | Mantan guru masih bisa login karena lupa dinonaktifkan | ⚠️ | **DIKOREKSI 4 Jul 2026.** Sama dengan 5.3: ada deteksi + nonaktifkan (manual/batch), belum terjadwal otomatis. |
| 7.3 | Siswa mencoba tebak NIS guru untuk login ke portal guru | ✅ | Password guru adalah string acak yang tidak ada hubungannya dengan NIP. Mengetahui NIP saja tidak cukup. |
| 7.4 | SUPERADMIN_KEY platform bocor | ⚠️ | Key disimpan di Supabase Secrets, tidak di kode. Tapi tidak ada IP whitelist. Kalau bocor, attacker bisa provision sekolah baru. |
| 7.5 | Token JWT user dicuri (man-in-the-middle) | ✅ | Semua komunikasi lewat HTTPS. Token bersifat sementara (1 jam), refresh token tersimpan aman di browser. |
| 7.6 | Dua orang login dengan akun yang sama di waktu bersamaan | ⚠️ | **DIKOREKSI 4 Jul 2026 (vs kode).** ADA **deteksi sesi ganda** (`shared/login-guard.js`): bila sesi lain masih segar (<30 mnt) dari perangkat/UA berbeda, muncul banner peringatan + tombol "Keluar Semua Perangkat". Belum ada BLOKIR keras concurrent login (Supabase izinkan multi-session), jadi dua orang tetap bisa edit bersamaan (idempotency melindungi absensi, tak semua operasi). |

---

## 8. Data & Sinkronisasi

| # | Skenario | Status | Keterangan |
|---|----------|--------|------------|
| 8.1 | Dua guru input absensi kelas yang sama bersamaan | ✅ | `sync_idempotency` dengan composite key mencegah duplikat. Yang terakhir submit menang. |
| 8.2 | Request terputus di tengah, tidak tahu apakah berhasil | ⚠️ | Tidak ada retry queue. User mungkin submit ulang. Dilindungi oleh idempotency key untuk absensi, tapi tidak semua operasi punya perlindungan ini. |
| 8.3 | Impor file yang sama dua kali (tidak sengaja) | ✅ | Impor bersifat idempoten — data lama diupdate, tidak duplikat. |
| 8.4 | Backup data hilang / perlu restore | ⚠️ | Supabase punya PITR (point-in-time recovery) untuk plan berbayar. Tidak ada tombol "backup sekarang" atau "restore" di platform ini. |
| 8.5 | Data tidak sinkron antara dua browser yang dibuka bersamaan | ⚠️ | Tidak ada realtime sync antar tab/browser. Perlu refresh manual untuk melihat data terbaru. |
| 8.6 | Dua sekolah (multi-tenant) punya guru/ortu dengan NIP/NIK yang sama | ✅ | **FIXED (3 Juli 2026, commit 440763d + a3d47d7).** Auth Supabase bersifat GLOBAL, sedangkan NIP/NIK tak unik lintas-sekolah (guru mengajar di 2 sekolah, ortu punya anak di 2 sekolah). Dulu email-login dirakit `{id}@{domain}` tanpa prefix → `createUser` sekolah kedua gagal "email already registered" dan akun itu **senyap tak terbuat**. Kini email di-namespace `{id}@{schoolPrefix}.{domain}` (NIP staf, NIK ortu; NIS siswa sudah aman karena `students.nis` unik global). Login tetap resolve via `fn_resolve_login_email(identifier, school_id)`. Akun lama tetap jalan. |

---

## 9. Kasus Khusus: Stakeholder — Kode vs Password

| # | Skenario | Status | Keterangan |
|---|----------|--------|------------|
| 9.1 | Salah ketik kode stakeholder → masuk ke akun orang lain | ✅ | **FIXED (2 Juli 2026, commit ec1cfa3).** Kode dan password kini dipisah. Password adalah string acak, bukan kode. Mengetikkan kode yang salah tidak akan pernah cocok dengan password orang lain. |
| 9.2 | Stakeholder A menebak kode Stakeholder B (KOMITE01 → KOMITE02) | ✅ | **FIXED (2 Juli 2026).** Menebak kode hanya menemukan `login_identifier` yang benar, tapi password adalah string acak berbeda tiap akun. Mengetahui kode tidak cukup untuk login. |
| 9.3 | Admin membagikan kode via WA, kode tersebut bocor | ⚠️ | Kode yang bocor hanya memberi tahu orang lain *siapa* akun itu, bukan cara masuknya. Password terpisah dan tidak ada di kode. Risiko berkurang signifikan, tapi admin tetap harus bagikan kode + password secara terpisah dan aman. |
| 9.4 | Stakeholder lupa password (bukan kode) | ⚠️ | Password acak tidak bisa di-derive ulang oleh admin — harus reset manual. Admin lihat kode di daftar, lalu reset password via konsol. Tidak ada alur "lupa password" mandiri untuk stakeholder. |

**Status per 2 Juli 2026:** Akar masalah (kode = password) sudah diperbaiki. Kode login = identitas saja; password = string acak yang dibagikan admin saat akun dibuat. Wizard admin menampilkan keduanya secara terpisah dengan peringatan "catat, tidak bisa ditampilkan ulang".

---

## 10. Alumni

| # | Skenario | Status | Keterangan |
|---|----------|--------|------------|
| 10.1 | Siswa lulus, akun masih aktif dan bisa login | ✅ | **FIXED (2 Juli 2026, commit a3ad47b).** Portal Siswa hanya izinkan student_status AKTIF/PKL; LULUS (alumni) & KELUAR ditolak saat login dengan pesan jelas. |
| 10.2 | Alumni butuh bukti kehadiran / rekap pelanggaran / rekap prestasi | ✅ | **FIXED (2 Juli 2026, commit 66937e3).** Admin > panel Alumni > "Cetak Rekap" per alumnus: identitas + rekap kehadiran + catatan pembinaan (positif/perhatian) + PKL, siap cetak/PDF sbagai surat keterangan. |
| 10.3 | Alumni butuh konfirmasi PKL selesai (untuk keperluan kerja / kuliah) | ✅ | **FIXED (2 Juli 2026, commit 66937e3).** Rekap alumnus memuat riwayat PKL (tempat DUDI, periode, status selesai) yang bisa dicetak. |
| 10.4 | Sekolah ingin pantau karir alumni setelah lulus | ⚠️ | **DIKOREKSI 4 Jul 2026 (vs kode).** ADA pencatatan karir alumni: panel Alumni admin punya tombol "Karir" → modal "Update Karir Alumni" (`updateAlumniCareer`, kolom `alumni_career_track`/`alumni_career_note`). Catatan penting: data ini **ikut terhapus** oleh retensi 6-bulan (10.6) → tak cocok untuk penelusuran jangka panjang. Keputusan 4 Jul: tracking alumni jangka-panjang **tidak diperluas** (bentrok privasi/retensi); rekap agregat anonim per-angkatan bisa dipertimbangkan bila dibutuhkan akreditasi. |
| 10.5 | Siswa KELUAR mendaftar kembali (re-enroll) | ✅ | **DIKOREKSI 4 Jul 2026 (vs kode).** ADA alur: `markStudentKeluar` (AKTIF→KELUAR) + `reEnrollStudent` (KELUAR→AKTIF, tombol "Daftar ulang" di panel admin) — NIS lama dipakai kembali, tak perlu akun baru. *(Catatan: re-enroll ini untuk siswa yang KELUAR, bukan alumnus LULUS — LULUS bersifat final.)* |
| 10.6 | Data siswa perlu dihapus sesuai kebijakan privasi (setelah X tahun) | ✅ | **DIKOREKSI 4 Jul 2026 (vs kode).** ADA kebijakan retensi: siswa LULUS/KELUAR > 6 bulan dihapus permanen (`fn_purge_expired_student` + edge `purge-expired-students` + panel admin `getRetentionCandidates`/`purgeExpiredStudents`). |

---

## Ringkasan Status

> **Dihitung ulang & dikoreksi 4 Jul 2026** (setelah rekonsiliasi ke kode; tabel lama salah hitung dan belum mencakup item 4.9/6.6).

| Kategori | ✅ Siap | ⚠️ Sebagian | ❌ Belum |
|----------|---------|------------|---------|
| 1. Internet / Koneksi | 1 | 4 | 0 |
| 2. Password / Login | 3 | 5 | 0 |
| 3. Ganti Perangkat | 4 | 1 | 0 |
| 4. Kesalahan Admin | 7 | 2 | 0 |
| 5. Pergantian Personil | 4 | 3 | 0 |
| 6. Sistem Down | 3 | 1 | 2 |
| 7. Keamanan Kredensial | 2 | 4 | 0 |
| 8. Data & Sinkronisasi | 3 | 3 | 0 |
| 9. Stakeholder Kode vs Password | 2 | 2 | 0 |
| 10. Alumni | 5 | 1 | 0 |
| **Total** | **34** | **26** | **2** |

**Hanya 2 ❌ tersisa**, keduanya risiko infrastruktur inheren: **6.1** (Supabase down) & **6.2** (GitHub Pages down) — tak ada fallback hosting. Semua ❌ lain dari versi 3 Jul ternyata sudah ada penanganannya di kode (offline queue, auto-deactivate, alert perangkat baru, alumni tracking/re-enroll/retensi) atau termitigasi parsial (2.6 via Kepsek).

---

## Prioritas Perbaikan

### Kritis — Harus diselesaikan sebelum sekolah ke-2 bergabung
- ~~**9.1 / 9.2**~~ ✅ FIXED (2 Juli 2026) — Kode stakeholder sudah dipisah dari password
- ~~**5.6**~~ ✅ FIXED (2 Juli 2026, Tahap 2) — Kepsek bisa tambah/hapus admin sendiri

### Penting — Harus diselesaikan sebelum tahun ajaran penuh berjalan
- ~~**1.5 / 3.4**~~ ✅ **DIKOREKSI 4 Jul** — write queue offline ADA & diperbaiki (`427e866`); sisa hanya perangkat hancur sebelum sync (inheren)
- ~~**4.1**~~ ✅ FIXED — Recycle Bin (`restore-user`) sudah ada sejak 2 Jul
- ~~**5.3 / 7.2**~~ ⚠️ **DIKOREKSI 4 Jul** — deteksi + nonaktifkan staf tanpa jadwal ADA; sisa: belum terjadwal otomatis
- ~~**10.1 sampai 10.3**~~ ✅ FIXED (2 Juli 2026) — Blokir login alumni + cetak rekap/dokumen alumnus

### Backlog — Perlu direncanakan
- ~~**2.7**~~ ✅ FIXED (2 Juli 2026, b0bdb3b) — Pesan jelas saat akun terkena rate-limit login
- ~~**3.2 / 3.3**~~ ✅ FIXED (2 Juli 2026, e84a504) — Idle timeout auto-logout 15 menit di semua portal
- ~~**4.3**~~ ✅ FIXED (2 Juli 2026, 8785661) — Batalkan buka tahun ajaran
- ~~**6.4 / 6.5**~~ ✅ FIXED (2 Juli 2026) — Banner maintenance (7fd4187) + monitoring storage (f864428)
- ~~**7.1**~~ ✅ **FIXED 4 Jul 2026** (`54a4d38`) — Notifikasi login dari perangkat baru (portal guru)
- ~~**10.4 / 10.5 / 10.6**~~ ✅/⚠️ **DIKOREKSI 4 Jul** — retensi (10.6) & re-enroll KELUAR (10.5) ADA; tracking karir (10.4) ADA tapi transien (bentrok retensi) — tak diperluas per keputusan 4 Jul

### Sisa terbuka (nyata, per 4 Jul 2026)
- **6.1 / 6.2** — Supabase / GitHub Pages down: tak ada fallback (inheren arsitektur)
- **2.6** — admin+kepsek sama-sama kehilangan akses → bergantung superadmin
- **Push notification** ke device offline — terblokir service worker dinonaktifkan (lihat `service-worker-status.md`), ditunda
