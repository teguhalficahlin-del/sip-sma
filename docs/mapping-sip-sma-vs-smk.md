# SIP SMA vs SMK — Feature Gap Analysis

**Tanggal:** 20 Juli 2026  
**Dibuat oleh:** Claude Code (mapping otomatis dari inventarisasi kode)  
**Status:** DRAFT — perlu review Romo

---

## Ringkasan Eksekutif

| Kategori | Jumlah |
|---|---|
| Total fitur diinventarisasi | ~52 fitur |
| UNIVERSAL | 28 fitur |
| SMK-ONLY (perlu dihapus/skip untuk SMA) | 14 fitur |
| BEDA-IMPLEMENTASI (perlu adaptasi) | 7 fitur |
| TIDAK-TAHU (perlu konfirmasi) | 3 fitur |
| Fitur baru untuk SMA (tidak ada di SMK) | 6 item |

---

## 1. Inventarisasi Fitur per Portal

### Portal Guru (`guru/dashboard.html`)
Tab yang tersedia:
- **tab-guru**: Jadwal mengajar (hari/minggu), rekap kehadiran siswa per kelas
- **tab-observasi**: Tulis catatan siswa (dimensi + sentimen + visibilitas), riwayat catatan
- **tab-forum**: Buat posting ke forum kelas, kelola audience postingan
- **tab-wali_kelas**: Rekap absensi kelas walian, export rekap
- **tab-bk**: Fungsi Bimbingan Konseling (kasus/eskalasi)
- **tab-kaprodi**: Monitoring kehadiran per kelas (khusus Kepala Program)
- **tab-waka_humas**: Laporan masalah PKL dari DUDI
- **tab-waka_kesiswaan**: Monitoring kesiswaan schoolwide
- **tab-waka_kurikulum**: Monitoring kurikulum
- **tab-kepsek**: Dashboard monitoring kepsek (kehadiran, guru hadir, ringkasan kasus)
- **tab-ks_admin**: Kelola admin sekolah (khusus kepsek)
- **tab-jurnal**: Jurnal mengajar (catatan sesi per pertemuan)
- **tab-kasus**: Buat & kelola kasus siswa, eskalasi, audience
- **tab-perangkat_ajar**: Upload dokumen perangkat ajar, approval workflow (ATP, modul ajar)

### Portal Siswa (`student/dashboard.html`)
- **tab-jadwal**: Jadwal pelajaran (hari ini / minggu ini)
- **tab-kehadiran**: Rekap kehadiran diri sendiri + statistik
- **tab-observasi**: Catatan dari guru, kasus tentang saya, prestasi & penghargaan
- **tab-pkl**: Status PKL, absensi PKL di DUDI

### Portal Orang Tua (`parent/portal.html`)
- **section-pkl**: Informasi PKL anak, absensi PKL
- **section-schedule**: Jadwal pelajaran anak
- **section-attendance**: Kehadiran anak + filter tanggal
- **section-observations**: Catatan guru tentang anak
- **section-cases**: Kasus tentang anak
- **section-forum**: Forum kelas anak

### Portal Admin (`admin/dashboard.html`)
- **Setup**: Setup sekolah awal, profil & branding
- **Program Keahlian**: Manajemen program keahlian SMK
- **Kelas & Rombel**: Manajemen kelas
- **Staf & Peran**: Import dan kelola staf, jabatan
- **Siswa**: Import dan kelola siswa, alumni
- **Alumni**: Tracking alumni, re-enroll, karir
- **Orang Tua**: Import dan kelola data orang tua
- **DUDI**: Import dan kelola mitra DUDI
- **Stakeholder**: Kelola akun stakeholder
- **Jadwal**: Builder jadwal pelajaran, template
- **Penugasan Forum**: Kelola kelas yang bisa akses forum
- **Tutup Semester**: Workflow penutupan semester
- **Tahun Ajaran Baru**: Workflow buka tahun ajaran baru
- **Export Data**: Export data sekolah
- **Log Aktivitas**: Audit log aktivitas pengguna
- **Wizard Reset**: Reset data sekolah (untuk testing)

### Portal DUDI (`dudi/dashboard.html`)
- Absensi harian siswa PKL
- Tambah catatan/observasi siswa PKL
- Riwayat catatan observasi
- Laporan masalah PKL (buat kasus)

### Portal Stakeholder (`stakeholder/dashboard.html`)
- Ringkasan statistik sekolah (siswa aktif, PKL, staf, program keahlian, kelas, kehadiran)

### Portal Superadmin (`superadmin/dashboard.html`)
- Daftarkan sekolah baru (provisioning)
- Kelola sekolah terdaftar
- Mode pemeliharaan sistem
- Monitoring storage database

### Edge Functions (operasional backend)
- `bulk-import-dudi`, `bulk-import-pkl`, `bulk-import-programs`: import batch data SMK
- `bulk-import-students`, `bulk-import-users`, `bulk-import-parents`, `bulk-import-schedules`, `bulk-import-classes`: import batch umum
- `generate-atp` / `generate-atp-v2`: generate ATP dengan AI
- `evaluate-teacher-indicators`: evaluasi indikator kinerja guru (AI)
- `sync-attendance-batch`, `sync-case`, `sync-journal`, `sync-observation`: sinkronisasi offline
- `open-academic-year`, `cancel-academic-year`: manajemen tahun ajaran
- `provision-school`, `delete-school`, `list-schools`: operasi superadmin
- `purge-expired-students`, `restore-user`, `delete-user`, `set-user-password`: manajemen pengguna

---

## 2. Kategorisasi Fitur

| Fitur | Kategori | Alasan |
|---|---|---|
| Jadwal pelajaran (lihat & input) | UNIVERSAL | Ada di semua jenis sekolah |
| Absensi siswa (catat & rekap) | UNIVERSAL | Ada di semua jenis sekolah |
| Catatan/observasi siswa oleh guru | UNIVERSAL | Ada di semua jenis sekolah |
| Jurnal mengajar guru | UNIVERSAL | Ada di semua jenis sekolah |
| Kasus siswa & eskalasi | UNIVERSAL | BK dan manajemen kasus berlaku universal |
| Forum kelas | UNIVERSAL | Komunikasi guru-siswa berlaku universal |
| Portal orang tua (kehadiran, catatan, kasus) | UNIVERSAL | Ada di semua jenis sekolah |
| Notifikasi (push + bell) | UNIVERSAL | Ada di semua jenis sekolah |
| Manajemen kelas & rombel | UNIVERSAL | Ada di semua jenis sekolah |
| Manajemen staf & peran | UNIVERSAL | Ada di semua jenis sekolah |
| Manajemen siswa (import, alumni) | UNIVERSAL | Ada di semua jenis sekolah |
| Manajemen orang tua | UNIVERSAL | Ada di semua jenis sekolah |
| Jadwal builder & template | UNIVERSAL | Ada di semua jenis sekolah |
| Tutup semester / buka tahun ajaran | UNIVERSAL | Ada di semua jenis sekolah |
| Export data | UNIVERSAL | Ada di semua jenis sekolah |
| Audit log | UNIVERSAL | Ada di semua jenis sekolah |
| Branding per sekolah | UNIVERSAL | Multi-tenant berlaku universal |
| Multi-tenant (school_id isolation) | UNIVERSAL | Berlaku universal |
| Superadmin (provisioning sekolah) | UNIVERSAL | Berlaku universal |
| PWA / offline queue | UNIVERSAL | Ada di semua jenis sekolah |
| Role-based access (wali kelas, kepsek, dll) | UNIVERSAL | Ada di semua jenis sekolah |
| Bimbingan Konseling (tab BK) | UNIVERSAL | BK ada di SMA dan SMK |
| Monitoring kepsek | UNIVERSAL | Ada di semua jenis sekolah |
| Rekap kehadiran (per kelas, per siswa) | UNIVERSAL | Ada di semua jenis sekolah |
| Perangkat Ajar (upload + approval) | UNIVERSAL | Guru di SMA juga butuh modul ajar |
| Capaian Pembelajaran (CP) basis kurikulum | UNIVERSAL | Kurikulum Merdeka berlaku untuk SMA dan SMK |
| Tujuan Pembelajaran (TP) | UNIVERSAL | Berlaku universal di Kurikulum Merdeka |
| Generate ATP dengan AI | UNIVERSAL | Kebutuhan yang sama ada di SMA |
| **PKL (Praktik Kerja Lapangan)** | SMK-ONLY | PKL adalah kewajiban SMK; SMA tidak punya program magang industri wajib |
| **Portal DUDI** | SMK-ONLY | DUDI (Dunia Usaha & Dunia Industri) adalah konsep eksklusif SMK |
| **Absensi PKL** | SMK-ONLY | Entitas turunan dari PKL yang tidak ada di SMA |
| **Program Keahlian (Kaprodi)** | SMK-ONLY | Struktur program keahlian / konsentrasi adalah struktur organisasi SMK |
| **Tab Kaprodi di portal guru** | SMK-ONLY | Jabatan Kepala Program Keahlian tidak ada di SMA |
| **Tab WAKA_HUMAS untuk laporan PKL** | SMK-ONLY | Fungsi koordinasi PKL ke DUDI adalah peran WAKA_HUMAS di SMK |
| **Import data DUDI** | SMK-ONLY | Data mitra industri tidak relevan untuk SMA |
| **Import data PKL** | SMK-ONLY | Data penempatan PKL tidak ada di SMA |
| **Import data Program Keahlian** | SMK-ONLY | Struktur program keahlian SMK tidak ada di SMA |
| **Edge function bulk-import-dudi/pkl/programs** | SMK-ONLY | Backend support untuk fitur SMK-ONLY |
| **Stakeholder summary: stat PKL** | SMK-ONLY | Metrik "siswa PKL" tidak relevan untuk stakeholder SMA |
| **core.vocational_fields/programs/concentrations** | SMK-ONLY | Skema bidang/program/konsentrasi kejuruan |
| **Teaching Factory** | SMK-ONLY | Tidak ada di kurikulum SMA (belum ada di SIP tapi perlu dicatat) |
| **Kasus eskalasi jalur PKL** (DUDI→Kaprodi→WAKA_HUMAS) | SMK-ONLY | Rantai eskalasi ini melibatkan aktor DUDI dan Kaprodi |
| **Penjurusan (IPA/IPS/Bahasa)** | BEDA-IMPLEMENTASI | SMK punya "Program Keahlian" sebagai analog; di SMA disebut "peminatan" atau "jurusan" — logika berbeda |
| **Kurikulum ATP / CP per mata pelajaran** | BEDA-IMPLEMENTASI | CP ada di keduanya, tapi CP SMK punya elemen "kompetensi industri" yang tidak ada di SMA |
| **Peran WAKA** | BEDA-IMPLEMENTASI | SMA punya WAKA_KESISWAAN & WAKA_KURIKULUM tapi tidak punya WAKA_HUMAS yang fokus ke PKL/industri |
| **Mata pelajaran (subjects)** | BEDA-IMPLEMENTASI | Mata pelajaran SMK punya komponen Produktif; SMA tidak punya; daftar mapel berbeda |
| **Alumni tracking** | BEDA-IMPLEMENTASI | SMK butuh tracking ke dunia kerja/industri; SMA butuh tracking ke perguruan tinggi |
| **Struktur kelas** | BEDA-IMPLEMENTASI | SMK: kelas per program keahlian; SMA: kelas per jurusan atau campuran |
| **Evaluate teacher indicators (AI)** | BEDA-IMPLEMENTASI | Indikator kinerja guru SMK mungkin berbeda dimensinya dengan SMA (misal: sinkronisasi industri) |
| **Ekstra kurikuler** | TIDAK-TAHU | SMK punya ekskul tapi tabelnya sudah di-drop (`drop_ekskul_status`); perlu konfirmasi apakah akan dibangun ulang |
| **Prestasi & Penghargaan** | TIDAK-TAHU | Tab ini ada di portal siswa SMK tapi tabelnya di-drop (`drop_achievements_table`); perlu konfirmasi scope |
| **Catatan siswa (catatan_siswa enum)** | TIDAK-TAHU | Kategori catatan siswa mungkin perlu disesuaikan untuk SMA |

---

## 3. Entitas Database SMK-spesifik

| Tabel / Schema | Kategori | Rekomendasi untuk SMA |
|---|---|---|
| `core.vocational_fields` | SMK-ONLY | **HAPUS** — tidak ada bidang kejuruan di SMA |
| `core.vocational_programs` | SMK-ONLY | **HAPUS** — tidak ada program keahlian di SMA; diganti dengan `peminatan` atau `jurusan` |
| `core.vocational_concentrations` | SMK-ONLY | **HAPUS** — konsentrasi keahlian tidak ada di SMA |
| `pkl_placements` (tersirat dari `pkl_attendance`) | SMK-ONLY | **HAPUS** — entitas penempatan PKL tidak ada di SMA |
| `pkl_attendance` | SMK-ONLY | **HAPUS** — absensi PKL tidak ada di SMA |
| `bk_class_assignments` | UNIVERSAL | **PERTAHANKAN** — BK ada di SMA |
| `forum_posts`, `forum_post_*` | UNIVERSAL | **PERTAHANKAN** |
| `capaian_pembelajaran`, `tujuan_pembelajaran` | BEDA-IMPLEMENTASI | **MODIFIKASI** — hapus kolom/data yang mengacu ke kompetensi industri |
| `core.capaian_pembelajaran` | BEDA-IMPLEMENTASI | **MODIFIKASI** — seed data berbeda; CP mapel umum bisa dipakai, CP produktif tidak relevan |
| `core.subjects` | BEDA-IMPLEMENTASI | **MODIFIKASI** — mapel SMA berbeda; perlu seed ulang mapel umum + peminatan SMA |
| `core.subject_phases` | BEDA-IMPLEMENTASI | **MODIFIKASI** — fase Kurikulum Merdeka SMA: Fase E (X) dan Fase F (XI-XII), sama seperti SMK |
| `public.teacher_profiles`, `teaching_contexts` | BEDA-IMPLEMENTASI | **PERTAHANKAN DENGAN REVISI** — `vocational_*` reference perlu dihapus |
| `public.teacher_documents`, `teacher_document_approvals` | UNIVERSAL | **PERTAHANKAN** |
| `ld_documents`, `ld_document_*` (learning documents) | UNIVERSAL | **PERTAHANKAN** |
| `notifications` | UNIVERSAL | **PERTAHANKAN** |
| `audit_log` | UNIVERSAL | **PERTAHANKAN** |
| `schools`, multi-tenant tables | UNIVERSAL | **PERTAHANKAN** |
| `ld_program_knowledge_national` | BEDA-IMPLEMENTASI | **MODIFIKASI** — knowledge nasional SMA berbeda dari SMK |

---

## 4. Fitur Baru yang Dibutuhkan SMA

| Fitur | Prioritas | Catatan |
|---|---|---|
| **SNBP/SNBT Tracking** | Tinggi | Persiapan masuk perguruan tinggi adalah kebutuhan utama siswa SMA. Tidak ada analog di SMK (SMK lebih ke dunia kerja). Butuh modul tersendiri: target PT, nilai raport, status eligibilitas SNBP. |
| **Peminatan / Jurusan** (IPA/IPS/Bahasa/dll) | Tinggi | Kurikulum Merdeka SMA punya "fase F pilihan" — siswa bisa ambil mapel peminatan. Perlu tabel `student_specializations` atau semacamnya. Ini menggantikan `vocational_programs` di SMK. |
| **P5 (Projek Penguatan Profil Pelajar Pancasila) — fase SMA** | Sedang | SMK dan SMA sama-sama punya P5 di Kurikulum Merdeka, TAPI di SMA P5 tidak terkait industri. Perlu modul tracking topik P5 per kelas per semester. |
| **Ekstra Kurikuler** | Sedang | SMA memiliki kegiatan ekskul yang aktif dan sering menjadi nilai tambah SNBP. Butuh manajemen ekskul: jenis, pembina, anggota siswa, catatan prestasi. (Di SMK, `ekskul_status` sudah di-drop.) |
| **Raport & Nilai (input dan rekap)** | Sedang | Baik SMA maupun SMK butuh ini, tapi SIP saat ini tidak punya modul nilai/raport. Di SMA ini lebih kritis karena terkait langsung SNBP. |
| **Tracking Karir Alumni ke PT** | Rendah | Analog dengan tracking alumni SMK ke dunia kerja, SMA butuh tracking alumni ke perguruan tinggi mana yang diterima. |

---

## 5. Pertanyaan untuk Romo

Berikut hal-hal yang perlu dikonfirmasi sebelum ADR (Architecture Decision Record) bisa ditulis:

1. **Apakah SMA juga akan punya DUDI?**  
   Beberapa SMA punya program magang ringan atau kunjungan industri. Apakah ini masuk scope SIP SMA, atau PKL murni SMK-ONLY?

2. **Bagaimana peminatan/jurusan SMA akan dimodelkan?**  
   Opsi a: tabel `peminatan` baru sebagai analog `vocational_programs`. Opsi b: flag di tabel `students`. Mana yang sesuai dengan cara SMA mengelola peminatan di lapangan?

3. **Apakah modul nilai/raport masuk scope SIP SMA (atau SIP versi mana)?**  
   Saat ini tidak ada di SIP SMK. Untuk SMA, nilai raport sangat kritis (SNBP). Apakah ini fitur fase 1 atau ditunda?

4. **Ekskul — seberapa dalam?**  
   Hanya pencatatan keanggotaan siswa, atau juga termasuk jadwal latihan, prestasi, dan laporan pembina?

5. **Apakah P5 perlu ditrack per siswa atau hanya per kelas?**  
   Di SMK, P5 tidak diimplementasikan di SIP. Untuk SMA, apakah cukup informasi kelas (topik + periode) atau butuh penilaian individual per siswa?

6. **Jabatan WAKA — apakah SMA punya peran analog WAKA_HUMAS?**  
   Di SMK, WAKA_HUMAS mengkoordinasi PKL dan hubungan industri. Di SMA tidak ada fungsi ini. Apakah WAKA_HUMAS perlu dihapus dari enum roles, atau dipertahankan untuk fungsi humas umum (press release, hubungan masyarakat)?

7. **Apakah `catatan_siswa` enum perlu disesuaikan untuk SMA?**  
   Saat ini berisi kategori yang mungkin bias ke SMK. Perlu review apakah dimensi catatan (akademik, sosial, PKL, dll) tetap relevan.

8. **Apakah SIP SMA akan dipakai paralel dengan SIP SMK di platform yang sama?**  
   Ini menentukan apakah perlu repo baru atau multi-tenant yang diperluas (lihat Section 6).

9. **Kapan target go-live SIP SMA?**  
   Menentukan apakah ada waktu untuk refactor besar atau harus mulai dari fork SMK.

---

## 6. Rekomendasi Awal: Repo Baru vs Multi-tenant Diperluas

*Catatan: Ini adalah analisis pro/kontra berdasarkan temuan mapping — bukan keputusan. Keputusan ada di tangan Romo.*

### Opsi A: Repo Terpisah (Fork dari SMK)

**Pro:**
- Bisa jalan cepat: copy repo SMK, hapus fitur SMK-ONLY, tambah fitur SMA
- Tidak risiko regresi di SIP SMK yang sudah live
- Tim bisa bekerja paralel tanpa koordinasi yang kompleks
- Kurikulum data (`core.*`) bisa di-seed ulang dengan data SMA tanpa dampak ke SMK

**Kontra:**
- Duplikasi kode besar: ~28 fitur UNIVERSAL harus di-maintain di dua tempat
- Bug fix dan security patch harus di-apply dua kali
- Infrastruktur (Supabase, edge functions) doubled
- Sulit unified reporting jika ada sekolah yang punya SMA dan SMK sekaligus (SLTP-SMA, SMA-SMK satu yayasan)

**Cocok jika:** Timeline ketat, SMA dianggap produk terpisah, tidak ada rencana sekolah dengan dua jenjang.

---

### Opsi B: Multi-tenant Diperluas (Tambah `school_type` di schema)

**Pro:**
- Satu codebase, bug fix sekali berlaku semua
- Fitur UNIVERSAL langsung tersedia untuk sekolah SMA baru
- Mungkinkan satu yayasan punya SMK dan SMA di platform sama
- Skema `core.*` sudah dirancang lepas dari `public.*` — potensial untuk di-share

**Kontra:**
- Kompleksitas conditional rendering meningkat signifikan (tiap fitur SMK-ONLY butuh `if schoolType === 'SMK'`)
- Database schema `core.vocational_*` harus tetap ada tapi nullable/kosong untuk SMA — bikin skema lebih kompleks
- Risiko fitur SMA dan SMK saling terganggu
- Testing surface area berlipat ganda (perlu test tiap fitur di konteks SMA dan SMK)
- Migration history sudah ~170 file — akan makin panjang

**Cocok jika:** Ada rencana platform lintas jenjang, atau tim cukup besar untuk manage kompleksitas.

---

### Opsi C: Monorepo dengan Shared Core (Jalan Tengah)

Pisahkan repo tapi share `core.*` schema dan business logic umum via shared library/supabase project. Lebih kompleks di setup awal tapi solusi paling scalable jangka panjang.

**Pro:** Tidak ada duplikasi logika inti; tetap ada isolasi per jenjang.  
**Kontra:** Butuh setup monorepo yang non-trivial; perlu diskusi lebih dalam.

---

**Rekomendasi kasar (belum keputusan):**  
Berdasarkan ukuran tim saat ini dan fakta bahwa 14 dari ~52 fitur (27%) adalah SMK-ONLY, **Opsi A (fork)** tampak paling pragmatis untuk fase awal — terutama jika SMA adalah produk baru dengan timeline tersendiri. Namun jika ada satu pun sekolah yang punya SMA + SMK di bawah yayasan yang sama, **Opsi B** layak dipertimbangkan sejak awal karena retrofit multi-school-type belakangan akan lebih mahal.
