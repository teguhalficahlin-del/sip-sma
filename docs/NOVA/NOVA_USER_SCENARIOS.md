# NOVA — Skenario Penggunaan Per Aktor
**Tanggal:** 2026-07-07  
**Status:** Draft — menunggu review dan koreksi  
**Konteks:** SMP Harapan Bangsa, Kota Dumai, Riau

---

## AKTOR 1 — GURU
### Pak Rudi, Guru Matematika Kelas 7B & 8A

**06.45 — Sebelum masuk kelas**

Pak Rudi membuka NOVA di HP-nya. Dashboard menampilkan jadwal hari ini: Matematika 7B jam 07.00, Matematika 8A jam 09.00.

Dia lihat notifikasi — ada pesan masuk dari Kepala Sekolah soal rapat sore. Dia baca, tutup, lanjut siapkan mengajar.

---

**07.00 — Di dalam kelas**

Pak Rudi tap "Absensi Sekarang" di dashboard. Sistem otomatis tahu dia sedang mengajar Matematika 7B jam ini.

Muncul daftar nama 28 siswa. Pak Rudi tap satu per satu:
- Budi → Hadir
- Sari → Hadir
- Doni → Alpha (tidak ada kabar)

Selesai dalam 2 menit. Tap "Simpan Absensi". Data tersimpan.

Di saat yang sama, HP orang tua Doni menerima notifikasi push: *"Doni tidak hadir di kelas Matematika hari ini — status: Alpha."*

---

**08.30 — Persiapan mengajar kelas berikutnya**

Pak Rudi ingin buat modul ajar untuk Matematika 8A minggu depan — topik Persamaan Linear.

Dia tap "Buat Modul Ajar". Muncul alur 8 langkah:

1. Pilih kelas → tap **8A**
2. Pilih mapel → **Matematika** (otomatis)
3. Pilih semester & minggu → Semester 1, Minggu ke-8
4. Pilih topik → tap **"Persamaan Linear Satu Variabel"** dari daftar bawaan
5. Pilih durasi → tap **2 JP**
6. Pilih metode → tap **Tanya Jawab** + **Kerja Kelompok**
7. Konfirmasi → sistem cek cache — belum pernah dibuat → tap **"Buat Modul Sekarang"**
8. Loading 15 detik → modul tampil lengkap: tujuan pembelajaran, alur kegiatan, media, penilaian

Pak Rudi baca sebentar, edit satu bagian di alur inti, tap **"Simpan & Bagikan ke Siswa"**.

Siswa 8A sekarang bisa baca modul ini di NOVA mereka.

---

**09.00 — Mengajar 8A**

Absensi 8A. Proses sama seperti tadi — selesai dalam 2 menit.

---

**10.30 — Jam istirahat**

Pak Rudi input nilai ulangan harian yang tadi dipungut dari kelas 7B.

Tap "Input Nilai" → pilih 7B → pilih Matematika → pilih "Harian" → pilih tanggal → muncul daftar siswa → input nilai satu per satu.

Selesai, simpan.

---

**13.00 — Akhir hari mengajar**

Pak Rudi isi jurnal mengajar harian:
- Kelas: 7B
- Mapel: Matematika
- Topik: Pecahan desimal
- Aktivitas: Ceramah + latihan soal
- Respon siswa: Sebagian besar paham, 5 siswa perlu pendampingan
- Tindak lanjut: Remedial minggu depan untuk 5 siswa

Simpan. Selesai.

---

**Yang TIDAK bisa dilakukan Pak Rudi:**
- Tidak bisa lihat data siswa kelas lain yang bukan tugasnya
- Tidak bisa edit absensi hari kemarin (sudah terkunci)
- Tidak bisa akses fitur modul ajar jika sekolah masih tier gratis
- Tidak bisa generate modul lebih dari 10x hari ini

---

## AKTOR 2 — WALI KELAS
### Bu Dewi, Wali Kelas 7B, Guru Bahasa Indonesia

**07.00 — Masuk sekolah**

Bu Dewi buka NOVA. Dashboardnya terlihat berbeda dari guru biasa — ada satu kartu tambahan di atas: **"Rekap Kelas 7B Hari Ini"**.

Kartu itu menampilkan:
- Total siswa: 28
- Sudah hadir: 0 (belum ada guru yang absensi)
- Belum tercatat: 28

---

**08.00 — Setelah jam pertama selesai**

Bu Dewi cek kartu rekap lagi:
- Sudah hadir: 24
- Sakit: 1
- Izin: 1
- Alpha: 2
- Belum tercatat: 0

Dia lihat ada 2 siswa alpha — Doni dan Rizky. Bu Dewi kirim pesan ke orang tua keduanya lewat NOVA:

- Penerima: orang tua Doni (individual)
- Judul: "Konfirmasi Ketidakhadiran Doni"
- Isi: "Selamat pagi, hari ini Doni tidak hadir tanpa kabar. Mohon konfirmasi kondisi Doni. Terima kasih."
- Kirim

Proses sama untuk orang tua Rizky.

---

**10.00 — Jam istirahat**

Bu Dewi buka halaman **Rekap Kelas Lengkap**. Filter: bulan ini.

Tampil tabel per siswa — Hadir / Sakit / Izin / Alpha / Persentase. Data ini agregat dari semua mapel di kelas 7B — bukan hanya Bahasa Indonesia yang dia ajar.

Bu Dewi lihat Doni sudah 4x alpha bulan ini. Dia catat untuk dibicarakan dengan orang tua.

---

**13.30 — Akhir hari**

Bu Dewi tap "Export Rekap" di halaman Rekap Kelas Lengkap. Print dialog muncul. Dia simpan sebagai PDF untuk arsip atau laporan ke Wakil Kepala.

---

**Yang TIDAK bisa dilakukan Bu Dewi:**
- Tidak bisa lihat rekap kelas lain (hanya 7B)
- Tidak bisa edit absensi yang diinput guru lain
- Tidak bisa akses nilai siswa kelas lain
- Tidak bisa publish atau kelola data sekolah

---

## AKTOR 3 — WAKIL KEPALA
### Pak Hendra, Wakil Kepala Bidang Kurikulum

**06.50 — Sebelum bel masuk**

Pak Hendra buka NOVA. Dashboardnya menampilkan Rekap Seluruh Sekolah Hari Ini — masih kosong karena belum ada yang absensi.

---

**08.30 — Setelah jam pertama**

Pak Hendra cek dashboard:

| Kelas | Wali Kelas | Hadir | Sakit | Izin | Alpha | Belum Tercatat |
|---|---|---|---|---|---|---|
| 7A | Bu Sari | 27 | 1 | 0 | 0 | 0 |
| 7B | Bu Dewi | 24 | 1 | 1 | 2 | 0 |
| 8A | Bu Rina | 0 | 0 | 0 | 0 | 28 |
| ... | ... | ... | ... | ... | ... | ... |

8A belum ada absensi sama sekali. Pak Hendra kirim pesan ke guru yang bersangkutan lewat NOVA.

---

**09.30 — Monitoring berlanjut**

Pak Hendra buka Rekap Absensi Lengkap — filter minggu ini. Dia bisa lihat semua siswa semua kelas. Klik kelas 7B → drill-down ke rekap detail kelas 7B.

---

**10.00 — Monitoring jurnal mengajar**

| Guru | Jurnal Diisi | Seharusnya |
|---|---|---|
| Pak Rudi | 3 | 4 |
| Bu Dewi | 4 | 4 |
| Bu Ani | 2 | 4 |

Bu Ani baru mengisi 2 dari 4 jurnal. Pak Hendra kirim pesan pengingat ke Bu Ani.

---

**11.30 — Export laporan mingguan**

Filter "Minggu ini" → tap "Export PDF". Laporan rekap absensi seluruh sekolah siap dalam satu dokumen.

---

**13.00 — Kirim pesan ke semua wali kelas**

- Penerima: centang semua wali kelas
- Judul: "Reminder Laporan Absensi Bulanan"
- Isi: "Mohon kumpulkan rekap absensi kelas masing-masing paling lambat Jumat siang."
- Kirim

---

**Yang TIDAK bisa dilakukan Pak Hendra:**
- Tidak bisa edit absensi yang diinput guru lain
- Tidak bisa akses nilai individual siswa
- Tidak bisa kelola data master sekolah
- Tidak bisa akses data sekolah lain

---

## AKTOR 4 — KEPALA SEKOLAH
### Ibu Ratna, Kepala SMP Harapan Bangsa

**07.30 — Tiba di sekolah**

Ibu Ratna buka NOVA di tablet. Dashboard menampilkan ringkasan sekolah hari ini:
- Total siswa: 252
- Hadir: 187 | Sakit: 8 | Izin: 3 | Alpha: 4 | Belum tercatat: 50

---

**08.30 — Monitoring rutin**

Lihat ada 1 kelas belum ada absensi — 9C. Kirim pesan ke Pak Hendra:
- "Pak Hendra, 9C belum ada absensi jam pertama. Mohon dicek."

Pak Hendra yang menindaklanjuti.

---

**09.00 — Pantau aktivitas guru**

Laporan Progres Guru — filter minggu ini. Bu Ani baru 2 dari 4 jurnal. Ibu Ratna catat — jika minggu depan masih sama, akan dipanggil langsung.

---

**10.00 — Pantau nilai**

Laporan Nilai — filter semester ini. Rata-rata Matematika kelas 7C: 58. Kelas lain 72-75. Akan dibahas di rapat dengan guru Matematika.

Ibu Ratna tidak bisa lihat nilai individual siswa — hanya agregat per kelas.

---

**11.00 — Pantau statistik platform**

- Modul ajar dibuat bulan ini: 47
- Guru aktif generate modul: 8 dari 14
- Login aktif 7 hari terakhir: 11 guru

6 guru belum pernah generate modul — perlu pendampingan.

---

**13.00 — Kirim pesan ke seluruh guru**

Ada kebijakan baru dari Dinas soal format jurnal:
- Penerima: semua guru
- Judul: "Update Format Jurnal Mengajar — Surat Edaran Dinas"
- Kirim

---

**14.30 — Tangani komplain orang tua**

Orang tua Rizky komplain soal 4x alpha. Ibu Ratna buka NOVA — lihat rekap absensi Rizky. Ternyata izin tidak disampaikan ke semua guru. Ibu Ratna minta Bu Dewi update data yang kurang.

Ibu Ratna tidak bisa edit sendiri — semua data akademik read-only untuk Kepsek.

---

**Yang TIDAK bisa dilakukan Ibu Ratna:**
- Tidak bisa edit absensi, nilai, atau jurnal
- Tidak bisa tambah atau hapus data guru/siswa
- Tidak bisa lihat nilai individual siswa secara detail
- Tidak bisa publish apapun

---

## AKTOR 5 — ADMIN
### Bu Siska, Staf Tata Usaha SMP Harapan Bangsa

**Hari Pertama — Onboarding Sekolah**

Bu Siska daftar akun admin. Input nama sekolah, jenjang, alamat, email. Sistem generate `school_id`. Checklist onboarding muncul — progress 0%.

**Langkah 1 — Profil sekolah:**
Isi tahun ajaran aktif (2025/2026), semester aktif (1), wilayah (Dumai, Riau).

**Langkah 2 — Tambah guru:**
Input 14 guru. Assign jabatan tambahan: Bu Dewi → Wali Kelas 7B, Pak Hendra → Wakil Kepala. Sistem generate akun otomatis, kirim kredensial via email.

**Langkah 3 — Tambah siswa:**
Import CSV 252 siswa. Sistem buat 252 akun dalam hitungan detik.

**Langkah 4 — Buat kelas:**
Buat 9 kelas, assign siswa. Sistem populate `class_members` otomatis.

**Langkah 5 — Atur jadwal:**
Input jadwal per kelas per hari. Saat ada konflik — Pak Rudi dijadwalkan dua kelas jam sama — sistem tampilkan error. Bu Siska perbaiki.

**Langkah 6 — Undang orang tua:**
Input nomor HP orang tua per siswa (atau import CSV). Sistem kirim WhatsApp OTP ke setiap orang tua. Checklist 100% — platform siap.

---

**Hari Kerja Biasa**

Dashboard admin menampilkan:
- Total guru aktif: 14
- Total siswa aktif: 252
- Login hari ini: 8 guru, 47 siswa
- Status lisensi: Gratis

Notifikasi: *"Jumlah siswa mendekati batas tier S."* Bu Siska laporkan ke Ibu Ratna.

---

**Siswa baru pindahan — Fajar:**
Tambah akun, assign ke 8B, input HP orang tua, undang via WhatsApp OTP. Selesai 5 menit.

**Guru resign — Bu Ani:**
Set `is_active = false`. Data Bu Ani tetap tersimpan. Jadwal dikosongkan. Tambah guru pengganti.

**Reset password:**
Pak Joko lupa password → Bu Siska tap "Reset Password" → link dikirim ke email Pak Joko.

**Kirim pengumuman libur nasional:**
- Penerima: semua guru + semua orang tua
- Kirim

---

**Yang TIDAK bisa dilakukan Bu Siska:**
- Tidak bisa lihat atau edit nilai siswa
- Tidak bisa lihat isi jurnal mengajar guru secara detail
- Tidak bisa akses data sekolah lain
- Tidak bisa generate modul ajar

---

## AKTOR 6 — SISWA
### Budi, Kelas 7B, SMP Harapan Bangsa

**Pagi — Sebelum berangkat**

Buka NOVA. Dashboard menampilkan jadwal hari ini dan notifikasi:
- 🔴 "Tugas Matematika deadline besok — belum dikumpulkan"
- 📘 "Modul ajar baru: Persamaan Linear — Pak Rudi"

Budi tap modul → baca sebentar → tutup. Dia tahu topik hari ini.

---

**Di sekolah — Jam Matematika**

Pak Rudi absensi. Budi tercatat hadir. Budi tidak melakukan apapun di NOVA saat ini.

---

**Jam Istirahat**

Budi cek tab "Tugas":

| Tugas | Mapel | Deadline | Status |
|---|---|---|---|
| Latihan Soal Bab 3 | Matematika | Besok 23.59 | Belum dikumpul |
| Rangkuman Paragraf | Bahasa Indonesia | Minggu depan | Belum dikumpul |
| Laporan Pengamatan | IPA | Sudah lewat | Terlambat |

Budi buka Laporan Pengamatan IPA → tap "Kumpulkan Sekarang" → ketik jawaban → kirim.

Status: *"Terkumpul — terlambat 2 hari."*

---

**Pulang sekolah**

Kerjakan Tugas Matematika → buka NOVA → ketik jawaban → kirim.

Status: *"Terkumpul — tepat waktu."*

---

**Akhir Minggu — Cek Nilai**

| Mapel | Harian | Mid Semester | Observasi Perilaku |
|---|---|---|---|
| Matematika | 78 | — | Baik |
| Bahasa Indonesia | 85 | — | Sangat Baik |
| IPA | 70 | — | Cukup |
| IPS | 82 | — | Baik |

IPA paling rendah. Budi buka modul ajar IPA untuk belajar ulang.

---

**Yang TIDAK bisa dilakukan Budi:**
- Tidak bisa lihat nilai siswa lain
- Tidak bisa kirim pesan ke siapapun
- Tidak bisa akses fitur di luar kelasnya
- Tidak bisa edit tugas yang sudah dikumpulkan

---

## AKTOR 7 — ORANG TUA
### Pak Agus, Ayah Budi, Kelas 7B

**Hari Pertama — Aktivasi Akun**

HP Pak Agus terima WhatsApp dari NOVA. Tap link → masuk halaman NOVA → input nomor HP → terima OTP → tap Verifikasi. Akun aktif, langsung terhubung ke data Budi. Tidak perlu input apapun lagi.

---

**Hari Kerja — Senin Pagi**

Notifikasi push: *"Budi tidak hadir di kelas Matematika hari ini — status: Alpha."*

Pak Agus tap notifikasi → lihat detail: tanggal, mapel, jam, guru. Hubungi Budi lewat HP — ternyata terlambat masuk. Pak Agus hubungi sekolah lewat jalur biasa untuk klarifikasi.

---

**Siang — Cek Nilai**

| Mapel | Harian | Observasi Perilaku |
|---|---|---|
| Matematika | 78 | Baik |
| Bahasa Indonesia | 85 | Sangat Baik |
| IPA | 70 | Cukup |
| IPS | 82 | Baik |

IPA rendah dan observasi "Cukup" — dibicarakan dengan Budi malam ini.

---

**Sore — Cek Jadwal Besok**

Tab "Jadwal": Selasa ada Bahasa Indonesia jam 07.00. Pak Agus pastikan Budi bangun lebih awal.

---

**Minggu — Pesan Masuk**

Inbox: pesan dari Bu Dewi (Wali Kelas):
*"Selamat pagi. Budi tercatat alpha 2 kali bulan ini. Mohon perhatian dari rumah. Terima kasih."*

Pak Agus tidak bisa membalas lewat NOVA. Jika ingin merespons, hubungi Bu Dewi lewat nomor HP sekolah.

---

**Akhir Bulan — Rekap Kehadiran**

Tab "Kehadiran Budi" — filter bulan ini:
- Hadir: 18 | Sakit: 1 | Izin: 1 | Alpha: 2
- Persentase: 90%

---

**Yang TIDAK bisa dilakukan Pak Agus:**
- Tidak bisa kirim pesan lewat NOVA
- Tidak bisa lihat data siswa lain
- Tidak bisa edit atau komplain absensi lewat NOVA
- Jika punya anak lebih dari satu di sekolah yang sama → akun yang sama terhubung ke semua anak

---

## AKTOR 8 — KOMITE
### Pak Bambang, Ketua Komite Sekolah

**Aktivasi Akun**

Akun dibuat oleh Admin (Bu Siska). Login dengan email. Dashboard sangat sederhana — hanya data yang perlu untuk fungsi pengawasan.

---

**Monitoring Bulanan**

Dashboard menampilkan rekap kehadiran siswa bulan Juli:
- Rata-rata kehadiran seluruh sekolah: 91%
- Kelas tertinggi: 9A (97%)
- Kelas terendah: 7C (84%)

Tidak ada nama siswa individual — hanya angka agregat.

---

**Monitoring Konsistensi Absensi**

- Total sesi mengajar seharusnya: 54
- Sesi sudah diabsensi: 51
- Sesi belum diabsensi: 3

Pak Bambang catat untuk ditanyakan ke Kepala Sekolah di rapat komite.

---

**Pesan Masuk**

Pesan dari Ibu Ratna — undangan rapat koordinasi komite-sekolah Jumat, 11 Juli 2025.

Pak Bambang tidak bisa membalas lewat NOVA — konfirmasi lewat WhatsApp langsung.

---

**Rapat Komite**

Pak Bambang bawa data dari NOVA sebagai bahan diskusi tanpa perlu minta laporan manual ke sekolah.

---

**Yang TIDAK bisa dilakukan Pak Bambang:**
- Tidak bisa lihat nama siswa individual
- Tidak bisa lihat nilai siswa
- Tidak bisa kirim pesan lewat NOVA
- Tidak bisa edit data apapun

---

## AKTOR 9 — DINAS PENDIDIKAN
### Bu Marlina, Staf Bidang Pendidikan Dasar, Dinas Pendidikan Kota Dumai

**Aktivasi Akun**

Akun dibuat di level admin NOVA pusat dengan field `region = "Dumai, Riau"`. Bu Marlina hanya bisa akses 47 sekolah di wilayah Dumai.

---

**Senin Pagi — Pantau Wilayah**

Dashboard menampilkan:
- Total sekolah terdaftar: 47
- Sekolah sudah ada data hari ini: 31
- Sekolah belum ada data: 16
- Rata-rata kehadiran wilayah: 88%

---

**Rekap Per Sekolah**

| Sekolah | Jenjang | Total Siswa | Hadir | Alpha | % Hadir |
|---|---|---|---|---|---|
| SMP Harapan Bangsa | SMP | 252 | 231 | 10 | 91.6% |
| SMA Pelita | SMA | 320 | 275 | 25 | 85.9% |
| ... | ... | ... | ... | ... | ... |

SMA Pelita alpha tinggi — catat untuk ditindaklanjuti. Tidak bisa lihat siapa saja yang alpha.

---

**Akhir Bulan — Laporan untuk Pimpinan**

Filter bulan Juli → Export PDF → kirim ke Kepala Dinas. Tidak perlu minta laporan manual ke 47 sekolah satu per satu.

---

**Perbandingan Antar Sekolah**

Ranking kehadiran siswa seluruh wilayah:
1. SD Cahaya Ilmu — 96.2%
2. SMP Harapan Bangsa — 91.6%
...
47. SMA Pelita — 79.3%

SMA Pelita konsisten di bawah — jadwalkan kunjungan pembinaan.

---

**Sekolah Tidak Aktif**

3 sekolah tidak punya data di NOVA bulan ini. Bu Marlina akan follow up lewat surat resmi Dinas.

---

**Yang TIDAK bisa dilakukan Bu Marlina:**
- Tidak bisa lihat nama atau nilai siswa individual
- Tidak bisa kirim pesan lewat NOVA
- Tidak bisa akses sekolah di luar wilayah Dumai
- Tidak bisa edit data apapun

---

*Dokumen ini adalah referensi skenario penggunaan nyata NOVA per aktor.*
*Dibuat berdasarkan sesi perencanaan 2026-07-07.*
*Perlu divalidasi dengan pengguna nyata sebelum dijadikan acuan UX final.*
