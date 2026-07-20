-- Tambah kolom is_waka_humas, implementasi fn_is_waka_humas(),
-- dan update fn_matches_case_handler() untuk WAKA_HUMAS.
-- Konteks SMA: publikasi, komite sekolah, PPDB, hubungan pemda
-- dan perguruan tinggi. BUKAN PKL/DUDI/BKK (konteks SMK).

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS is_waka_humas BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN users.is_waka_humas IS
    'TRUE = berperan sebagai Wakil Kepala Bidang Humas (SMA: publikasi, '
    'komite sekolah, PPDB, hubungan pemda & perguruan tinggi).';

CREATE OR REPLACE FUNCTION fn_is_waka_humas()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM users u
        WHERE u.auth_user_id = auth.uid()
          AND u.school_id    = fn_current_school_id()
          AND (u.role_type = 'WAKA_HUMAS' OR u.is_waka_humas)
    );
$$;

REVOKE EXECUTE ON FUNCTION fn_is_waka_humas() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION fn_is_waka_humas() FROM anon;
GRANT  EXECUTE ON FUNCTION fn_is_waka_humas() TO authenticated;

CREATE OR REPLACE FUNCTION fn_matches_case_handler(
    p_handler_role role_type,
    p_student_id   uuid
)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    SELECT fn_current_user_role() = p_handler_role
        OR (p_handler_role = 'BK'::role_type             AND fn_is_bk())
        OR (p_handler_role = 'KEPSEK'::role_type         AND fn_is_kepsek())
        OR (p_handler_role = 'WAKA_KESISWAAN'::role_type AND fn_is_waka_kesiswaan())
        OR (p_handler_role = 'WAKA_KURIKULUM'::role_type AND fn_is_waka_kurikulum())
        OR (p_handler_role = 'WAKA_HUMAS'::role_type     AND fn_is_waka_humas())
        OR (p_handler_role = 'WALI_KELAS'::role_type     AND fn_wali_of_student(p_student_id));
$$;
