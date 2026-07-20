# NOVA — Prompt Master Claude Code
## Fase 7: Hardening
**Gunakan prompt ini setelah Fase 6 selesai dan dikonfirmasi.**

---

## KONTEKS PROJECT

Kamu menyelesaikan pembangunan **NOVA (Next-gen One-stop Virtual Academy)** dengan fase hardening — memastikan platform aman, stabil, performan, dan siap produksi.

**Fase 1–6 sudah selesai dan terverifikasi:**
- Foundation, Core Akademik, Penilaian, Pembelajaran, Komunikasi, Laporan & Dashboard berjalan penuh
- Checkpoint Audit Fase 1–3 sudah selesai (`AUDIT_REPORT.md` tersedia)

**Fase 7 ini adalah fase terakhir** — tidak ada fitur baru, fokus pada keamanan, performa, offline, dan notifikasi push.

Baca `CLAUDE.md`, `SPEC.md`, dan `AUDIT_REPORT.md` di root repository sebelum mulai.

---

## ATURAN KERJA WAJIB

1. **Audit dulu, perbaiki kemudian** — identifikasi semua masalah sebelum mulai
2. **Satu area selesai sebelum lanjut** — jangan overlap antar area
3. **Tidak ada fitur baru** — jika ada ide fitur, catat di `BACKLOG.md`, jangan implementasi
4. **Setiap perubahan harus bisa di-revert** — commit atomic per perubahan
5. **Uji setelah setiap perubahan** — jangan tumpuk perubahan tanpa verifikasi
6. **Commit per area** — setiap area hardening selesai langsung commit

---

## FASE 7 — HARDENING

### Target Fase 7
- RLS seluruh platform diaudit ulang secara menyeluruh
- Service Worker aktif — offline fallback berjalan
- Web Push + notifikasi push aktif
- Performa dioptimasi — tidak ada query N+1, index lengkap
- Keamanan divalidasi — tidak ada celah auth, input validation lengkap
- Platform siap produksi

---

### AREA 1 — Audit RLS Final (Seluruh Platform)

Ini adalah audit RLS terlengkap — mencakup semua tabel dari Fase 1–6.

**Daftar tabel yang harus diaudit:**

```
schools, users, roles, licenses
classes, subjects, schedules, attendances
grades
teaching_journals, lesson_modules, curriculum_topics, teaching_methods
assignments, submissions, rate_limits, module_cache
messages, message_recipients, notifications
```

**Skenario wajib diuji per tabel:**

1. **Isolasi antar sekolah:** User sekolah A tidak bisa baca/tulis data sekolah B
2. **Isolasi antar role:** Siswa tidak bisa akses data guru, ortu tidak bisa akses data siswa lain
3. **Isolasi wali kelas:** Wali kelas hanya bisa lihat rekap kelasnya sendiri
4. **Isolasi wakil kepala:** Wakil kepala hanya bisa lihat data sekolahnya
5. **Akses Dinas:** Hanya bisa lihat data agregat sekolah dalam wilayahnya, tidak bisa lihat data individual siswa
6. **Akses Komite:** Hanya kehadiran, tidak bisa lihat nilai

**Output:** Update `AUDIT_REPORT.md` dengan hasil audit RLS final.

**Verifikasi:**
- Semua skenario PASS
- Tidak ada tabel yang missing RLS policy
- Tidak ada query yang bisa bypass RLS

---

### AREA 2 — Service Worker & Offline

Ini adalah satu-satunya area yang mengaktifkan Service Worker — ditunda dari Fase 1.

**Install dependency:**
```bash
npm install vite-plugin-pwa workbox-window
```

**Konfigurasi `vite.config.js`:**
```javascript
import { VitePWA } from 'vite-plugin-pwa'

VitePWA({
  registerType: 'autoUpdate',
  workbox: {
    globPatterns: ['**/*.{js,css,html,ico,png,svg}'],
    runtimeCaching: [
      {
        urlPattern: /^https:\/\/.*\.supabase\.co\/.*/i,
        handler: 'NetworkFirst',
        options: {
          cacheName: 'supabase-cache',
          networkTimeoutSeconds: 10,
          cacheableResponse: { statuses: [0, 200] }
        }
      }
    ]
  },
  manifest: {
    name: 'NOVA — Next-gen One-stop Virtual Academy',
    short_name: 'NOVA',
    theme_color: '#1e40af',
    background_color: '#ffffff',
    display: 'standalone',
    start_url: '/',
    icons: [
      { src: '/icons/icon-192.png', sizes: '192x192', type: 'image/png' },
      { src: '/icons/icon-512.png', sizes: '512x512', type: 'image/png' }
    ]
  }
})
```

**Halaman offline fallback:**
- Buat `public/offline.html` — halaman sederhana yang tampil saat tidak ada koneksi
- Pesan: "Anda sedang offline. Data terakhir masih bisa diakses."

**Integrasi sync queue:**
Hubungkan `src/lib/sync.js` (sudah dibuat di Fase 1) dengan Service Worker:
- Saat online kembali → SW trigger sync queue
- Operasi yang antri (absensi, nilai, jurnal) dikirim ke Supabase
- Jika sukses → hapus dari queue; jika gagal → coba lagi maksimal 3x

**Strategi cache per tipe data:**

| Data | Strategi | Alasan |
|---|---|---|
| Asset statis (JS, CSS, gambar) | Cache First | Tidak berubah sering |
| Data jadwal | Stale While Revalidate | Berubah mingguan |
| Data absensi & nilai | Network First | Harus selalu terbaru |
| Halaman login | Network First | Auth harus fresh |

**Verifikasi:**
- App bisa diinstall dari browser
- Halaman utama tampil saat offline
- Data jadwal tersedia saat offline
- Absensi yang diinput offline terkirim saat kembali online
- Update SW tidak merusak sesi pengguna yang sedang aktif

---

### AREA 3 — Web Push & Notifikasi Push

**Setup VAPID keys:**
```bash
npx web-push generate-vapid-keys
```
Simpan di environment variables:
```
VITE_VAPID_PUBLIC_KEY=
VAPID_PRIVATE_KEY= (hanya di server/Edge Function)
```

**Alur Web Push:**
1. User login → browser minta izin notifikasi
2. Jika diizinkan → browser generate push subscription
3. Subscription dikirim ke Supabase → disimpan di tabel `push_subscriptions`
4. Saat event terjadi (absensi, pesan, nilai) → Supabase Edge Function kirim push

**Tabel `push_subscriptions`:**
```sql
id uuid primary key default gen_random_uuid()
user_id uuid references users(id) not null
school_id uuid references schools(id) not null
subscription jsonb not null -- endpoint, keys
created_at timestamptz default now()
updated_at timestamptz default now()
UNIQUE(user_id, subscription->>'endpoint')
```

**Supabase Edge Function `send-push`:**
```typescript
import webpush from 'npm:web-push'

Deno.serve(async (req) => {
  const { userId, title, body, url } = await req.json()
  
  // Ambil subscription user
  const { data: subs } = await supabase
    .from('push_subscriptions')
    .select('subscription')
    .eq('user_id', userId)
  
  // Kirim push ke semua device user
  for (const sub of subs) {
    await webpush.sendNotification(
      sub.subscription,
      JSON.stringify({ title, body, url })
    )
  }
  
  return new Response('OK')
})
```

**Event yang trigger push notification:**

| Event | Penerima | Judul | Isi |
|---|---|---|---|
| Absensi diinput | Ortu siswa terkait | "Kehadiran [nama]" | "[nama] [hadir/sakit/izin/alpha] hari ini" |
| Pesan baru diterima | Penerima pesan | "Pesan dari [pengirim]" | "[judul pesan]" |
| Pesan diedit | Penerima yang sudah baca | "Pesan diperbarui" | "[judul pesan] telah diperbarui" |
| Tugas baru dibuat | Siswa di kelas | "Tugas baru" | "[judul tugas] — deadline [tanggal]" |
| Tugas H-1 deadline | Siswa belum kumpul | "Deadline besok!" | "[judul tugas] harus dikumpul besok" |
| Rapor published | Siswa & ortu | "Rapor tersedia" | "Rapor semester [X] sudah bisa dilihat" |

**Verifikasi:**
- Izin notifikasi diminta saat login
- Push notification diterima saat event terjadi (uji dengan dua device berbeda)
- Notifikasi tap membuka halaman yang relevan di app
- Unsubscribe berfungsi saat user logout

---

### AREA 4 — Performa

**4A — Database Index:**

Jalankan query berikut untuk cek index yang ada:
```sql
SELECT tablename, indexname FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename;
```

Index yang wajib ada:
```sql
-- Core
CREATE INDEX IF NOT EXISTS idx_users_school_id ON users(school_id);
CREATE INDEX IF NOT EXISTS idx_users_role_id ON users(role_id);

-- Akademik
CREATE INDEX IF NOT EXISTS idx_attendances_school_id ON attendances(school_id);
CREATE INDEX IF NOT EXISTS idx_attendances_class_id ON attendances(class_id);
CREATE INDEX IF NOT EXISTS idx_attendances_student_id ON attendances(student_id);
CREATE INDEX IF NOT EXISTS idx_attendances_date ON attendances(date);
CREATE INDEX IF NOT EXISTS idx_grades_school_id ON grades(school_id);
CREATE INDEX IF NOT EXISTS idx_grades_student_id ON grades(student_id);
CREATE INDEX IF NOT EXISTS idx_grades_class_id ON grades(class_id);

-- Pembelajaran
CREATE INDEX IF NOT EXISTS idx_lesson_modules_cache_key ON lesson_modules(cache_key);
CREATE INDEX IF NOT EXISTS idx_submissions_assignment_id ON submissions(assignment_id);
CREATE INDEX IF NOT EXISTS idx_submissions_student_id ON submissions(student_id);

-- Komunikasi
CREATE INDEX IF NOT EXISTS idx_message_recipients_recipient_id ON message_recipients(recipient_id);
CREATE INDEX IF NOT EXISTS idx_message_recipients_is_read ON message_recipients(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
```

**4B — Query Optimization:**

Audit komponen React yang berpotensi N+1:
- Dashboard yang fetch data dalam loop
- Komponen yang re-fetch saat re-render tanpa dependency yang benar
- Query yang tidak menggunakan select spesifik (hindari `select *` di tabel besar)

Perbaiki dengan:
- Gunakan Supabase `.select()` dengan kolom spesifik
- Gunakan join di sisi Supabase bukan multiple fetch di React
- Implementasi `useMemo` dan `useCallback` di komponen berat

**4C — Bundle Size:**

```bash
npm run build -- --analyze
```

Jika ada chunk > 500KB:
- Implementasi lazy loading untuk halaman yang jarang diakses
- Split chunk laporan dan dashboard dari bundle utama

**Verifikasi:**
- Semua index terbuat
- Tidak ada komponen dengan N+1 query
- Build sukses tanpa warning bundle size kritis
- Lighthouse Performance score > 70 di mobile

---

### AREA 5 — Keamanan Final

**5A — Input Validation:**

Audit semua form dan input di seluruh platform:
- Nilai siswa: harus angka 0–100
- Tanggal: harus valid dan tidak di masa depan (untuk absensi)
- Field teks: trim whitespace, batasi panjang maksimal
- File upload (submissions): validasi tipe file dan ukuran maksimal 5MB

**5B — Auth Security:**

- Verifikasi semua protected route cek session sebelum render
- Pastikan token refresh berjalan — user tidak tiba-tiba logout
- Verifikasi logout membersihkan semua data lokal (IndexedDB, session storage)
- Rate limiting login: maksimal 5 percobaan gagal dalam 10 menit

**5C — Environment Variables:**

Scan seluruh codebase:
```bash
grep -r "supabase\|anthropic\|vapid" src/ --include="*.js" --include="*.jsx" --include="*.ts" | grep -v ".env"
```
Pastikan tidak ada key yang hardcoded.

**5D — Dependency Audit:**
```bash
npm audit
```
Perbaiki semua vulnerability level `high` dan `critical`.

**Verifikasi:**
- Tidak ada API key hardcoded di codebase
- Semua form punya validasi input
- Logout membersihkan semua data lokal
- `npm audit` tidak ada vulnerability high/critical

---

### AREA 6 — Onboarding & UX Polish

Sebelum produksi, pastikan pengalaman pertama kali pengguna mulus.

**6A — Empty States:**
Audit semua halaman — pastikan ada pesan yang jelas saat data kosong:
- Dashboard guru yang baru daftar: "Belum ada jadwal. Hubungi admin sekolah."
- Inbox kosong: "Tidak ada pesan masuk."
- Daftar siswa kosong: "Belum ada siswa terdaftar. Tambahkan siswa di menu manajemen."

**6B — Error States:**
Pastikan semua API call punya error handling yang ramah pengguna:
- Koneksi gagal: "Gagal memuat data. Periksa koneksi internet Anda."
- Session expired: redirect ke login dengan pesan "Sesi berakhir. Silakan login kembali."
- Rate limit tercapai: "Batas generate harian tercapai. Coba lagi besok."

**6C — Loading States:**
Pastikan semua fetch data punya skeleton loader atau spinner — tidak ada halaman yang kosong tiba-tiba.

**6D — Onboarding Checklist untuk Admin Baru:**
Setelah admin pertama kali login, tampilkan checklist onboarding:
```
[ ] Lengkapi profil sekolah
[ ] Tambahkan guru
[ ] Tambahkan siswa
[ ] Buat kelas
[ ] Atur jadwal pelajaran
[ ] Undang orang tua
```
Progress bar menunjukkan seberapa siap sekolah menggunakan platform.

---

### AREA 7 — Dokumen Final

**7A — Update CLAUDE.md:**
```markdown
## Status Fase
- [x] Fase 1: Foundation
- [x] Fase 2: Core Akademik
- [x] Fase 3: Penilaian
- [x] Fase 4: Pembelajaran
- [x] Fase 5: Komunikasi
- [x] Fase 6: Laporan & Dashboard
- [x] Fase 7: Hardening ✅ PLATFORM SIAP PRODUKSI

## Status Platform
PRODUCTION READY — [tanggal]
```

**7B — Buat `BACKLOG.md`:**
Catat semua ide fitur yang muncul selama development tapi tidak diimplementasi:
```markdown
# NOVA — Backlog Fitur

## Prioritas Tinggi
- [ ] ...

## Prioritas Sedang
- [ ] ...

## Prioritas Rendah
- [ ] ...
```

**7C — Buat `DEPLOYMENT.md`:**
Panduan deploy ke Vercel:
```markdown
# NOVA — Deployment Guide

## Environment Variables yang Dibutuhkan
- VITE_SUPABASE_URL
- VITE_SUPABASE_ANON_KEY
- VITE_ANTHROPIC_API_KEY
- VITE_VAPID_PUBLIC_KEY

## Langkah Deploy
1. Push ke branch main
2. Vercel auto-deploy
3. Set environment variables di Vercel dashboard
4. Verifikasi Supabase Edge Functions aktif
5. Test push notification di production
```

---

## CHECKLIST SELESAI FASE 7

### Area 1 — RLS Final
- [ ] Semua tabel diaudit — tidak ada yang missing RLS policy
- [ ] Semua skenario isolasi PASS
- [ ] `AUDIT_REPORT.md` diupdate dengan hasil final

### Area 2 — Service Worker & Offline
- [ ] SW aktif dan terdaftar
- [ ] App bisa diinstall dari browser
- [ ] Halaman utama tampil saat offline
- [ ] Sync queue berjalan saat kembali online

### Area 3 — Web Push
- [ ] VAPID keys dikonfigurasi
- [ ] Izin notifikasi diminta saat login
- [ ] Push notification diterima saat event terjadi
- [ ] Tap notifikasi membuka halaman yang relevan

### Area 4 — Performa
- [ ] Semua index database terbuat
- [ ] Tidak ada N+1 query
- [ ] Bundle size tidak ada chunk > 500KB kritis
- [ ] Lighthouse Performance > 70 di mobile

### Area 5 — Keamanan
- [ ] Tidak ada API key hardcoded
- [ ] Semua form punya validasi input
- [ ] Logout membersihkan semua data lokal
- [ ] `npm audit` tidak ada vulnerability high/critical

### Area 6 — UX Polish
- [ ] Semua halaman punya empty state yang jelas
- [ ] Semua error punya pesan ramah pengguna
- [ ] Semua fetch punya loading state
- [ ] Onboarding checklist untuk admin baru berfungsi

### Area 7 — Dokumen
- [ ] `CLAUDE.md` diupdate — status PRODUCTION READY
- [ ] `BACKLOG.md` terbuat
- [ ] `DEPLOYMENT.md` terbuat

---

## SETELAH FASE 7 SELESAI

Laporkan:
1. Checklist di atas — centang semua yang sudah selesai
2. URL production di Vercel
3. Hasil Lighthouse score (Performance, Accessibility, PWA)
4. `AUDIT_REPORT.md` final
5. Jika ada item yang tidak bisa diselesaikan — jelaskan kenapa

**NOVA siap produksi setelah semua checklist terpenuhi.**
