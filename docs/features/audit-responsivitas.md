# Audit Responsivitas — Portal Guru, Siswa, Orang Tua, DUDI & Stakeholder

**Tanggal audit:** 18 Juli 2026  
**Metode:** Read-only — inspeksi CSS statik + pengukuran computed style via JavaScript browser + screenshot langsung di viewport yang di-resize + analisis matematis lebar flex/grid  
**Viewport utama yang diuji:** 375×667 (iPhone SE 2nd gen, baseline minimum), 360px (lebar Android umum), simulasi 480px boundary

---

## Ringkasan Eksekutif

Portal guru secara umum sudah responsif untuk kasus dasar: layout utama tidak overflow horizontal, bottom nav berfungsi, form observasi dan absensi carousel rapi di mobile. Namun ditemukan **3 bug layout yang perlu diperbaiki** dan **5 masalah visual/UX** yang perlu diperhatikan sebelum go-live dengan banyak pengguna.

| Severity | Jumlah |
|---|---|
| 🔴 Bug (layout rusak / membingungkan pengguna) | 3 |
| 🟡 Degradasi visual (fungsional tapi tidak optimal) | 3 |
| 🔵 Minor / polish | 3 |

---

## Metodologi

1. Browser di-resize ke 375×667
2. Auth state di-bypass via JS injection (file:// URL, bukan server live) — data dummy diisi untuk mengaktifkan elemen
3. Setiap tab diaktifkan satu per satu; computed styles dan bounding rect diukur via `getBoundingClientRect()` + `getComputedStyle()`
4. Screenshot diambil per tab untuk konfirmasi visual
5. CSS `guru/css/guru.css` dan seluruh HTML `guru/dashboard.html` dibaca lengkap

---

## Bug Layout (🔴 Harus Diperbaiki)

---

### BUG-1 — Label "s/d:" terputus dari inputnya (Tab BK & Waka Kesiswaan)

**Lokasi:**
- `tab-bk` — baris 300–306 `dashboard.html`
- `tab-waka_kesiswaan` — baris 540–546 `dashboard.html`

**Apa yang terjadi:**  
Kedua tab menggunakan pola date-row yang berbeda dari tab lainnya: `display:flex; flex-wrap:wrap` secara inline, bukan class `.date-row`. Di 375px dengan lebar konten tersedia ~331px:

- Baris 1: `"Dari:"` (30px) + input tanggal (166px) + `"s/d:"` (30px) = 226px → **semua masuk baris 1**
- Input tanggal kedua (166px) tidak muat sisa ruang (105px) → **wrap ke baris 2**
- Filter button juga masuk baris 2 bersama input kedua

**Hasilnya:** Label `"s/d:"` mengambang sendirian di ujung baris 1, sementara input pasangannya ada di baris 2. Terkonfirmasi lewat screenshot — `rowHeight: 98px` (2 baris).

```
┌─────────────────────────────────────────┐
│ Dari:  [mm/dd/yyyy 📅]           s/d:  │  ← "s/d:" terpisah dari inputnya
│ [mm/dd/yyyy 📅]   [Filter]             │
└─────────────────────────────────────────┘
```

**Dampak:** Membingungkan — pengguna tidak tahu label "s/d:" mengacu ke input mana.

**Solusi:** Ganti inline flex menjadi class `.date-row` yang sudah ada (sudah menggunakan CSS grid 2 kolom di ≤640px dan memasangkan label+input dengan benar). Alternatif: bungkus masing-masing label+input dalam `div` flex row sendiri, seperti pola di Kepsek yang sudah benar.

---

### BUG-2 — Tombol "Tampilkan" muncul di atas input tanggalnya (Tab Waka Kurikulum)

**Lokasi:** `tab-waka_kurikulum` — baris 603–613, section "Sesi Belum Diisi — Rentang Waktu"

**Apa yang terjadi:**  
Header section menggunakan `display:flex; justify-content:space-between; flex-wrap:wrap`:

```html
<div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px">
    <h2>Sesi Belum Diisi — Rentang Waktu</h2>
    <button id="wk-kur2-btn">Tampilkan</button>
</div>
```

Di 375px, judul "Sesi Belum Diisi — Rentang Waktu" (~247px di 15px bold) + tombol "Tampilkan" (~90px) = 337px > 331px tersedia → **tombol wrap ke baris berikutnya**. Tombol "Tampilkan" lalu muncul **di atas** input tanggal Dari/s/d yang berada di elemen setelahnya.

```
┌─────────────────────────────────────────┐
│ Sesi Belum Diisi — Rentang Waktu        │
│ [Tampilkan]                             │  ← tombol submit tampil SEBELUM inputnya
│ Dari  [mm/dd/yyyy 📅]   s/d            │
│ [mm/dd/yyyy 📅]                        │
└─────────────────────────────────────────┘
```

**Dampak:** Urutan visual terbalik — tombol submit tampil sebelum field yang harus diisi. Pengguna mungkin klik "Tampilkan" sebelum isi tanggal.

**Solusi:** Pisahkan tombol dari header row — pindahkan tombol ke bawah input tanggal, atau sederhanakan judul section (e.g. "Rentang Waktu") agar header fit dalam satu baris di 375px.

---

### BUG-3 — Dua tombol overlap di date-row saat "Unduh Excel" muncul (Tab Wali Kelas)

**Lokasi:** `tab-wali_kelas` — baris 279–287 `dashboard.html`

**Apa yang terjadi:**  
CSS breakpoint ≤640px mengubah `.date-row` menjadi grid 2 kolom dan menempatkan semua `button` di `grid-column:2; grid-row:3`:

```css
.date-row button { grid-column: 2; grid-row: 3; justify-self: end; }
```

Tab Wali Kelas punya **dua tombol** di dalam `.date-row`: "Filter" dan "Unduh Excel" (awalnya `display:none`). Ketika "Unduh Excel" ditampilkan (setelah data berhasil dimuat), CSS menempatkan **kedua tombol di koordinat grid yang sama** → keduanya **overlap persis di atas satu sama lain**.

**Dampak:** Tombol "Filter" tidak bisa diklik ketika "Unduh Excel" tampil karena tertutup. Skenario ini terjadi setiap kali user berhasil memfilter data.

**Solusi:** Bungkus kedua tombol dalam `<div class="date-row-actions">` lalu target div itu dengan grid placement, bukan `button` secara langsung. Atau pindahkan tombol "Unduh Excel" ke luar `.date-row`, e.g. di pojok kanan judul section.

---

## Degradasi Visual (🟡 Perlu Diperhatikan)

---

### DEG-1 — Stats grid Waka Kurikulum terlalu sempit di mobile

**Lokasi:** `tab-waka_kurikulum` — baris 560 & 614

**Apa yang terjadi:**  
Dua stats grid (`wk-kur-stats-row` dan `wk-kur2-stats-row`) menggunakan `grid-template-columns:repeat(3,1fr)` sebagai **inline style**. Karena inline, CSS media query di `guru.css` tidak bisa meng-override breakpoint ini.

Di 375px:
- Konten tersedia: ~331px → tiap cell: (331 − 24px gap) / 3 = **102px**
- Cell padding 16px tiap sisi: content width = **70px**
- Label "Sudah isi absensi" (13px font) di 70px: **wrap ke 2 baris**
- Cell terukur: 110×116px (tinggi 116px karena label 2-baris)

Di 360px kondisi makin sempit (97px cell, 65px content).

**Dampak:** Kartu stat terlihat cramped dan tidak proporsional; angka besar (28px) tidak punya napas visual. Terkonfirmasi via screenshot.

**Solusi:** Pindahkan definisi grid ke CSS class, tambahkan breakpoint `@media (max-width: 480px) { .wk-stats-grid { grid-template-columns: 1fr 1fr; } }` agar di 375px menampilkan 2+1 layout, atau stack ke 1 kolom.

---

### DEG-2 — Nama sekolah panjang merusak tinggi header

**Lokasi:** `guru.css` baris 97–101; `.app-header h2`

**Apa yang terjadi:**  
Header menggunakan flex row: `[nama sekolah (flex:1)] [info user] [bell] [tombol keluar]`. Elemen `h2` (nama sekolah) punya `flex:1` tapi tidak ada `white-space:nowrap`, `overflow:hidden`, atau `text-overflow:ellipsis`. Nama seperti "SMK Karya Bangsa Nusantara Jaya" (>25 karakter, ~14px) akan **wrap ke 2 baris** di dalam flex item dan mendorong header menjadi sangat tinggi.

Di 375px, ruang untuk h2 hanya ~57px (setelah info-user + bell + logout). Nama sekolah apa pun yang lebih panjang dari 8 karakter akan wrap.

**Dampak:** Header setinggi 80–110px (bukan 66px normal) → memotong konten halaman secara signifikan di layar kecil.

**Solusi:**
```css
@media (max-width: 640px) {
    .app-header h2 {
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }
}
```

---

### DEG-3 — Kepsek period buttons: 3 baris di 375px

**Lokasi:** `tab-kepsek` — baris 673–679

**Apa yang terjadi:**  
5 tombol preset (`flex-wrap:wrap; white-space:nowrap`) terbagi ke 3 baris di 375px:
- Baris 1: "7 Hari Terakhir" (116px) + "Hari Ini" (103px) = 223px
- Baris 2: "Minggu Lalu" (103px) + "Bulan Lalu" (163px) = 270px
- Baris 3: "Tahun Ajaran Lalu" (163px)

**Dampak:** 3 baris tombol + divider + 2 input tanggal = konten card ini sangat panjang sebelum chart bahkan muncul. Di 375×667, user perlu scroll sebelum melihat chart. Fungsional, tapi tidak ideal untuk overview KPI kepsek.

**Solusi:** Pertimbangkan menu dropdown "Pilih Periode" untuk preset di mobile, atau 2-kolom button grid. Atau cukup persingkat label: "7 Hari" / "Hari Ini" / "Minggu Lalu" / "Bulan Lalu" / "Tahun Lalu" untuk menghemat 1 baris.

---

## Minor / Polish (🔵 Perbaikan Kualitas)

---

### MIN-1 — Sync banner tertimpa bottom nav saat keduanya aktif

**Lokasi:** `guru.css` baris 266; `.sync-banner` + `.bottom-nav`

**Apa yang terjadi:**  
Ketika user offline dan melakukan aksi, `.sync-banner` tampil di `bottom:0; z-index:2000`. Bottom nav floating pill ada di `bottom:12px; z-index:200`. Karena z-index banner (2000) lebih tinggi dari nav (200), banner tampil **di atas** pill, menutupi ~22px bagian bawah pill nav (area icon/label).

**Solusi:** Beri banner offset yang menghitung tinggi nav: `bottom: calc(12px + 57px + env(safe-area-inset-bottom, 0))` — atau naikkan banner dari bawah saat aktif via JS yang menambahkan class.

---

### MIN-2 — Bottom nav tanpa indikator scroll untuk role dengan 7+ tab

**Lokasi:** `guru.css` baris 344–349; `.bottom-nav-inner { overflow-x:auto; scrollbar-width:none }`

**Apa yang terjadi:**  
Role seperti Wali Kelas yang juga mengajar memiliki 7 tab: Dashboard Guru, Wali Kelas, Pembinaan Siswa, Catatan Siswa, Jurnal Mengajar, Kurikulum Merdeka, Forum Kelas. Dengan `min-width:52px` per tab, total 7×52 = 364px > 335px (lebar pill nav di 375px) → tab overflow dan harus di-scroll. Scrollbar disembunyikan (`scrollbar-width:none`).

Tidak ada indikasi visual bahwa masih ada tab di luar viewport (fade gradient, arrow hint, dsb).

**Solusi:** Tambahkan gradient fade di sisi kanan pill saat konten overflow:
```css
.bottom-nav-inner::after {
    content: '';
    position: sticky;
    right: 0;
    width: 24px;
    flex-shrink: 0;
    background: linear-gradient(to right, transparent, rgba(11,17,32,.96));
}
```

---

### MIN-3 — Canvas chart kepsek tanpa `width:100%` eksplisit

**Lokasi:** `tab-kepsek` — baris 705–706

**Apa yang terjadi:**  
Container canvas: `style="position:relative;height:220px"` tanpa `width` eksplisit. Responsivitas chart bergantung sepenuhnya pada Chart.js `responsive:true`. Tidak ada CSS fallback `canvas { width: 100% !important; max-width: 100%; }`.

Pada beberapa kondisi (render sebelum layout stabil, atau jika Chart.js gagal mendeteksi parent width), canvas bisa terlalu lebar dan menyebabkan horizontal scroll.

**Solusi:** Tambahkan `width:100%` ke container:
```html
<div style="position:relative;height:220px;width:100%">
```

---

## Yang Sudah Benar ✅

Untuk konteks, berikut hal yang sudah berfungsi baik di mobile dan tidak perlu diubah:

| Komponen | Status |
|---|---|
| Bottom nav pill design (icon + label + scroll) | ✅ Benar |
| Attendance carousel (1 siswa per slide) | ✅ Benar |
| Form observasi (fields stack column) | ✅ Benar |
| Kepsek date range (label dipasangkan per baris) | ✅ Benar |
| Kaprodi form: 1 kolom di ≤480px | ✅ Benar |
| Modal lebar: `min(560px, 100vw-32px)` | ✅ Benar |
| Body tidak horizontal overflow | ✅ Terkonfirmasi |
| `.table-wrapper { overflow-x:auto }` | ✅ Benar |
| `env(safe-area-inset-bottom)` di nav & page-body | ✅ Benar |
| Tombol utama full-width di mobile | ✅ Benar |
| Att-row stack column di ≤480px | ✅ Benar |
| Login card responsive | ✅ Benar |

---

## Prioritas Perbaikan

| # | Bug/Temuan | Severity | File | Perkiraan Effort |
|---|---|---|---|---|
| 1 | BUG-3: Tombol Filter & Unduh Excel overlap di Wali Kelas | 🔴 | `dashboard.html:285` | Kecil |
| 2 | BUG-1: Label "s/d:" orphan di BK & Waka Kesiswaan | 🔴 | `dashboard.html:300,540` | Kecil |
| 3 | BUG-2: Tombol "Tampilkan" di atas input tanggal (Waka Kurikulum) | 🔴 | `dashboard.html:606` | Kecil |
| 4 | DEG-2: Header nama sekolah panjang wrap | 🟡 | `guru.css:98` | Trivial |
| 5 | DEG-1: Stats grid Waka Kurikulum terlalu sempit | 🟡 | `dashboard.html:560,614` | Sedang |
| 6 | DEG-3: Kepsek period buttons 3 baris | 🟡 | `dashboard.html:673` | Sedang |
| 7 | MIN-1: Sync banner tertimpa pill nav | 🔵 | `guru.css:266` | Kecil |
| 8 | MIN-2: Tidak ada indikator scroll bottom nav | 🔵 | `guru.css:350` | Kecil |
| 9 | MIN-3: Canvas chart tanpa `width:100%` | 🔵 | `dashboard.html:705` | Trivial |

---

---

# Portal Siswa — Audit Responsivitas

**Tanggal:** 18 Juli 2026  
**File:** `student/dashboard.html`, `student/css/student.css`, `student/js/dashboard.js`  
**Metode:** Analisis CSS + HTML statik + perhitungan matematis lebar flex; browser tidak dapat digunakan untuk screenshot (file:// cross-file navigation tidak didukung di session ini)

---

## Tab yang Ada

| Status siswa | Tab yang muncul |
|---|---|
| AKTIF (non-PKL) | Jadwal, Kehadiran, Catatan, Forum (4 tab) |
| PKL | Kehadiran, Catatan, Forum, PKL (4 tab — Jadwal diganti PKL) |

---

## Ringkasan Temuan

| Severity | Jumlah |
|---|---|
| 🔴 Bug (layout rusak / perilaku salah) | 3 |
| 🟡 Degradasi visual | 2 |
| 🔵 Minor / polish | 3 |

---

## Bug Layout (🔴)

---

### BUG-S1 — Input tanggal terlalu sempit di Tab Kehadiran & Observasi (≤480px)

**Lokasi:** `student/dashboard.html` baris 87–93 (tab kehadiran), baris 112–118 (tab observasi)

**Apa yang terjadi:**  
Kedua tab menggunakan class `.date-row` dengan pola: label + input + label + input + button — total 5 item dalam satu flex container.

Di `student.css` breakpoint ≤480px:
```css
.date-row input[type="date"] { flex: 1; min-width: 0; }
```
`flex:1` membuat tiap input *bertumbuh* untuk berbagi sisa ruang di baris yang sama. Di 375px:
- Ruang tersedia: 375 − 24px padding − 20px card padding = **331px**
- Item fixed: `"Dari:"` (≈30px) + gap + `"s/d:"` (≈30px) + gap + `[Filter]` (≈85px) + 4×gap(10px) = **185px**
- Sisa untuk 2 input: 331 − 185 = **146px → 73px per input**

Date input Chrome/WebKit menampilkan `mm/dd/yyyy 📅`. Di 73px, teks terpotong — format tanggal tidak terbaca sepenuhnya.

Di **360px** kondisi lebih parah: (360−44−185)/2 = **65.5px per input** — sangat sempit.

```
┌──────────────────────────────────────┐
│ Dari: [mm/dd 📅]  s/d: [mm/dd 📅] [Filter] │  ← semua satu baris, input 73px
└──────────────────────────────────────┘
```

**Dampak:** Pengguna tidak bisa membaca tanggal yang dipilih dengan jelas.

**Solusi:** Gunakan pola column-stacked seperti di Kepsek guru portal — masing-masing label + input dalam satu `div` flex row sendiri:
```html
<div style="display:flex;flex-direction:column;gap:6px">
  <div style="display:flex;align-items:center;gap:8px">
    <label style="min-width:32px">Dari:</label>
    <input type="date" class="input" style="flex:1">
  </div>
  <div style="display:flex;align-items:center;gap:8px">
    <label style="min-width:32px">s/d:</label>
    <input type="date" class="input" style="flex:1">
    <button class="btn btn-secondary btn-sm">Filter</button>
  </div>
</div>
```

---

### BUG-S2 — Tab Forum tidak punya `.page-body` — konten render tanpa padding

**Lokasi:** `student/dashboard.html` baris 166–173

**Apa yang terjadi:**  
Semua tab lain membungkus kontennya dalam `<div class="page-body">` yang memberikan `padding: 16px 12px` (≤640px) dan `max-width: 1100px`. Tab Forum adalah satu-satunya yang tidak:

```html
<div class="tab-panel" id="tab-forum">
    <div id="forum-loading" class="hint">Memuat forum…</div>
    <div id="forum-posts-list"></div>      <!-- tidak ada .page-body! -->
    <button id="btn-load-more-forum" ...>Muat lebih banyak</button>
</div>
```

**Dampak:**
1. Forum posts di `#forum-posts-list` merender dari edge ke edge layar — tanpa margin horizontal — teks dan kartu forum menempel ke tepi kiri/kanan layar
2. Tombol "Muat lebih banyak" punya `margin: 16px auto` tapi sebagai `inline-flex` tanpa `display:block` atau `width` eksplisit, centering-nya bergantung pada parent yang tidak punya lebar terdefinisi
3. Konten forum bisa overflow ke kiri saat konten dinamis (misalnya gambar atau tabel) dirender

**Solusi:** Bungkus konten forum dalam `.page-body`:
```html
<div class="tab-panel" id="tab-forum">
    <div class="page-body">
        <div id="forum-loading" class="hint">Memuat forum…</div>
        <div id="forum-posts-list"></div>
        <button id="btn-load-more-forum" class="btn btn-secondary"
            style="display:none; display:block; margin:16px auto; width:fit-content">
            Muat lebih banyak
        </button>
    </div>
</div>
```

---

### BUG-S3 — Kolom "Status" tersembunyi di tabel PKL saat ≤480px

**Lokasi:** `student/css/student.css` baris 278–279; `student/dashboard.html` baris 154–156

**Apa yang terjadi:**  
CSS global untuk menyederhanakan tabel di mobile:
```css
@media (max-width: 480px) {
    .table td:nth-child(2),
    .table th:nth-child(2) { display: none; }
}
```

Rule ini dimaksudkan untuk menyembunyikan kolom "Jam" di tabel kehadiran siswa (`Tanggal | Jam | Mata Pelajaran | Guru | Status`). Ini benar untuk tabel kehadiran.

Namun rule yang sama berlaku pada tabel PKL recap (`Tanggal | Status | Catatan`). Di sini kolom ke-2 adalah **"Status"** (Hadir/Izin/Sakit/Alpa) — kolom yang paling penting. Di 375px, tabel PKL hanya tampilkan:

```
┌──────────────────────┐
│ Tanggal   │ Catatan  │  ← "Status" hilang di 375px!
│ 01/07     │ —        │
│ 02/07     │ —        │
└──────────────────────┘
```

Siswa PKL tidak bisa melihat status kehadiran mereka di mobile.

**Solusi:** Buat rule lebih spesifik — targetkan hanya kolom "Jam" di tabel kehadiran, bukan semua tabel:
```css
@media (max-width: 480px) {
    #att-table td:nth-child(3),
    #att-table th:nth-child(3) { display: none; }  /* Mata Pelajaran — kolom terpanjang */
}
```
Atau beri class spesifik ke kolom yang ingin disembunyikan: `<th class="hide-mobile">Jam</th>`.

---

## Degradasi Visual (🟡)

---

### DEG-S1 — 5 stat cards: layout 2+2+1 dengan kartu terakhir sendirian

**Lokasi:** `student/dashboard.html` baris 78–84 (kehadiran), 144–150 (PKL)

**Apa yang terjadi:**  
Kehadiran dan PKL masing-masing menampilkan 5 stat cards: Hadir / Izin / Sakit / Alpa / % Hadir.

Di `student.css` ≤480px:
```css
.stat-card { min-width: calc(50% - 6px); }
```
5 kartu dengan lebar 50%: layout → **2 + 2 + 1**. Kartu "% Hadir" sendirian di baris ketiga dengan lebar penuh. Secara visual, "% Hadir" tampak lebih dominan dari 4 stat lainnya, padahal secara hierarki informasi ia tidak lebih penting.

**Solusi opsi A:** Ubah ke 3+2 dengan satu breakpoint tambahan:
```css
@media (max-width: 480px) {
    .stat-card:nth-child(-n+3) { min-width: calc(33.333% - 8px); }  /* 3 di baris 1 */
    .stat-card:nth-child(n+4)  { min-width: calc(50% - 6px); }       /* 2 di baris 2 */
}
```
**Solusi opsi B:** Gunakan 5 kolom dengan scroll horizontal, atau reorder agar "% Hadir" jadi kartu ke-1 (paling penting di urutan pertama).

---

### DEG-S2 — Nama sekolah panjang bisa merusak tinggi header (sama dengan guru portal)

**Lokasi:** `student/css/student.css` baris 88

**Apa yang terjadi:** Identik dengan temuan DEG-2 di portal guru — `.app-header h2 { flex:1 }` tanpa constraint overflow. Nama sekolah panjang akan wrap dan mendorong header jauh lebih tinggi dari 66px normal.

**Solusi:**
```css
@media (max-width: 640px) {
    .app-header h2 {
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }
}
```

---

## Minor / Polish (🔵)

---

### MIN-S1 — Tab Forum menggunakan ikon fallback `ti-circle` di bottom nav

**Lokasi:** `student/js/dashboard.js` baris 129

**Apa yang terjadi:**
```js
const TAB_ICON = {
    jadwal: 'ti-calendar',
    kehadiran: 'ti-clipboard-check',
    observasi: 'ti-notes',
    pkl: 'ti-briefcase'
    // 'forum' tidak ada!
};
// Bottom nav: TAB_ICON[t.key] ?? 'ti-circle'
```
Tab Forum di bottom nav menampilkan ikon lingkaran kosong (`ti-circle`) — fallback yang tidak bermakna. Semua tab lain punya ikon deskriptif.

**Solusi:** Tambahkan satu entri:
```js
const TAB_ICON = { ..., forum: 'ti-messages' };
```

---

### MIN-S2 — Tombol `.btn` (tanpa `.btn-sm`) di bawah 44px touch target

**Lokasi:** `student/css/student.css` baris 37–42; `student/dashboard.html` baris 169

**Apa yang terjadi:**  
`.btn-sm` punya `min-height: 44px`, tapi `.btn` dasar tidak. Tombol "Muat lebih banyak" di forum menggunakan `.btn.btn-secondary` (tanpa `.btn-sm`) sehingga tingginya hanya dari padding: `10+14+10 = 34px` — di bawah 44px touch target minimum (WCAG 2.5.5).

**Solusi:** Tambahkan `min-height: 44px` ke `.btn` dasar:
```css
.btn { ... min-height: 44px; }
```

---

### MIN-S3 — Notif dropdown bisa overflow kiri layar di HP sangat sempit

**Lokasi:** `student/css/student.css` baris 150–162; `.notif-dropdown { width:300px; right:0 }`

**Apa yang terjadi:**  
Dropdown notifikasi lebar 300px, diposisikan `right:0` relatif ke container tombol bell. Pada layar sempit (misalnya 320px — iPhone SE gen 1, atau beberapa Android murah), jika posisi container bell di ~310px dari kiri, maka dropdown kiri = 310−300 = 10px (masih aman). Tapi jika header layout berubah dan bell lebih ke kiri, dropdown bisa keluar viewport kiri.

Tidak ada `max-width` atau constraint `left: max(0px, ...)`.

**Solusi:** Tambahkan:
```css
.notif-dropdown { max-width: calc(100vw - 16px); }
```

---

## Yang Sudah Benar di Portal Siswa ✅

| Komponen | Status |
|---|---|
| Bottom nav pill: 4 tab selalu fit di 375px (4×52=208px < 335px) | ✅ Benar |
| Safe-area insets (notch + home bar) | ✅ Benar |
| `.table-wrapper { overflow-x:auto }` di semua tabel | ✅ Benar |
| `min-height:44px` di `.btn-sm` (dipakai mayoritas tombol) | ✅ Benar |
| Stat cards di ≤640px: `min-width:72px; padding:12px` — tidak overflow | ✅ Benar |
| `pkl-detail` layout: default 1 kolom (tidak perlu override) | ✅ Benar |
| Tabel kehadiran menyembunyikan kolom "Jam" di ≤480px (untuk tabel kehadiran) | ✅ Benar |
| Light mode support via `prefers-color-scheme: light` | ✅ Benar (unik di portal siswa) |
| Login card responsive (`padding: 24px 20px` di mobile) | ✅ Benar |

---

## Prioritas Perbaikan — Portal Siswa

| # | Bug/Temuan | Severity | File | Perkiraan Effort |
|---|---|---|---|---|
| 1 | BUG-S2: Forum tab tanpa `.page-body` — konten tanpa padding | 🔴 | `student/dashboard.html:166` | Trivial |
| 2 | BUG-S3: Kolom "Status" PKL tersembunyi di ≤480px (rule terlalu lebar) | 🔴 | `student/css/student.css:278` | Trivial |
| 3 | BUG-S1: Input tanggal 73px — terlalu sempit di ≤480px | 🔴 | `student/dashboard.html:87,112` | Kecil |
| 4 | DEG-S1: 5 stat cards layout 2+2+1 — kartu terakhir orphan | 🟡 | `student/css/student.css:273` | Kecil |
| 5 | DEG-S2: Header nama sekolah bisa wrap (sama dengan guru) | 🟡 | `student/css/student.css:88` | Trivial |
| 6 | MIN-S1: Forum ikon fallback ti-circle | 🔵 | `student/js/dashboard.js:129` | Trivial |
| 7 | MIN-S2: Tombol "Muat lebih banyak" touch target 34px | 🔵 | `student/css/student.css:37` | Trivial |
| 8 | MIN-S3: Notif dropdown tanpa max-width constraint | 🔵 | `student/css/student.css:153` | Trivial |

---

---

# Portal Orang Tua — Audit Responsivitas

**Tanggal:** 18 Juli 2026  
**File:** `parent/portal.html`, `parent/css/parent.css`, `parent/js/portal.js`  
**Metode:** Analisis CSS + HTML + JS statik; pengukuran matematis lebar flex

---

## Tab yang Ada

Tab dirender hardcoded di HTML; visibilitas dikontrol JS via atribut `hidden`:

| Status anak | Tab yang terlihat |
|---|---|
| AKTIF (non-PKL) | Jadwal, Kehadiran, Catatan Guru, Kasus, Forum (5 tab) |
| PKL | PKL, Kehadiran, Catatan Guru, Kasus, Forum (5 tab) |
| LULUS / KELUAR | Catatan Guru, Kasus, Forum (3 tab) |

---

## Ringkasan Temuan

| Severity | Jumlah |
|---|---|
| 🔴 Bug | 2 |
| 🟡 Degradasi visual | 4 |
| 🔵 Minor / polish | 3 |

---

## Bug Layout (🔴)

---

### BUG-P1 — CSS variable mismatch di tab-nav: teks tab gelap & hover jarring di dark mode

**Lokasi:** `parent/css/parent.css` baris 460–501 (blok "Tab Navigation refactor Juli 2026")

**Apa yang terjadi:**  
Blok CSS tab-nav yang ditambahkan Juli 2026 menggunakan nama variabel yang **tidak pernah didefinisikan** di `:root` parent.css:

| Variabel yang dipakai | Yang didefinisikan | Fallback yang terpakai |
|---|---|---|
| `var(--text-muted, #64748b)` | `--color-text-muted` | `#64748b` (abu medium) |
| `var(--primary, #2563eb)` | `--color-primary` | `#2563eb` (biru terang) |
| `var(--surface-hover, #f1f5f9)` | tidak ada | `#f1f5f9` (putih keabu-abuan) |
| `var(--border, #e2e8f0)` | `--color-border` | `#e2e8f0` (abu terang) |
| `var(--text, #1e293b)` | `--color-text` | `#1e293b` (hampir hitam) |

Seluruh fallback adalah warna **light mode hardcoded**. Karena variabel tak pernah terdefinisi, fallback ini selalu dipakai — di dark mode maupun light mode.

**Dampak di dark mode** (background `#0b1120`):
- Teks tab: `#64748b` pada latar `#0b1120` → kontras ~3.1:1, **di bawah WCAG AA 4.5:1**. Tab hampir tidak terbaca.
- Hover background: `#f1f5f9` (hampir putih) pada latar gelap → patch terang yang sangat jarring.
- Border bawah tab-nav: `#e2e8f0` (abu terang) pada dark surface → hampir tidak terlihat.

**Solusi:** Ganti semua nama variabel agar mengacu ke token yang sudah ada:
```css
.tab-btn        { color: var(--color-text-muted); }
.tab-btn:hover  { color: var(--color-text); background: var(--color-surface); }
.tab-btn.active { color: var(--color-primary); border-bottom-color: var(--color-primary); }
.tab-nav        { border-bottom: 2px solid var(--color-border); }
```

---

### BUG-P2 — Kolom "Status" PKL tersembunyi di ≤480px (rule terlalu lebar)

**Lokasi:** `parent/css/parent.css` baris 399–403

**Apa yang terjadi:** Identik dengan BUG-S3 di portal siswa. CSS ≤480px:
```css
.data-table td:nth-child(2),
.data-table th:nth-child(2) { display: none; }
```
Tabel PKL absensi: `Tanggal | Status | Catatan`. Rule ini menyembunyikan kolom ke-2 = **"Status"** (Hadir/Izin/Sakit/Alpa). Orang tua tidak bisa melihat status kehadiran PKL anaknya di mobile.

Rule dimaksudkan hanya untuk menyembunyikan "Waktu" di tabel kehadiran (`Tanggal | Waktu | Mata Pelajaran | Guru | Status | Catatan`).

**Solusi:** Buat rule spesifik per tabel:
```css
@media (max-width: 480px) {
    #attendance-table td:nth-child(2),
    #attendance-table th:nth-child(2) { display: none; }  /* Waktu */
    #attendance-table td:nth-child(4),
    #attendance-table th:nth-child(4) { display: none; }  /* Guru */
    /* PKL table: tidak sembunyikan apapun — semua 3 kolom penting */
}
```

---

## Degradasi Visual (🟡)

---

### DEG-P1 — Tab nav wrap 2 baris di mobile, tanpa bottom nav

**Lokasi:** `parent/css/parent.css` baris 461–468; `.tab-nav { flex-wrap:wrap }`

**Apa yang terjadi:**  
Portal guru dan siswa mengonversi tab nav ke **bottom pill nav** di ≤640px. Portal orang tua tidak — tab tetap di atas dengan `flex-wrap:wrap`.

Di 375px (portal-shell padding 16px = 343px tersedia), 5 tab untuk anak AKTIF:
- "Jadwal"(70px) + "Kehadiran"(91px) + "Catatan Guru"(112px) = 277px → **baris 1**
- "Kasus"(63px) + "Forum"(63px) = 130px → **baris 2** (hanya 2 tombol, rata kiri)

Total tinggi tab nav: 2 × (8+13+8)px + border = **~70px** terpakai sebelum konten.

**Dampak:**
1. Konten bergeser ke bawah 70px — kurang ruang konten di viewport 667px
2. Baris ke-2 hanya berisi 2 tombol rata kiri — asimetris secara visual
3. Inkonsisten dengan UX portal guru/siswa (bottom pill nav)

**Solusi:** Tambahkan bottom nav pill yang sama dengan portal lain, atau setidaknya gunakan `justify-content:center` pada tab-nav agar baris ke-2 terpusat.

---

### DEG-P2 — Topbar column-stack: tombol aksi left-aligned di mobile

**Lokasi:** `parent/css/parent.css` baris 367–371; `.topbar { flex-direction:column }` di ≤600px

**Apa yang terjadi:**  
Di ≤600px, topbar berubah ke `flex-direction:column`. Div kanan (`<div style="display:flex;gap:10px">` dengan bell + Keluar) tidak punya alignment eksplisit → ikut `align-items` default topbar (tidak di-set = stretch). Tombol bell dan Keluar menjadi **left-aligned** di mobile, padahal di desktop mereka right-aligned.

**Dampak:** Terasa tidak polished — tombol "Keluar" dan bell menempel ke kiri halaman setelah judul.

**Solusi:**
```css
@media (max-width: 600px) {
    .topbar { align-items: flex-start; }
    .topbar > div:last-child { align-self: flex-end; }
    /* atau: align-self:flex-start untuk konsistensi left-align */
}
```

---

### DEG-P3 — Tabel kehadiran cramped di ≤600px (5 kolom, ~69px per kolom)

**Lokasi:** `parent/portal.html` baris 97–110; `.data-table` tanpa `overflow-x:auto` wrapper

**Apa yang terjadi:**  
Tabel kehadiran punya 6 kolom: Tanggal | Waktu | Mata Pelajaran | Guru | Status | Catatan. Di ≤600px (lebar 343px), kolom Guru disembunyikan → 5 kolom × ~69px. Teks seperti "Pemrograman Web Dinamis" atau catatan panjang akan **wrap ke 3–4 baris** per sel, membuat tabel sangat tinggi dan sulit dibaca.

Tidak ada `overflow-x:auto` wrapper — tabel tidak bisa di-scroll horizontal, melainkan memaksa text wrap.

**Solusi:** Bungkus tabel dalam div scroll: `<div style="overflow-x:auto">`. Ini memungkinkan scroll horizontal jika teks panjang daripada wrap paksa.

---

### DEG-P4 — `.summary-card.card-izin` menggunakan warna hardcoded light mode

**Lokasi:** `parent/css/parent.css` baris 253

```css
.summary-card.card-izin { background: #eff4ff; color: var(--color-primary); }
```

`#eff4ff` adalah biru sangat terang — dirancang untuk light mode. Di dark mode (`--color-bg: #0b1120`), kartu "Izin" tampil sebagai **kotak terang mencolok** di antara kartu-kartu lain yang menggunakan `rgba` transparan. Ketiga kartu lain (Hadir, Sakit, Alpha) menggunakan `var(--color-*-bg)` yang bekerja di kedua mode.

**Solusi:** Ganti ke token transparan yang sudah ada:
```css
.summary-card.card-izin { background: var(--color-primary-bg); color: var(--color-primary); }
```

---

## Minor / Polish (🔵)

---

### MIN-P1 — Tombol "Muat lebih banyak" tidak ter-center di forum

**Lokasi:** `parent/portal.html` baris 145

`<button style="display:none;margin:16px auto">` — sebagai `inline-flex`, `margin:auto` tidak bekerja untuk centering dalam block flow tanpa `display:block`. Tombol muncul left-aligned.

**Solusi:** Bungkus dalam `<div style="text-align:center">` atau ubah button ke `display:block; margin:16px auto; width:fit-content`.

---

### MIN-P2 — `.btn` tanpa `min-height:44px` — touch target kecil

**Lokasi:** `parent/css/parent.css` baris 46–58

Identik dengan MIN-S2 portal siswa. `.btn` hanya `padding:10px 18px` → tinggi ~34px. Tombol "Tampilkan", "Keluar", dll. di bawah 44px WCAG 2.5.5.

**Solusi:** `min-height: 44px` di `.btn`.

---

### MIN-P3 — Notif dropdown tanpa `max-width` constraint

**Lokasi:** `parent/css/parent.css` baris 316–328; `.notif-dropdown { width:300px }`

Identik dengan MIN-S3 portal siswa. Pada layar sangat sempit (<320px), dropdown bisa keluar viewport kiri.

**Solusi:** `max-width: calc(100vw - 16px)` di `.notif-dropdown`.

---

## Yang Sudah Benar di Portal Orang Tua ✅

| Komponen | Status |
|---|---|
| `filter-row { flex-direction:column }` di ≤600px — input tanggal full-width & readable | ✅ Benar |
| `child-selector` stack vertical di ≤480px | ✅ Benar |
| `summary-card { min-width:calc(50%-5px) }` di ≤480px — layout 2+2 bersih (4 kartu) | ✅ Benar |
| Safe-area inset (`max(16px, env(safe-area-inset-top))`) di topbar | ✅ Benar |
| `portal-shell { max-width:800px; padding:16px }` — konten tidak overflow | ✅ Benar |
| Light mode support via `prefers-color-scheme: light` | ✅ Benar |
| Tab PKL / Jadwal disembunyikan via `hidden` attribute (bukan `display:none`) | ✅ Benar |
| Login card responsive | ✅ Benar |
| Kolom 4 (Guru) disembunyikan di ≤600px untuk tabel kehadiran | ✅ Benar |

---

## Prioritas Perbaikan — Portal Orang Tua

| # | Bug/Temuan | Severity | File | Perkiraan Effort |
|---|---|---|---|---|
| 1 | BUG-P1: CSS var mismatch di tab-nav — teks gelap & hover jarring di dark mode | 🔴 | `parent/css/parent.css:460` | Kecil |
| 2 | BUG-P2: Kolom "Status" PKL tersembunyi di ≤480px | 🔴 | `parent/css/parent.css:399` | Trivial |
| 3 | DEG-P1: Tab nav wrap 2 baris — tidak ada bottom nav di mobile | 🟡 | `parent/css/parent.css:461` | Sedang |
| 4 | DEG-P3: Tabel kehadiran cramped, tidak ada overflow-x:auto | 🟡 | `parent/portal.html:97` | Trivial |
| 5 | DEG-P2: Topbar tombol aksi left-aligned di mobile | 🟡 | `parent/css/parent.css:367` | Trivial |
| 6 | DEG-P4: `.card-izin` background hardcoded light mode | 🟡 | `parent/css/parent.css:253` | Trivial |
| 7 | MIN-P1: Tombol "Muat lebih banyak" tidak ter-center | 🔵 | `parent/portal.html:145` | Trivial |
| 8 | MIN-P2: `.btn` touch target 34px | 🔵 | `parent/css/parent.css:46` | Trivial |
| 9 | MIN-P3: Notif dropdown tanpa max-width | 🔵 | `parent/css/parent.css:316` | Trivial |

---

---

# Portal DUDI — Audit Responsivitas

**Tanggal:** 18 Juli 2026  
**File:** `dudi/dashboard.html`, `dudi/css/dudi.css`  
**Metode:** Analisis CSS + HTML statik; pengukuran matematis lebar flex/grid

---

## Struktur Navigasi

Portal DUDI **tidak memiliki tab navigation**. Semua konten ditampilkan sebagai section vertikal yang di-scroll, selalu terlihat setelah login:

| # | Section | Deskripsi |
|---|---|---|
| 1 | Ringkasan | 3 stat cards (Siswa PKL, Hadir Hari Ini, Belum Dicatat) |
| 2 | Absensi Harian | Date nav + daftar siswa dengan radio status |
| 3 | Tambah Catatan/Observasi | Form 2-kolom (siswa, penilaian, aspek, catatan) |
| 4 | Riwayat Catatan | Daftar observasi yang sudah dibuat |
| 5 | Laporan Masalah PKL | Buat/lihat/teruskan laporan kasus PKL |
| 6 | Riwayat Absensi | Tabel 14 hari terakhir (semua siswa) |

---

## Ringkasan Temuan

| Severity | Jumlah |
|---|---|
| 🔴 Bug | 2 |
| 🟡 Degradasi visual | 2 |
| 🔵 Minor / polish | 2 |

---

## Bug Layout (🔴)

---

### BUG-D1 — Date nav prev/next jadi tombol full-width di ≤480px

**Lokasi:** `dudi/css/dudi.css` baris 462–464

**Apa yang terjadi:**  
Di ≤480px:
```css
.date-nav { flex-direction: column; width: 100%; gap: 6px; }
.date-nav .btn { width: 100%; }
.date-nav input[type="date"] { width: 100%; }
```

Tombol navigasi `‹` (hari sebelumnya) dan `›` (hari berikutnya) menjadi **tombol full-width** yang hanya berisi satu karakter. Layout menjadi:

```
┌─────────────────────────────┐
│           ‹                  │  ← tombol penuh, 1 karakter
├─────────────────────────────┤
│       2026-07-18             │  ← date input penuh
├─────────────────────────────┤
│           ›                  │  ← tombol penuh, 1 karakter
└─────────────────────────────┘
```

UX-nya membingungkan: user tidak intuitif mengerti bahwa `‹` di atas = prev dan `›` di bawah = next. Tombol full-width untuk 1 karakter juga tidak efisien secara ruang.

**Solusi yang lebih baik:** Pertahankan layout `flex-direction:row` tapi buat input tanggal `flex:1`, dan hilangkan `width:100%` dari tombol:
```css
@media (max-width: 480px) {
    .date-nav { flex-wrap: nowrap; }       /* tetap 1 baris */
    .date-nav input[type="date"] { flex: 1; min-width: 0; }
    /* .date-nav .btn — biarkan shrink-to-content */
}
```

---

### BUG-D2 — Status "Izin" menggunakan warna hardcoded light mode di portal dark

**Lokasi:** `dudi/css/dudi.css` baris 286, 412

**Apa yang terjadi:**  
Dua tempat menggunakan warna `#eff6ff` (biru sangat terang) untuk status Izin:

```css
/* Radio button */
.radio-izin input:checked + label { background: #eff6ff; color: #1d4ed8; border-color: #1d4ed8; }
/* Badge di tabel riwayat */
.badge-izin { background: #eff6ff; color: #1d4ed8; }
```

Portal DUDI adalah **dark mode saja** (`--color-bg: #0b1120`). Tidak ada `prefers-color-scheme: light` override. Warna `#eff6ff` di dark mode menghasilkan **kotak biru terang mencolok** di antara badge/radio lain yang menggunakan token `rgba` transparan.

**Solusi:** Gunakan token warna yang konsisten:
```css
.radio-izin input:checked + label { background: rgba(29,78,216,0.15); color: #60a5fa; border-color: #60a5fa; }
.badge-izin { background: rgba(29,78,216,0.15); color: #60a5fa; }
```
Atau tambahkan CSS variable `--color-info` dan `--color-info-bg` ke token portal DUDI.

---

## Degradasi Visual (🟡)

---

### DEG-D1 — Topbar column-stack: bell + Keluar left-aligned di mobile

**Lokasi:** `dudi/css/dudi.css` baris 432–437; `.topbar { flex-direction:column }` di ≤600px

**Apa yang terjadi:** Identik dengan DEG-P2 portal orang tua. Di ≤600px, topbar stack vertikal. Elemen kanan (bell + "Keluar") tidak punya `align-self` eksplisit → ikut `align-items:flex-start` default → tombol left-aligned di mobile.

**Solusi:**
```css
@media (max-width: 600px) {
    .topbar > div:first-child + * { align-self: flex-start; }
}
```
Atau secara eksplisit: `align-self: flex-end` pada div yang berisi bell + button Keluar.

---

### DEG-D2 — `section-header` tidak wrap di mobile — heading + button cramped

**Lokasi:** `dudi/css/dudi.css` baris 193–200; `dudi/dashboard.html` baris 63, 136

**Apa yang terjadi:**  
`.section-header { display:flex; justify-content:space-between }` tanpa `flex-wrap:wrap` atau media query stack.

Di mobile (303px inner width setelah `section { padding:20px }`):
- **"Absensi Harian"** + date-nav `[‹][date][›]`: date-nav sudah ada di dalam section-header di baris 64-68. Teks heading + 3 kontrol date nav dalam space-between → tanpa wrap, kontrol bisa sangat cramped.
- **"Laporan Masalah PKL"** + tombol `"+ Laporan Baru"`: heading ~147px + tombol ~110px + gap = ~267px → pas di 303px, masih aman.

Yang bermasalah adalah section Absensi Harian karena `.date-nav` di dalam `.section-header` membawa 3 elemen (prev, date input, next) yang bersaing ruang dengan heading "Absensi Harian".

**Solusi:** Pisahkan date-nav dari section-header, atau tambahkan `flex-wrap:wrap` pada section-header:
```css
@media (max-width: 480px) {
    .section-header { flex-wrap: wrap; gap: 8px; }
    .section-header h3 { width: 100%; }  /* heading ambil baris penuh */
}
```

---

## Minor / Polish (🔵)

---

### MIN-D1 — `.btn` dasar tanpa `min-height:44px` — touch target kecil

**Lokasi:** `dudi/css/dudi.css` baris 47–59

`.btn-sm` punya `min-height: 44px` ✅. Namun `.btn` dasar hanya `padding:10px 18px` → tinggi ~34px. Tombol "Simpan" di setiap baris absensi menggunakan `.btn.btn-primary` tanpa `.btn-sm` → touch target 34px (WCAG 2.5.5 = 44px).

**Catatan:** `.btn-sm` dengan `min-height:44px` adalah naming yang kontra-intuitif (`sm` biasanya lebih kecil). Idealnya `min-height:44px` ada di `.btn` dasar, bukan hanya `.btn-sm`.

**Solusi:** `min-height: 44px` pada `.btn`.

---

### MIN-D2 — Notif dropdown inline style tanpa `max-width` constraint

**Lokasi:** `dudi/dashboard.html` baris 31; `#notif-dropdown` inline style

Dropdown notif menggunakan inline style (`width:300px`) tanpa `max-width`. Identik dengan portal siswa dan ortu. Pada layar <320px bisa overflow viewport.

**Solusi:** Tambahkan ke inline style atau CSS: `max-width: calc(100vw - 16px)`.

---

## Yang Sudah Benar di Portal DUDI ✅

| Komponen | Status |
|---|---|
| `table-scroll { overflow-x:auto }` — tabel riwayat bisa scroll horizontal | ✅ Benar |
| `obs-form { grid-template-columns:1fr }` di ≤600px — form 1 kolom di mobile | ✅ Benar |
| `attendance-row { flex-direction:column }` di ≤600px — stack vertikal per siswa | ✅ Benar |
| `status-radios { flex-wrap:wrap }` — 4 pilihan tetap wrap kalau tidak muat | ✅ Benar |
| `filter-row { flex-direction:column }` di ≤600px | ✅ Benar |
| `summary-card { min-width:calc(50%-5px) }` di ≤480px — layout 2+1 (3 kartu) | ✅ Benar |
| Safe-area insets (topbar padding-top, body padding-bottom) | ✅ Benar |
| `.btn-sm { min-height:44px }` — tombol kecil sudah memenuhi WCAG | ✅ Benar |
| `data-table { min-width:auto }` di ≤480px — tidak paksa overflow horizontal | ✅ Benar |
| Kolom "Catatan" (ke-4) disembunyikan di ≤480px di tabel riwayat | ✅ Benar |
| Login card responsive | ✅ Benar |

---

## Prioritas Perbaikan — Portal DUDI

| # | Bug/Temuan | Severity | File | Perkiraan Effort |
|---|---|---|---|---|
| 1 | BUG-D1: Date nav prev/next jadi full-width button di ≤480px | 🔴 | `dudi/css/dudi.css:462` | Trivial |
| 2 | BUG-D2: Warna Izin hardcoded light (#eff6ff) di portal dark mode | 🔴 | `dudi/css/dudi.css:286,412` | Trivial |
| 3 | DEG-D2: `section-header` tidak wrap — heading + date-nav cramped | 🟡 | `dudi/css/dudi.css:193` | Kecil |
| 4 | DEG-D1: Topbar button left-aligned setelah column-stack | 🟡 | `dudi/css/dudi.css:432` | Trivial |
| 5 | MIN-D1: `.btn` touch target 34px — di bawah WCAG 44px | 🔵 | `dudi/css/dudi.css:47` | Trivial |
| 6 | MIN-D2: Notif dropdown tanpa max-width | 🔵 | `dudi/dashboard.html:31` | Trivial |

---

---

# Portal Stakeholder — Audit Responsivitas

**Tanggal:** 18 Juli 2026  
**File:** `stakeholder/dashboard.html`, `stakeholder/css/stakeholder.css`  
**Metode:** Analisis CSS + HTML statik; pengukuran matematis lebar flex

---

## Struktur Navigasi

Portal Stakeholder **tidak memiliki tab navigation**. Ini adalah dashboard view-only satu halaman dengan dua baris stat cards dan satu section info:

| # | Konten | Deskripsi |
|---|---|---|
| 1 | Stats row 1 (5 cards) | Siswa Aktif, Siswa PKL, Staf & Guru, Program Keahlian, Kelas |
| 2 | Stats row 2 (3 cards) | % Kehadiran Bulan Ini, Sesi Hari Ini, Kehadiran Tercatat Hari Ini |
| 3 | Section info | Keterangan dashboard hanya menampilkan data agregat |

Tidak ada fitur interaktif selain tombol "Muat Ulang" dan "Keluar".

---

## Ringkasan Temuan

Portal Stakeholder adalah portal paling sederhana dan paling bersih responsivitasnya. Tidak ada bug layout kritis.

| Severity | Jumlah |
|---|---|
| 🔴 Bug | 0 |
| 🟡 Degradasi visual | 2 |
| 🔵 Minor / polish | 1 |

---

## Degradasi Visual (🟡)

---

### DEG-SK1 — 5 stat cards row 1 → layout 2+2+1, satu kartu orphan

**Lokasi:** `stakeholder/css/stakeholder.css` baris 131; `stakeholder/dashboard.html` baris 48–54

**Apa yang terjadi:**  
Di ≤480px: `stat-card { min-width: calc(50% - 6px) }`. Dengan 5 kartu (flex-wrap), hasilnya:
```
┌──────────────┬──────────────┐
│ Siswa Aktif  │ Siswa PKL    │  ← baris 1
├──────────────┬──────────────┤
│ Staf & Guru  │ Prog. Keahl. │  ← baris 2
├──────────────────────────────┤
│           Kelas              │  ← baris 3: 1 kartu full-width
└──────────────────────────────┘
```

Kartu "Kelas" tampak jauh lebih dominan dari keempat kartu lain, padahal hierarki informasinya tidak lebih penting.

**Solusi opsi A:** Reorder stat cards — pindahkan "Kelas" ke posisi genap (ke-2 atau ke-4).  
**Solusi opsi B:** Gunakan `grid-template-columns: repeat(3, 1fr)` di ≤480px untuk row pertama:
```css
@media (max-width: 480px) {
    .stats-row:first-of-type .stat-card { min-width: calc(33.333% - 8px); }
}
```

---

### DEG-SK2 — 3 stat cards row 2 → layout 2+1, satu kartu orphan full-width

**Lokasi:** `stakeholder/css/stakeholder.css` baris 131; `stakeholder/dashboard.html` baris 56–60

**Apa yang terjadi:**  
Row kedua memiliki 3 stat cards. Dengan `min-width: calc(50%-6px)`:
```
┌────────────────┬────────────────┐
│ % Kehadiran    │  Sesi Hari Ini │  ← baris 1
│ Bulan Ini      │                │
├────────────────────────────────┤
│   Kehadiran Tercatat Hari Ini  │  ← baris 2: 1 kartu full-width
└────────────────────────────────┘
```

Kartu ketiga "Kehadiran Tercatat Hari Ini" (label 30 karakter) menjadi full-width sendirian. Labelnya yang panjang pun akan tampil awkward di kartu full-width tapi nilai "—" di tengah.

**Solusi:** Gunakan 3 kolom untuk row kedua:
```css
@media (max-width: 480px) {
    .stats-row:nth-of-type(2) { flex-direction: column; }
    /* atau: stats-row:nth-of-type(2) .stat-card { min-width: 100%; } */
}
```
Atau reorder: "Kehadiran Tercatat Hari Ini" menjadi kartu ke-1 atau ke-2 agar tidak jadi orphan.

---

## Minor / Polish (🔵)

---

### MIN-SK1 — Tombol "Muat Ulang" jadi full-width di ≤480px

**Lokasi:** `stakeholder/css/stakeholder.css` baris 138; `.head-actions .btn { width:100% }` di ≤480px

**Apa yang terjadi:**  
Di ≤480px, `.section-head` stack vertikal dan `.head-actions { width:100% }` + `.head-actions .btn { width:100% }` menjadikan tombol "Muat Ulang" selebar konten penuh (~351px). Tombol refresh yang sederhana ini tidak perlu selebar layar — terasa overengineered untuk fungsinya.

Di sebelah kiri tombol ada `.hint` (timestamp "diperbarui pukul...") yang juga stretch full-width, membuat keduanya dalam kolom vertikal.

**Solusi:** Tidak perlu tombol full-width untuk aksi refresh:
```css
@media (max-width: 480px) {
    .head-actions .btn { width: auto; }  /* biarkan shrink ke kontennya */
}
```

---

## Yang Sudah Benar di Portal Stakeholder ✅

| Komponen | Status |
|---|---|
| `app-header { flex-wrap:wrap }` — header wrap jika nama sekolah terlalu panjang | ✅ Benar |
| `section-head { flex-wrap:wrap }` — section head wrap di semua lebar | ✅ Benar |
| `page-body { padding: 16px 12px }` di ≤640px — konten tidak overflow | ✅ Benar |
| `section-card { padding: 12px 10px }` di ≤480px — section lebih compact | ✅ Benar |
| Safe-area insets (app-header padding-top, body padding-bottom) | ✅ Benar |
| Kedua tombol ("Keluar" + "Muat Ulang") menggunakan `.btn-sm` dengan `min-height:44px` | ✅ Benar |
| Tidak ada tabel → tidak ada nth-child hide-column issues | ✅ N/A |
| Tidak ada dropdown notif → tidak ada max-width issue | ✅ N/A |
| Login card responsive (`padding: 24px 20px` di mobile) | ✅ Benar |
| `stat-card` label panjang ("% Kehadiran Bulan Ini") tetap muat di kartu 50% width | ✅ Benar |

---

## Prioritas Perbaikan — Portal Stakeholder

| # | Bug/Temuan | Severity | File | Perkiraan Effort |
|---|---|---|---|---|
| 1 | DEG-SK1: 5 stat cards → 2+2+1 orphan layout | 🟡 | `stakeholder/css/stakeholder.css:131` | Trivial |
| 2 | DEG-SK2: 3 stat cards row 2 → 2+1 orphan layout | 🟡 | `stakeholder/css/stakeholder.css:131` | Trivial |
| 3 | MIN-SK1: Tombol "Muat Ulang" jadi full-width di ≤480px | 🔵 | `stakeholder/css/stakeholder.css:138` | Trivial |
