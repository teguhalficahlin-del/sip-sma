# NOVA — Prompt Master Claude Code
## Fase 5: Komunikasi
**Gunakan prompt ini setelah Fase 4 selesai dan dikonfirmasi.**

---

## KONTEKS PROJECT

Kamu melanjutkan pembangunan **NOVA (Next-gen One-stop Virtual Academy)** — platform PWA multi-tenant sistem informasi sekolah SD-SMP-SMA.

**Fase 1–4 sudah selesai dan terverifikasi:**
- Foundation, Core Akademik, Penilaian, dan Pembelajaran berjalan penuh
- Claude API terintegrasi dengan rate limiting dan caching
- Semua RLS lintas fase sudah diaudit dan bersih

**Fase 5 ini membangun sistem komunikasi satu arah** — guru/admin mengirim pesan ke orang tua, orang tua menerima. Notifikasi di Fase 5 hanya dalam app. Web Push + Service Worker ditunda ke Fase 7.

Baca `CLAUDE.md` dan `SPEC.md` di root repository sebelum mulai.

---

## ATURAN KERJA WAJIB

1. **Baca dulu, kode kemudian** — analisis seluruh instruksi sebelum mulai
2. **Satu langkah selesai sebelum lanjut** — jangan overlap antar langkah
3. **Tidak ada placeholder** — semua kode harus fungsional dan dapat dijalankan
4. **RLS wajib diuji** — setiap tabel baru harus diverifikasi isolasinya per `school_id`
5. **Mobile-first wajib** — semua UI diuji logikanya di 320px terlebih dahulu
6. **Tidak ada keputusan arsitektur mandiri** — jika ada ambiguitas, tulis pertanyaan dan tunggu konfirmasi
7. **Commit per langkah** — setiap langkah selesai langsung commit dengan pesan yang deskriptif
8. **Service Worker tidak disentuh** — SW + Web Push diaktifkan penuh di Fase 7

---

## ARSITEKTUR MULTI-TENANT (PENGINGAT)

- Setiap tabel baru wajib punya kolom `school_id uuid references schools(id)`
- RLS wajib aktif di setiap tabel baru
- Tidak ada query yang boleh return data lintas sekolah kecuali role `dinas`

---

## FASE 5 — KOMUNIKASI

### Target Fase 5
- Semua aktor internal (Guru, Admin, Kepala Sekolah) bisa kirim pesan ke penerima yang diseleksi bebas
- Penerima bisa dipilih dari semua role: guru, siswa, ortu, komite, atau kombinasi
- Aktor eksternal (siswa, ortu, komite, dinas) hanya bisa menerima pesan
- Pesan bisa diedit maksimal 24 jam setelah dikirim
- Notifikasi dalam app aktif (badge, inbox)
- Web Push ditunda ke Fase 7

### Entitas yang dibangun
`messages` → `message_recipients` → `notifications`

---

### Langkah-langkah

#### LANGKAH 1 — Sistem Pesan Terpadu

**Pengirim yang bisa kirim pesan:**
- Guru
- Admin
- Kepala Sekolah

**Penerima yang bisa diseleksi:**
- Semua guru di sekolah
- Guru tertentu (pilih individual)
- Semua siswa di kelas tertentu
- Siswa tertentu (pilih individual)
- Semua orang tua di kelas tertentu
- Semua orang tua di sekolah
- Orang tua siswa tertentu
- Komite
- Kombinasi dari pilihan di atas

**Tabel `messages`:**
```sql
id uuid primary key default gen_random_uuid()
school_id uuid references schools(id) not null
sender_id uuid references users(id) not null
title text not null
content text not null
is_sent boolean default false
sent_at timestamptz
edited_at timestamptz -- null jika belum pernah diedit
created_at timestamptz default now()
```

**Tabel `message_recipients`:**
```sql
id uuid primary key default gen_random_uuid()
message_id uuid references messages(id) not null
recipient_id uuid references users(id) not null
is_read boolean default false
read_at timestamptz
created_at timestamptz default now()
```

**RLS:**
- Guru, Admin, Kepsek bisa buat & lihat pesan yang mereka kirim
- Semua role bisa lihat pesan yang ditujukan ke mereka (via `message_recipients`)
- Admin bisa lihat semua pesan di sekolahnya

**Logika penting:**
- Pengirim memilih penerima secara bebas saat compose pesan
- Sistem otomatis populate `message_recipients` sesuai seleksi pengirim
- Pesan bisa diedit maksimal **24 jam** setelah dikirim
- Setelah 24 jam → pesan terkunci, tidak bisa diedit
- Jika diedit → penerima yang sudah membaca mendapat notifikasi "Pesan telah diperbarui"
- Pesan tidak bisa dihapus setelah dikirim

**UI yang dibangun:**
- `src/pages/messages/Compose.jsx` — buat & kirim pesan (guru, admin, kepsek)
  - Pilih penerima: multi-select dengan kategori (semua guru / kelas tertentu / individual)
  - Form: judul, isi pesan
  - Preview daftar penerima sebelum kirim
  - Tombol "Kirim Pesan"
- `src/pages/messages/Outbox.jsx` — pesan terkirim (pengirim)
  - Daftar pesan yang pernah dikirim
  - Status: berapa penerima sudah baca
  - Edit pesan (jika masih dalam 24 jam)
- `src/pages/messages/Inbox.jsx` — kotak masuk (semua role)
  - Daftar pesan masuk, sorted terbaru di atas
  - Badge jumlah pesan belum dibaca
  - Tap pesan → baca detail → tandai sudah dibaca
- `src/components/MessageCard.jsx` — kartu pesan di inbox/outbox
- `src/components/RecipientSelector.jsx` — komponen seleksi penerima

**Verifikasi:**
- Guru bisa kirim pesan ke kombinasi penerima yang berbeda
- Admin bisa kirim pesan ke semua guru sekolah
- Kepsek bisa kirim pesan ke semua ortu
- Penerima hanya melihat pesan yang ditujukan ke mereka
- Pesan bisa diedit dalam 24 jam, terkunci setelahnya
- Penerima yang sudah baca mendapat notifikasi saat pesan diedit

---

#### LANGKAH 2 — Sistem Notifikasi Dalam App
Buat sistem notifikasi in-app untuk semua role setelah sistem pesan terpadu selesai.
target_type text not null -- 'all_parents' | 'class_parents' | 'individual_parent'
target_user_id uuid references users(id) -- diisi jika target_type = 'individual_parent'
is_sent boolean default false
sent_at timestamptz
created_at timestamptz default now()
```

**Tabel `message_recipients`** (penerima per pesan):
```sql
id uuid primary key default gen_random_uuid()
message_id uuid references messages(id) not null
recipient_id uuid references users(id) not null -- id ortu
is_read boolean default false
read_at timestamptz
created_at timestamptz default now()
```

**RLS:**
- Guru hanya bisa buat & lihat pesan yang dia kirim
- Ortu hanya bisa lihat pesan yang ditujukan ke mereka (via `message_recipients`)
- Admin/Kepsek bisa lihat semua pesan di sekolahnya

**Logika penting:**
- Saat guru kirim pesan ke `class_parents` → sistem otomatis populate `message_recipients` dengan semua ortu di kelas itu
- Saat guru kirim ke `all_parents` → populate semua ortu di sekolah
- Pesan bisa diedit maksimal **24 jam** setelah dikirim (`sent_at + 24 jam`)
- Setelah 24 jam → pesan terkunci, tidak bisa diedit
- Jika pesan diedit → ortu yang sudah membaca mendapat notifikasi "Pesan telah diperbarui"
- Pesan tidak bisa dihapus setelah dikirim

**UI yang dibangun:**
- `src/pages/teacher/Messages.jsx` — buat & kirim pesan (guru)
  - Pilih target: Semua orang tua / Orang tua kelas tertentu / Orang tua siswa tertentu
  - Form: judul, isi pesan
  - Preview penerima sebelum kirim
  - Tombol "Kirim Pesan"
  - Riwayat pesan yang pernah dikirim
- `src/pages/parent/Messages.jsx` — kotak masuk pesan (ortu)
  - Daftar pesan masuk, sorted terbaru di atas
  - Badge jumlah pesan belum dibaca
  - Tap pesan → baca detail → tandai sudah dibaca
- `src/components/MessageCard.jsx` — tampilan kartu pesan di inbox

**Verifikasi:**
- Guru bisa kirim pesan ke semua ortu kelas
- Ortu hanya melihat pesan yang ditujukan ke mereka
- Pesan bisa diedit dalam 24 jam setelah dikirim, terkunci setelah itu
- Status baca terupdate saat ortu membuka pesan

---

#### LANGKAH 3 — Sistem Notifikasi Dalam App
Buat sistem notifikasi in-app untuk semua role.

**Tabel `notifications`:**
```sql
id uuid primary key default gen_random_uuid()
school_id uuid references schools(id) not null
user_id uuid references users(id) not null
type text not null -- 'announcement' | 'message' | 'attendance' | 'grade' | 'assignment'
title text not null
body text not null
reference_id uuid -- id entitas terkait (announcement, message, dll)
reference_type text -- 'announcements' | 'messages' | 'attendances' | 'grades' | 'assignments'
is_read boolean default false
read_at timestamptz
created_at timestamptz default now()
```

**RLS:**
- User hanya bisa lihat notifikasi miliknya sendiri

**Kapan notifikasi dibuat:**

| Event | Penerima | Tipe |
|---|---|---|
| Pengumuman published | Semua target audience | `announcement` |
| Pesan guru terkirim | Ortu yang dituju | `message` |
| Absensi diinput | Ortu siswa terkait | `attendance` |
| Nilai diinput | Siswa terkait | `grade` |
| Tugas dibuat | Siswa di kelas | `assignment` |
| Tugas mendekati deadline (H-1) | Siswa yang belum kumpul | `assignment` |

**UI yang dibangun:**
- `src/components/NotificationBell.jsx` — ikon lonceng di header dengan badge jumlah belum dibaca
- `src/pages/Notifications.jsx` — halaman daftar semua notifikasi
  - Sorted terbaru di atas
  - Tap notifikasi → navigasi ke halaman terkait → tandai sudah dibaca
  - Tombol "Tandai semua sudah dibaca"
- `src/hooks/useNotifications.js` — hook untuk fetch & manage notifikasi
- Notifikasi di-fetch ulang setiap kali app di-focus (bukan realtime di Fase ini)

**Verifikasi:**
- Badge notifikasi muncul saat ada notifikasi baru
- Tap notifikasi membawa user ke halaman yang relevan
- Notifikasi hilang dari badge setelah dibaca

---

#### LANGKAH 4 — Update Dashboard per Role

**Dashboard Guru:**
- Badge pesan yang sudah dibaca ortu (berapa % ortu sudah baca)
- Shortcut "Kirim Pesan ke Orang Tua"

**Dashboard Siswa:**
- Pengumuman terbaru dari sekolah
- Notifikasi tugas mendekati deadline

**Dashboard Orang Tua:**
- Kotak masuk pesan — jumlah belum dibaca
- Pengumuman sekolah terbaru

**Dashboard Admin/Kepsek:**
- Pengumuman aktif saat ini
- Shortcut buat pengumuman baru

**Dashboard Komite:**
- Pengumuman sekolah terbaru yang relevan

**Verifikasi:**
- Setiap role melihat informasi komunikasi yang relevan di dashboardnya

---

#### LANGKAH 5 — Update CLAUDE.md

```markdown
## Status Fase
- [x] Fase 1: Foundation
- [x] Fase 2: Core Akademik
- [x] Fase 3: Penilaian
- [x] Fase 4: Pembelajaran
- [x] Fase 5: Komunikasi
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
- [2026-07-07] Generate modul: 8 langkah, semua input via pilihan
- [2026-07-07] Topik & metode: bawaan sistem + bisa ditambah guru
- [2026-07-07] Komunikasi: sistem pesan terpadu — semua aktor internal bisa kirim, penerima diseleksi bebas
- [2026-07-07] Aktor eksternal (siswa, ortu, komite, dinas): hanya terima pesan, tidak bisa kirim
- [2026-07-07] Kepala Sekolah: bisa kirim pesan, akses data akademik read-only
- [2026-07-07] Notifikasi: in-app di Fase 5, Web Push + SW di Fase 7
- [2026-07-07] Pesan: bisa diedit maksimal 24 jam setelah dikirim, terkunci setelahnya
```

---

## CHECKLIST SELESAI FASE 5

- [ ] Tabel `announcements` terbuat + RLS aktif + UI admin berfungsi
- [ ] Pengumuman draft tidak terlihat audience, published terlihat sesuai target
- [ ] Tabel `messages` + `message_recipients` terbuat + RLS aktif
- [ ] Guru bisa kirim pesan ke semua ortu kelas
- [ ] Ortu hanya melihat pesan yang ditujukan ke mereka
- [ ] Pesan bisa diedit dalam 24 jam, terkunci setelah itu
- [ ] Ortu mendapat notifikasi "Pesan diperbarui" jika pesan yang sudah dibaca diedit
- [ ] Tabel `notifications` terbuat + RLS aktif
- [ ] Badge notifikasi berfungsi di semua role
- [ ] Tap notifikasi navigasi ke halaman yang relevan
- [ ] Dashboard semua role diupdate dengan data komunikasi
- [ ] `CLAUDE.md` diupdate dengan status Fase 5 selesai
- [ ] Semua langkah sudah di-commit ke GitHub

---

## SETELAH FASE 5 SELESAI

Laporkan:
1. Checklist di atas — centang semua yang sudah selesai
2. Deskripsi singkat alur guru kirim pesan → ortu terima → notifikasi muncul
3. Jika ada item yang tidak bisa diselesaikan — jelaskan kenapa dan tunggu instruksi

**Jangan mulai Fase 6 sebelum mendapat konfirmasi.**
