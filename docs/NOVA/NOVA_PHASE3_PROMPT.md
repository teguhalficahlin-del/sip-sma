# NOVA — Prompt Master Claude Code
## Fase 3: Penilaian
**Gunakan prompt ini setelah Fase 2 selesai dan dikonfirmasi.**

---

## KONTEKS PROJECT

Kamu melanjutkan pembangunan **NOVA (Next-gen One-stop Virtual Academy)** — platform PWA multi-tenant sistem informasi sekolah SD-SMP-SMA.

**Fase 1 & 2 sudah selesai dan terverifikasi:**
- Multi-tenant berjalan: `schools`, `users`, `roles`, `licenses` + RLS aktif
- Core Akademik berjalan: `classes`, `subjects`, `schedules`, `attendances` + RLS aktif
- Semua 6 role bisa login dan mengakses data sesuai aksesnya
- Dashboard per role menampilkan data Core Akademik

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

## FASE 3 — PENILAIAN

### Target Fase 3
- Guru bisa input nilai siswa per mapel
- Tipe penilaian: harian, tengah semester, observasi perilaku
- Siswa dan orang tua bisa melihat nilai
- Admin bisa melihat rekap nilai per kelas
- Rapor TIDAK masuk platform

### Entitas yang dibangun
`grades`

---

### Langkah-langkah

#### LANGKAH 1 — Tabel `grades`
Buat migration file untuk tabel `grades`:

```sql
id uuid primary key default gen_random_uuid()
school_id uuid references schools(id) not null
class_id uuid references classes(id) not null
subject_id uuid references subjects(id) not null
teacher_id uuid references users(id) not null
student_id uuid references users(id) not null
academic_year text not null -- contoh: '2025/2026'
semester integer not null -- 1 | 2
assessment_type text not null -- 'harian' | 'tengah_semester' | 'observasi_perilaku'
score numeric(5,2) not null -- 0.00 - 100.00
note text
recorded_at timestamptz default now()
created_at timestamptz default now()
```

**RLS:**
- Guru hanya bisa input & lihat nilai untuk mapel yang dia ajar
- Siswa hanya bisa lihat nilainya sendiri
- Orang tua hanya bisa lihat nilai anaknya
- Admin/Kepsek bisa lihat semua nilai di sekolahnya
- Dinas: tidak ada akses ke nilai individual

**Logika penting:**
- Satu guru bisa input beberapa nilai untuk satu siswa (berbeda `assessment_type`)
- Nilai bisa diedit selama semester yang sama belum dikunci (rapor belum diterbitkan)

**UI yang dibangun:**
- `src/pages/teacher/Grades.jsx` — input nilai per mapel per kelas (guru)
  - Pilih kelas → pilih mapel → pilih semester → pilih tipe penilaian → list siswa → input nilai
- `src/pages/student/Grades.jsx` — lihat nilai sendiri per mapel per semester (siswa)
- `src/pages/parent/Grades.jsx` — lihat nilai anak per mapel per semester (ortu)
- `src/pages/admin/GradesReport.jsx` — rekap nilai per kelas (admin)
- `src/components/GradeTable.jsx` — tabel nilai dengan kolom per tipe penilaian

**Verifikasi:**
- Guru bisa input nilai dan data tersimpan
- Siswa hanya lihat nilainya sendiri
- Orang tua hanya lihat nilai anaknya
- Admin lihat semua nilai di sekolahnya
- Nilai tidak bisa diedit jika rapor sudah diterbitkan

---

#### CATATAN PENTING — Rapor Tidak Masuk Platform
Rapor resmi (akhir semester) tidak dikelola di NOVA. Platform hanya menyimpan nilai harian, tengah semester, dan observasi perilaku sebagai data referensi guru. Nilai ini bisa dilihat siswa dan orang tua, tapi tidak ada fitur generate atau publish rapor.

---

#### LANGKAH 3 — Update Dashboard per Role
Setelah semua entitas selesai, update dashboard masing-masing role:

**Dashboard Guru:**
- Shortcut input nilai kelas aktif
- Notifikasi: ada kelas yang belum semua nilainya diinput

**Dashboard Siswa:**
- Nilai terbaru per mapel
- Ringkasan nilai per mapel semester ini

**Dashboard Orang Tua:**
- Nilai terbaru anak per mapel
- Ringkasan nilai anak per mapel semester ini

**Dashboard Admin/Kepsek:**
- Progres input nilai per kelas (% guru yang sudah input)
- Progres input nilai per kelas (% sudah diinput)

**Verifikasi:**
- Setiap role melihat data penilaian yang relevan dengan aksesnya

---

#### LANGKAH 4 — Update CLAUDE.md
Update file `CLAUDE.md` di root repository:

```markdown
## Status Fase
- [x] Fase 1: Foundation
- [x] Fase 2: Core Akademik
- [x] Fase 3: Penilaian
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
- [2026-07-07] Rapor: TIDAK masuk platform
- [2026-07-07] Tipe penilaian: harian | tengah_semester | observasi_perilaku
```

---

## CHECKLIST SELESAI FASE 3

Sebelum melaporkan Fase 3 selesai, verifikasi semua item ini:

- [ ] Tabel `grades` terbuat + RLS aktif + input nilai guru berfungsi
- [ ] Tipe penilaian: harian, tengah_semester, observasi_perilaku berfungsi
- [ ] Siswa bisa lihat nilainya sendiri
- [ ] Orang tua bisa lihat nilai anak
- [ ] Dashboard setiap role diupdate dengan data penilaian
- [ ] Tidak ada data lintas sekolah yang bocor
- [ ] `CLAUDE.md` diupdate dengan status Fase 3 selesai
- [ ] Semua langkah sudah di-commit ke GitHub

---

## SETELAH FASE 3 SELESAI

Laporkan:
1. Checklist di atas — centang semua yang sudah selesai
2. Screenshot atau deskripsi singkat tampilan rapor siswa di mobile (320px)
3. Jika ada item yang tidak bisa diselesaikan — jelaskan kenapa dan tunggu instruksi

**Jangan mulai Fase 4 sebelum mendapat konfirmasi.**
