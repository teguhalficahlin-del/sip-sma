-- SIP SMA: Drop semua tabel vocational SMK dari core schema
-- Schema operasional SMA tidak memerlukan domain vokasi

DROP TABLE IF EXISTS core.vocational_concentrations CASCADE;
DROP TABLE IF EXISTS core.vocational_programs CASCADE;
DROP TABLE IF EXISTS core.vocational_fields CASCADE;
