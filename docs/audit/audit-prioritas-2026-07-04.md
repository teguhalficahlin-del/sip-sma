# Prioritas Tindak Lanjut Audit — Platform Sekolah SMK

**Tanggal audit:** 4 Juli 2026
**Metode:** Analisis statik read-only, 181 item dari `00-audit-konsolidasi.md`
**Dokumen terkait:** `kesiapan-platform.md` (gerbang go-live), `temuan-total.md` (riwayat audit sebelumnya)

---

## Scorecard

| Status | Jumlah |
|---|---|
| ✅ LULUS | 114 |
| ⚠️ PERLU PERHATIAN | 48 |
| ❌ GAGAL | 4 |
| 🔵 Tidak dapat diverifikasi statik | 15 |
| **Total** | **181** |

---

## Catatan Verifikasi Bukti (4 Juli 2026)

Dokumen ini **hanya memuat item yang masih perlu perbaikan**, disajikan sebagai tabel. Kolom **Temuan & Bukti** memuat path + baris yang bisa diverifikasi langsung ke kode/migrasi. Kolom **Perbaikan** menjelaskan dampak dari **sisi pengguna** (guru, wali, siswa, DUDI, admin) — bukan istilah teknis.

Pada revisi terdahulu, **dua temuan dihapus** karena verifikasi menunjukkan sudah tertangani di kode live (celah penomoran **P2-B** & **P3-C** disengaja, agar huruf item lain tetap terlacak ke nomor sumbernya):

- **P2-B** — policy `rls_cases_update_sync` live sudah ter-scope (`school_id` + handler-match + kepsek), bukan `USING(TRUE)`.
- **P3-C** — tombol tutup kasus/laporan sudah punya konfirmasi dua-langkah inline.

**Atribusi migrasi P2-A dikoreksi** (klausa dihapus di `…130000`, bukan `…350000`), kesimpulan intinya tetap valid.

---

## Tabel Tindak Lanjut

<table>
<thead>
<tr>
<th rowspan="2">Kode</th>
<th rowspan="2">Temuan &amp; Bukti (path:baris)</th>
<th colspan="2">Perbaikan — dari sisi pengguna</th>
<th rowspan="2">Tindakan teknis</th>
</tr>
<tr>
<th>Sebelum</th>
<th>Sesudah</th>
</tr>
</thead>
<tbody>

<tr><td colspan="5">🔴 <strong>PRIORITAS 1 — BLOCKER GO-LIVE</strong></td></tr>

<tr>
<td><strong>P1-A</strong><br><em>Item 143</em></td>
<td><strong>Backup belum pernah diuji restore.</strong> Tabel "Catatan hasil latihan restore" berisi baris <code>_(belum)_</code> — <a href="../konsep/runbook-rilis-aman.md"><code>runbook-rilis-aman.md:113-118</code></a>. Dokumen menyatakan B2 SELESAI hanya bila ada verdikt <strong>BERHASIL</strong>.</td>
<td>Jika data sekolah rusak/terhapus massal, pemulihan jadi taruhan — tak ada yang tahu cadangan benar bisa dikembalikan.</td>
<td>Admin yakin data bisa dipulihkan karena sudah pernah diuji nyata, lengkap dengan catatan tanggal &amp; hasil "BERHASIL".</td>
<td>Restore 1× ke project Supabase terpisah, jalankan <code>tenant-isolation.mjs</code>, catat verdikt di runbook. ~2 jam.</td>
</tr>

<tr>
<td><strong>P1-B</strong><br><em>Item 92</em></td>
<td><strong>Portal DUDI tanpa offline queue.</strong> Tak ada <code>dudi/js/offline.js</code>; <code>saveAttendance()</code> upsert langsung lalu <code>throw error</code> saat gagal — <a href="../../dudi/js/api.js"><code>dudi/js/api.js:104-118</code></a>.</td>
<td>Pembimbing DUDI di lokasi PKL tanpa sinyal menekan "Simpan", mengira absensi tersimpan — padahal hilang diam-diam.</td>
<td>Absensi tersimpan di HP saat offline, muncul banner "menunggu koneksi", lalu terkirim otomatis begitu internet kembali.</td>
<td>Tambah <code>offline.js</code> (reuse pola <code>guru/js/offline.js</code>, store <code>pkl_att_queue</code>) + banner status. ~4 jam.</td>
</tr>

<tr><td colspan="5">🟠 <strong>PRIORITAS 2 — KEAMANAN &amp; INTEGRITAS DATA</strong></td></tr>

<tr>
<td><strong>P2-A</strong><br><em>Item 77</em></td>
<td><strong>WITH CHECK PKL tanpa <code>recorded_by_user_id</code>.</strong> Policy <code>rls_pkl_attendance_rw_dudi</code> — <a href="../../supabase/migrations/20260701350000_rls_fix_insert_bypass_all_tables.sql"><code>20260701350000…:44-46</code></a>. Klausa asli ada di <a href="../../supabase/migrations/20260630130000_pkl_attendance.sql"><code>20260630130000…:132</code></a>, hilang sejak <a href="../../supabase/migrations/20260701130000_rls_add_school_filter.sql"><code>20260701130000…:613</code></a>.</td>
<td>Absensi PKL bisa tercatat seolah ditulis pembimbing lain — keabsahan dokumen PKL bisa diragukan saat sengketa.</td>
<td>Setiap absensi PKL pasti tercatat atas nama pembimbing yang benar-benar menginputnya.</td>
<td>Tambah <code>AND recorded_by_user_id = fn_current_user_id()</code> ke WITH CHECK. ~30 mnt.</td>
</tr>

<tr>
<td><strong>P2-C</strong><br><em>Item 170</em></td>
<td><strong><code>previous_status: 'OPEN'</code> hardcode</strong> di <code>escalateCase()</code> — <a href="../../guru/js/api.js"><code>guru/js/api.js:754</code></a>. Bandingkan <code>changeCaseStatus</code>/<code>closeCase</code> yang dinamis.</td>
<td>Riwayat kasus siswa menampilkan perpindahan status yang salah (selalu "dari OPEN") — kronologi menyesatkan.</td>
<td>Riwayat kasus menampilkan status asal yang benar setiap kali kasus dieskalasi.</td>
<td>Baca status aktual dari server sebelum insert, atau RPC baca-dan-insert atomik. ~1 jam.</td>
</tr>

<tr>
<td><strong>P2-D</strong><br><em>Item 13</em></td>
<td><strong>Tak ada <code>audit_log</code> generik.</strong> Pencarian <code>audit_log</code> di seluruh <code>supabase/</code> = 0 berkas (dari 105 migrasi).</td>
<td>Jika observasi/kasus terhapus, tak ada cara menelusuri siapa yang menghapus dan kapan.</td>
<td>Setiap penghapusan penting meninggalkan jejak: siapa, apa, kapan — bisa ditelusuri saat sengketa.</td>
<td>Buat tabel <code>audit_log</code> + trigger DELETE di <code>observations</code>/<code>cases</code>/<code>case_events</code>. ~4 jam.</td>
</tr>

<tr><td colspan="5">🟡 <strong>PRIORITAS 3 — OPERASIONAL SEBELUM SEKOLAH PERTAMA</strong></td></tr>

<tr>
<td><strong>P3-A</strong><br><em>Item 6</em></td>
<td><strong>Token guru pengganti tak ada di UI.</strong> <code>sync_token</code> = 0 kemunculan di seluruh <code>.js</code>; hanya dipakai RLS <a href="../../supabase/migrations/20260701350000_rls_fix_insert_bypass_all_tables.sql"><code>20260701350000…:94-104</code></a>.</td>
<td>Guru pengganti tak bisa mengisi absensi — tak ada cara praktis mengirim token akses ke HP-nya.</td>
<td>Admin/wali kelas bisa menyalin &amp; mengirim token (via WA) agar guru pengganti langsung bisa mencatat kehadiran.</td>
<td>Tampilkan token di dashboard admin/panel wali kelas (bisa disalin).</td>
</tr>

<tr>
<td><strong>P3-B</strong><br><em>Item 4</em></td>
<td><strong><code>WAKA_HUMAS</code> belum ada di enum contracts.</strong> <a href="../../contracts/09_event_schema.js"><code>contracts/09_event_schema.js:37-47</code></a> — enum <code>ROLE_TYPE</code> tanpa <code>WAKA_HUMAS</code> (DB sudah punya via <a href="../../supabase/migrations/20260704090000_waka_humas_enum.sql"><code>20260704090000</code></a>).</td>
<td>Akun WAKA HUMAS bisa berperilaku tak konsisten (menu/izin) karena perannya belum dikenali penuh sisi aplikasi.</td>
<td>WAKA HUMAS dikenali konsisten; menu &amp; izin tampil sesuai perannya.</td>
<td>Tambah <code>'WAKA_HUMAS'</code> ke array <code>ROLE_TYPE</code>. ~15 mnt.</td>
</tr>

<tr>
<td><strong>P3-D</strong><br><em>Item 79</em></td>
<td><strong>Propagasi nama siswa satu arah.</strong> Trigger <code>student_name_sync</code> hanya <code>AFTER UPDATE OF full_name ON students</code> — <a href="../../supabase/migrations/20260704000000_sync_student_name_to_user.sql"><code>20260704000000…:37-42</code></a>. Tak ada arah balik <code>users → students</code>.</td>
<td>TU memperbaiki nama siswa di satu tempat, tapi di portal lain nama lama masih muncul — data tak sinkron.</td>
<td>Perbaikan nama siswa langsung seragam di semua portal (siswa, wali, guru).</td>
<td>Tambah trigger arah balik, atau kunci <code>users.full_name</code> agar hanya lewat jalur resmi. ~1 jam.</td>
</tr>

<tr>
<td><strong>P3-E</strong><br><em>Item 34</em></td>
<td><strong>Kontras placeholder gagal WCAG AA (≈2.8:1).</strong> <code>::placeholder { color: rgba(255,255,255,0.30) }</code> di <strong>6</strong> CSS: guru:32, dudi:33, parent:32, student:32, admin:33, stakeholder:32.</td>
<td>Teks petunjuk di kolom isian nyaris tak terbaca (abu samar) — menyulitkan di layar terang / mata lelah.</td>
<td>Teks petunjuk cukup kontras dan mudah dibaca semua pengguna.</td>
<td>Naikkan opacity ke <code>rgba(255,255,255,0.50)</code> di 6 file CSS. ~30 mnt.</td>
</tr>

<tr>
<td><strong>P3-F</strong><br><em>Item 16, 26</em></td>
<td><strong>Istilah sentimen tak seragam.</strong> Guru "Negatif" — <a href="../../guru/dashboard.html"><code>guru/dashboard.html:89</code></a> vs DUDI "Perlu Perhatian" — <a href="../../dudi/js/dashboard.js"><code>dudi/js/dashboard.js:457</code></a>. Nilai DB sama (<code>NEGATIF</code>).</td>
<td>Observasi negatif ditulis beda antar-portal — guru yang membaca observasi DUDI jadi bingung.</td>
<td>Istilah seragam ("Perlu Perhatian") di semua portal; makna sama, tak membingungkan.</td>
<td>Satukan label tampilan, tetap <code>NEGATIF</code> sebagai nilai DB. ~1 jam.</td>
</tr>

<tr><td colspan="5">🔵 <strong>PRIORITAS 4 — PERBAIKAN PROSES RILIS</strong> (sisi tim developer/operator)</td></tr>

<tr>
<td><strong>P4-A</strong><br><em>Item 135, 139</em></td>
<td><strong>Mayoritas migrasi tanpa rollback tertulis.</strong> Hanya <strong>4 dari 105</strong> file migrasi memuat blok <code>-- ROLLBACK</code>.</td>
<td>Kalau sebuah perubahan database bermasalah, tim tak punya langkah baku membatalkannya — pemulihan lambat &amp; berisiko.</td>
<td>Tiap perubahan punya langkah pembatalan tertulis — pemulihan cepat saat ada masalah.</td>
<td>Template migrasi wajib berisi blok <code>-- SNAPSHOT PRA-APPLY</code> &amp; <code>-- ROLLBACK</code>.</td>
</tr>

<tr>
<td><strong>P4-B</strong><br><em>Item 147</em><br>🔵 runtime</td>
<td><strong>Konsistensi <code>schema_migrations</code> belum terverifikasi.</strong> Apply manual via <code>supabase db query --linked</code> — belum dibuktikan statik.</td>
<td>Tim tak yakin semua perubahan database tercatat resmi — risiko beda diam-diam antar lingkungan.</td>
<td>Ada verifikasi semua migrasi tercatat — kondisi database bisa dipercaya.</td>
<td>Bandingkan daftar file <code>migrations/</code> vs isi tabel <code>schema_migrations</code> live.</td>
</tr>

<tr>
<td><strong>P4-C</strong><br><em>Item 14, 15, 87</em></td>
<td><strong>Kontrak offline melampaui implementasi.</strong> 13 kemunculan "Background Sync"/<code>dead_letter</code>/<code>conflict_queue</code> di <a href="../../contracts/12_offline_sync_reference.md"><code>contracts/12_offline_sync_reference.md</code></a> tanpa label <code>[PLANNED]</code>.</td>
<td>Developer baru mengira fitur canggih (sinkronisasi latar) sudah ada, padahal belum.</td>
<td>Bagian yang belum ada ditandai <code>[PLANNED]</code> — tak ada salah paham.</td>
<td>Tandai bagian belum-terimplementasi dengan <code>[PLANNED]</code>.</td>
</tr>

<tr><td colspan="5">⚪ <strong>PRIORITAS 5 — UX &amp; VISUAL (Pasca Go-Live)</strong></td></tr>

<tr>
<td><strong>P5-A</strong><br><em>Item 39</em></td>
<td><strong>Tak ada <code>@media print</code>.</strong> 0 kemunculan di seluruh CSS portal.</td>
<td>Saat mencetak rekap/laporan, hasilnya berantakan (menu ikut, latar gelap, tabel terpotong).</td>
<td>Hasil cetak rapi: tanpa navigasi, latar putih, tabel utuh.</td>
<td>Tambah <code>@media print</code>: sembunyikan nav, background putih, tabel tak terpotong.</td>
</tr>

<tr>
<td><strong>P5-B</strong><br><em>Item 88</em></td>
<td><strong>Manifest Stakeholder &amp; Admin tanpa ikon PNG.</strong> Glob <code>{stakeholder,admin}/**/*.png</code> = 0 berkas.</td>
<td>Portal Stakeholder &amp; Admin tak menawarkan "pasang aplikasi" di sebagian HP/browser.</td>
<td>Kedua portal bisa dipasang seperti aplikasi di semua perangkat.</td>
<td>Tambah PNG 192×192 &amp; 512×512 ke kedua manifest.</td>
</tr>

<tr>
<td><strong>P5-C</strong><br><em>Item 31</em><br>⏳ belum re-verif</td>
<td><strong>Pola feedback tak seragam</strong> (<code>.status-msg</code>/<code>.alert</code>/<code>span</code> inline). <em>Belum diverifikasi ulang pada pass ini</em> — perlu grep silang antar-portal.</td>
<td>Pesan sukses/gagal tampil beda gaya antar layar — terasa tidak rapi.</td>
<td>Semua pesan status seragam gayanya di seluruh portal.</td>
<td>Pilih satu pola, terapkan konsisten.</td>
</tr>

<tr>
<td><strong>P5-D</strong><br><em>Item 49</em></td>
<td><strong>Textarea observasi guru tanpa counter.</strong> <a href="../../guru/dashboard.html"><code>guru/dashboard.html</code></a> hanya 1 pola <code>maxlength|/1000|counter</code> (kemungkinan <code>maxlength</code> saja), tanpa counter live seperti DUDI.</td>
<td>Guru menulis observasi tanpa tahu sisa batas karakter — bisa terpotong tak terduga.</td>
<td>Guru melihat penghitung "0/1000" seperti di portal DUDI.</td>
<td>Tambah counter karakter live pada textarea observasi guru.</td>
</tr>

<tr>
<td><strong>P5-E</strong><br><em>Item 38</em></td>
<td><strong>Platform dark-only.</strong> <code>prefers-color-scheme</code> = 0 kemunculan di seluruh CSS.</td>
<td>Aplikasi selalu gelap — kurang nyaman dibaca di bawah cahaya terang, terutama siswa/orang tua.</td>
<td>Tersedia mode terang mengikuti preferensi perangkat.</td>
<td>Tambah <code>@media (prefers-color-scheme: light)</code> minimal untuk portal siswa &amp; orang tua.</td>
</tr>

<tr><td colspan="5">🔵 <strong>PERLU AKSI MANUAL</strong> (runtime/dashboard — tak dapat dibuktikan statik)</td></tr>

<tr>
<td><strong>Item 68</strong></td>
<td>Cek Supabase Storage: adakah bucket? Jika ada, pastikan RLS ter-scope <code>school_id</code>.</td>
<td>Jika ada file diunggah, ada risiko bocor lintas sekolah (belum dipastikan).</td>
<td>File tiap sekolah dijamin terisolasi.</td>
<td>Cek dashboard Storage + policy bucket.</td>
</tr>

<tr>
<td><strong>Item 127/142</strong></td>
<td>Cek Supabase Dashboard → Backups: konfirmasi backup otomatis aktif.</td>
<td>Belum dipastikan cadangan harian benar berjalan.</td>
<td>Backup otomatis terkonfirmasi aktif.</td>
<td>Cek panel Backups.</td>
</tr>

<tr>
<td><strong>Item 145</strong></td>
<td>Ekspor data per sekolah belum ada di codebase.</td>
<td>Sekolah yang berhenti tak bisa membawa datanya keluar (offboarding).</td>
<td>Tersedia ekspor data lengkap per sekolah.</td>
<td>Implementasikan ekspor sebelum ada permintaan offboarding.</td>
</tr>

<tr>
<td><strong>Item 176</strong></td>
<td>Verifikasi <a href="../../supabase/migrations/20260630130000_pkl_attendance.sql"><code>20260630130000_pkl_attendance.sql</code></a> — <code>rls_pkl_attendance_rw_dudi</code> mengikat DUDI ke placement miliknya (<code>fn_dudi_supervises_student</code>).</td>
<td>Perlu pastikan DUDI hanya melihat siswa placement-nya sendiri.</td>
<td>Terkonfirmasi DUDI terikat ke placement sendiri.</td>
<td>Uji runtime dengan akun DUDI lintas placement.</td>
</tr>

</tbody>
</table>

---

## Ringkasan Urutan Pengerjaan

```
SEKARANG (sebelum go-live):
  P1-A  Uji restore backup            ~2 jam   ← BLOCKER K:7
  P1-B  Offline queue DUDI            ~4 jam   ← BLOCKER K:18
  P2-A  Fix RLS PKL recorded_by       ~30 mnt
  P2-C  Fix previous_status eskalasi  ~1 jam
  P2-D  Audit log destruktif          ~4 jam

MINGGU PERTAMA SETELAH GO-LIVE:
  P3-A  Token guru pengganti (UI)
  P3-B  WAKA_HUMAS ke contracts enum  ~15 mnt
  P3-D  Propagasi nama siswa 2 arah   ~1 jam
  P3-E  Perbaiki kontras placeholder  ~30 mnt
  P3-F  Konsistensi istilah sentimen  ~1 jam

BULAN PERTAMA:
  P4-A  Template rollback per migrasi
  P4-B  Verifikasi schema_migrations
  P4-C  Selaraskan kontrak offline
  P5-A  @media print
  P5-B  PNG icon manifest stakeholder/admin
  P5-C  Standarkan pola feedback
  P5-D  Counter textarea observasi guru
  P5-E  Light mode (portal siswa & ortu)
```

---

*Dokumen ini adalah hasil audit statik. Item bertanda 🔵 memerlukan verifikasi runtime atau akses Supabase dashboard untuk dikonfirmasi.*
