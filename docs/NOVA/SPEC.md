# NOVA — Next-gen One-stop Virtual Academy
## Dokumen Spesifikasi Platform (SPEC.md)
**Versi:** 1.5  
**Status:** Approved — Direvisi  
**Tanggal:** 2026-07-07

---

## 1. TUJUAN

Membangun **platform ekosistem belajar multi-tenant** (SD-SMP-SMA) yang menjadi satu-satunya sistem operasional sekaligus asisten mengajar bagi sekolah yang belum punya sistem apapun — menghubungkan guru di sekolah, siswa, dan orang tua di rumah dalam satu alur pembelajaran yang kohesif, sehingga:

- Guru bisa fokus mengajar, bukan administrasi
- Administrasi sekolah berjalan efisien dan digital
- Orang tua memahami materi yang dipelajari anak dan bisa mendampingi belajar di rumah
- Siswa mendapat pengalaman belajar yang konsisten antara di sekolah dan di rumah
- AI menjembatani guru, siswa, dan orang tua dalam satu ekosistem pembelajaran

---

## 2. PLATFORM

- **Jenis:** Progressive Web App (PWA)
- **Offline:** Ya — IndexedDB + sync queue
- **Installable:** Ya — via browser prompt
- **Target device:** Mobile-first, support desktop

---

## 3. STAKEHOLDER & FITUR

### Klasifikasi Aktor

**Aktor Internal (bisa kirim & terima pesan):**
| Aktor | Mengajar | Jabatan Tambahan | Akses Data Akademik |
|---|---|---|---|
| Guru | ✅ Tercatat di jadwal | — | Read-write sesuai tugasnya |
| Guru (Wali Kelas) | ✅ Tercatat di jadwal | Wali kelas — akses rekap absensi seluruh mapel kelasnya | Read-write + rekap kelas |
| Guru (Wakil Kepala) | ✅ Tercatat di jadwal | Wakil kepala — akses rekap absensi seluruh sekolah | Read-write + rekap sekolah |
| Admin | ❌ | — | Read-write data sekolah |
| Kepala Sekolah | ❌ | — | Read-only seluruh sekolah |

**Aktor Eksternal (hanya terima pesan & read-only):**
| Aktor | Akses |
|---|---|
| Siswa | Data diri sendiri |
| Orang Tua | Data anak |
| Komite | Kehadiran & kegiatan |
| Dinas Pendidikan | Rekap data wilayah |

---

### 3.1 Guru
| Fitur | Tier |
|---|---|
| Absensi siswa digital | Gratis |
| Jadwal pelajaran | Gratis |
| Input nilai | Berbayar |
| Jurnal mengajar harian | Berbayar |
| Generate CP otomatis (AI) | Berbayar |
| Generate ATP dari CP (AI) | Berbayar |
| Modul ajar otomatis per minggu (AI) | Berbayar |
| Pilih materi yang dibagikan ke orang tua | Berbayar |
| Teaching Runtime — panduan mengajar real-time tanpa kertas | Berbayar |
| Jurnal otomatis dari sesi runtime | Berbayar |
| Kirim & terima pesan (semua aktor) | Berbayar |

### 3.2 Siswa
| Fitur | Tier |
|---|---|
| Lihat jadwal pelajaran | Gratis |
| Lihat nilai | Gratis |
| Akses materi & modul ajar yang dibagikan guru | Berbayar |
| Tanya AI tentang materi (berbasis konten guru) | Berbayar |
| Tanya AI pengembangan (dalam konteks topik) | Berbayar |
| Tugas & pengumpulan tugas | Berbayar |
| Terima pesan (read-only) | Berbayar |

### 3.3 Orang Tua
| Fitur | Tier |
|---|---|
| Lihat jadwal anak | Gratis |
| Lihat nilai anak | Gratis |
| Notifikasi absensi | Berbayar |
| Akses materi ajar yang dibagikan guru | Berbayar |
| Tanya AI tentang materi (berbasis konten guru) | Berbayar |
| Tanya AI pengembangan (dalam konteks topik) | Berbayar |
| Terima pesan (read-only) | Berbayar |

### 3.4 Kepala Sekolah
| Fitur | Tier |
|---|---|
| Dashboard statistik sekolah | Berbayar |
| Laporan kehadiran siswa (read-only) | Berbayar |
| Laporan nilai siswa (read-only) | Berbayar |
| Kirim & terima pesan (semua aktor) | Berbayar |

### 3.5 Admin
| Fitur | Tier |
|---|---|
| Manajemen data guru & siswa | Gratis |
| Pengumuman sekolah | Gratis |
| Kirim & terima pesan (semua aktor) | Berbayar |

### 3.6 Komite
| Fitur | Tier |
|---|---|
| Pantau kehadiran rapat & kegiatan | Gratis |
| Pantau kehadiran guru & siswa (read-only) | Gratis |
| Terima pesan (read-only) | Gratis |

### 3.7 Dinas Pendidikan
| Fitur | Tier |
|---|---|
| Laporan kehadiran guru & siswa (read-only) | Gratis |
| Rekap data seluruh sekolah dalam wilayah (read-only) | Berbayar |

---

## 4. MODEL BISNIS

| Aspek | Detail |
|---|---|
| **Model** | Freemium + beli putus (one-time license) |
| **Tier Gratis** | Fitur dasar selamanya, tanpa batas waktu |
| **Tier Berbayar** | Upgrade satu kali, semua fitur terbuka permanen |
| **Harga** | Per jumlah siswa — makin besar sekolah, makin mahal |
| **Target awal** | Sekolah SD-SMP-SMA yang belum punya sistem apapun |

### Skala harga (rekomendasi awal, dapat disesuaikan):
| Jumlah Siswa | Estimasi Harga |
|---|---|
| 1–100 siswa | Tier S |
| 101–300 siswa | Tier M |
| 301–600 siswa | Tier L |
| 601+ siswa | Tier XL |

---

## 5. STACK TEKNOLOGI

**Model: Hybrid — Cloud dulu, migrasi ke VPS setelah revenue stabil**

| Layer | Teknologi | Keterangan |
|---|---|---|
| Frontend | React + Vite + Tailwind CSS | Component-based, mobile-first |
| PWA Engine | manifest.json (SW diaktifkan di Fase 7) | Install prompt |
| Backend & DB | Supabase (PostgreSQL + RLS) | Multi-tenant isolation |
| AI Engine | Anthropic Claude API | Modul ajar otomatis |
| Storage | Supabase Storage → Cloudflare R2 | File tugas, materi, dokumen |
| Notifikasi | In-app (Fase 5), Web Push + SW (Fase 7) | Bertahap sesuai fase |
| Offline | IndexedDB + sync queue | Data tersedia tanpa internet |
| Deployment | Vercel → Coolify (VPS) | Zero-config awal, exit strategy ada |

---

## 6. ARSITEKTUR MULTI-TENANT

- **Pendekatan:** Satu database PostgreSQL, isolasi via `school_id`
- **Mekanisme:** Row Level Security (RLS) Supabase — setiap query otomatis difilter per `school_id`
- **Jaminan isolasi:** Setiap user hanya bisa membaca dan menulis data sekolahnya sendiri
- **Migration path:** Jika dibutuhkan, dapat dimigrasi ke schema-per-school tanpa rebuild frontend

---

## 7. SKEMA DATABASE HIGH-LEVEL

### CORE
```
schools         — data sekolah, jenjang, lisensi
users           — semua pengguna lintas role
roles           — guru, siswa, ortu, kepsek, admin, komite, dinas
```

### AKADEMIK
```
classes         — kelas per sekolah per tahun ajaran
class_members   — relasi siswa ke kelas
subjects        — mata pelajaran
schedules       — jadwal pelajaran
attendances     — absensi siswa per kelas per mapel
grades          — nilai siswa (harian, tengah_semester, observasi_perilaku)
```

### RELASI
```
parent_student  — relasi orang tua ke siswa
```

### PEMBELAJARAN
```
capaian_pembelajaran   — CP per jenjang & mapel (AI-generated, guru review)
alur_tujuan_pembelajaran — ATP per semester, turunan dari CP
teaching_journals      — jurnal mengajar harian
lesson_modules         — modul ajar per minggu (dengan materi ajar)
assignments            — tugas
submissions            — pengumpulan tugas siswa
ai_conversations       — log percakapan AI per modul (ortu & siswa)
teaching_runtime_sessions — log sesi mengajar real-time (otomatis isi jurnal)
```

### KOMUNIKASI
```
messages            — pesan terpadu antar semua aktor internal
message_recipients  — penerima per pesan
notifications       — notifikasi in-app semua role
```

### SISTEM
```
licenses        — lisensi per sekolah, jumlah siswa, status
audit_logs      — jejak aktivitas seluruh pengguna
```

### PENGATURAN SEKOLAH
```
schools.active_academic_year  — tahun ajaran aktif (contoh: '2025/2026')
schools.active_semester       — semester aktif (1 | 2)
schools.region                — wilayah sekolah (untuk filter Dinas)
users.region                  — wilayah Dinas Pendidikan (untuk RLS filter)
```

---

## 8. DEPENDENCY MAP & URUTAN BUILD

### FASE 1 — Foundation
**Entitas:** `schools`, `users`, `roles`, `licenses`  
**Target:** Sistem multi-tenant berjalan, autentikasi semua role aktif, RLS terkonfigurasi  
**Prasyarat:** Tidak ada  

### FASE 2 — Core Akademik
**Entitas:** `classes`, `subjects`, `schedules`, `attendances`  
**Target:** Guru bisa absensi, jadwal tampil per kelas, data tersimpan per sekolah  
**Prasyarat:** Fase 1 selesai & terverifikasi  

### FASE 3 — Penilaian
**Entitas:** `grades`, `report_cards`  
**Target:** Guru input nilai, siswa & ortu lihat rapor  
**Prasyarat:** Fase 2 selesai & terverifikasi  

### FASE 4 — Pembelajaran
**Entitas:** `capaian_pembelajaran`, `alur_tujuan_pembelajaran`, `teaching_journals`, `lesson_modules`, `assignments`, `submissions`
**Target:** Guru generate CP & ATP otomatis, jurnal mengajar aktif, AI generate modul ajar per minggu, siswa kumpul tugas
**Prasyarat:** Fase 2 selesai & terverifikasi, Claude API terkonfigurasi

### FASE 4B — Ekosistem Belajar (Rumah-Sekolah)
**Entitas:** `ai_conversations`, update `lesson_modules.is_shared_to_parent`
**Target:** Guru bagikan materi ke orang tua, orang tua & siswa bisa akses materi dan tanya AI berbasis konten guru
**Prasyarat:** Fase 4 selesai & terverifikasi  

### FASE 5 — Komunikasi
**Entitas:** `messages`, `message_recipients`, `notifications`  
**Target:** Sistem pesan terpadu aktif — semua aktor internal bisa kirim ke penerima yang diseleksi, notifikasi in-app berjalan  
**Prasyarat:** Fase 1 selesai & terverifikasi  

### FASE 6 — Laporan & Dashboard
**Entitas:** Agregasi dari semua fase  
**Target:** Dashboard kepsek, laporan Dinas, rekap kehadiran & nilai  
**Prasyarat:** Fase 1–5 selesai & terverifikasi  

### FASE 7 — Hardening
**Fokus:** RLS audit, offline sync, Web Push notification, performance, security  
**Target:** Platform siap produksi, multi-tenant aman, offline reliable  
**Prasyarat:** Fase 1–6 selesai & terverifikasi  

---

## 9. ALUR AUTENTIKASI

### Metode Login per Role
| Role | Metode |
|---|---|
| Admin / Kepala Sekolah | Email + password |
| Guru | Email + password |
| Siswa | NIS + password |
| Orang Tua | No. HP + OTP WhatsApp |
| Komite | Email + password |
| Dinas Pendidikan | Email + password |

### Alur Onboarding Sekolah Baru
1. Admin daftar → input data sekolah → sistem generate `school_id`
2. Admin input data guru & siswa (manual atau import CSV)
3. Sistem generate akun otomatis per guru & siswa
4. Orang tua diundang via WhatsApp OTP — tidak perlu password

### Deteksi Role
- Satu halaman login untuk semua role
- Sistem deteksi role otomatis setelah autentikasi
- Redirect ke dashboard sesuai role

---

## 10. ATURAN KERJA UNTUK CLAUDE CODE

1. Ikuti urutan fase — jangan mulai fase berikutnya sebelum fase aktif selesai dan terverifikasi
2. Setiap fase harus menghasilkan output yang dapat dijalankan dan diuji
3. RLS harus diuji di setiap fase, bukan hanya di Fase 7
4. Tidak ada placeholder atau mock data di output akhir
5. Mobile-first adalah fondasi wajib semua keputusan layout
6. Setiap perubahan arsitektur harus dikonfirmasi sebelum diimplementasi
7. Satu modul selesai dan dikonfirmasi sebelum lanjut ke modul berikutnya
8. Offline sync diuji di setiap modul yang menyentuh data

---


## 11. HIERARKI REKAP ABSENSI

| Level | Role | Cakupan Rekap |
|---|---|---|
| 1 | Guru | Absensi kelas & mapel yang dia ajar sendiri |
| 2 | Wali Kelas | Absensi seluruh mapel di kelas yang dia wali |
| 3 | Wakil Kepala | Absensi seluruh kelas di sekolah |
| 4 | Kepala Sekolah | Sama dengan Wakil Kepala — read-only |

**Implementasi:**
- Guru punya akses rekap & export absensi kelasnya sendiri
- Wali Kelas melihat rekap agregat dari semua guru yang mengajar di kelasnya
- Wakil Kepala melihat rekap dari semua wali kelas / semua kelas di sekolah
- Kepala Sekolah melihat tampilan yang sama dengan Wakil Kepala, read-only

**Field pendukung di tabel `users`:**
- `is_homeroom_teacher boolean` — true jika guru adalah wali kelas
- `homeroom_class_id uuid` — kelas yang dia wali
- `is_vice_principal boolean` — true jika guru adalah wakil kepala

## 12. RIWAYAT REVISI

| Versi | Tanggal | Perubahan |
|---|---|---|
| 1.0 | 2026-07-07 | Dokumen awal |
| 1.1 | 2026-07-07 | Revisi struktur role — klasifikasi aktor internal/eksternal; Kepala Sekolah bisa kirim pesan; sistem pesan terpadu menggantikan announcements terpisah; SW ditunda ke Fase 7; stack PWA diupdate |
| 1.2 | 2026-07-07 | Tambah hierarki rekap absensi 4 level (Guru → Wali Kelas → Wakil Kepala → Kepala Sekolah); field `is_homeroom_teacher`, `homeroom_class_id`, `is_vice_principal` di tabel users |
| 1.3 | 2026-07-07 | Hapus rapor dari scope; tipe penilaian: harian + tengah_semester + observasi_perilaku; tambah tabel class_members dan parent_student; tambah field region dan active_academic_year di schools; rekap kehadiran = rekap status siswa (hadir/sakit/izin/alpha); enforcement tier via useFeatureAccess hook |
| 1.4 | 2026-07-07 | Repositioning NOVA menjadi platform ekosistem belajar (SIS + Teaching Assistant); tambah CP, ATP, ai_conversations; fitur AI tutor orang tua & siswa berbasis konten guru; guru kontrol materi yang dibagikan; tambah Fase 4B |
| 1.5 | 2026-07-07 | Tambah Teaching Runtime — panduan mengajar real-time tanpa kertas; jurnal otomatis dari sesi runtime; offline-capable via IndexedDB cache; responsive semua perangkat |

*SPEC.md ini adalah dokumen living — update setiap kali ada keputusan arsitektur baru yang disetujui.*
