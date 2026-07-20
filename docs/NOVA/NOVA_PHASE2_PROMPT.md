# NOVA — Prompt Master Claude Code
## Fase 2: Core Akademik
**Gunakan prompt ini setelah Fase 1 selesai dan dikonfirmasi.**

---

## KONTEKS PROJECT

Kamu melanjutkan pembangunan **NOVA (Next-gen One-stop Virtual Academy)** — platform PWA multi-tenant sistem informasi sekolah SD-SMP-SMA.

**Fase 1 sudah selesai dan terverifikasi:**
- Repository aktif di GitHub (`teguhalficahlin-del/nova-platform`)
- Multi-tenant berjalan: `schools`, `users`, `roles`, `licenses` + RLS aktif
- Semua 6 role bisa login dan redirect ke dashboard yang benar
- Onboarding sekolah baru berfungsi end-to-end
- PWA installable via manifest.json
- IndexedDB & sync queue struktur siap

Baca `CLAUDE.md` dan `SPEC.md` di root repository sebelum mulai.

---

## ATURAN KERJA WAJIB

1. **Baca dulu, kode kemudian** — analisis seluruh instruksi sebelum mulai
2. **Satu langkah selesai sebelum lanjut** — jangan overlap antar langkah
3. **Tidak ada placeholder** — semua kode harus fungsional dan dapat dijalankan
4. **RLS wajib diuji** — setiap tabel baru harus diverifikasi isolasinya per `school_id`
5. **Mobile-first wajib** — semua UI diuji logikanya di 320px terlebih dahulu
6. **Tidak ada keputusan arsitektur mandiri** — jika ada ambiguitas, tulis pertanyaan dan tunggu konfirmasi
7. **Commit per langkah** — setiap langkah selesai langsung commit dengan pesan yang deskriptif
8. **Service Worker tidak disentuh** — SW diaktifkan di Fase 7

---

## ARSITEKTUR MULTI-TENANT (PENGINGAT)

- Setiap tabel baru wajib punya kolom `school_id uuid references schools(id)`
- RLS wajib aktif di setiap tabel baru
- Tidak ada query yang boleh return data lintas sekolah kecuali role `dinas`

---

## FASE 2 — CORE AKADEMIK

### Target Fase 2
- Guru bisa melakukan absensi siswa secara digital
- Jadwal pelajaran tampil per kelas
- Data tersimpan dan terisolasi per sekolah
- Semua fitur berjalan di tier gratis

### Entitas yang dibangun
`classes` → `subjects` → `schedules` → `attendances`

---

### Langkah-langkah

#### LANGKAH 1 — Tabel `classes`
Buat migration file untuk tabel `classes`:

```sql
id uuid primary key default gen_random_uuid()
school_id uuid references schools(id) not null
name text not null -- contoh: 'Kelas 1A', 'VII B', 'X IPA 2'
level text not null -- 'SD' | 'SMP' | 'SMA'
grade integer not null -- 1-6 untuk SD, 7-9 SMP, 10-12 SMA
academic_year text not null -- contoh: '2025/2026'
homeroom_teacher_id uuid references users(id) -- wali kelas
is_active boolean default true
created_at timestamptz default now()
```

**RLS:**
- Guru hanya bisa lihat kelas di sekolahnya
- Admin bisa buat, edit, hapus kelas
- Siswa hanya bisa lihat kelasnya sendiri

**UI yang dibangun:**
- `src/pages/admin/Classes.jsx` — CRUD kelas (admin)
- `src/components/ClassCard.jsx` — tampilan kartu kelas
- Tampil di dashboard admin setelah login

**Verifikasi:**
- Admin bisa buat kelas baru
- Kelas hanya tampil untuk sekolah yang login
- User sekolah lain tidak bisa lihat kelas ini

**Catatan:** Saat admin membuat kelas dan assign siswa ke kelas → sistem otomatis populate tabel `class_members` yang sudah dibuat di Fase 1.

---

#### LANGKAH 2 — Tabel `subjects`
Buat migration file untuk tabel `subjects`:

```sql
id uuid primary key default gen_random_uuid()
school_id uuid references schools(id) not null
name text not null -- contoh: 'Matematika', 'Bahasa Indonesia'
code text -- kode mapel opsional
level text not null -- 'SD' | 'SMP' | 'SMA'
is_active boolean default true
created_at timestamptz default now()
```

**RLS:**
- Semua role di sekolah bisa lihat subjects
- Hanya admin yang bisa buat, edit, hapus

**UI yang dibangun:**
- `src/pages/admin/Subjects.jsx` — CRUD mata pelajaran (admin)
- Data subjects tersedia sebagai referensi untuk schedules & grades

**Verifikasi:**
- Admin bisa tambah mata pelajaran
- Mata pelajaran terisolasi per sekolah

---

#### LANGKAH 3 — Tabel `schedules`
Buat migration file untuk tabel `schedules`:

```sql
id uuid primary key default gen_random_uuid()
school_id uuid references schools(id) not null
class_id uuid references classes(id) not null
subject_id uuid references subjects(id) not null
teacher_id uuid references users(id) not null
day text not null -- 'Senin' | 'Selasa' | 'Rabu' | 'Kamis' | 'Jumat'
start_time time not null
end_time time not null
academic_year text not null
is_active boolean default true
created_at timestamptz default now()
```

**RLS:**
- Guru hanya lihat jadwal yang mengandung `teacher_id` miliknya atau jadwal kelasnya
- Siswa hanya lihat jadwal kelasnya
- Orang tua hanya lihat jadwal kelas anaknya
- Admin bisa kelola semua jadwal sekolahnya

**Validasi konflik jadwal (wajib dicek sebelum simpan):**
- Guru tidak boleh dijadwalkan dua kelas di hari + jam yang sama
- Kelas tidak boleh punya dua mapel di hari + jam yang sama
- Jika konflik terdeteksi → tampilkan pesan error yang jelas, jangan simpan

**UI yang dibangun:**
- `src/pages/admin/Schedules.jsx` — CRUD jadwal (admin)
- `src/pages/teacher/Schedule.jsx` — jadwal mengajar guru (read)
- `src/pages/student/Schedule.jsx` — jadwal kelas siswa (read)
- `src/pages/parent/Schedule.jsx` — jadwal anak (read)
- `src/components/ScheduleGrid.jsx` — tampilan grid jadwal per hari

**Verifikasi:**
- Admin bisa buat jadwal dengan memilih kelas, mapel, guru, hari, jam
- Guru hanya melihat jadwalnya sendiri
- Siswa hanya melihat jadwal kelasnya
- Orang tua hanya melihat jadwal anaknya

---

#### LANGKAH 4 — Tabel `attendances`
Buat migration file untuk tabel `attendances`:

```sql
id uuid primary key default gen_random_uuid()
school_id uuid references schools(id) not null
class_id uuid references classes(id) not null
subject_id uuid references subjects(id) not null
teacher_id uuid references users(id) not null
student_id uuid references users(id) not null
date date not null
status text not null -- 'hadir' | 'sakit' | 'izin' | 'alpha'
note text
recorded_at timestamptz default now()
created_at timestamptz default now()
```

**RLS:**
- Guru hanya bisa input & lihat absensi kelas yang dia ajar
- Siswa hanya bisa lihat absensi dirinya sendiri
- Orang tua hanya bisa lihat absensi anaknya
- Admin bisa lihat semua absensi sekolahnya
- Komite bisa lihat rekap kehadiran (read-only, aggregated)

**UI yang dibangun:**
- `src/pages/teacher/Attendance.jsx` — input absensi (guru)
  - Pilih kelas → pilih mapel → pilih tanggal → list siswa → input status per siswa
  - Submit satu kali untuk seluruh kelas
- `src/pages/student/Attendance.jsx` — riwayat kehadiran diri sendiri (siswa)
- `src/pages/parent/Attendance.jsx` — riwayat kehadiran anak (ortu)
- `src/pages/admin/AttendanceReport.jsx` — rekap kehadiran per kelas (admin)
- `src/components/AttendanceStatus.jsx` — badge status hadir/sakit/izin/alpha

**Logika penting:**
- Satu guru tidak bisa input absensi dua kali untuk kelas + mapel + tanggal yang sama
- Jika sudah diinput, tampilkan data yang ada dengan opsi edit (hanya hari yang sama)

**Verifikasi:**
- Guru bisa input absensi dan data tersimpan
- Siswa hanya lihat absensi dirinya
- Orang tua hanya lihat absensi anaknya
- Tidak bisa duplikasi absensi untuk kelas + mapel + tanggal yang sama

---

#### LANGKAH 5 — Update Dashboard per Role
Setelah semua entitas selesai, update dashboard masing-masing role:

**Dashboard Guru:**
- Jadwal mengajar hari ini
- Shortcut input absensi kelas aktif
- Jumlah siswa hadir hari ini

**Dashboard Siswa:**
- Jadwal hari ini
- Status kehadiran minggu ini

**Dashboard Orang Tua:**
- Jadwal anak hari ini
- Status kehadiran anak minggu ini

**Dashboard Admin:**
- Total siswa hadir hari ini (per kelas)
- Ringkasan absensi minggu ini
- Shortcut kelola data sekolah

**Dashboard Kepala Sekolah:**
- Total siswa hadir hari ini (seluruh sekolah, read-only)
- Ringkasan absensi minggu ini (read-only)

**Dashboard Komite:**
- Rekap kehadiran siswa & guru (aggregated, read-only)

**Verifikasi:**
- Setiap role melihat data yang relevan dengan aksesnya
- Tidak ada data lintas sekolah yang bocor

---

#### LANGKAH 6 — Update CLAUDE.md
Update file `CLAUDE.md` di root repository:

```markdown
## Status Fase
- [x] Fase 1: Foundation
- [x] Fase 2: Core Akademik
- [ ] Fase 3: Penilaian
- [ ] Fase 4: Pembelajaran
- [ ] Fase 5: Komunikasi
- [ ] Fase 6: Laporan & Dashboard
- [ ] Fase 7: Hardening

## Keputusan Arsitektur yang Sudah Fix
- [2026-07-07] Multi-tenant: school_id + RLS (bukan schema-per-school)
- [2026-07-07] Stack: Hybrid cloud (Supabase → VPS)
- [2026-07-07] Auth ortu: WhatsApp OTP
- [2026-07-07] Auth siswa: NIS + password
- [2026-07-07] Service Worker: tidak diaktifkan di Fase 1–6, diaktifkan di Fase 7
- [2026-07-07] Absensi: tidak bisa duplikasi per kelas + mapel + tanggal
```

---

## CHECKLIST SELESAI FASE 2

Sebelum melaporkan Fase 2 selesai, verifikasi semua item ini:

- [ ] Tabel `classes` terbuat + RLS aktif + UI admin berfungsi
- [ ] Tabel `subjects` terbuat + RLS aktif + UI admin berfungsi
- [ ] Tabel `schedules` terbuat + RLS aktif + tampil per role dengan benar
- [ ] Tabel `attendances` terbuat + RLS aktif + input absensi guru berfungsi
- [ ] Duplikasi absensi dicegah (kelas + mapel + tanggal sama)
- [ ] Dashboard setiap role sudah menampilkan data Core Akademik
- [ ] Tidak ada data lintas sekolah yang bocor
- [ ] `CLAUDE.md` diupdate dengan status Fase 2 selesai
- [ ] Semua langkah sudah di-commit ke GitHub

---

## SETELAH FASE 2 SELESAI

Laporkan:
1. Checklist di atas — centang semua yang sudah selesai
2. Screenshot atau deskripsi singkat tampilan absensi guru di mobile (320px)
3. Jika ada item yang tidak bisa diselesaikan — jelaskan kenapa dan tunggu instruksi

**Jangan mulai Fase 3 sebelum mendapat konfirmasi.**
