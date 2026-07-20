# Kesiapan Platform — 10 Sekolah hingga Ribuan Sekolah

**Versi:** v1.3 · **Tanggal:** 4 Juli 2026
**Menyatukan:** `go-live-10-sekolah-checklist.md` + `thousands-of-schools-readiness-guideline.md`

> Dokumen ini adalah gerbang akhir sebelum go-live. Terdiri dari dua jalur yang harus hijau secara bersamaan:
>
> - **Jalur Platform** — diverifikasi lewat audit konsolidasi. Membuktikan platform berfungsi, aman, dan benar.
> - **Jalur Go-Live** — diverifikasi oleh manusia di lapangan. Membuktikan sekolah dan operator siap menggunakannya.
>
> Keduanya wajib terpenuhi. Platform yang siap secara teknis tapi sekolahnya belum siap tetap tidak boleh go-live, dan sebaliknya.

---

## Bagian 1 — Go-Live 10 Sekolah

---

### Jalur Platform *(diverifikasi lewat audit konsolidasi)*

Setiap item di bawah punya penopang langsung di `docs/audit/00-audit-konsolidasi.md`. Item dinyatakan terpenuhi bila audit penopangnya sudah dijalankan dan hasilnya hijau.

#### A. Keamanan & Isolasi Tenant
*(Penopang: seksi I)*
1. RLS enabled di seluruh tabel; setiap policy memfilter `school_id`
2. Tidak ada RPC SECURITY DEFINER VOLATILE yang dapat dieksekusi oleh anon
3. Semua view publik menegakkan RLS penanya; anon tidak dapat membaca baris
4. Cross-tenant test nyata: akun Sekolah A tidak dapat membaca data Sekolah B
5. Guard-rail isolasi tenant berjalan otomatis di CI dan memblokir rilis bila gagal

#### B. Rilis & Pemulihan Data
*(Penopang: seksi N)*
6. Backup otomatis database aktif dan terkonfirmasi
7. Restore backup teruji ke lingkungan terpisah
8. Backup terverifikasi sebelum setiap migrasi dijalankan ke live
9. Setiap migrasi memiliki rencana rollback tertulis sebelum di-apply
10. Ekspor data per sekolah tersedia bila diminta

#### C. QA Fungsional End-to-End
*(Penopang: seksi O)*
11. Alur Guru: absensi tersimpan (online dan offline sync), observasi tercatat
12. Alur Wali Kelas / Kaprodi: hanya melihat siswa tanggung jawabnya; rekap benar
13. Alur BK: membuat dan menangani kasus, eskalasi antar peran berjalan
14. Alur Siswa & Orang Tua: melihat data diri sendiri; jadwal dan kehadiran tampil benar
15. Alur DUDI & PKL: pembimbing hanya melihat siswa PKL binaannya
16. Alur Kepsek / Waka / Stakeholder: dashboard hanya menampilkan data sekolah sendiri
17. Setup sekolah end-to-end: impor massal → tahun ajaran → jadwal → penugasan → absensi tersambung

#### D. Ketahanan di Lapangan
*(Penopang: seksi M, E)*
18. Input guru tetap bisa disimpan saat internet mati dan terkirim otomatis saat online kembali
19. Impor massal idempoten — aman diulang bila koneksi terputus di tengah proses
20. Tidak ada akun dengan password default aktif; ganti password wajib saat login pertama
21. Sesi otomatis berakhir setelah idle; perangkat bersama tidak meninggalkan sesi aktif
22. Platform menampilkan pesan jelas saat sistem dalam pemeliharaan

#### E. Legal & Privasi
*(Penopang: seksi D, M9)*
23. Kebijakan retensi data terdokumentasi
24. Mekanisme hapus data siswa atas permintaan tersedia

---

### Jalur Go-Live *(diverifikasi oleh manusia di lapangan)*

Item di bawah tidak bisa diverifikasi dari kode. Dicentang oleh operator platform dan pihak sekolah secara langsung sebelum go-live.

#### F. Kesiapan Operator Platform
25. Template file impor (siswa, guru, orang tua, jadwal) tersedia dan terdokumentasi
26. Panduan admin sekolah tersedia, terbaca, dan mencakup urutan kerja yang benar
27. Jalur dukungan tersedia dengan waktu respons yang jelas selama jam sekolah
28. Operator siaga aktif pada hari pertama go-live setiap sekolah
29. Rencana mundur tersedia: langkah yang diambil bila sistem tidak dapat diakses di hari pertama

#### G. Infrastruktur & Perangkat Sekolah
30. Koneksi internet di sekolah memadai untuk jumlah pengguna yang akan mengakses bersamaan
31. Guru memiliki perangkat (HP/tablet) yang dapat mengakses platform
32. Admin memiliki akses komputer untuk mengelola konsol admin

#### H. Kesiapan Data
33. Data siswa (nama, NIS, kelas, program keahlian) diverifikasi kebenarannya oleh pihak sekolah
34. Data guru dan penugasan mengajar lengkap dan diverifikasi
35. Struktur kelas, program keahlian, dan jadwal tersedia sebelum tahun ajaran dibuka
36. Kepala sekolah atau admin menandatangani persetujuan bahwa data yang akan diimpor sudah benar
37. Uji coba impor dilakukan; hasilnya diperiksa dan disetujui sebelum impor ke live

#### I. Kredensial & Akses
38. Prosedur distribusi kredensial ke guru, siswa, dan orang tua ditetapkan
39. Seluruh guru menerima dan mengonfirmasi kredensialnya sebelum hari go-live
40. Admin sekolah mengetahui cara reset password pengguna secara mandiri

#### J. Pelatihan & Orientasi
41. Admin sekolah menjalani sesi orientasi penggunaan konsol admin
42. Guru menjalani sesi orientasi penggunaan portal guru sebelum hari pertama absensi
43. Dry-run dilakukan: minimal admin dan beberapa guru menyelesaikan siklus absensi penuh
44. Masalah yang ditemukan saat dry-run diselesaikan sebelum go-live

#### K. Komunikasi & Persetujuan
45. Semua guru diberitahu tanggal go-live, cara login, dan ke mana melapor bila ada masalah
46. Orang tua diberitahu bahwa data anak mereka diproses di platform dan cara mengakses portal
47. Kepala sekolah menyatakan sekolah siap go-live secara formal

---

### Gerbang Go / No-Go

Go-live hanya boleh dilakukan bila:
- Semua item **Jalur Platform** (A–E) terpenuhi, dibuktikan lewat audit konsolidasi
- Semua item **Jalur Go-Live** (F–K) dicentang oleh operator dan pihak sekolah

Bila ada satu item pun yang belum terpenuhi, go-live ditunda.

---

## Bagian 2 — Kesiapan Ribuan Sekolah

> Skala acuan: ~2.000 sekolah × ~1.000 siswa → ~2,4 miliar baris `attendance`/tahun.
> Setiap item wajib memiliki gerbang verifikasi otomatis — item tanpa gerbang akan diam-diam melenceng.

### G-ISO — Isolasi Tenant
48. RLS enabled di seluruh tabel operasional; setiap policy memfilter tenant
49. Tidak ada RPC penulis yang dapat dieksekusi anon
50. Cross-tenant test otomatis: login Sekolah A → 0 baris Sekolah B di seluruh tabel inti
51. `school_id` selalu diturunkan server-side dari `auth.uid()` — tidak pernah dari input klien
52. Setiap operasi service_role memvalidasi `school_id` objek target

### G-PERF — Performa & Kapasitas
53. Setiap tabel operasional memiliki indeks komposit dipimpin `school_id`
54. Latensi query berfilter-RLS terjaga pada dataset skala (p95 < 200 ms pada 500 juta baris)
55. Tabel volume-tinggi dipartisi per tahun ajaran atau hash tenant
56. Data tahun ajaran non-aktif diarsip dan dipisah dari tabel panas
57. Kolom join pada helper RLS terindeks
58. Pooler koneksi aktif; utilisasi koneksi terpantau dan tidak melebihi ambang pada beban puncak

### G-REL — Keandalan & Ketersediaan
59. SLO ketersediaan ditetapkan, dipantau, dan ada alerting saat dilanggar
60. Backup berkala aktif; restore teruji terjadwal; RPO dan RTO ditetapkan
61. Observability aktif: slow-query, error rate, dan metrik per-tenant terpantau
62. Tidak ada komponen tunggal yang jatuhnya menghentikan seluruh tenant tanpa mitigasi

### G-OPS — Operasional & Rilis
63. Setiap migrasi melewati staging dan test isolasi sebelum dipromosikan ke live
64. Provisioning sekolah baru otomatis, idempoten, dan dapat diuji berulang
65. Lifecycle tenant (suspend, delete, arsip) idempoten dan meninggalkan jejak audit
66. Runbook insiden dan prosedur eskalasi terdokumentasi serta dilatih
67. Setiap migrasi memiliki rollback plan; template PR mewajibkan bagian rollback

### G-SEC — Keamanan & Kepatuhan
68. Akses dan perubahan data sensitif tercatat dalam audit log
69. Rate-limit per akun dan per IP aktif; proteksi brute-force tersedia
70. Kepatuhan UU PDP terpenuhi: retensi data, hak hapus, dan dasar pemrosesan tercatat
71. Tidak ada akun dengan password default; mekanisme ganti-password saat login pertama aktif
72. Secret dikelola aman, tidak masuk repo, dan dirotasi berkala

### G-SAAS — Kapabilitas SaaS per-Tenant
73. Konfigurasi per-tenant dapat diubah tanpa mengubah kode
74. Fitur dapat diaktifkan atau dinonaktifkan per tenant melalui feature flag
75. Pemakaian per tenant terukur untuk keperluan penagihan

### G-COST — Ekonomi & Efisiensi
76. Model biaya per tenant terprediksi dan menurun per unit saat skala naik
77. Kuota sumber daya per tenant ditegakkan agar satu sekolah tidak mempengaruhi performa tenant lain

---

## Urutan Pengerjaan (Bagian 2)

**Fase 0 — Fondasi**
G-ISO-01..05 · G-PERF-01, 02 · G-OPS-01, 05 · G-REL-02 · G-SEC-03, 04 · semua gerbang CI aktif

**Fase 1 — Kesiapan Operasi & Performa**
G-PERF-03..06 · G-REL-01, 03 · G-OPS-02..04 · G-SEC-01, 02, 05

**Fase 2 — Kematangan SaaS & Ekonomi**
G-REL-04 · G-SAAS-01..03 · G-COST-01, 02
