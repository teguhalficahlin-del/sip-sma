-- SIP SMA: Platform helper functions untuk superadmin dashboard
-- fn_school_staff_health + fn_school_student_health
-- Dipanggil oleh edge function list-schools via service role (bypass RLS)

-- ──────────────────────────────────────────────────────────
-- fn_school_staff_health
-- Returns: per-school staff role counts
-- SMA: waka_humas_count selalu 0 (WAKA_HUMAS tidak ada di enum)
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_school_staff_health()
RETURNS TABLE (
    school_id            uuid,
    kepsek_count         bigint,
    waka_kurikulum_count bigint,
    waka_kesiswaan_count bigint,
    waka_humas_count     bigint,
    staff_count          bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
        u.school_id,
        count(*) FILTER (WHERE u.role_type = 'KEPSEK'::role_type)          AS kepsek_count,
        count(*) FILTER (WHERE u.role_type = 'WAKA_KURIKULUM'::role_type)  AS waka_kurikulum_count,
        count(*) FILTER (WHERE u.role_type = 'WAKA_KESISWAAN'::role_type)  AS waka_kesiswaan_count,
        0::bigint                                                            AS waka_humas_count,
        count(*) FILTER (
            WHERE u.role_type NOT IN ('SISWA'::role_type, 'ORTU'::role_type)
              AND u.is_active = true
        ) AS staff_count
    FROM users u
    GROUP BY u.school_id
$$;

REVOKE EXECUTE ON FUNCTION public.fn_school_staff_health() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_school_staff_health() FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_school_staff_health() TO authenticated;
GRANT  EXECUTE ON FUNCTION public.fn_school_staff_health() TO service_role;

-- ──────────────────────────────────────────────────────────
-- fn_school_student_health
-- Returns: per-school student count vs provisioned (punya akun login)
-- provisioned = ada di auth.users via user_id di users table dengan role SISWA
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_school_student_health()
RETURNS TABLE (
    school_id         uuid,
    student_count     bigint,
    provisioned_count bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
        s.school_id,
        count(*)                                               AS student_count,
        count(*) FILTER (WHERE s.user_id IS NOT NULL)          AS provisioned_count
    FROM students s
    WHERE s.student_status = 'AKTIF'::student_status
    GROUP BY s.school_id
$$;

REVOKE EXECUTE ON FUNCTION public.fn_school_student_health() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_school_student_health() FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_school_student_health() TO authenticated;
GRANT  EXECUTE ON FUNCTION public.fn_school_student_health() TO service_role;
