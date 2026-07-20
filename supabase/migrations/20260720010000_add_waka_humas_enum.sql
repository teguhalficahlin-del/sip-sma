-- Tambah nilai WAKA_HUMAS ke enum role_type.
-- Dipisah ke migration tersendiri karena ALTER TYPE ADD VALUE
-- tidak bisa dijalankan dalam transaksi (PostgreSQL constraint).
ALTER TYPE role_type ADD VALUE IF NOT EXISTS 'WAKA_HUMAS';
