# ADR-003 — Knowledge Repository
# Student Insight Platform (SIP)
# Status: DRAFT v2 — OPEN untuk penyempurnaan
# Tanggal: 18 Juli 2026
# Berlaku untuk: Fitur AI Learning — SMK
# Bergantung pada: ADR-001, ADR-002

---

## 1. Konteks

Knowledge Repository adalah sub-repository kedua dari SIP Core.
Berbeda dengan Curriculum Repository yang berisi regulasi nasional,
Knowledge Repository berisi konteks dunia kerja dan preferensi mengajar
yang membuat output AI relevan untuk kelas nyata guru.

ADR ini mendefinisikan:
- Dua layer Knowledge: Nasional (SIP) dan Teacher (Guru)
- Schema tabel
- Bagaimana Context Builder menggunakan kedua layer ini
- Mekanisme tap + input di UI

---

## 2. Koreksi terhadap ADR-001

ADR-001 mendefinisikan tiga layer Knowledge:
- Knowledge Nasional → SIP
- Knowledge Sekolah  → Admin sekolah
- Teacher Knowledge  → Guru

**Koreksi:** Knowledge Sekolah sebagai entitas terpisah yang dikelola
admin dihapus dari arsitektur. Alasannya: admin tidak terlibat dalam
alur Generate PPM. Konteks lokal sekolah (nama DUDI, Teaching Factory,
produk unggulan) diisi oleh guru sendiri saat setup konteks Generate,
dan disimpan sebagai bagian dari Teacher Knowledge.

**Struktur final Knowledge Repository:**

```
Knowledge Nasional  → SIP Team (konten pilihan-pilihan per bidang keahlian)
                      Tidak terlihat guru — hanya dibaca AI di balik layar
                      Disimpan di schema core

Teacher Knowledge   → Guru (tap pilihan + input spesifik)
                      Disimpan permanen, bisa di-refresh kapan saja
                      Disimpan di schema public (Teacher Workspace)
                      Terbagi dua:
                        Teacher Profile  → stabil lintas tahun ajaran
                        Teaching Context → per kelas per tahun ajaran
```

---

## 3. Knowledge Nasional

### 3.1 Definisi

Knowledge Nasional adalah pengetahuan tentang dunia kerja per bidang
keahlian yang dikurasi oleh SIP Team. Guru tidak pernah melihat atau
mengedit konten ini — hanya AI yang membacanya saat Context Builder
merakit prompt.

### 3.2 Isi Knowledge Nasional per Program Keahlian

Contoh untuk TKJ (Teknik Jaringan Komputer dan Telekomunikasi):

```
SOFTWARE & TOOLS INDUSTRI
  Cisco Packet Tracer, GNS3, Wireshark, MikroTik RouterOS,
  Putty, Nmap, Zabbix, Grafana

SERTIFIKASI STANDAR
  MikroTik MTCNA, MTCRE, Cisco CCNA, CompTIA Network+
  → per sertifikasi: topik wajib, urutan materi resmi,
    kompetensi yang diuji, passing score

ISTILAH TEKNIS
  VLAN, subnetting, routing, firewall, NAT, DHCP, DNS,
  BGP, OSPF, VPN, QoS, load balancing

CONTOH PROYEK INDUSTRI
  Konfigurasi jaringan kantor, setup hotspot publik,
  implementasi VLAN untuk sekolah, monitoring jaringan

DUDI UMUM
  ISP, perusahaan telekomunikasi, data center, IT support
  perusahaan, instansi pemerintah

STANDAR KOMPETENSI
  Unit kompetensi BNSP yang relevan per program keahlian
```

### 3.3 Schema — core.knowledge_national

```sql
CREATE TABLE core.knowledge_national (
  kn_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id      UUID REFERENCES core.vocational_programs(program_id),
  -- NULL = berlaku lintas program (umum semua SMK)

  category        VARCHAR(50) NOT NULL CHECK (category IN (
                    'SOFTWARE_TOOLS',       -- software dan alat industri
                    'SERTIFIKASI',          -- sertifikasi standar industri
                    'ISTILAH_TEKNIS',       -- kosakata dan terminologi
                    'CONTOH_PROYEK',        -- contoh proyek nyata industri
                    'DUDI_UMUM',            -- jenis DUDI yang relevan
                    'STANDAR_KOMPETENSI',   -- unit kompetensi BNSP
                    'BUDAYA_KERJA'          -- norma dan budaya kerja industri
                  )),

  label           VARCHAR(200) NOT NULL,    -- nama singkat untuk UI pilihan
  deskripsi       TEXT NOT NULL,            -- penjelasan lengkap untuk prompt AI
  tags            TEXT[],                   -- tag untuk pencarian/filter
  version_id      UUID NOT NULL REFERENCES core.curriculum_versions(version_id),
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);
```

### 3.4 RLS Knowledge Nasional

```sql
ALTER TABLE core.knowledge_national ENABLE ROW LEVEL SECURITY;

CREATE POLICY kn_select ON core.knowledge_national
  FOR SELECT TO authenticated
  USING (is_active = true);

-- Tidak ada INSERT/UPDATE/DELETE untuk tenant
-- SIP Team menggunakan service_role via migration
```

---

## 4. Teacher Knowledge

### 4.1 Definisi

Teacher Knowledge adalah konteks mengajar yang diisi guru sendiri via
tap pilihan dan input spesifik di UI. Disimpan permanen dan dipakai
ulang untuk Generate berikutnya. Guru bisa me-refresh kapan saja.

Tidak ada admin yang terlibat. Guru adalah satu-satunya yang mengisi
dan memiliki data ini.

### 4.2 Teacher Profile

Stabil lintas tahun ajaran. Diisi sekali, dipakai semua Generate.
Saat Generate, ditampilkan sebagai ringkasan konfirmasi — guru tidak
perlu mengisi ulang kecuali ingin mengubah.

**Isi Teacher Profile:**

```
INSTRUCTIONAL INTENT (tap satu pilihan)
  ○ Persiapan PKL
  ○ Persiapan Dunia Kerja
  ○ Persiapan Sertifikasi
    → Input spesifik: nama sertifikasi (contoh: Mikrotik MTCNA)
  ○ Persiapan LKS
  ○ Penguatan Konsep Dasar
  ○ Projek Kewirausahaan
  ○ UMKM Lokal
  ○ Lainnya
    → Input spesifik: deskripsi bebas

ASSESSMENT PHILOSOPHY (tap satu pilihan)
  ○ Praktik
  ○ Portofolio
  ○ Presentasi
  ○ Observasi
  ○ Tes Tertulis
  ○ Kombinasi

TEACHING STYLE (tap satu pilihan)
  ○ Guru dominan
  ○ Siswa dominan
  ○ Seimbang

MODEL PEMBELAJARAN (tap satu pilihan)
  ○ Project-Based Learning
  ○ Problem-Based Learning
  ○ Discovery Learning
  ○ Ceramah + Latihan

GAYA PENYAMPAIAN (tap satu pilihan)
  ○ Banyak praktik
  ○ Banyak diskusi
  ○ Banyak demonstrasi

JADWAL PEMBELAJARAN (tap satu pilihan)
  ○ 2 JP × beberapa hari terpisah
  ○ 6 JP sekaligus (block)
  ○ Teori dulu lalu praktik
  ○ Praktik penuh

DURASI PROYEK (tap satu pilihan)
  ○ 1 minggu
  ○ 2–4 minggu
  ○ Satu semester

TINGKAT KEDALAMAN (tap satu pilihan)
  ○ Dasar
  ○ Menengah
  ○ Mahir

KONTEKS LOKAL (input teks, opsional)
  Kota/daerah     : [teks bebas]
  Industri lokal  : [teks bebas]
  Nama DUDI mitra : [teks bebas]
  Produk/jasa lokal: [teks bebas]

YANG DIHINDARI (tap multi-pilihan, opsional)
  ☐ Role play
  ☐ Debat
  ☐ Presentasi individu
  ☐ Tugas rumah
  ☐ Praktik outdoor
  ☐ Lainnya → Input spesifik

INTEGRATION PREFERENCE (tap multi-pilihan, opsional)
  ☐ Numerasi
  ☐ Literasi
  ☐ AI / Teknologi
  ☐ Kewirausahaan
  ☐ Budaya lokal
  ☐ Profil Lulusan 8 Dimensi
```

### 4.3 Teaching Context

Per kelas per tahun ajaran. Berubah sesuai kondisi kelas nyata.

**Isi Teaching Context:**

```
KONTEKS SISWA (tap pilihan + input)
  Latar belakang    : ○ Anak petani ○ Pedagang ○ Pengrajin ○ Campuran
  Akses teknologi   : ○ Smartphone saja ○ Laptop tersedia ○ Tidak ada internet
  Bahasa sehari-hari: [teks bebas, opsional]

KARAKTERISTIK KELAS (tap multi-pilihan)
  ☐ Pasif
  ☐ Aktif bertanya
  ☐ Sulit bekerja kelompok
  ☐ Disiplin tinggi
  ☐ Cepat bosan
  ☐ Sangat heterogen

TINGKAT OTONOMI SISWA (tap satu pilihan)
  ○ Sangat mandiri
  ○ Perlu arahan
  ○ Sangat bergantung guru

LEARNING CONSTRAINTS (tap multi-pilihan)
  ☐ Internet sering mati
  ☐ Lab dipakai bergantian
  ☐ HP tidak boleh dibawa
  ☐ Praktik hanya seminggu sekali
  ☐ Waktu praktik maksimal 2 JP
  ☐ Lainnya → Input spesifik

RESOURCE AVAILABILITY (tap multi-pilihan)
  ☐ Buku paket resmi
  ☐ Modul sekolah
  ☐ Internet stabil
  ☐ Video pembelajaran
  ☐ Laboratorium
  ☐ Teaching Factory
  ☐ DUDI aktif
    → Input spesifik: nama DUDI
  ☐ Narasumber industri
    → Input spesifik: nama/bidang narasumber

OUTPUT NYATA YANG DIHARAPKAN (tap satu pilihan)
  ○ Laporan tertulis
  ○ Presentasi
  ○ Produk fisik
  ○ Website / Aplikasi
  ○ Video
  ○ Konfigurasi jaringan / sistem
  ○ Prototype
  ○ Poster
  ○ Simulasi
  ○ Lainnya → Input spesifik

KEBIASAAN SEKOLAH (tap multi-pilihan, opsional)
  ☐ Literasi 15 menit
  ☐ P5 setiap Jumat
  ☐ Teaching Factory
  ☐ Block schedule
  ☐ Apel Senin
  ☐ Ibadah rutin
  ☐ Lainnya → Input spesifik

MEDIA & ALAT TERSEDIA (tap multi-pilihan)
  ☐ Proyektor / TV
  ☐ Speaker
  ☐ Laptop/komputer siswa
  ☐ Tablet
  ☐ Kartu / flashcard
  ☐ Akses internet stabil
  ☐ Papan tulis
  ☐ Lainnya → Input spesifik
```

### 4.4 Schema — public.teacher_profiles

```sql
CREATE TABLE public.teacher_profiles (
  profile_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id           UUID NOT NULL REFERENCES public.schools(id),
  teacher_user_id     UUID NOT NULL REFERENCES auth.users(id),

  -- Layer 2: Teacher Profile (stabil)
  instructional_intent  VARCHAR(50),        -- 'PKL', 'SERTIFIKASI', dst
  intent_detail         TEXT,               -- input spesifik jika ada
  assessment_philosophy VARCHAR(50),        -- 'PRAKTIK', 'PORTOFOLIO', dst
  teaching_style        VARCHAR(30),        -- 'GURU_DOMINAN', 'SISWA_DOMINAN', dst
  learning_model        VARCHAR(50),        -- 'PBL', 'PROBLEM_BASED', dst
  delivery_style        VARCHAR(50),        -- 'PRAKTIK', 'DISKUSI', dst
  schedule_pattern      VARCHAR(50),        -- 'BLOCK', 'TERPISAH', dst
  project_duration      VARCHAR(30),        -- '1_MINGGU', '2_4_MINGGU', dst
  depth_level           VARCHAR(20),        -- 'DASAR', 'MENENGAH', 'MAHIR'

  -- Layer 3: Konteks lokal (stabil)
  local_city            TEXT,
  local_industry        TEXT,
  local_dudi_partners   TEXT,
  local_products        TEXT,

  -- Preferensi negatif (apa yang dihindari)
  avoided_activities    TEXT[],             -- ['ROLE_PLAY', 'DEBAT', dst]
  avoided_detail        TEXT,

  -- Preferensi integrasi
  integration_prefs     TEXT[],             -- ['NUMERASI', 'LITERASI', dst]

  last_refreshed_at     TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),

  UNIQUE (school_id, teacher_user_id)
);
```

### 4.5 Schema — public.teaching_contexts

```sql
CREATE TABLE public.teaching_contexts (
  context_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id           UUID NOT NULL REFERENCES public.schools(id),
  teacher_user_id     UUID NOT NULL REFERENCES auth.users(id),
  academic_year       VARCHAR(10) NOT NULL,   -- '2026/2027'

  -- Bisa per kelas atau per mapel+kelas
  subject_id          UUID REFERENCES public.subjects(id),
  class_id            UUID REFERENCES public.classes(id),

  -- Konteks siswa
  student_background  VARCHAR(50),            -- 'PETANI', 'PEDAGANG', dst
  tech_access         VARCHAR(50),            -- 'SMARTPHONE', 'LAPTOP', dst
  daily_language      TEXT,

  -- Karakteristik kelas (multi)
  class_characteristics TEXT[],              -- ['PASIF', 'AKTIF_BERTANYA', dst]
  student_autonomy    VARCHAR(30),            -- 'MANDIRI', 'ARAHAN', 'BERGANTUNG'

  -- Batasan dan ketersediaan
  learning_constraints TEXT[],               -- ['INTERNET_MATI', 'LAB_BERGANTIAN']
  constraints_detail   TEXT,
  resources_available  TEXT[],               -- ['BUKU_PAKET', 'LAB', 'DUDI_AKTIF']
  dudi_name            TEXT,                 -- nama DUDI jika DUDI_AKTIF dipilih
  narasumber_detail    TEXT,

  -- Output dan kebiasaan
  expected_output      VARCHAR(50),          -- 'LAPORAN', 'KONFIGURASI', dst
  output_detail        TEXT,
  school_habits        TEXT[],               -- ['LITERASI_15', 'TEACHING_FACTORY']
  habits_detail        TEXT,

  -- Media
  media_available      TEXT[],              -- ['PROYEKTOR', 'LAPTOP_SISWA', dst]
  media_detail         TEXT,

  last_refreshed_at    TIMESTAMPTZ,
  created_at           TIMESTAMPTZ DEFAULT now(),
  updated_at           TIMESTAMPTZ DEFAULT now(),

  UNIQUE (school_id, teacher_user_id, academic_year, subject_id, class_id)
);
```

---

## 5. Bagaimana Context Builder Menggunakan Knowledge Repository

```
GENERATE REQUEST dari guru
          │
          ▼
┌─────────────────────────────────────────────────────┐
│                  CONTEXT BUILDER                    │
│                                                     │
│  Layer 1 (sistem):                                  │
│    core.capaian_pembelajaran  ← CP per mapel/fase   │
│    core.cp_elements           ← elemen CP           │
│    jadwal sekolah             ← JP, minggu efektif  │
│                                                     │
│  Layer 2 (Knowledge Nasional — tidak terlihat guru):│
│    core.knowledge_national    ← per program keahlian│
│    → software, sertifikasi, istilah teknis,         │
│      contoh proyek, DUDI umum, standar BNSP         │
│                                                     │
│  Layer 3 (Teacher Knowledge — dari tap guru):       │
│    public.teacher_profiles    ← Teacher Profile     │
│    public.teaching_contexts   ← Teaching Context    │
│    → tujuan, style, konteks lokal, batasan kelas    │
└──────────────────────────┬──────────────────────────┘
                           │
                           ▼
                   Prompt Builder
                   (rakit semua menjadi
                    satu prompt spesifik)
                           │
                           ▼
                   Model Adapter
                   (Gemini / Claude)
                           │
                           ▼
                   Generated PPM
```

**Prinsip perakitan:**
- Layer 1 selalu ada — tanpa ini AI tidak bisa bekerja
- Layer 2 memperkaya konteks industri tanpa guru perlu tahu
- Layer 3 mempersonalisasi output sesuai kondisi kelas nyata
- Jika Layer 3 kosong → AI pakai nilai default dari Layer 2

---

## 6. RLS Teacher Knowledge

```sql
-- Teacher Profiles: hanya guru sendiri yang baca/tulis
ALTER TABLE public.teacher_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY tp_select ON public.teacher_profiles
  FOR SELECT TO authenticated
  USING (
    school_id = get_school_id()
    AND teacher_user_id = auth.uid()
  );

CREATE POLICY tp_insert ON public.teacher_profiles
  FOR INSERT TO authenticated
  WITH CHECK (
    school_id = get_school_id()
    AND teacher_user_id = auth.uid()
  );

CREATE POLICY tp_update ON public.teacher_profiles
  FOR UPDATE TO authenticated
  USING (
    school_id = get_school_id()
    AND teacher_user_id = auth.uid()
  );

-- Teaching Contexts: sama — hanya guru sendiri
-- (policy identik, tidak diulang)
```

---

## 7. Mekanisme Refresh

Guru bisa me-refresh Teacher Profile atau Teaching Context kapan saja
tanpa kehilangan dokumen PPM yang sudah dibuat.

```
Guru tap [Ubah Profil Mengajar]
          ↓
Layar setup muncul dengan nilai terakhir yang tersimpan
          ↓
Guru ubah pilihan yang ingin diubah
          ↓
Tap [Simpan]
          ↓
teacher_profiles.last_refreshed_at = now()
          ↓
Generate berikutnya menggunakan profil yang baru
          ↓
PPM lama tidak berubah (merujuk snapshot konteks saat generate)
```

**PPM menyimpan snapshot konteks saat generate** — bukan referensi ke
profil yang bisa berubah. Ini memastikan audit trail tetap akurat:
"PPM ini dibuat dengan preferensi X, bukan Y."

---

## 8. Yang Tidak Diputuskan di ADR Ini

| Topik | Catatan |
|-------|---------|
| Schema Teacher Workspace (ATP, PPM, dst) | ADR-004 |
| Bagaimana snapshot konteks disimpan di PPM | ADR-004 |
| Implementasi Context Builder + Prompt Builder | ADR-005 |
| Konten lengkap Knowledge Nasional per 50 program | Dikerjakan saat seed sprint |

---

## 9. Checklist Persetujuan

- [ ] Knowledge Sekolah (admin) dihapus — konteks lokal masuk Teacher Knowledge
- [ ] Knowledge Nasional: disediakan SIP, tidak terlihat guru, hanya AI yang baca
- [ ] Teacher Knowledge = Teacher Profile (stabil) + Teaching Context (per kelas/tahun)
- [ ] Mekanisme UI: tap pilihan → input spesifik jika dipilih → disimpan permanen
- [ ] Guru bisa refresh kapan saja tanpa merusak PPM yang sudah ada
- [ ] PPM menyimpan snapshot konteks saat generate — bukan referensi ke profil aktif
- [ ] Schema: core.knowledge_national + public.teacher_profiles + public.teaching_contexts
- [ ] RLS: teacher_profiles dan teaching_contexts hanya bisa dibaca/ditulis guru pemilik
- [ ] Context Builder: Layer 1 (sistem) + Layer 2 (Knowledge Nasional) + Layer 3 (Teacher Knowledge)
- [ ] Jika Layer 3 kosong: AI gunakan nilai default dari Layer 2
