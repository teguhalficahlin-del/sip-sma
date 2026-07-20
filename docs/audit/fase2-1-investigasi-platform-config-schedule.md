# Fase 2.1 — Investigasi: `platform_config` & `schedule_time_slots`
**Tanggal:** 2026-07-06  
**Metode:** grep codebase + baca migration SQL (READ-ONLY, tidak ada perubahan)  
**Tujuan:** Klarifikasi dua tabel 🟠 HIGH dari laporan RLS Coverage Audit

---

## 1. `platform_config`

### Skema & Sifat Data

```sql
-- migration 20260702140000_platform_maintenance.sql
CREATE TABLE public.platform_config (
    id                 SMALLINT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    maintenance_active BOOLEAN  NOT NULL DEFAULT FALSE,
    maintenance_message TEXT,
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
INSERT INTO public.platform_config (id) VALUES (1) ON CONFLICT (id) DO NOTHING;
```

**Kesimpulan:** Tabel **platform-wide**, satu baris global (`id = 1`). Tidak ada kolom `school_id`. Berisi satu hal: flag maintenance dan pesannya. Tidak ada data tenant.

### Siapa yang Mengakses

| Jalur | Metode | Aktor | Keterangan |
|---|---|---|---|
| `supabase/functions/set-maintenance/index.ts` | `getAdminClient()` (service_role) | Superadmin via `X-Superadmin-Key` | GET: baca status; PATCH: ubah flag |
| `shared/branding.js` | RPC `fn_maintenance_status` (anon key) | **Semua portal** (branding.js diimpor semua) | Hanya baca `active` + `message` |
| Tidak ada | `.from('platform_config')` langsung dari authenticated client | — | **Tidak ditemukan di codebase** |

### Bagaimana `fn_maintenance_status` Bekerja

```sql
-- SECURITY DEFINER, dapat dipanggil anon
CREATE OR REPLACE FUNCTION public.fn_maintenance_status()
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER
AS $$ SELECT jsonb_build_object(
    'active',  COALESCE(maintenance_active, FALSE),
    'message', maintenance_message
) FROM platform_config WHERE id = 1; $$;

GRANT EXECUTE ON FUNCTION public.fn_maintenance_status() TO anon, authenticated;
```

Fungsi hanya mengembalikan dua field (`active`, `message`). Tidak mengekspos kolom `updated_at` atau `id`.

### Mengapa "Zero Policy" Ini Wajar

- Tabel **bukan data tenant** — tidak ada `school_id`, tidak ada data per-sekolah
- Satu-satunya nilai yang perlu dibaca tenant (banner maintenance) sudah tersedia via RPC `fn_maintenance_status` yang hanya mengembalikan subset aman
- Penulisan hanya lewat edge function `set-maintenance` yang diauthentikasi oleh `X-Superadmin-Key` (service_role)
- Tidak ada jalur `.from('platform_config')` dari client tenant maupun anon
- RLS enabled = default deny total untuk siapa pun yang mencoba `.from('platform_config')` langsung

**Status:** Desain sudah benar. Zero policy adalah perlindungan yang disengaja, bukan kelalaian.

---

## 2. `schedule_time_slots`

### Skema & Sifat Data

```sql
CREATE TABLE schedule_time_slots (
    slot_id      UUID        PRIMARY KEY,
    school_id    UUID        NOT NULL REFERENCES schools,   -- per-sekolah
    academic_year VARCHAR(9) NOT NULL,
    semester     semester    NOT NULL,
    day_of_week  day_of_week NOT NULL,
    slot_number  INTEGER     NOT NULL,
    start_time   TIME        NOT NULL,
    end_time     TIME        NOT NULL,
    is_break     BOOLEAN     NOT NULL DEFAULT FALSE,
    break_label  VARCHAR(50),                               -- label istirahat saja
    created_at   TIMESTAMPTZ NOT NULL
);
```

**Kesimpulan:** Tabel per-sekolah (`school_id NOT NULL`). Berisi **metadata jadwal**: jam mulai/selesai, nomor slot, apakah slot itu istirahat. **Tidak ada** kolom: nama guru, nama siswa, ruangan, biaya, atau data sensitif lain.

### Siapa yang Membaca di Frontend

| File | Fungsi/Konteks | Role yang Bisa Akses |
|---|---|---|
| `admin/js/api.js` → `getTimeSlots()` | Baca semua slot untuk hari tertentu (`select *`) | ADMINISTRATIVE (portal admin) |
| `admin/js/api.js` → `saveTimeSlots()` | DELETE + INSERT slot | ADMINISTRATIVE |
| `admin/js/schedule-builder.js` | Builder jadwal — saat TU menyusun struktur slot waktu | ADMINISTRATIVE |
| `admin/js/dashboard.js` (baris ~1483) | Preview jadwal di dashboard admin | ADMINISTRATIVE |

**Portal lain:** Tidak ditemukan referensi `schedule_time_slots` maupun `getTimeSlots` di `guru/`, `parent/`, `student/`, `dudi/`, `stakeholder/`, `superadmin/`.

### Policy RLS Saat Ini (versi terakhir — mig `20260701350000`)

```sql
-- READ: semua role yang terautentikasi di sekolah yang sama
CREATE POLICY rls_time_slots_read ON schedule_time_slots FOR SELECT
    USING (school_id = fn_current_school_id());

-- WRITE: hanya ADMINISTRATIVE sekolah yang sama
CREATE POLICY rls_time_slots_write ON schedule_time_slots FOR ALL
    USING (school_id = fn_current_school_id()
        AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type)
    WITH CHECK (school_id = fn_current_school_id()
        AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);
```

### Analisis: Apakah READ Policy Terlalu Lebar?

Policy `rls_time_slots_read` mengizinkan **semua role terautentikasi** di sekolah yang sama (GURU, ORTU, SISWA, DUDI, STAKEHOLDER, dll.) membaca tabel ini — namun:

- Di kode frontend yang ada, **hanya portal admin yang membacanya** (tidak ada `getTimeSlots` di portal lain)
- Kolom yang tersedia tidak mengandung data sensitif (hanya jam, nomor slot, label istirahat)
- Tabel ini adalah metadata operasional jadwal — setara dengan "jam mulai pelajaran di hari Senin", bukan data personal

**Potensi risiko:** Jika portal guru/siswa suatu saat perlu menampilkan jadwal, mereka akan bisa membaca tabel ini tanpa perlu perubahan policy — ini bisa dianggap **sengaja atau tidak sengaja** terbuka lebar.

---

## Ringkasan Temuan untuk Keputusan

| Tabel | Status Saat Ini | Kekhawatiran | Pertanyaan untuk Diputuskan |
|---|---|---|---|
| `platform_config` | Zero policy = default deny total. Semua akses sudah lewat RPC/edge fn. | **Tidak ada kekhawatiran** — desain sudah tepat. | Tidak perlu keputusan. |
| `schedule_time_slots` | READ terbuka ke semua role terautentikasi (hanya dibatasi `school_id`). | Policy lebih lebar dari penggunaan aktual (hanya admin pakai). Kolom tidak sensitif. | Apakah READ perlu dibatasi ke ADMINISTRATIVE saja (sesuai penggunaan aktual), ataukah biarkan terbuka untuk memudahkan fitur jadwal publik di masa depan (guru/siswa melihat jam pelajaran)? |

**Catatan:** Tidak ada rekomendasi dibuat di sini — kedua pilihan untuk `schedule_time_slots` punya argumen yang valid. Fakta di atas disajikan agar Romo bisa memutuskan berdasarkan rencana fitur ke depan.
