# Daftar Item Audit — Platform Sekolah SMK

**Dibuat:** 4 Juli 2026.
**Isi:** penyatuan **item audit** (aspek/pemeriksaan yang ditinjau) dari seluruh dokumen di `docs/audit/` menjadi satu daftar. Ini **bukan** daftar temuan dan **tidak** memuat status/keparahan — hanya *apa saja yang diaudit*.

**Dokumen sumber:** `00-master-summary.md`, `level-a … level-h`, `level-f2`, `audit-multi-tenant.md`, `attendance-audit.md`, `referential-integrity-audit.md`, `temuan-total.md`.

**Tag orang tua:** `[K:N]` = item ini punya orang tua di `kesiapan-platform.md` item N (Jalur Platform). `[-]` = tidak punya orang tua di kesiapan — item perbaikan berkelanjutan atau relevan di fase mendatang.

---

## A. Kebutuhan & Nilai Operasional
1. Inventaris Fitur `[-]`
2. Audit Kebutuhan per Fitur `[-]`
3. Audit Nilai Operasional `[-]`

## B. Aktor & Workflow
4. Audit Aktor `[-]`
5. Audit Workflow `[-]`
6. Audit Beban Operasional `[-]`

## C. Data
7. Audit Model Data `[-]`
8. Audit Kualitas Data `[K:33]` `[K:34]`
9. Audit Pelaporan `[-]`

## D. Tata Kelola
10. Audit Hak Akses `[K:20]`
11. Audit Privasi `[K:23]` `[K:24]`
12. Audit Keamanan `[K:1]` `[K:2]` `[K:3]` `[K:4]`
13. Audit Trail `[-]`

## E. Teknologi
14. Audit Offline-First `[K:18]`
15. Audit Sinkronisasi `[K:18]`

## F. Keterbacaan & UX
16. Audit Bahasa `[-]`
17. Audit Beban Kognitif `[-]`
18. Audit Hierarki Informasi `[-]`
19. Audit Dashboard `[-]`
20. Audit Form `[-]`
21. Audit Tabel `[-]`
22. Audit Tombol & Aksi `[-]`
23. Audit Pesan Kesalahan `[-]`
24. Audit Mobile `[-]`
25. Audit 5-Detik `[-]`

## F2. Konsistensi Sistem (Audit 32)
26. Konsistensi Istilah `[-]`
27. Konsistensi Status `[-]`
28. Konsistensi Format Tanggal `[-]`
29. Konsistensi Pola Tombol `[-]`
30. Konsistensi Permission `[-]`
31. Konsistensi Pola Feedback `[-]`
32. Konsistensi Layout `[-]`

## G. Warna & Visual
33. Audit Makna Warna `[-]`
34. Audit Kontras `[-]`
35. Audit Aksesibilitas Warna `[-]`
36. Audit Prioritas Visual `[-]`
37. Audit Konsistensi Status `[-]`
38. Audit Dark Mode `[-]`
39. Audit Cetak `[-]`
40. Audit Emosi Visual `[-]`

## H. Prinsip Desain Mobile-First
41. One Screen, One Purpose `[-]`
42. Primary Action First `[-]`
43. Content Before Decoration `[-]`
44. Progressive Disclosure `[-]`
45. Fast Recognition `[-]`
46. Thumb Friendly `[-]`
47. Minimize Typing `[-]`
48. Minimize Navigation `[-]`
49. Immediate Feedback `[-]`
50. Consistency `[-]`
51. Performance First `[-]`
52. Error Prevention `[-]`
53. Mobile First `[-]`
54. Operational First `[-]`
55. Navigation First `[-]`
56. Exception First `[-]`

---

## I. Isolasi Multi-Tenant (guard-rail `tests/tenant-isolation.mjs`)
57. CHECK 1 — RLS enabled di semua tabel public `[K:1]`
58. CHECK 2 — Tak ada RPC SECURITY DEFINER VOLATILE executable oleh anon (di luar allowlist) `[K:2]`
59. CHECK 3 — Anon tak bisa membaca tabel inti `[K:1]`
60. CHECK 4 — Regresi RPC privileged (anon tanpa EXECUTE) `[K:2]`
61. CHECK 5 — Cross-Tenant (admin Sekolah A tak membaca data Sekolah B) `[K:4]`
62. CHECK 6 — View publik security_invoker & tak terbaca anon (SEC-1) `[K:3]`
63. CHECK 7 — Kunci eskalasi kasus (target internal-only & DUDI→Kaprodi) `[K:13]`

**Dimensi arsitektur multi-tenant yang ditinjau:**
64. Tenant sebagai root entity + kolom `school_id` per tabel `[K:1]`
65. Anti-spoof `school_id` diturunkan server-side (`fn_current_school_id`, `_shared/auth.ts`) `[K:1]`
66. Edge Function service_role — validasi tenant objek target `[K:2]`
67. Superadmin gate (fail-closed) `[K:1]`
68. Storage bucket & policy `[K:1]`

## J. Absensi
69. Kunci periode (`fn_is_period_closed`) — cakupan tenant `[K:11]`
70. Eksposur agregat kehadiran (`fn_kepsek_monitoring`) — cakupan peran `[K:16]`
71. Hak hapus/void baris absensi (TU vs desain void-only) `[K:11]` `[K:12]`
72. Perilaku upsert & un-void baris `[K:11]`
73. Jalur tulis absensi & penjaga enrolmen `[K:11]`
74. Kunci periode PKL (`pkl_attendance`) `[K:15]`
75. Cakupan enum `meeting_status` `[K:11]`
76. Mekanisme token guru pengganti (`rw_substitute`) `[K:11]`
77. Provenance & student-match tulis PKL `[K:15]`

## K. Integritas Referensial & Dampak Perubahan
78. Inventarisasi Modul (Implemented / Partial / Not Applicable) `[-]`
79. Analisis per-Data-Master (sumber kebenaran, FK by ID, propagasi baca, duplikasi) `[-]`
80. Update Mechanism (FK ON DELETE, cascade, propagasi baca via JOIN) `[-]`
81. Cache / Offline / Sync (cache klien, offline outbox, arah sync) `[-]`
82. Pencarian Global & Hardcode nama master `[-]`
83. Change Impact Map (peta dependensi nyata) `[-]`
84. Test Case per data master (nama guru/kelas/program/sekolah/siswa/DUDI/ortu, pindah tahun ajaran) `[-]`

## L. Re-Audit Portal Aktor & Arsitektur (temuan-total)
85. Bug Multi-Tenant & RLS sisi-server (Bagian 1) `[K:1]` `[K:2]` `[K:3]` `[K:4]`
86. Re-audit menyeluruh portal aktor lensa A–H sisi-klien (Bagian 2) `[K:11]` `[K:12]` `[K:13]` `[K:14]` `[K:15]` `[K:16]`
87. Audit Local-First / prinsip arsitektur (Bagian 3) `[K:18]`
88. Audit Installable (PWA) + atom Responsive (Bagian 4) `[-]`

---

## M. Kemungkinan Buruk di Lapangan

### M1. Internet & Koneksi
89. Perilaku input offline — antrean tulis (absensi/observasi/jurnal/kasus) saat internet mati `[K:18]`
90. Ketahanan impor massal saat koneksi terputus di tengah proses `[K:19]`
91. Perilaku form saat koneksi lambat (timeout, double-submit) `[-]`
92. Kemampuan offline portal DUDI di lokasi PKL / industri `[K:15]`
93. Ketahanan data offline saat perangkat hilang atau rusak fisik sebelum sync `[K:18]`

### M2. Autentikasi & Kredensial
94. Alur reset password self-service untuk guru, siswa, orang tua, DUDI `[K:20]`
95. Alur pemulihan akses admin utama yang kehilangan akses `[K:20]`
96. Perlindungan rate-limit dan pesan jelas saat terlalu banyak percobaan login `[K:20]`
97. Pemisahan kode identitas dan password (stakeholder) `[K:20]`

### M3. Pergantian Perangkat
98. Keamanan sesi saat perangkat dipinjam atau dipakai bergantian `[K:21]`
99. Penonaktifan sesi otomatis (idle timeout) `[K:21]`
100. Persistensi data saat ganti perangkat `[-]`

### M4. Kesalahan Operasional Admin
101. Pemulihan akun yang salah dihapus (soft-delete / Recycle Bin) `[K:17]`
102. Penanganan impor file duplikat atau berulang (idempotency) `[K:19]`
103. Pembatalan tahun ajaran yang keliru dibuka `[-]`
104. Koreksi absensi, observasi, dan kasus yang salah input (void/batalkan) `[K:11]` `[K:13]`
105. Alur roll-back eskalasi kasus yang salah tingkat `[K:13]`
106. Koreksi siswa yang diimpor ke program keahlian yang keliru `[-]`
107. Penanganan jadwal yang diimpor salah `[-]`

### M5. Pergantian Personil
108. Onboarding guru baru di tengah tahun ajaran `[-]`
109. Offboarding dan penonaktifan akun guru/staf yang resign `[-]`
110. Deteksi akun staf aktif tanpa jadwal (stale staff) `[-]`
111. Penggantian wali kelas dan kaprodi di tengah semester `[-]`
112. Suksesi admin utama sekolah `[-]`
113. Alur mutasi siswa pindah sekolah `[-]`

### M6. Ketersediaan Sistem
114. Perilaku platform saat Supabase down total `[-]`
115. Perilaku platform saat GitHub Pages down (tidak ada fallback hosting) `[-]`
116. Penanganan edge function timeout saat impor besar `[K:19]`
117. Komunikasi status pemeliharaan ke semua pengguna `[K:22]`
118. Monitoring kapasitas penyimpanan database `[-]`

### M7. Keamanan Kredensial
119. Deteksi dan notifikasi login dari perangkat baru `[K:20]`
120. Deteksi sesi ganda (concurrent login) dari perangkat berbeda `[K:20]`
121. Perlindungan akses setelah kredensial bocor di grup komunikasi `[K:20]`
122. Keamanan SUPERADMIN_KEY platform (tanpa IP whitelist) `[-]`
123. Keamanan token JWT (HTTPS, expiry) `[K:20]`

### M8. Data & Sinkronisasi
124. Konsistensi data saat dua guru input absensi kelas sama secara bersamaan `[K:11]`
125. Penanganan request terputus di tengah (retry, idempotency) `[K:19]`
126. Konsistensi data lintas tab/browser (realtime sync) `[-]`
127. Backup dan restore data (PITR) `[K:6]` `[K:7]`
128. Isolasi identifier antar tenant (NIP/NIK/NIS unik per sekolah di Auth global) `[K:1]`

### M9. Alumni
129. Pemblokiran login akun alumni setelah lulus `[-]`
130. Penerbitan rekap kehadiran, pembinaan, dan PKL untuk alumni `[-]`
131. Pencatatan dan penelusuran karir alumni pasca-lulus `[-]`
132. Re-enroll siswa KELUAR (bukan LULUS) tanpa membuat akun baru `[K:17]`
133. Kebijakan retensi dan penghapusan permanen data alumni `[K:23]` `[K:24]`

---

## N. Proses Rilis & Pemulihan

### N1. Disiplin Migrasi Skema
134. Keberadaan titik pulih terverifikasi sebelum tiap migrasi dijalankan ke live `[K:8]`
135. Snapshot bertarget objek yang diubah (fungsi, policy, kolom) sebelum apply `[K:8]`
136. Idempotency migrasi — aman diulang tanpa efek samping `[K:19]`
137. Pembersihan komentar SQL panjang sebelum apply (batas payload endpoint) `[-]`
138. Verifikasi guard-rail isolasi tenant sebelum dan sesudah apply `[K:5]`

### N2. Rencana Rollback
139. Ketersediaan rollback plan tertulis untuk setiap migrasi `[K:9]`
140. Pola rollback per jenis perubahan (fungsi, policy, kolom, data massal) `[K:9]`
141. Rollback destruktif / tidak-reversibel via restore backup `[K:9]`

### N3. Restore & Pemulihan Data
142. Ketersediaan dan aktifnya backup otomatis (daily/PITR) `[K:6]`
143. Uji restore ke lingkungan terpisah — bukan sekadar "backup ada" `[K:7]`
144. Verifikasi integritas data pasca-restore (jumlah baris, isolasi tenant) `[K:7]`
145. Kemampuan ekspor data per sekolah (portabilitas / offboarding tenant) `[K:10]`

### N4. Alur Rilis Aman
146. Urutan apply yang aman — snapshot → apply → verifikasi → guard-rail → smoke test `[K:8]` `[K:9]`
147. Konsistensi pencatatan migrasi di `schema_migrations` `[-]`
148. Smoke test login dan submit pasca-deploy `[K:8]`

---

## O. QA Fungsional End-to-End per Peran

### O1. Keamanan View Publik
149. Keterbacaan view publik oleh anon (bypass RLS via owner view) `[K:3]`
150. Isolasi lintas-tenant pada view yang terautentikasi `[K:4]`

### O2. Alur Guru
151. Penyimpanan absensi sesi — tunggal, idempoten, terotorisasi `[K:11]`
152. Validasi siswa terdaftar di kelas dan periode jadwal yang benar `[K:11]`
153. Keying absensi per tanggal — sesi berbeda tidak saling menimpa `[K:11]`
154. Perilaku antrean offline absensi saat disimpan lebih dari satu kali dalam sesi sama `[K:11]`
155. Siklus offline penuh — simpan → bertahan saat reload → flush otomatis saat online `[K:11]`
156. Jalur submit edge function (absensi, observasi, jurnal, kasus) mencapai server `[K:11]`
157. Pencatatan observasi siswa — offline-capable, validasi satu sekolah `[K:11]`
158. Akurasi banner status antrean ("menunggu sinkron" vs "tersimpan") `[K:11]`
159. Round-trip absensi — tersimpan dan tampil benar di rekap wali/kaprodi `[K:11]`

### O3. Alur Wali Kelas & Kaprodi
160. Scoping rekap — hanya kelas/program tanggung jawab sendiri (dari identitas server) `[K:12]`
161. Akurasi rekap kehadiran — tanggal sesi benar, sesi void dikecualikan `[K:12]`
162. Rekonsiliasi angka — kolom tampil menjumlah ke total dengan benar `[K:12]`
163. Konsistensi persentase kehadiran terhadap denominator `[K:12]`

### O4. Alur BK & Kasus
164. Pembuatan kasus — idempoten, validasi siswa satu sekolah `[K:13]`
165. Otorisasi tindakan kasus — hanya handler aktif atau KEPSEK yang bisa insert event `[K:13]`
166. Validasi target eskalasi — batas peran internal dan jalur DUDI → KAPRODI `[K:13]`
167. Authorship jejak audit — `author_user_id` dan `author_role_at_time` tidak bisa dipalsukan `[K:13]`
168. Append-only event kasus — UPDATE/DELETE diblokir `[K:13]`
169. Kunci kasus tertutup — tidak ada event baru pada kasus CLOSED `[K:13]`
170. Konsistensi `previous_status` / `previous_handler_role` di timeline `[K:13]`
171. Gating tombol aksi klien sesuai RLS server (hanya handler/KEPSEK) `[K:13]`

### O5. Alur Siswa & Orang Tua
172. Siswa hanya melihat data dirinya sendiri `[K:14]`
173. Orang tua hanya melihat data anaknya sendiri `[K:14]`
174. Jadwal dan kehadiran tampil benar di portal siswa/ortu `[K:14]`

### O6. Alur DUDI & PKL
175. Pembimbing DUDI hanya melihat siswa PKL binaannya `[K:15]`
176. Input absensi PKL oleh DUDI — validasi provenance dan student-match `[K:15]`

### O7. Alur Kepsek, Waka & Stakeholder
177. Dashboard monitoring hanya menampilkan data sekolah sendiri `[K:16]`
178. Agregat kehadiran (`fn_kepsek_monitoring`) — cakupan peran benar `[K:16]`

### O8. Setup Sekolah (E2E)
179. Impor massal siswa, guru, orang tua — idempoten, tanpa duplikat `[K:17]`
180. Pembukaan tahun ajaran dan semester `[K:17]`
181. Impor jadwal → penugasan mengajar → sesi absensi tersambung end-to-end `[K:17]`
