# ADR-002 — Curriculum Repository
# Student Insight Platform (SIP)
# Status: DRAFT v2 — OPEN untuk penyempurnaan
# Tanggal: 18 Juli 2026
# Berlaku untuk: Fitur AI Learning — SMK
# Bergantung pada: ADR-001
# Dasar hukum:
#   Kepmendikbudristek No. 244/M/2024 — Spektrum Keahlian SMK
#   Permendikdasmen No. 10/2025     — SKL + 8 Dimensi Profil Lulusan
#   Permendikdasmen No. 13/2025     — Kurikulum + Deep Learning
#   SK BSKAP No. 046/H/KR/2025     — Capaian Pembelajaran terbaru

---

## 1. Konteks

Curriculum Repository adalah sub-repository pertama dari SIP Core.
Berisi representasi terstruktur dari regulasi kurikulum nasional yang
dikurasi oleh SIP team — bukan data yang dibuat atau dimiliki tenant.

ADR ini mendefinisikan:
- Struktur hierarki kurikulum SMK
- Schema tabel di PostgreSQL schema `core`
- Strategi seed dan versioning
- Aturan akses (siapa boleh baca, tidak ada yang boleh tulis)

---

## 2. Hierarki Kurikulum SMK

Dalam Kurikulum Merdeka SMK, istilah "normatif/adaptif" tidak digunakan lagi.
Struktur resmi terbagi menjadi Kelompok A (Umum) dan Kelompok B (Kejuruan).

```
Kurikulum Nasional (versi)
    │
    ├── Kelompok A: Mata Pelajaran Umum
    │   (berlaku untuk semua SMK, semua kelas)
    │   │
    │   ├── Pendidikan Agama & Budi Pekerti  → Fase E + F
    │   │   (per agama: Islam, Kristen, Katolik, Buddha, Hindu, Khonghucu)
    │   ├── Pendidikan Pancasila             → Fase E + F
    │   ├── Bahasa Indonesia                 → Fase E + F
    │   ├── PJOK                             → Fase E + F (tidak ada di kelas XII)
    │   ├── Sejarah                          → Fase E + F (tidak ada di kelas XII)
    │   ├── Seni Budaya                      → Fase E (kelas X saja)
    │   │   (pilih 1: Musik / Rupa / Teater / Tari)
    │   └── Muatan Lokal                     → Fase E + F (maks 2 JP/minggu)
    │
    └── Kelompok B: Mata Pelajaran Kejuruan
        │
        ├── Berlaku semua SMK (kelas X):
        │   ├── Matematika                   → Fase E + F
        │   ├── Bahasa Inggris               → Fase E + F
        │   ├── Informatika                  → Fase E (kelas X saja)
        │   ├── Projek IPAS                  → Fase E (kelas X saja)
        │   └── Dasar-dasar Program Keahlian → Fase E (per program)
        │
        ├── Berlaku semua SMK (kelas XI-XII):
        │   ├── Projek Kreatif & Kewirausahaan → Fase F
        │   ├── Mata Pelajaran Pilihan          → Fase F
        │   └── PKL                             → Fase F (kelas XII)
        │
        └── Terikat Program Keahlian:
            Bidang Keahlian (10 bidang)
            └── Program Keahlian (50 program)
                └── Konsentrasi Keahlian (128 konsentrasi)
                    └── Mata Pelajaran Konsentrasi
                        └── Capaian Pembelajaran (CP)
                            └── Elemen CP
```

---

## 3. 10 Bidang Keahlian Nasional

Berdasarkan Kepmendikbudristek No. 244/M/2024:

| # | Bidang Keahlian |
|---|----------------|
| 1 | Teknologi Konstruksi dan Properti |
| 2 | Teknologi Manufaktur dan Rekayasa |
| 3 | Energi dan Pertambangan |
| 4 | Teknologi Informasi |
| 5 | Kesehatan dan Pekerjaan Sosial |
| 6 | Agribisnis dan Agriteknologi |
| 7 | Kemaritiman |
| 8 | Bisnis dan Manajemen |
| 9 | Pariwisata |
| 10 | Seni dan Ekonomi Kreatif |

Total: 50 Program Keahlian, 128 Konsentrasi Keahlian.

---

## 4. Seed Prioritas untuk Pilot

### Prioritas 1 — Mapel Umum + Kejuruan Lintas Prodi (berlaku semua SMK)

Di-seed sebelum pilot dimulai. Tanpa ini, tidak ada guru yang bisa
generate PPM apapun.

**Kelompok A — Mata Pelajaran Umum:**
```
Pendidikan Agama Islam & Budi Pekerti    Fase E + F
Pendidikan Agama Kristen & Budi Pekerti  Fase E + F
Pendidikan Agama Katolik & Budi Pekerti  Fase E + F
Pendidikan Agama Buddha & Budi Pekerti   Fase E + F
Pendidikan Agama Hindu & Budi Pekerti    Fase E + F
Pendidikan Agama Khonghucu & Budi Pekerti Fase E + F
Pendidikan Pancasila                     Fase E + F
Bahasa Indonesia                         Fase E + F
PJOK                                     Fase E + F
Sejarah                                  Fase E + F
Seni Budaya (Musik)                      Fase E
Seni Budaya (Rupa)                       Fase E
Seni Budaya (Teater)                     Fase E
Seni Budaya (Tari)                       Fase E
Muatan Lokal                             Fase E + F
```

**Kelompok B — Kejuruan Lintas Prodi (wajib semua SMK):**
```
Matematika                               Fase E + F
Bahasa Inggris                           Fase E + F
Informatika                              Fase E (kelas X)
Projek IPAS                              Fase E (kelas X)
Projek Kreatif dan Kewirausahaan         Fase F (kelas XI-XII)
```

### Prioritas 2 — 10 Program Keahlian SMKN 1 Ujungbatu (sekolah pilot)

Di-seed saat pilot SMKN 1 Ujungbatu dimulai.

```
1. Teknik Jaringan Komputer dan Telekomunikasi (TJKT) → TKJ
2. Teknik Kendaraan Ringan Otomotif (TKRO)
3. Teknik Bisnis Sepeda Motor (TBSM)
4. Bisnis Daring dan Pemasaran (BDP)
5. Teknik Elektronika
6. Teknik Logistik
7. Broadcasting dan Perfilman
8. Desain dan Produksi Busana (DPB)
9. Produksi dan Siaran Program Televisi (PSPT)
10. Seni Pertunjukan
```

### Prioritas 3 — Seluruh Spektrum Nasional

Di-seed sebelum go nasional. Mencakup seluruh 50 program keahlian
dan 128 konsentrasi keahlian berdasarkan Kepmendikbudristek No. 244/2024.

---

## 5. Schema Database

Semua tabel berada di PostgreSQL schema `core`.
Tidak ada `school_id`. Tidak ada `created_by`.
Hanya SIP Team yang bisa INSERT/UPDATE/DELETE.
Semua `authenticated` user bisa SELECT.

### 5.1 core.curriculum_versions

```sql
CREATE TABLE core.curriculum_versions (
  version_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version_code    VARCHAR(20) NOT NULL UNIQUE,  -- contoh: '2024', '2025'
  name            TEXT NOT NULL,                -- contoh: 'Kurikulum Nasional 2024'
  regulation_ref  TEXT NOT NULL,               -- contoh: 'Kepmendikbudristek No. 244/M/2024'
  effective_date  DATE NOT NULL,
  status          VARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'SUPERSEDED', 'DRAFT')),
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);
```

### 5.2 core.education_levels

```sql
CREATE TABLE core.education_levels (
  level_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code        VARCHAR(10) NOT NULL UNIQUE,   -- 'SMK', 'SMA', 'SMP', 'SD'
  name        TEXT NOT NULL,
  is_active   BOOLEAN DEFAULT true
);
```

### 5.3 core.phases

```sql
CREATE TABLE core.phases (
  phase_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  level_id        UUID NOT NULL REFERENCES core.education_levels(level_id),
  code            VARCHAR(5) NOT NULL,     -- 'E', 'F'
  name            TEXT NOT NULL,           -- 'Fase E (Kelas X SMK)'
  grade_range     VARCHAR(20),             -- 'Kelas X', 'Kelas XI-XII'
  UNIQUE (level_id, code)
);
```

### 5.4 core.vocational_fields

Bidang Keahlian — 10 bidang nasional.

```sql
CREATE TABLE core.vocational_fields (
  field_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code        VARCHAR(10) NOT NULL UNIQUE,  -- 'TI', 'BM', 'PAR', dst
  name        TEXT NOT NULL,               -- 'Teknologi Informasi'
  is_active   BOOLEAN DEFAULT true
);
```

### 5.5 core.vocational_programs

Program Keahlian — 50 program nasional.

```sql
CREATE TABLE core.vocational_programs (
  program_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  field_id      UUID NOT NULL REFERENCES core.vocational_fields(field_id),
  code          VARCHAR(20) NOT NULL UNIQUE,  -- 'TJKT', 'BDP', 'DPB', dst
  name          TEXT NOT NULL,               -- 'Teknik Jaringan Komputer dan Telekomunikasi'
  name_short    VARCHAR(50),                 -- 'TKJ / TJKT'
  is_active     BOOLEAN DEFAULT true
);
```

### 5.6 core.vocational_concentrations

Konsentrasi Keahlian — 128 konsentrasi nasional.

```sql
CREATE TABLE core.vocational_concentrations (
  concentration_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id        UUID NOT NULL REFERENCES core.vocational_programs(program_id),
  code              VARCHAR(20) NOT NULL UNIQUE,
  name              TEXT NOT NULL,
  is_active         BOOLEAN DEFAULT true
);
```

### 5.7 core.subjects

Mata Pelajaran — normatif/adaptif dan kejuruan.

```sql
CREATE TABLE core.subjects (
  subject_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code            VARCHAR(30) NOT NULL UNIQUE,  -- 'BHS_ING', 'MTK', 'TJKT_DASAR', dst
  name            TEXT NOT NULL,
  subject_type    VARCHAR(30) NOT NULL CHECK (
                    subject_type IN (
                      'UMUM',                  -- Kelompok A: berlaku semua SMK
                      'KEJURUAN_LINTAS_PRODI', -- Kelompok B: Matematika, B.Inggris,
                                               --   Informatika, Projek IPAS,
                                               --   Projek Kreatif & Kewirausahaan
                      'KEJURUAN_DASAR',        -- Dasar-dasar Program Keahlian (kelas X)
                      'KEJURUAN_KONSENTRASI',  -- Konsentrasi Keahlian (kelas XI-XII)
                      'KEJURUAN_PILIHAN',      -- Mata Pelajaran Pilihan
                      'PKL',                   -- Praktik Kerja Lapangan
                      'MUATAN_LOKAL'           -- Muatan Lokal sekolah
                    )
                  ),
  -- Untuk UMUM + KEJURUAN_LINTAS_PRODI: program_id NULL (berlaku semua SMK)
  -- Untuk KEJURUAN_DASAR + KONSENTRASI: program_id diisi
  program_id      UUID REFERENCES core.vocational_programs(program_id),
  concentration_id UUID REFERENCES core.vocational_concentrations(concentration_id),
  is_active       BOOLEAN DEFAULT true
);
```

### 5.8 core.subject_phases

Relasi mapel ↔ fase (satu mapel bisa ada di beberapa fase).

```sql
CREATE TABLE core.subject_phases (
  subject_phase_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id        UUID NOT NULL REFERENCES core.subjects(subject_id),
  phase_id          UUID NOT NULL REFERENCES core.phases(phase_id),
  version_id        UUID NOT NULL REFERENCES core.curriculum_versions(version_id),
  jp_per_week       INT,          -- JP/minggu default (bisa dioverride sekolah)
  UNIQUE (subject_id, phase_id, version_id)
);
```

### 5.9 core.capaian_pembelajaran

CP per mapel per fase — isi dari dokumen BSKAP.

```sql
CREATE TABLE core.capaian_pembelajaran (
  cp_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_phase_id UUID NOT NULL REFERENCES core.subject_phases(subject_phase_id),
  version_id      UUID NOT NULL REFERENCES core.curriculum_versions(version_id),

  -- Konten CP
  rasional        TEXT,           -- Rasional mapel
  tujuan          TEXT,           -- Tujuan pembelajaran mapel
  karakteristik   TEXT,           -- Karakteristik mapel
  cp_umum         TEXT NOT NULL,  -- Deskripsi CP keseluruhan fase

  -- Metadata regulasi
  bskap_ref       VARCHAR(100),   -- 'SK BSKAP No. 046/H/KR/2025'
  effective_date  DATE,

  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),

  UNIQUE (subject_phase_id, version_id)
);
```

### 5.10 core.cp_elements

Elemen CP — breakdown CP per elemen dalam satu fase.

```sql
CREATE TABLE core.cp_elements (
  element_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cp_id           UUID NOT NULL REFERENCES core.capaian_pembelajaran(cp_id)
                  ON DELETE CASCADE,
  urutan          INT NOT NULL,
  nama_elemen     VARCHAR(200) NOT NULL,   -- 'Menyimak', 'Berbicara', dst
  deskripsi_cp    TEXT NOT NULL,           -- Deskripsi CP per elemen
  UNIQUE (cp_id, urutan)
);
```

---

## 6. RLS (Row-Level Security)

Schema `core` menggunakan RLS yang sederhana:
- SELECT: semua `authenticated` (semua role SIP)
- INSERT/UPDATE/DELETE: hanya `service_role` (SIP Team via migration)
- Tidak ada policy untuk `anon`

```sql
-- Contoh untuk satu tabel — diterapkan ke semua tabel core.*
ALTER TABLE core.capaian_pembelajaran ENABLE ROW LEVEL SECURITY;

CREATE POLICY core_cp_select ON core.capaian_pembelajaran
  FOR SELECT TO authenticated
  USING (true);

-- Tidak ada INSERT/UPDATE/DELETE policy untuk authenticated atau anon
-- SIP Team menggunakan service_role (bypass RLS) via migration
```

---

## 7. Versioning CP

Saat Kemendikdasmen merilis CP baru:

1. SIP Team membuat row baru di `core.curriculum_versions`
   dengan `status = 'DRAFT'`
2. Seed data CP baru ke `core.capaian_pembelajaran` dengan `version_id` baru
3. Test validasi — pastikan semua CP baru lengkap
4. Set versi lama ke `status = 'SUPERSEDED'`
5. Set versi baru ke `status = 'ACTIVE'`

**Dokumen PPM guru yang sudah dibuat tidak berubah.**
PPM menyimpan `curriculum_version` yang merujuk ke versi saat generate.
Status "Perlu Ditinjau" muncul di UI jika versi aktif berbeda dari
versi yang digunakan PPM — bukan perubahan otomatis.

```
curriculum_version di PPM = '2024'
curriculum_versions.status = 'SUPERSEDED' untuk '2024'
→ UI menampilkan: "CP versi 2025.1 tersedia — [Tinjau] [Abaikan]"
```

---

## 8. Integrasi dengan School Tenant

Tabel `core` tidak memiliki `school_id`.
School Tenant merujuk ke `core` melalui foreign key di tabel `public`:

```
public.programs (tenant)
    └── program_id → core.vocational_programs.program_id

public.subjects (tenant — mapping mapel yang diajarkan sekolah)
    └── core_subject_id → core.subjects.subject_id

public.teaching_assignments (tenant)
    └── core_subject_id → core.subjects.subject_id
    └── phase_id        → core.phases.phase_id
```

Context Builder membaca CP dari `core` berdasarkan:
```
teaching_assignment → program_id → core.vocational_programs
                    → core_subject_id → core.subjects
                    → phase_id → core.phases
                    → core.subject_phases
                    → core.capaian_pembelajaran
                    → core.cp_elements
```

---

## 9. Seed Plan

### Format seed

Data CP di-seed melalui SQL migration files di:
```
supabase/seeds/core/
  001_curriculum_versions.sql
  002_education_levels.sql
  003_phases.sql
  004_vocational_fields.sql
  005_vocational_programs.sql
  006_vocational_concentrations.sql
  007_subjects_normatif_adaptif.sql
  008_subjects_kejuruan_pilot.sql
  009_subject_phases.sql
  010_capaian_pembelajaran_normatif.sql
  011_capaian_pembelajaran_pilot.sql
  012_cp_elements.sql
```

### Sumber data seed

CP diambil dari:
- SK BSKAP No. 046/H/KR/2025 (CP terbaru)
- Portal Kemdikdasmen: kurikulum.kemdikbud.go.id
- Divalidasi SIP Team sebelum di-push ke production

### Siapa yang mengerjakan seed

SIP Team (Romo) — bukan Claude Code.
Claude Code hanya membantu format SQL dan validasi struktur.
Konten CP adalah tanggung jawab SIP sebagai kurator.

---

## 10. Yang Tidak Diputuskan di ADR Ini

| Topik | Catatan |
|-------|---------|
| Schema Knowledge Repository | ADR-003 |
| Schema Teacher Workspace (ATP, PPM, dst) | ADR-004 |
| Bagaimana Context Builder membaca core.* | ADR-005 |
| Format dan isi lengkap setiap seed file | Dikerjakan saat implementasi sprint |
| Konversi spektrum lama ke 244/2024 | Diputuskan saat sekolah dengan prodi lama onboard |

---

## 11. Checklist Persetujuan

- [ ] Hierarki kurikulum SMK: Kurikulum → Bidang → Program → Konsentrasi → Mapel → CP → Elemen
- [ ] Schema `core` terpisah dari `public` — tidak ada school_id di tabel manapun
- [ ] 10 tabel schema: curriculum_versions, education_levels, phases, vocational_fields, vocational_programs, vocational_concentrations, subjects, subject_phases, capaian_pembelajaran, cp_elements
- [ ] subject_type membedakan normatif/adaptif/kejuruan — program_id NULL untuk normatif
- [ ] RLS: SELECT untuk semua authenticated, INSERT/UPDATE/DELETE hanya service_role
- [ ] Terminologi: tidak ada lagi "normatif/adaptif" — diganti Kelompok A (Umum) dan Kelompok B (Kejuruan)
- [ ] Matematika dan Bahasa Inggris masuk Kelompok B (Kejuruan), bukan Kelompok A
- [ ] PPKn diganti Pendidikan Pancasila
- [ ] Mapel baru yang terlewat: Informatika (kelas X), Projek IPAS (kelas X), Projek Kreatif & Kewirausahaan (kelas XI-XII)
- [ ] subject_type: 7 kategori (UMUM, KEJURUAN_LINTAS_PRODI, KEJURUAN_DASAR, KEJURUAN_KONSENTRASI, KEJURUAN_PILIHAN, PKL, MUATAN_LOKAL)
- [ ] Seed Prioritas 1: mapel Umum (15 mapel) + Kejuruan lintas prodi (5 mapel) — sebelum pilot
- [ ] Seed Prioritas 2: 10 prodi SMKN 1 Ujungbatu (saat pilot)
- [ ] Seed Prioritas 3: seluruh 50 program keahlian (sebelum go nasional)
- [ ] Sumber seed: SK BSKAP No. 046/H/KR/2025 + portal Kemdikdasmen
- [ ] Versioning: PPM lama tidak berubah saat CP diperbarui, hanya flag "Perlu Ditinjau"
- [ ] Integrasi: public.teaching_assignments merujuk ke core.subjects via foreign key
