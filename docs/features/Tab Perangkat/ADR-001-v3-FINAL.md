# ADR-001 — Domain Ownership & Architecture
# Student Insight Platform (SIP)
# Status: DRAFT v10 — OPEN untuk penyempurnaan
# Tanggal: 18 Juli 2026
# Berlaku untuk: Seluruh fitur AI Learning
# Horizon implementasi: 6–12 bulan

---

## 1. Prinsip Arsitektur

Empat prinsip ini menjadi kompas ketika muncul keputusan baru yang tidak tercakup ADR ini.

> **Prinsip 1 — Single Source of Truth**
>
> Setiap jenis informasi hanya memiliki satu sumber kebenaran di dalam arsitektur SIP.
> Tidak boleh ada duplikasi kepemilikan antar domain.

> **Prinsip 2 — Generated, Never Copied**
>
> AI menghasilkan artefak berdasarkan repository dan referensi.
> Repository tidak pernah berisi hasil generate guru.
> Guru tidak pernah meng-copy CP ke dokumen pribadi —
> AI membacanya langsung dari SIP Core.

> **Prinsip 3 — Stable Core, Evolving Workspace**
>
> SIP Core berubah sangat jarang (mengikuti siklus regulasi pemerintah).
> Teacher Workspace berubah setiap hari.
> Keduanya tidak boleh saling memblokir.

> **Prinsip 4 — Dependency Flows Downward**
>
> SIP Core → School Tenant → Teacher Workspace.
> Domain di bawah boleh bergantung pada domain di atas.
> Domain di atas tidak pernah bergantung pada domain di bawah.
> CP tidak pernah bergantung pada ATP guru.
> Melanggar prinsip ini akan membalik seluruh arsitektur.

---

## 2. Konteks

SIP membangun fondasi untuk fitur AI Learning Document dalam horizon 6–12 bulan.

**Scope ADR ini dikunci untuk SMK (Sekolah Menengah Kejuruan).**
Penyesuaian untuk SD, SMP, dan SMA akan didefinisikan dalam ADR terpisah
pada fase berikutnya. Seluruh keputusan domain, ownership, struktur modul,
dan Context Builder di dokumen ini dirancang berdasarkan karakteristik SMK:
program keahlian, teaching assignment per prodi, fase E dan F, DUDI,
PKL, sertifikasi, dan Teaching Factory.

Target hasil akhir yang harus dicapai:

```
Guru login → membuka tab "Perangkat Ajar" → memilih mapel →
mengisi konteks + media yang tersedia → klik Generate →
AI menghasilkan dokumen lengkap siap cetak →
guru review, edit, simpan → export Word/PDF →
cetak → tanda tangan kepala sekolah → selesai.
```

Tanpa keputusan domain yang jelas, setiap sprint akan membuat asumsi berbeda
tentang siapa pemilik data, di tabel mana data disimpan, dan bagaimana AI
mengakses konteks mengajar. ADR ini menetapkan domain, ownership, source of
truth, dan prinsip arsitektur secara permanen.

---

## 3. Tiga Domain Data SIP

```
┌─────────────────────────────────────────────────────────────┐
│                         SIP CORE                            │
│                                                             │
│  ┌──────────────────┐  ┌────────────────┐  ┌────────────┐  │
│  │   Curriculum     │  │   Knowledge    │  │ Generation │  │
│  │   Repository     │  │   Repository   │  │ Repository │  │
│  └──────────────────┘  └────────────────┘  └────────────┘  │
│                                                             │
│  → Tidak ada school_id                                      │
│  → Read-only untuk semua tenant                             │
│  → Dikelola SIP team (SIP Curated Repository)              │
└────────────────────────────┬────────────────────────────────┘
                             │ dibaca oleh
┌────────────────────────────▼────────────────────────────────┐
│                      SCHOOL TENANT                          │
│                                                             │
│  Siswa, guru, kelas, jadwal, program,                       │
│  teaching assignment, knowledge sekolah                     │
│                                                             │
│  → Selalu ada school_id                                     │
│  → Dikelola sekolah (admin + staf)                          │
└────────────────────────────┬────────────────────────────────┘
                             │ dikerjakan oleh
┌────────────────────────────▼────────────────────────────────┐
│                    TEACHER WORKSPACE                        │
│                                                             │
│  Seluruh artefak, preferensi, dan aset pribadi guru         │
│  yang tidak menjadi bagian dari School Tenant               │
│  maupun SIP Core.                                           │
│                                                             │
│  Contoh: ATP, Modul, LKPD, Soal, Rubrik,                   │
│  Teacher Knowledge, AI history, draft,                      │
│  template pribadi, bookmark, Program Tahunan,               │
│  Program Semester.                                          │
│                                                             │
│  → Selalu ada school_id + created_by                        │
│  → Dimiliki guru (user), bukan sekolah                      │
└─────────────────────────────────────────────────────────────┘
```

### SIP Core — tiga sub-repository

| Sub-repository | Isi | Laju perubahan |
|----------------|-----|----------------|
| Curriculum Repository | CP, elemen, fase, mata pelajaran, regulasi | Sangat jarang — mengikuti Permendikdasmen |
| Knowledge Repository | Konteks dunia kerja per bidang keahlian (nasional) | Jarang — tahunan |
| Generation Repository | Prompt template, model config, generation policy, routing rules | Sedang — per sprint fitur |

Knowledge Repository di level sekolah dan guru termasuk School Tenant dan
Teacher Workspace, bukan SIP Core.

---

## 4. Ownership, Steward, Human Consumer, System Consumer

| Entitas | Domain | Owner | Steward | Human Consumer | System Consumer |
|---------|--------|-------|---------|----------------|-----------------|
| Kurikulum (struktur, versi, regulasi) | SIP Core | SIP | SIP Team | — | AI Engine |
| Mata Pelajaran (master nasional) | SIP Core | SIP | SIP Team | Semua tenant (read) | AI Engine |
| Fase (E, F, dst) | SIP Core | SIP | SIP Team | Semua tenant (read) | AI Engine |
| Capaian Pembelajaran (CP) | SIP Core | SIP | SIP Team | Semua guru (read) | AI Engine |
| Elemen CP | SIP Core | SIP | SIP Team | Semua guru (read) | AI Engine |
| Knowledge Nasional | SIP Core | SIP | SIP Team | — | AI Engine |
| Prompt Template, Model Config | SIP Core | SIP | SIP Team | — | AI Engine |
| Data siswa, guru, kelas, jadwal | School Tenant | Sekolah | Admin sekolah | Staf sekolah | AI Engine (context) |
| Teaching Assignment | School Tenant | Sekolah | Admin sekolah | Guru terkait | AI Engine (context) |
| Knowledge Sekolah | School Tenant | Sekolah | Admin + staf tertentu | Guru di sekolah | AI Engine (context) |
| Teacher Profile (preferensi stabil lintas tahun) | Teacher Workspace | Guru | Guru pemilik | — | AI Engine (context) |
| Teaching Context (kondisi per kelas/tahun ajaran) | Teacher Workspace | Guru | Guru pemilik | — | AI Engine (context) |
| Program Tahunan | Teacher Workspace | Guru | Guru pemilik | Guru, Kepsek (read) | AI Engine |
| Program Semester | Teacher Workspace | Guru | Guru pemilik | Guru, Kepsek (read) | AI Engine |
| ATP | Teacher Workspace | Guru | Guru pemilik | Guru, Kepsek (read) | AI Engine |
| Perencanaan Pembelajaran Mendalam (PPM) | Teacher Workspace | Guru | Guru pemilik | Guru, Kepsek (read) | AI Engine |
| LKPD | Teacher Workspace | Guru | Guru pemilik | Guru, Kepsek (read) | — |
| Soal | Teacher Workspace | Guru | Guru pemilik | Guru pemilik saja | AI Engine (administrasi) |
| Rubrik | Teacher Workspace | Guru | Guru pemilik | Guru pemilik saja | AI Engine (administrasi) |

**Catatan penting:**
- Sekolah tidak memiliki ATP, Modul, atau dokumen guru lainnya.
- Sekolah hanya boleh membaca dokumen guru sesuai hak akses.
- SIP Team adalah satu-satunya yang bisa mengubah data SIP Core.
- Knowledge Nasional dan Prompt Template tidak pernah ditampilkan langsung ke guru —
  hanya dikonsumsi AI Engine.

---

## 5. Source of Truth

| Entitas | Source of Truth | Authority |
|---------|----------------|-----------|
| Kurikulum (struktur, regulasi) | Regulasi resmi | Kemendikdasmen |
| Capaian Pembelajaran (CP) | Regulasi resmi (BSKAP) | Kemendikdasmen |
| Mata Pelajaran | Regulasi resmi | Kemendikdasmen |
| Fase | Regulasi resmi | Kemendikdasmen |
| Knowledge Nasional | SIP Research | SIP |
| Knowledge Sekolah | Data sekolah | Sekolah |
| Teacher Profile (preferensi stabil) | Guru | Guru |
| Teaching Context (kondisi per kelas/tahun) | Guru | Guru |
| Program Tahunan, Program Semester | Guru | Guru |
| ATP, Modul, LKPD, Soal, Rubrik | Guru | Guru |

SIP berperan sebagai **kurator** untuk data nasional — mengambil dari regulasi
resmi, memvalidasi, menormalisasi, lalu mempublikasikan sebagai SIP Core.
SIP tidak menggantikan pemerintah sebagai source of truth; SIP menjadi
**representasi terstruktur** dari regulasi tersebut di dalam platform.

---

## 6. SIP Asset vs Generated Artifact

**SIP Asset** — apa yang dimiliki dan dioperasikan platform:

| Asset | Deskripsi |
|-------|-----------|
| Curriculum Repository | CP, elemen, fase, mata pelajaran nasional |
| Knowledge Repository | Konteks dunia kerja (nasional + sekolah + guru) |
| Generation Repository | Prompt template, model config, generation policy |
| AI Generation Engine | Orkestrasi konteks → Context Builder → Claude API → Artifact |

**Generated Artifact** — output yang dihasilkan, disimpan di Teacher Workspace:

```
Program Tahunan
    ↓
Program Semester
    ↓
ATP
    ↓
Perencanaan Pembelajaran Mendalam (PPM) (1 per TP)
    ├── LKPD
    ├── Soal
    └── Rubrik
```

Relasi antar dokumen berbentuk **hierarki atau directed graph**, bukan rantai
linear. Detail relasi (apakah Modul wajib punya parent ATP, apakah Soal bisa
berdiri sendiri, dst) akan didefinisikan di ADR-004.

Setiap Generated Artifact menyimpan referensi `curriculum_version` agar tidak
rusak saat kurikulum berganti.

### Auditability — Metadata Setiap Artefak

Setiap Generated Artifact menyimpan metadata berikut untuk kebutuhan audit
dan reproduksibilitas. Metadata ini tidak ditampilkan ke guru — hanya
digunakan sistem untuk menjawab pertanyaan seperti "mengapa ATP ini berbeda
dengan ATP yang dibuat dua tahun lalu?"

```
curriculum_version       → versi CP yang digunakan saat generate
knowledge_version        → versi Knowledge Repository yang digunakan
generation_policy_version→ versi prompt template dan generation policy
model_version            → versi model AI (claude-sonnet-4-6, dst)
generated_at             → timestamp generate
```

Detail implementasi metadata ini akan didefinisikan di ADR-005.

---

## 7. Context Builder

Sebelum memanggil Claude API, SIP merakit konteks melalui komponen
**Context Builder**. Ini adalah komponen paling kritis yang menentukan
kualitas seluruh output AI.

```
Curriculum Repository        ─┐
Knowledge Repository         ─┤
School Tenant Context        ─┼→ Context Builder → Prompt Builder → Claude API → Artifact
Teacher Workspace            ─┤
Input Spesifikasi Guru       ─┘
```

### Input Spesifikasi Guru (sebelum Generate)

Guru dapat langsung menekan Generate tanpa mengisi spesifikasi tambahan.
Sistem menggunakan nilai default dari repository dan data sekolah.
Spesifikasi tambahan hanya digunakan untuk meningkatkan relevansi hasil AI.

Ini adalah keunggulan utama SIP untuk go nasional: guru di Payakumbuh
mendapat modul dengan konteks penjahit lokal Payakumbuh, bukan industri
fashion Jakarta yang tidak pernah mereka temui.

**Definisi Layer Context Builder (berlaku di seluruh ADR):**

```
Layer 1 — System Context (wajib, otomatis dari sistem)
  CP, Teaching Assignment, Fase, Program, JP, Minggu Efektif

Layer 2 — Knowledge Repository (Knowledge Nasional dari SIP Core)
  Tidak terlihat guru — hanya AI yang membaca
  Software, sertifikasi, istilah teknis, contoh proyek, standar BNSP

Layer 3 — Teacher Context (dari tap guru)
  Teacher Profile  → stabil lintas tahun (preferensi mengajar, konteks lokal)
  Teaching Context → per kelas/tahun ajaran (kondisi kelas, batasan, media)
```

Istilah "Teacher Knowledge" tidak digunakan — diganti dengan
"Teacher Profile" dan "Teaching Context" secara konsisten di seluruh ADR.

---

**LAYER 1 — Wajib (dari sistem, guru tidak perlu mengisi)**
```
CP                    → dari Curriculum Repository
Teaching Assignment   → dari School Tenant
Fase                  → dari School Tenant
Program               → dari School Tenant
Minggu efektif        → dari jadwal sekolah
JP per minggu         → dari jadwal sekolah
```
Tanpa Layer 1, AI tidak bisa bekerja. Semua diambil otomatis.

---

**LAYER 2 — Sangat berpengaruh (mengubah output AI secara drastis)**

Disimpan sebagai **Teacher Profile** — diisi sekali di halaman Setup Profil Mengajar.
Saat Generate, guru hanya melihat ringkasan dan tombol konfirmasi — tidak mengisi ulang.

```
INSTRUCTIONAL INTENT (tujuan praktis pembelajaran)
  ○ Persiapan PKL
  ○ Persiapan Dunia Kerja
  ○ Persiapan Sertifikasi
  ○ Persiapan LKS
  ○ Penguatan Konsep Dasar
  ○ Projek Kewirausahaan
  ○ UMKM Lokal
  ○ Lainnya...
  → Mengubah: contoh, studi kasus, proyek, dan asesmen (B1, B4, B5)

ASSESSMENT PHILOSOPHY (asesmen dominan)
  ○ Praktik
  ○ Portofolio
  ○ Presentasi
  ○ Observasi
  ○ Tes Tertulis
  ○ Kombinasi
  → Mengubah: seluruh struktur aktivitas belajar dan rubrik (B4, B5)

TEACHING STYLE
  ○ Guru dominan   (guru memandu setiap langkah, siswa mengikuti)
  ○ Siswa dominan  (guru fasilitator, siswa mencari solusi sendiri)
  ○ Seimbang
  → Mengubah: peran guru dan siswa di setiap tahap kegiatan (B4)

MODEL PEMBELAJARAN
  ○ Project-Based Learning
  ○ Problem-Based Learning
  ○ Discovery Learning
  ○ Ceramah + Latihan
  → Mengubah: kerangka kegiatan pembelajaran (B4, B6)

GAYA PENYAMPAIAN
  ○ Banyak praktik
  ○ Banyak diskusi
  ○ Banyak demonstrasi
  → Mengubah: jenis aktivitas dominan di B4

JADWAL PEMBELAJARAN
  ○ 2 JP × beberapa hari terpisah
  ○ 6 JP sekaligus (block)
  ○ Teori dulu lalu praktik
  ○ Praktik penuh
  → Mengubah: struktur sesi dan kegiatan yang bisa dipotong/dilanjutkan (B4)

DURASI PROYEK
  ○ 1 minggu
  ○ 2–4 minggu
  ○ Satu semester
  → Mengubah: kompleksitas dan tahapan proyek (B4)

TINGKAT KEDALAMAN
  ○ Dasar
  ○ Menengah
  ○ Mahir
  → Mengubah: kompleksitas materi dan indikator pencapaian (B1, B2, B4)
```

---

**LAYER 3 — Penyempurna (modul tetap baik tanpa ini, tapi lebih relevan jika diisi)**

*Disimpan sebagai Teacher Profile (stabil):*
```
KONTEKS LOKAL
  Kota/daerah          : [teks bebas — contoh: Payakumbuh, Sumatera Barat]
  Industri lokal       : [teks bebas — contoh: penjahit, konveksi, sulaman]
  Nama DUDI mitra      : [teks bebas — contoh: Konveksi Bu Yanti]
  Produk/jasa lokal    : [teks bebas — contoh: sulaman Payakumbuh, tenun Pandai Sikek]
  → Mengubah: contoh, studi kasus, dan konteks proyek (B2, B3, B4)

YANG DIHINDARI GURU
  ☐ Role play
  ☐ Debat
  ☐ Presentasi individu
  ☐ Tugas rumah
  ☐ Praktik outdoor
  ☐ Lainnya...
  → Mengubah: AI tidak mengusulkan aktivitas yang dicentang (B4)

INTEGRATION PREFERENCE
  ☐ Numerasi
  ☐ Literasi
  ☐ AI / Teknologi
  ☐ Kewirausahaan
  ☐ Budaya lokal
  ☐ Profil Lulusan 8 Dimensi
  → Mengubah: aktivitas lintas kompetensi dan dimensi profil lulusan (A3, B4)
```

*Disimpan sebagai Teaching Context (per kelas/tahun ajaran):*
```
KONTEKS SISWA
  Latar belakang       : [pilihan — anak petani / pedagang / pengrajin / campuran]
  Akses teknologi      : [pilihan — smartphone saja / laptop tersedia / tidak ada internet]
  Bahasa sehari-hari   : [teks bebas — contoh: Minang + Indonesia]
  → Mengubah: contoh nyata dan pendekatan komunikasi (A2, B2, B4)

KARAKTERISTIK KELAS
  ☐ Pasif
  ☐ Aktif bertanya
  ☐ Sulit bekerja kelompok
  ☐ Disiplin tinggi
  ☐ Cepat bosan
  ☐ Sangat heterogen
  → Mengubah: strategi pembukaan, pengelolaan kelas, diferensiasi (B4, B6)

TINGKAT OTONOMI SISWA
  ○ Sangat mandiri     (siswa bisa bekerja tanpa arahan terus-menerus)
  ○ Perlu arahan       (siswa butuh panduan di setiap tahap)
  ○ Sangat bergantung  (siswa perlu scaffolding penuh)
  → Mengubah: instruksi kegiatan dan strategi diferensiasi (B4, B6)

LEARNING CONSTRAINTS (batasan nyata di kelas)
  ☐ Internet sering mati
  ☐ Lab dipakai bergantian
  ☐ HP tidak boleh dibawa
  ☐ Praktik hanya seminggu sekali
  ☐ Waktu praktik maksimal 2 JP
  ☐ Lainnya...
  → Mengubah: AI tidak merancang aktivitas yang mustahil dilaksanakan (B4)

RESOURCE AVAILABILITY (sumber belajar yang tersedia)
  ☐ Buku paket resmi
  ☐ Modul sekolah
  ☐ Internet stabil
  ☐ Video pembelajaran
  ☐ Laboratorium
  ☐ Teaching Factory
  ☐ DUDI aktif
  ☐ Narasumber industri
  → Mengubah: sumber referensi dan jenis aktivitas yang diusulkan (A4, B4)

OUTPUT NYATA YANG DIHARAPKAN (produk akhir modul)
  ○ Laporan tertulis
  ○ Presentasi
  ○ Produk fisik
  ○ Website / Aplikasi
  ○ Video
  ○ Konfigurasi jaringan / sistem
  ○ Prototype
  ○ Poster
  ○ Simulasi
  → Mengubah: seluruh struktur proyek dan tahapan kegiatan (B4, B5)

KEBIASAAN SEKOLAH
  ☐ Literasi 15 menit
  ☐ P5 setiap Jumat
  ☐ Teaching Factory
  ☐ Block schedule
  ☐ Apel Senin
  ☐ Sholat Dhuha / ibadah rutin
  ☐ Lainnya...
  → Mengubah: jadwal dan alokasi waktu yang realistis (B4)

MEDIA & ALAT TERSEDIA
  ☐ Proyektor / TV
  ☐ Speaker
  ☐ Laptop/komputer siswa
  ☐ Tablet
  ☐ Kartu / flashcard
  ☐ Akses internet stabil
  ☐ Papan tulis
  ☐ Lainnya...
  → Mengubah: AI tidak merekomendasikan aktivitas yang membutuhkan
    alat yang tidak dicentang guru (A4, B4)
```

---

**Pola UX — Teacher Profile Setup**

Teacher Profile (Layer 2 + Layer 3 stabil) diisi **sekali** di halaman
"Setup Profil Mengajar" yang terpisah dari alur Generate.

Saat guru hendak Generate, layar konfirmasi hanya menampilkan:

```
Profil Mengajar Anda:
  ✓ Instructional Intent : Persiapan PKL
  ✓ Assessment           : Portofolio
  ✓ Teaching Style       : Siswa dominan
  ✓ Model                : Project-Based Learning
  ✓ Konteks lokal        : Payakumbuh — penjahit, sulaman

  [Ubah Profil]   [✨ Generate]
```

Teaching Context (Layer 3 per kelas) ditampilkan di bawahnya dan bisa
diperbarui per kelas tanpa mengubah Teacher Profile.

Teacher Profile disimpan permanen dan dipakai ulang untuk semua generate
berikutnya. Teaching Context disimpan per kelas per tahun ajaran.
Keduanya dapat diubah kapan saja oleh guru pemilik.

Detail implementasi Context Builder akan didefinisikan di ADR-005.

---

## 8. Schema Separation

| Domain | PostgreSQL Schema | RLS Pattern |
|--------|------------------|-------------|
| SIP Core | `core` | SELECT untuk semua authenticated; tidak ada INSERT/UPDATE/DELETE untuk tenant |
| School Tenant | `public` (existing) | school_id = get_school_id() |
| Teacher Workspace | `public` (existing) | school_id = get_school_id() + created_by = auth.uid() |

Schema `core` terpisah dari `public`. Developer langsung tahu bahwa tabel
di schema `core` bukan data tenant dan tidak boleh dimodifikasi tenant.

---

## 9. Hasil Akhir yang Harus Dicapai

Ini adalah kontrak hasil akhir yang mengikat seluruh implementasi.

### Skenario A — Guru Mapel Produktif

Guru Teknologi Layanan Jaringan, Fase E, 1 program (TJK):

```
Output:
  ① Program Tahunan TJK          → 1 file Word, siap cetak
  ② Program Semester TJK Sem 1   → 1 file Word, siap cetak
  ③ Program Semester TJK Sem 2   → 1 file Word, siap cetak
  ④ Perencanaan Pembelajaran Mendalam (PPM) per TP            → N file Word, siap cetak
     (N = jumlah TP yang dihasilkan AI dari ATP)
```

### Skenario B — Guru Mapel Adaptif/Normatif

Guru Bahasa Inggris, Fase E, Kelas X, 4 prodi (AKL, BP, BDP, DPB):

```
Pilihan scope:
  ○ Semua prodi   → 1 set dokumen, tanpa konteks industri
  ○ Per prodi     → 4 set dokumen, masing-masing dengan konteks industri berbeda
  ○ Pilih tertentu → subset yang dipilih guru

Output per prodi (contoh AKL):
  ① Program Tahunan AKL          → 1 file Word
  ② Program Semester AKL Sem 1   → 1 file Word
  ③ Program Semester AKL Sem 2   → 1 file Word
  ④ Perencanaan Pembelajaran Mendalam (PPM) per TP            → N file Word
```

Untuk Bahasa Inggris dengan 4 prodi dan 18 TP per prodi:
**72 modul ajar** dihasilkan AI, bukan ditulis manual.

### Struktur Perencanaan Pembelajaran Mendalam (PPM) yang Dihasilkan

Istilah resmi Kemendikdasmen per Permendikdasmen No. 13 Tahun 2025.
Menggantikan istilah RPP dan Modul Ajar. Digunakan di seluruh UI SIP.

```
A. INFORMASI UMUM
   A1 — Identitas PPM            ← AI menyusun draft lengkap, guru meninjau
   A2 — Kompetensi Awal Siswa    ← AI menyusun draft lengkap, guru meninjau
   A3 — Profil Lulusan           ← AI menyusun draft lengkap, guru meninjau
        8 Dimensi: Keimanan & Ketakwaan, Kewargaan, Penalaran Kritis,
        Kreativitas, Kolaborasi, Kemandirian, Kesehatan, Komunikasi
        Dasar: Permendikdasmen No. 10 Tahun 2025
        Terintegrasi di aktivitas B4 — bukan projek terpisah
   A4 — Sarana & Prasarana       ← AI menyusun draft (berbasis media & alat tersedia), guru meninjau
   A5 — Target Peserta Didik     ← AI menyusun draft lengkap, guru meninjau
   A6 — Model Pembelajaran       ← AI menyusun draft lengkap, guru meninjau

B. KOMPONEN INTI
   B1 — TP + Indikator           ← AI menyusun draft lengkap, guru meninjau
   B2 — Pemahaman Bermakna       ← AI menyusun draft lengkap, guru meninjau
   B3 — Pertanyaan Pemantik      ← AI menyusun draft lengkap, guru meninjau
   B4 — Kegiatan Pembelajaran    ← AI menyusun kerangka, guru melengkapi detail
        Pendekatan Deep Learning wajib tercermin:
        minimal satu dari: berkesadaran (mindful) /
        bermakna (meaningful) / menggembirakan (joyful)
        Integrasi 8 Dimensi Profil Lulusan di sini — bukan projek terpisah
   B5 — Asesmen & Rubrik         ← AI menyusun draft lengkap, guru meninjau
   B6 — Pengayaan & Remedial     ← AI menyusun draft lengkap, guru meninjau

C. LAMPIRAN
   C1 — LKPD                     ← guru menyusun manual
   C2 — Glosarium & Pengucapan   ← AI menyusun draft lengkap, guru meninjau
   C3 — Bahan Bacaan Guru        ← AI menyusun draft lengkap, guru meninjau
   C4 — Refleksi Guru            ← guru mengisi manual setelah mengajar
   C5 — Daftar Pustaka           ← AI menyusun draft lengkap, guru meninjau
   C6 — Tanda Tangan             ← guru mengisi manual, tanda tangan fisik
```

---

## 10. Fitur Tab "Perangkat Ajar" — Keputusan yang Dikunci

| Keputusan | Nilai |
|-----------|-------|
| Nama tab | Perangkat Ajar |
| Tab lama ATP (tab-kurikulum) | Dihapus, diganti tab baru |
| Titik masuk | Dashboard pekerjaan per mapel |
| Deteksi konteks | Otomatis dari teaching assignment |
| Scope mapel produktif | Program otomatis, tidak perlu pilih |
| Scope mapel adaptif/normatif | Pilihan: Semua / Per Prodi / Pilih Tertentu |
| Batch generate | Tersedia untuk mapel adaptif/normatif |
| Progress | Progress bar persentase per mapel |
| Status dokumen | AI Draft → Direview Guru → Disahkan Kepsek |
| Status perlu ditinjau | Muncul jika CP atau minggu efektif berubah |
| Reuse & Smart Update | Tersedia di awal tahun ajaran baru |
| Input Spesifikasi Guru | 5 kategori: Konteks Lokal, Konteks Siswa, Preferensi Mengajar, Kondisi Kelas, Media & Alat |
| Konteks Lokal | Kota, industri lokal, nama DUDI mitra, produk/jasa lokal — membuat modul relevan secara geografis |
| Konteks Siswa | Latar belakang, akses teknologi, bahasa sehari-hari |
| Preferensi Mengajar | Model pembelajaran, gaya penyampaian, durasi proyek, tingkat kedalaman |
| Kondisi Kelas | Jumlah siswa, kemampuan awal, tantangan khusus |
| Media & Alat Tersedia | Checklist — AI tidak rekomendasikan aktivitas dengan alat yang tidak tersedia |
| Input disimpan sebagai | Teacher Profile — bisa dipakai ulang, tidak perlu isi ulang setiap kali generate |
| Rekomendasi langkah berikutnya | Muncul setelah dokumen disimpan |
| AI Summary | Ditampilkan di review sebelum simpan |
| Referensi AI | Ditampilkan di review (Kurikulum + Knowledge + Preferensi) |
| Export | Word (.docx) + PDF |
| Tanda tangan | Cetak fisik, tanda tangan manual |
| Dokumen dimiliki | Guru, bukan sekolah |

---

## 11. Implementasi Lama yang Deprecated

Implementasi sebelumnya yang memperlakukan CP sebagai tenant-owned
dinyatakan **deprecated** dan akan digantikan oleh implementasi berbasis
SIP Core. Detail migrasi teknis terdokumentasi di dokumen implementasi
terpisah, bukan di ADR ini.

---

## 12. Yang Tidak Diputuskan di ADR Ini

| Topik | ADR |
|-------|-----|
| Schema lengkap Curriculum Repository (core.capaian_pembelajaran, dst) | ADR-002 |
| Schema Knowledge Repository (Nasional + Sekolah + Guru) + Hybrid Knowledge | ADR-003 |
| Schema Teacher Workspace (Program Tahunan, Program Semester, ATP, Modul, dst) + Document Graph | ADR-004 |
| AI Generation Pipeline + Context Builder implementasi | ADR-005 |

---

## 13. Checklist Persetujuan Final

- [ ] Empat prinsip arsitektur
- [ ] Tiga domain: SIP Core / School Tenant / Teacher Workspace
- [ ] Teacher Workspace didefinisikan sebagai seluruh artefak dan aset pribadi guru
- [ ] SIP Core terdiri dari tiga sub-repository (Curriculum, Knowledge, Generation)
- [ ] Tabel ownership dengan kolom Owner + Steward + Human Consumer + System Consumer
- [ ] Tabel Source of Truth dengan kolom Authority
- [ ] ATP dan semua dokumen guru dimiliki guru, bukan sekolah
- [ ] Kepsek hanya consumer (read), bukan owner
- [ ] Schema core terpisah dari public
- [ ] Prinsip 4: Dependency hanya mengalir ke bawah
- [ ] Context Builder sebagai komponen kritis — detail di ADR-005
- [ ] Teacher Profile (stabil, lintas tahun) dipisah dari Teaching Context (per kelas/tahun ajaran)
- [ ] Scope dikunci untuk SMK — SD, SMP, SMA didefinisikan di ADR terpisah fase berikutnya
- [ ] Layer 2 ditambah: Jadwal Pembelajaran (mengubah struktur sesi B4)
- [ ] Layer 3 Teaching Context ditambah: Resource Availability dan Tingkat Otonomi Siswa
- [ ] Setiap atribut di Layer 2 dan 3 mencantumkan "→ Mengubah: bagian modul mana"
- [ ] Pola UX Teacher Profile: diisi sekali di Setup, saat Generate hanya konfirmasi ringkasan
- [ ] Teaching Context tetap bisa diperbarui per kelas tanpa mengubah Teacher Profile
- [ ] Bahasa "AI menyusun draft lengkap, guru meninjau" konsisten di seluruh dokumen
- [ ] Auditability: setiap artefak menyimpan curriculum_version, knowledge_version, generation_policy_version, model_version, generated_at
- [ ] Metadata audit tidak ditampilkan ke guru — hanya untuk kebutuhan sistem
- [ ] Istilah resmi UI: "Perencanaan Pembelajaran Mendalam (PPM)" — bukan "Modul Ajar" atau "RPP"
- [ ] Istilah resmi: "Profil Lulusan 8 Dimensi" — bukan "Profil Pelajar Pancasila"
- [ ] Dasar hukum: Permendikdasmen No. 10/2025 (SKL + 8 Dimensi) dan No. 13/2025 (Deep Learning)
- [ ] Struktur PPM: AI menyusun draft kecuali B4 (kerangka) dan C1/C4/C6 (manual guru)
- [ ] Hasil akhir: dokumen Word siap cetak, tanda tangan fisik
- [ ] Tab "Perangkat Ajar" menggantikan tab ATP lama
- [ ] Relasi dokumen adalah graph, bukan rantai linear — detail di ADR-004
- [ ] Implementasi lama (CP sebagai tenant-owned) dinyatakan deprecated
