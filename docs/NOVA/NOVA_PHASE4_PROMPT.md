# NOVA — Prompt Master Claude Code
## Fase 4: Pembelajaran
**Gunakan prompt ini setelah Checkpoint Audit Fase 1–3 selesai dan dikonfirmasi.**

---

## KONTEKS PROJECT

Kamu melanjutkan pembangunan **NOVA (Next-gen One-stop Virtual Academy)** — platform PWA multi-tenant sistem informasi sekolah SD-SMP-SMA.

**Fase 1–3 + Audit sudah selesai dan terverifikasi:**
- Foundation, Core Akademik, dan Penilaian berjalan penuh
- RLS lintas fase sudah diaudit dan bersih
- Data integrity, keamanan, dan performa dasar sudah diverifikasi

**Fase 4 ini adalah fase paling kompleks** — menyentuh Claude API dan alur UX yang dirancang khusus untuk guru dengan pengetahuan teknologi minim (target terburuk: guru SD yang hanya familiar dengan WhatsApp).

Baca `CLAUDE.md`, `SPEC.md`, dan `AUDIT_REPORT.md` di root repository sebelum mulai.

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

## FASE 4 — PEMBELAJARAN

### Target Fase 4
- Guru bisa generate CP (Capaian Pembelajaran) otomatis via Claude API
- Guru bisa generate ATP (Alur Tujuan Pembelajaran) dari CP yang sudah disetujui
- Guru bisa generate modul ajar per minggu dengan alur 8 langkah yang sangat mudah
- Guru bisa menulis jurnal mengajar harian
- Siswa bisa akses materi & modul ajar yang dibagikan guru
- Siswa bisa mengerjakan dan mengumpulkan tugas
- Semua fitur ini masuk tier berbayar

### Entitas yang dibangun
`capaian_pembelajaran` → `alur_tujuan_pembelajaran` → `teaching_journals` → `lesson_modules` → `assignments` → `submissions`

---

### Langkah-langkah

#### LANGKAH 0A — Tabel `capaian_pembelajaran`
Buat migration file untuk tabel `capaian_pembelajaran`:

```sql
id uuid primary key default gen_random_uuid()
school_id uuid references schools(id) not null
level text not null -- 'SD' | 'SMP' | 'SMA'
grade integer not null -- 1-12
subject_id uuid references subjects(id) not null
academic_year text not null
content jsonb not null -- hasil generate AI: elemen CP, deskripsi, indikator
is_ai_generated boolean default true
is_approved boolean default false -- guru harus approve sebelum bisa generate ATP
approved_by uuid references users(id)
approved_at timestamptz
created_at timestamptz default now()
updated_at timestamptz default now()
```

**RLS:**
- Guru hanya bisa lihat & edit CP untuk mapel yang dia ajar di sekolahnya
- Admin/Kepsek bisa lihat semua CP di sekolahnya (read-only)

**Alur generate CP:**
1. Guru tap "Generate CP" → pilih mapel & kelas
2. Claude API generate CP berdasarkan Kurikulum Merdeka untuk jenjang & mapel tersebut
3. CP tampil dalam format yang mudah dibaca — elemen CP, deskripsi, indikator
4. Guru review → edit jika perlu → tap "Setujui CP Ini"
5. Status `is_approved = true` → CP siap dijadikan dasar ATP

**System prompt untuk generate CP:**
```
Kamu adalah asisten kurikulum untuk guru sekolah Indonesia.
Generate Capaian Pembelajaran (CP) berdasarkan Kurikulum Merdeka untuk:
- Jenjang: {level}
- Kelas: {grade}
- Mata Pelajaran: {subject}
- Tahun Ajaran: {academic_year}

Format output JSON:
{
  "elemen_cp": ["elemen 1", "elemen 2"],
  "deskripsi_umum": "deskripsi CP secara umum",
  "indikator": [
    {"elemen": "elemen 1", "indikator": ["indikator a", "indikator b"]}
  ]
}
```

**UI yang dibangun:**
- `src/pages/teacher/CapaianPembelajaran.jsx` — generate & kelola CP per mapel
- `src/components/CPCard.jsx` — tampilan kartu CP yang mudah dibaca guru

**Verifikasi:**
- Guru bisa generate CP untuk mapelnya
- CP bisa diedit sebelum disetujui
- Setelah disetujui, tombol "Generate ATP" aktif

---

#### LANGKAH 0B — Tabel `alur_tujuan_pembelajaran`
Buat migration file untuk tabel `alur_tujuan_pembelajaran`:

```sql
id uuid primary key default gen_random_uuid()
school_id uuid references schools(id) not null
cp_id uuid references capaian_pembelajaran(id) not null
subject_id uuid references subjects(id) not null
grade integer not null
academic_year text not null
semester integer not null
content jsonb not null -- ATP per minggu: minggu ke-X, tujuan, materi pokok
is_ai_generated boolean default true
is_approved boolean default false
approved_by uuid references users(id)
approved_at timestamptz
created_at timestamptz default now()
updated_at timestamptz default now()
```

**Alur generate ATP:**
1. Guru buka CP yang sudah disetujui → tap "Generate ATP"
2. Pilih semester (1 atau 2)
3. Claude API generate ATP — breakdown tujuan pembelajaran per minggu selama 1 semester
4. ATP tampil sebagai timeline minggu ke-1 sampai minggu ke-18
5. Guru review → edit urutan atau isi jika perlu → tap "Setujui ATP Ini"
6. Status `is_approved = true` → ATP siap dijadikan panduan susun modul ajar

**System prompt untuk generate ATP:**
```
Berdasarkan Capaian Pembelajaran berikut:
{cp_content}

Generate Alur Tujuan Pembelajaran (ATP) untuk Semester {semester}
dalam format JSON:
{
  "minggu": [
    {
      "ke": 1,
      "tujuan_pembelajaran": "tujuan minggu ini",
      "materi_pokok": ["materi 1", "materi 2"],
      "perkiraan_jp": 2
    }
  ]
}
Total minggu efektif: 18 minggu per semester.
Pastikan urutan ATP logis dan membangun pemahaman secara bertahap.
```

**UI yang dibangun:**
- `src/pages/teacher/AlurTujuanPembelajaran.jsx` — generate & kelola ATP
- `src/components/ATPTimeline.jsx` — tampilan timeline ATP per minggu yang visual dan mudah dibaca

**Verifikasi:**
- ATP hanya bisa di-generate dari CP yang sudah disetujui
- ATP tampil sebagai timeline 18 minggu yang jelas
- Setelah ATP disetujui, modul ajar per minggu bisa mulai disusun mengacu ATP

---

#### LANGKAH 1 — Tabel `teaching_journals`
Buat migration file untuk tabel `teaching_journals`:

```sql
id uuid primary key default gen_random_uuid()
school_id uuid references schools(id) not null
class_id uuid references classes(id) not null
subject_id uuid references subjects(id) not null
teacher_id uuid references users(id) not null
date date not null
topic text not null
activities text not null
student_response text -- catatan respon siswa
follow_up text -- tindak lanjut
academic_year text not null
semester integer not null
created_at timestamptz default now()
updated_at timestamptz default now()
```

**RLS:**
- Guru hanya bisa buat & lihat jurnal miliknya sendiri
- Admin/Kepsek bisa lihat semua jurnal di sekolahnya (read-only)
- Role lain tidak punya akses

**UI yang dibangun:**
- `src/pages/teacher/Journal.jsx` — input jurnal harian (guru)
  - Pilih kelas & mapel (dari jadwal hari ini — otomatis tersedia)
  - Input topik, aktivitas, respon siswa, tindak lanjut
  - Desain: form sederhana, field teks pendek, tidak intimidatif
- `src/pages/admin/Journals.jsx` — lihat semua jurnal per guru (admin, read-only)

**Verifikasi:**
- Guru bisa buat jurnal dan data tersimpan
- Admin bisa lihat jurnal semua guru di sekolahnya
- Guru lain tidak bisa lihat jurnal guru lain

---

#### LANGKAH 2 — Tabel `lesson_modules`

Buat migration file untuk tabel `lesson_modules`:

```sql
id uuid primary key default gen_random_uuid()
school_id uuid references schools(id) not null
class_id uuid references classes(id) not null
subject_id uuid references subjects(id) not null
teacher_id uuid references users(id) not null
academic_year text not null
semester integer not null
week integer not null -- minggu ke berapa
topic text not null
duration_jp integer not null -- jumlah jam pelajaran
methods text[] not null -- array metode mengajar
content jsonb not null -- hasil generate dari Claude API
is_ai_generated boolean default true
is_published boolean default false -- true jika sudah dibagikan ke siswa
cache_key text -- hash dari input untuk caching
created_at timestamptz default now()
updated_at timestamptz default now()
```

**RLS:**
- Guru hanya bisa buat & edit modul miliknya
- Siswa bisa lihat modul yang sudah dipublish oleh gurunya di kelas yang sama
- Admin bisa lihat semua modul di sekolahnya

---

#### LANGKAH 3 — Data Referensi Kurikulum

Sebelum membangun UI generate modul, siapkan data referensi:

**Tabel `curriculum_topics`** (data bawaan, tidak per sekolah):
```sql
id uuid primary key default gen_random_uuid()
level text not null -- 'SD' | 'SMP' | 'SMA'
grade integer not null -- 1-12
subject_name text not null
semester integer not null
topic text not null
is_custom boolean default false -- true jika ditambah guru
school_id uuid references schools(id) -- null jika bawaan sistem
created_at timestamptz default now()
```

**Tabel `teaching_methods`** (data bawaan + custom):
```sql
id uuid primary key default gen_random_uuid()
name text not null
description text
is_custom boolean default false
school_id uuid references schools(id) -- null jika bawaan sistem
created_at timestamptz default now()
```

**Seed data `teaching_methods` bawaan:**
```sql
INSERT INTO teaching_methods (name, description) VALUES
('Ceramah', 'Guru menjelaskan materi secara langsung'),
('Diskusi', 'Siswa berdiskusi untuk memahami materi'),
('Praktik Langsung', 'Siswa mempraktikkan keterampilan'),
('Permainan', 'Belajar melalui aktivitas bermain'),
('Tanya Jawab', 'Guru dan siswa saling bertanya'),
('Demonstrasi', 'Guru memperagakan, siswa mengamati'),
('Kerja Kelompok', 'Siswa bekerja sama dalam kelompok'),
('Bercerita', 'Penyampaian materi melalui cerita');
```

**RLS `curriculum_topics`:**
```sql
-- Bisa baca jika data bawaan sistem (school_id IS NULL) 
-- ATAU data custom sekolah sendiri
CREATE POLICY "read_curriculum_topics" ON curriculum_topics
FOR SELECT USING (school_id IS NULL OR school_id = auth.uid()::uuid);
```

**Seed data `curriculum_topics`:**
Isi dengan topik-topik umum Kurikulum Merdeka untuk:
- SD Kelas 1–6, semua mapel utama, Semester 1 & 2
- SMP Kelas 7–9, semua mapel utama, Semester 1 & 2
- SMA Kelas 10–12, semua mapel utama, Semester 1 & 2

---

#### LANGKAH 4 — Alur Generate Modul Ajar (UI)

Ini adalah fitur paling kritis di Fase 4. Desain untuk guru SD dengan pengetahuan teknologi minim.

**Prinsip UX wajib:**
- Setiap langkah hanya satu keputusan
- Semua input via pilihan (tap/klik) — bukan ketik, kecuali saat tambah topik/metode baru
- Bahasa Indonesia sehari-hari, tidak ada istilah teknis
- Progress indicator — guru tahu ada di langkah berapa
- Setiap langkah bisa kembali ke langkah sebelumnya

**Buat `src/pages/teacher/GenerateModule.jsx` dengan 8 langkah:**

---

**Langkah 1 — Pilih Kelas**
- Tampilkan daftar kelas yang diajar guru (dari jadwal)
- Tampil sebagai kartu besar, mudah di-tap
- Satu pilihan, lanjut otomatis ke Langkah 2

---

**Langkah 2 — Pilih Mata Pelajaran**
- Tampilkan mapel yang diajar di kelas yang dipilih
- Tampil sebagai kartu besar
- Satu pilihan, lanjut otomatis ke Langkah 3

---

**Langkah 3 — Pilih Semester & Minggu**
- Dropdown semester: "Semester 1" / "Semester 2"
- Dropdown minggu: "Minggu ke-1" sampai "Minggu ke-18"
- Tombol "Lanjut"

---

**Langkah 4 — Pilih Topik**
- Tampilkan daftar topik bawaan Kurikulum Merdeka untuk kelas + mapel + semester yang dipilih
- Tampil sebagai daftar dengan radio button besar
- Di bagian bawah: tombol "+ Tambah Topik Sendiri"
  - Jika ditap: muncul field teks untuk input topik baru
  - Topik baru disimpan ke `curriculum_topics` dengan `is_custom = true` dan `school_id` sekolah guru
- Satu pilihan, tombol "Lanjut"

---

**Langkah 5 — Pilih Durasi**
- Pilihan jumlah jam pelajaran: 1 JP / 2 JP / 3 JP / 4 JP
- Tampil sebagai 4 tombol besar
- Satu pilihan, lanjut otomatis ke Langkah 6

---

**Langkah 6 — Pilih Metode Mengajar**
- Tampilkan daftar metode bawaan sebagai chip/tag yang bisa dipilih banyak
- Di bagian bawah: tombol "+ Tambah Metode Lain"
  - Jika ditap: muncul field teks untuk input metode baru
  - Metode baru disimpan ke `teaching_methods` dengan `is_custom = true`
- Minimal satu pilihan, tombol "Lanjut"

---

**Langkah 7 — Konfirmasi & Generate**
- Tampilkan ringkasan semua pilihan:
  - Kelas, Mapel, Semester, Minggu, Topik, Durasi, Metode
- Cek cache: jika kombinasi yang sama pernah di-generate → tampilkan hasil sebelumnya langsung (tanpa API call)
- Jika tidak ada cache: tombol "Buat Modul Sekarang" yang besar dan jelas
- Saat proses generate:
  - Loading indicator dengan pesan: "Sedang membuat modul mengajar..."
  - Estimasi waktu: "Biasanya selesai dalam 10–20 detik"
- Setelah selesai: tampilkan hasil modul langsung

---

**Langkah 8 — Review & Simpan**
- Tampilkan modul hasil generate dalam format yang mudah dibaca
- Guru bisa edit bagian tertentu jika diperlukan
- Tombol "Simpan Modul" — simpan ke `lesson_modules`
- Tombol "Buat Ulang" — generate ulang dengan pilihan yang sama
- Tombol "Bagikan ke Siswa" — publish modul agar bisa diakses siswa

---

#### LANGKAH 5 — Integrasi Claude API

**File:** `src/lib/claude.js`

```javascript
// Konfigurasi
const CLAUDE_API_URL = 'https://api.anthropic.com/v1/messages';
const MODEL = 'claude-sonnet-4-6';
const MAX_TOKENS = 2000;
const RATE_LIMIT_PER_DAY = 10; // maksimal generate per guru per hari

// System prompt untuk generate modul ajar
const SYSTEM_PROMPT = `Kamu adalah asisten pembuatan modul ajar untuk guru sekolah di Indonesia.
Buat modul ajar berdasarkan Kurikulum Merdeka yang:
- Sesuai dengan tingkat kelas yang ditentukan
- Menggunakan bahasa Indonesia yang jelas dan mudah dipahami
- Praktis dan bisa langsung digunakan di kelas
- Sesuai dengan durasi dan metode yang dipilih guru

Format output HARUS dalam JSON dengan struktur berikut:
{
  "tujuan_pembelajaran": ["tujuan 1", "tujuan 2"],
  "alur_kegiatan": {
    "pendahuluan": { "durasi": "X menit", "kegiatan": ["kegiatan 1", "kegiatan 2"] },
    "inti": { "durasi": "X menit", "kegiatan": ["kegiatan 1", "kegiatan 2"] },
    "penutup": { "durasi": "X menit", "kegiatan": ["kegiatan 1", "kegiatan 2"] }
  },
  "media_alat": ["media 1", "alat 2"],
  "penilaian": {
    "teknik": "teknik penilaian",
    "instrumen": "bentuk instrumen penilaian"
  },
  "catatan_guru": "tips atau catatan penting untuk guru"
}

Jangan tambahkan teks di luar JSON.`;
```

**Fungsi generate dengan rate limiting & caching:**
```javascript
async function generateLessonModule({ 
  level, grade, subject, semester, week, topic, durationJP, methods, teacherId, schoolId 
}) {
  // 1. Cek rate limit
  const todayCount = await checkDailyLimit(teacherId);
  if (todayCount >= RATE_LIMIT_PER_DAY) {
    throw new Error(`Batas generate harian tercapai (${RATE_LIMIT_PER_DAY}x per hari). Coba lagi besok.`);
  }

  // 2. Cek cache
  const cacheKey = generateCacheKey({ level, grade, subject, semester, topic, durationJP, methods });
  const cached = await checkCache(cacheKey, schoolId);
  if (cached) return { data: cached, fromCache: true };

  // 3. Sanitasi input
  const sanitizedTopic = sanitizeInput(topic);
  const sanitizedMethods = methods.map(sanitizeInput);

  // 4. Build prompt
  const userPrompt = `Buat modul ajar dengan detail berikut:
- Jenjang: ${level}
- Kelas: ${grade}
- Mata Pelajaran: ${subject}
- Semester: ${semester}
- Minggu ke: ${week}
- Topik: ${sanitizedTopic}
- Durasi: ${durationJP} Jam Pelajaran
- Metode mengajar: ${sanitizedMethods.join(', ')}`;

  // 5. Call Claude API
  const response = await fetch(CLAUDE_API_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system: SYSTEM_PROMPT,
      messages: [{ role: 'user', content: userPrompt }]
    })
  });

  const data = await response.json();
  const content = JSON.parse(data.content[0].text);

  // 6. Simpan ke cache & increment counter
  await saveToCache(cacheKey, content, schoolId);
  await incrementDailyLimit(teacherId);

  return { data: content, fromCache: false };
}
```

**Fungsi pendukung yang harus dibangun:**
- `checkDailyLimit(teacherId)` — cek jumlah generate hari ini dari tabel `rate_limits`
- `incrementDailyLimit(teacherId)` — tambah counter harian
- `generateCacheKey(params)` — hash dari parameter input
- `checkCache(cacheKey, schoolId)` — cek tabel `module_cache`
- `saveToCache(cacheKey, content, schoolId)` — simpan ke `module_cache`
- `sanitizeInput(text)` — bersihkan input dari karakter berbahaya

**Tabel pendukung yang perlu dibuat:**

```sql
-- Rate limiting
CREATE TABLE rate_limits (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid references users(id) not null,
  date date not null default current_date,
  count integer default 1,
  UNIQUE(teacher_id, date)
);

-- Cache modul
CREATE TABLE module_cache (
  id uuid primary key default gen_random_uuid(),
  school_id uuid references schools(id) not null,
  cache_key text not null,
  content jsonb not null,
  hit_count integer default 1,
  created_at timestamptz default now(),
  UNIQUE(cache_key, school_id)
);
```

---

#### LANGKAH 6 — Tabel `assignments` & `submissions`

**Tabel `assignments`:**
```sql
id uuid primary key default gen_random_uuid()
school_id uuid references schools(id) not null
class_id uuid references classes(id) not null
subject_id uuid references subjects(id) not null
teacher_id uuid references users(id) not null
lesson_module_id uuid references lesson_modules(id) -- opsional, bisa standalone
title text not null
description text not null
due_date timestamptz not null
academic_year text not null
semester integer not null
is_published boolean default false
created_at timestamptz default now()
```

**Tabel `submissions`:**
```sql
id uuid primary key default gen_random_uuid()
school_id uuid references schools(id) not null
assignment_id uuid references assignments(id) not null
student_id uuid references users(id) not null
content text -- jawaban teks
file_url text -- jika ada file upload
submitted_at timestamptz default now()
status text default 'submitted' -- 'submitted' | 'graded'
score numeric(5,2)
feedback text
graded_at timestamptz
graded_by uuid references users(id)
```

**RLS:**
- Guru bisa buat & lihat tugas dan submission di kelasnya
- Siswa hanya bisa lihat tugas yang published + submission miliknya sendiri
- Ortu hanya bisa lihat tugas & submission anaknya

**UI yang dibangun:**
- `src/pages/teacher/Assignments.jsx` — buat & kelola tugas (guru)
- `src/pages/teacher/Submissions.jsx` — lihat & nilai submission siswa (guru)
- `src/pages/student/Assignments.jsx` — lihat daftar tugas (siswa)
- `src/pages/student/SubmitAssignment.jsx` — kerjakan & kumpul tugas (siswa)
- `src/pages/parent/Assignments.jsx` — lihat tugas & status pengumpulan anak (ortu)

---

#### LANGKAH 7 — Update Dashboard per Role

**Dashboard Guru:**
- Shortcut "Buat Modul Hari Ini"
- Tugas yang belum dinilai (jumlah submission masuk)
- Sisa kuota generate hari ini (X dari 10)

**Dashboard Siswa:**
- Tugas yang belum dikumpulkan + deadline
- Modul ajar terbaru dari guru
- Notifikasi tugas mendekati deadline

**Dashboard Orang Tua:**
- Status pengumpulan tugas anak
- Tugas yang belum dikumpulkan anak

**Dashboard Admin:**
- Jumlah modul ajar yang sudah dibuat per guru
- Ringkasan aktivitas pembelajaran minggu ini

---

#### LANGKAH 8 — Update CLAUDE.md

```markdown
## Status Fase
- [x] Fase 1: Foundation
- [x] Fase 2: Core Akademik
- [x] Fase 3: Penilaian
- [x] Fase 4: Pembelajaran
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
- [2026-07-07] Claude API: rate limit 10x generate per guru per hari
- [2026-07-07] Claude API: cache aktif — topik sama tidak generate ulang
- [2026-07-07] CP: AI generate berdasarkan Kurikulum Merdeka, guru review & approve
- [2026-07-07] ATP: AI generate dari CP yang disetujui, breakdown per minggu 18 minggu
- [2026-07-07] Generate modul: mengacu ATP yang sudah disetujui, 8 langkah (bukan ketik bebas)
- [2026-07-07] Topik & metode: bawaan sistem + bisa ditambah guru
```

---

## CHECKLIST SELESAI FASE 4

- [ ] Tabel `capaian_pembelajaran` terbuat + RLS aktif + generate CP berfungsi
- [ ] Guru bisa review, edit, dan approve CP
- [ ] Tabel `alur_tujuan_pembelajaran` terbuat + RLS aktif + generate ATP berfungsi
- [ ] ATP hanya bisa dibuat dari CP yang sudah disetujui
- [ ] ATP tampil sebagai timeline 18 minggu
- [ ] Tabel `teaching_journals` terbuat + RLS aktif + UI guru berfungsi
- [ ] Tabel `lesson_modules` terbuat + RLS aktif
- [ ] Tabel `curriculum_topics` terbuat + seed data Kurikulum Merdeka terisi
- [ ] Tabel `teaching_methods` terbuat + seed data 8 metode bawaan terisi
- [ ] Tabel `rate_limits` terbuat + rate limiting berfungsi (max 10x/hari)
- [ ] Tabel `module_cache` terbuat + cache berfungsi
- [ ] Alur generate modul 8 langkah berfungsi end-to-end
- [ ] Claude API berhasil dipanggil dan menghasilkan modul dalam format JSON
- [ ] Guru dengan pengetahuan minim bisa generate modul tanpa bingung
- [ ] Topik baru bisa ditambahkan guru
- [ ] Metode baru bisa ditambahkan guru
- [ ] Tabel `assignments` + `submissions` terbuat + RLS aktif
- [ ] Siswa bisa lihat dan kumpul tugas
- [ ] Dashboard setiap role diupdate
- [ ] `CLAUDE.md` diupdate dengan status Fase 4 selesai
- [ ] Semua langkah sudah di-commit ke GitHub

---

## SETELAH FASE 4 SELESAI

Laporkan:
1. Checklist di atas — centang semua yang sudah selesai
2. Screenshot atau deskripsi alur generate modul dari Langkah 1 sampai hasil tampil
3. Konfirmasi rate limiting berfungsi — coba generate lebih dari 10x dan pastikan error muncul
4. Jika ada item yang tidak bisa diselesaikan — jelaskan kenapa dan tunggu instruksi

**Jangan mulai Fase 5 sebelum mendapat konfirmasi.**
