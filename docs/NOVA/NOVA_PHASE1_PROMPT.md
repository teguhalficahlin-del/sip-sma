# NOVA — Prompt Master Claude Code
## Fase 1: Foundation
**Gunakan prompt ini sebagai pesan pertama ke Claude Code.**

---

## IDENTITAS PROJECT

Kamu adalah Claude Code yang akan membangun **NOVA (Next-gen One-stop Virtual Academy)** — platform PWA multi-tenant sistem informasi sekolah untuk SD-SMP-SMA.

Dokumen ini adalah instruksi lengkap untuk Fase 1. Baca seluruh dokumen ini sebelum menulis satu baris kode pun.

---

## TUJUAN PLATFORM

Membangun sistem informasi sekolah multi-tenant yang menjadi satu-satunya sistem operasional bagi sekolah yang belum punya sistem apapun — mencakup administrasi, pengelolaan pembelajaran, dan komunikasi sekolah-orang tua.

---

## STACK TEKNOLOGI

| Layer | Teknologi |
|---|---|
| Frontend | React + Vite + Tailwind CSS |
| PWA | manifest.json (tanpa Service Worker — diaktifkan di Fase 7) |
| Backend & DB | Supabase (PostgreSQL + RLS) |
| AI | Anthropic Claude API |
| Offline | IndexedDB + sync queue (struktur siap, SW belum aktif) |
| Deployment | Vercel |

---

## ARSITEKTUR MULTI-TENANT

- Satu database PostgreSQL
- Isolasi data via `school_id` di setiap tabel
- Row Level Security (RLS) Supabase wajib aktif di semua tabel
- Setiap user hanya bisa akses data sekolahnya sendiri

---

## ATURAN KERJA WAJIB

1. **Baca dulu, kode kemudian** — analisis seluruh instruksi sebelum mulai
2. **Satu langkah selesai sebelum lanjut** — jangan overlap antar langkah
3. **Tidak ada placeholder** — semua kode harus fungsional dan dapat dijalankan
4. **RLS wajib diuji** — setiap tabel yang dibuat harus diverifikasi isolasinya
5. **Mobile-first wajib** — semua UI diuji logikanya di 320px terlebih dahulu
6. **Tidak ada keputusan arsitektur mandiri** — jika ada ambiguitas, tulis pertanyaan dan tunggu konfirmasi
7. **Commit per langkah** — setiap langkah selesai langsung commit dengan pesan yang deskriptif

---

## FASE 1 — FOUNDATION

### Target Fase 1
Sistem multi-tenant berjalan penuh:
- Semua role bisa login
- RLS aktif dan terverifikasi
- Onboarding sekolah baru berfungsi
- Scaffold PWA siap

### Langkah-langkah

#### LANGKAH 1 — Setup Repository
1. Buat repository baru di GitHub dengan nama `nova-platform` (akun: `teguhalficahlin-del`)
2. Init project React + Vite + Tailwind CSS
3. **Jangan install Workbox atau vite-plugin-pwa** — Service Worker diaktifkan di Fase 7
4. Setup struktur folder:
```
nova-platform/
├── src/
│   ├── components/
│   ├── pages/
│   ├── hooks/
│   ├── lib/
│   │   ├── supabase.js
│   │   ├── indexeddb.js
│   │   └── sync.js
│   ├── stores/
│   └── utils/
├── supabase/
│   └── migrations/
├── public/
├── SPEC.md
└── CLAUDE.md
```
5. Push initial commit ke GitHub

**Verifikasi:** Repository aktif di GitHub, `npm run dev` berjalan tanpa error.

---

#### LANGKAH 2 — Koneksi Supabase
1. Install Supabase client: `npm install @supabase/supabase-js`
2. Buat `src/lib/supabase.js` dengan koneksi ke project Supabase yang sudah ada
3. Setup environment variables:
```
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
```
4. Buat `.env.example` — jangan commit `.env` ke GitHub

**Verifikasi:** Koneksi ke Supabase berhasil dari browser.

---

#### LANGKAH 3 — Skema Database & RLS
Buat migration file di `supabase/migrations/` untuk tabel berikut:

**Tabel `schools`**
```sql
id uuid primary key default gen_random_uuid()
name text not null
level text not null -- 'SD' | 'SMP' | 'SMA'
address text
phone text
email text
region text -- wilayah sekolah, digunakan untuk filter akses Dinas Pendidikan
license_status text default 'free' -- 'free' | 'paid'
student_count integer default 0
active_academic_year text default '2025/2026' -- tahun ajaran aktif
active_semester integer default 1 -- semester aktif: 1 | 2
created_at timestamptz default now()
```

**Tabel `roles`**
```sql
id uuid primary key default gen_random_uuid()
name text not null -- 'admin' | 'kepala_sekolah' | 'guru' | 'siswa' | 'ortu' | 'komite' | 'dinas'
```

**Tabel `users`**
```sql
id uuid primary key references auth.users(id)
school_id uuid references schools(id)
role_id uuid references roles(id)
full_name text not null
identifier text -- NIS untuk siswa, no HP untuk ortu, email untuk lainnya
region text -- diisi untuk role dinas: wilayah yang bisa diakses
is_homeroom_teacher boolean default false
homeroom_class_id uuid -- diisi jika is_homeroom_teacher = true
is_vice_principal boolean default false
is_active boolean default true
created_at timestamptz default now()
```

**Tabel `licenses`**
```sql
id uuid primary key default gen_random_uuid()
school_id uuid references schools(id)
tier text not null -- 'free' | 'paid'
student_limit integer
activated_at timestamptz
created_at timestamptz default now()
```

**Tabel `class_members`** (relasi siswa ke kelas):
```sql
id uuid primary key default gen_random_uuid()
school_id uuid references schools(id) not null
class_id uuid references classes(id) not null
student_id uuid references users(id) not null
academic_year text not null
is_active boolean default true
created_at timestamptz default now()
UNIQUE(class_id, student_id, academic_year)
```

**Tabel `parent_student`** (relasi orang tua ke siswa):
```sql
id uuid primary key default gen_random_uuid()
school_id uuid references schools(id) not null
parent_id uuid references users(id) not null
student_id uuid references users(id) not null
created_at timestamptz default now()
UNIQUE(parent_id, student_id)
```

**Catatan: Tabel `class_members` dan `parent_student` dibuat di Fase 1 tapi diisi datanya saat onboarding (Langkah 5).**

**RLS yang wajib diterapkan:**
- `schools`: hanya bisa diakses oleh user dengan `school_id` yang sama
- `users`: hanya bisa diakses oleh user dalam sekolah yang sama
- `licenses`: hanya bisa diakses oleh admin sekolah yang bersangkutan
- Dinas Pendidikan: akses read-only ke semua sekolah dalam wilayah (tandai dengan flag `region`)

**Verifikasi RLS:**
Setelah migration, jalankan query test:
1. Login sebagai user sekolah A → pastikan tidak bisa lihat data sekolah B
2. Login sebagai admin → pastikan bisa kelola data sekolahnya sendiri

---

#### LANGKAH 4 — Autentikasi
Implementasi login per role:

| Role | Metode |
|---|---|
| Admin / Kepala Sekolah | Email + password (Supabase Auth) |
| Guru | Email + password (Supabase Auth) |
| Siswa | NIS + password (custom auth via tabel users) |
| Orang Tua | No. HP + OTP WhatsApp (Supabase Phone Auth) |
| Komite | Email + password (Supabase Auth) |
| Dinas Pendidikan | Email + password (Supabase Auth) |

Buat:
- `src/pages/Login.jsx` — satu halaman login, deteksi role otomatis setelah auth
  - Deteksi format input: angka saja → coba sebagai NIS (siswa); mengandung "@" → email (guru/admin/kepsek/komite/dinas); angka panjang (10-13 digit) → no HP (ortu)
  - Tampilkan field yang sesuai berdasarkan deteksi format
- `src/hooks/useAuth.js` — hook untuk state autentikasi
- `src/lib/auth.js` — fungsi login, logout, session management
- Protected routes berdasarkan role
- Redirect ke dashboard sesuai role setelah login

**Verifikasi:** Semua 6 role bisa login dan diarahkan ke halaman yang benar.

---

#### LANGKAH 5 — Onboarding Sekolah
Buat alur onboarding untuk sekolah baru:

1. Halaman registrasi sekolah (`src/pages/Register.jsx`):
   - Input: nama sekolah, jenjang (SD/SMP/SMA), alamat, email, no HP admin
   - Sistem generate `school_id` otomatis
   - Buat akun admin pertama

2. Dashboard admin pasca registrasi:
   - Input data guru (manual)
   - Input data siswa (manual + import CSV)
   - Sistem generate akun otomatis per guru & siswa
   - Undang orang tua via WhatsApp OTP

**Verifikasi:** Sekolah baru bisa mendaftar, admin bisa login, guru & siswa bisa dibuat dari dashboard admin.

---

#### LANGKAH 5B — Feature Access Hook
Buat `src/hooks/useFeatureAccess.js`:

```javascript
// Daftar fitur per tier
const PAID_FEATURES = [
  'grades', 'lesson_modules', 'assignments', 'submissions',
  'teaching_journals', 'messages', 'notifications',
  'dashboard_stats', 'reports_full'
]

export function useFeatureAccess(featureName) {
  const { school } = useAuth()
  const isPaid = school?.license_tier === 'paid'
  const isLocked = PAID_FEATURES.includes(featureName) && !isPaid

  return {
    isLocked,
    isPaid,
    isFree: !isLocked
  }
}
```

Gunakan di setiap komponen fitur berbayar:
```jsx
const { isLocked } = useFeatureAccess('grades')
if (isLocked) return <LockedFeatureCard message="Fitur ini tersedia di versi lengkap NOVA." />
```

Buat `src/components/LockedFeatureCard.jsx` — tampilan kartu terkunci dengan pesan dan tombol "Info Upgrade".

**Verifikasi:** Fitur berbayar tampil terkunci di sekolah tier gratis, terbuka di sekolah tier berbayar.

---

#### LANGKAH 6 — PWA Setup
**Catatan: Service Worker TIDAK diaktifkan di fase ini. Diaktifkan di Fase 7 setelah platform stabil.**

1. Buat `public/manifest.json`:
   - Nama: NOVA
   - Short name: NOVA
   - Theme color: sesuai desain
   - Icons: placeholder dulu, akan diganti
   - Start URL: `/`
   - Display: `standalone`
2. Link `manifest.json` di `index.html`
3. Setup IndexedDB di `src/lib/indexeddb.js`:
   - Database: `nova-db`
   - Store awal: `sync_queue`, `user_session`
4. Setup sync queue di `src/lib/sync.js`:
   - Struktur antrian siap
   - Belum dihubungkan ke SW — akan diaktifkan di Fase 7

**Verifikasi:** App bisa diinstall dari browser (manifest terbaca). Tidak perlu verifikasi offline di fase ini.

---

#### LANGKAH 7 — CLAUDE.md
Buat file `CLAUDE.md` di root repository dengan isi:

```markdown
# NOVA — Claude Code Context

## Status Fase
- [x] Fase 1: Foundation
- [ ] Fase 2: Core Akademik
- [ ] Fase 3: Penilaian
- [ ] Fase 4: Pembelajaran
- [ ] Fase 5: Komunikasi
- [ ] Fase 6: Laporan & Dashboard
- [ ] Fase 7: Hardening

## Arsitektur
- Multi-tenant: satu database, isolasi via school_id + RLS
- Stack: React + Vite + Tailwind, Supabase, Claude API, IndexedDB + sync queue (SW aktif di Fase 7)
- Deployment: Vercel

## Aturan Kerja
1. Baca SPEC.md sebelum memulai fase baru
2. Satu langkah selesai sebelum lanjut
3. Tidak ada placeholder
4. RLS wajib diuji di setiap fase
5. Mobile-first wajib di semua UI
6. Commit per langkah

## Keputusan Arsitektur yang Sudah Fix
- [2026-07-07] Multi-tenant: school_id + RLS (bukan schema-per-school)
- [2026-07-07] Stack: Hybrid cloud (Supabase → VPS)
- [2026-07-07] Auth ortu: WhatsApp OTP
- [2026-07-07] Auth siswa: NIS + password
- [2026-07-07] Service Worker: tidak diaktifkan di Fase 1–6, diaktifkan di Fase 7 (Hardening)
```

---

## CHECKLIST SELESAI FASE 1

Sebelum melaporkan Fase 1 selesai, verifikasi semua item ini:

- [ ] Repository aktif di GitHub (`teguhalficahlin-del/nova-platform`)
- [ ] `npm run dev` berjalan tanpa error
- [ ] Semua 4 tabel (schools, roles, users, licenses) terbuat di Supabase
- [ ] RLS aktif dan terverifikasi — user sekolah A tidak bisa lihat data sekolah B
- [ ] Semua 6 role bisa login dan redirect ke dashboard yang benar
- [ ] Onboarding sekolah baru berfungsi end-to-end
- [ ] PWA bisa diinstall dari browser (manifest.json terbaca)
- [ ] IndexedDB & sync queue struktur siap (SW belum aktif — normal)
- [ ] `CLAUDE.md` terbuat di root repository
- [ ] Semua langkah sudah di-commit ke GitHub

---

## SETELAH FASE 1 SELESAI

Laporkan:
1. URL repository GitHub
2. Checklist di atas — centang semua yang sudah selesai
3. Jika ada item yang tidak bisa diselesaikan — jelaskan kenapa dan tunggu instruksi

**Jangan mulai Fase 2 sebelum mendapat konfirmasi.**
