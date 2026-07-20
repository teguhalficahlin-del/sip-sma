-- SIP SMA: Schema gaps ditemukan saat provision Phase 3B
-- Kolom-kolom yang ada di SMK tapi belum ada di SMA schema awal

-- schools: tambah slug + secondary_color
ALTER TABLE public.schools
    ADD COLUMN IF NOT EXISTS slug            text UNIQUE,
    ADD COLUMN IF NOT EXISTS secondary_color text NOT NULL DEFAULT '#1e40af';
