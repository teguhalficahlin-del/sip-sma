-- SIP SMA: Helper functions untuk RLS policies
-- Diadaptasi dari SIP SMK — referensi vocational (KAPRODI, DUDI, PKL) dihapus
-- Semua SECURITY DEFINER disertai REVOKE dua lapis (Rule §3a)

-- ──────────────────────────────────────────────────────────
-- 1. ROLE CHECKS (sederhana, tidak berubah dari SMK)
-- ──────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.fn_is_kepsek()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT EXISTS (
        SELECT 1 FROM users u
        WHERE u.auth_user_id = auth.uid()
          AND (u.role_type = 'KEPSEK' OR u.is_kepsek)
    );
$$;
REVOKE EXECUTE ON FUNCTION public.fn_is_kepsek() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_is_kepsek() FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_is_kepsek() TO authenticated;

CREATE OR REPLACE FUNCTION public.fn_is_bk()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT EXISTS (
        SELECT 1 FROM users u
        WHERE u.auth_user_id = auth.uid()
          AND (u.role_type = 'BK' OR u.is_bk)
    );
$$;
REVOKE EXECUTE ON FUNCTION public.fn_is_bk() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_is_bk() FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_is_bk() TO authenticated;

CREATE OR REPLACE FUNCTION public.fn_is_waka_kesiswaan()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT EXISTS (
        SELECT 1 FROM users u
        WHERE u.auth_user_id = auth.uid()
          AND (u.role_type = 'WAKA_KESISWAAN' OR u.is_waka_kesiswaan)
    );
$$;
REVOKE EXECUTE ON FUNCTION public.fn_is_waka_kesiswaan() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_is_waka_kesiswaan() FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_is_waka_kesiswaan() TO authenticated;

CREATE OR REPLACE FUNCTION public.fn_is_waka_kurikulum()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT EXISTS (
        SELECT 1 FROM users u
        WHERE u.auth_user_id = auth.uid()
          AND (u.role_type = 'WAKA_KURIKULUM' OR u.is_waka_kurikulum)
    );
$$;
REVOKE EXECUTE ON FUNCTION public.fn_is_waka_kurikulum() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_is_waka_kurikulum() FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_is_waka_kurikulum() TO authenticated;

-- SMA: WAKA_HUMAS tidak ada di enum role_type — stub returns false
CREATE OR REPLACE FUNCTION public.fn_is_waka_humas()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT false;
$$;
REVOKE EXECUTE ON FUNCTION public.fn_is_waka_humas() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_is_waka_humas() FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_is_waka_humas() TO authenticated;

-- ──────────────────────────────────────────────────────────
-- 2. OBSERVER / ACCESS LEVEL HELPERS (sebelum fn_can_see_student)
-- ──────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.fn_is_schoolwide_observer()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT EXISTS (
        SELECT 1 FROM users u
        WHERE u.auth_user_id = auth.uid()
          AND ( u.role_type IN ('BK','KEPSEK','WAKA_KURIKULUM','WAKA_KESISWAAN')
                OR u.is_bk OR u.is_kepsek OR u.is_waka_kurikulum OR u.is_waka_kesiswaan )
    );
$$;
REVOKE EXECUTE ON FUNCTION public.fn_is_schoolwide_observer() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_is_schoolwide_observer() FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_is_schoolwide_observer() TO authenticated;

-- ──────────────────────────────────────────────────────────
-- 3. STUDENT HELPER FUNCTIONS
-- ──────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.fn_current_student_id()
RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT student_id FROM students WHERE user_id = fn_current_user_id();
$$;
REVOKE EXECUTE ON FUNCTION public.fn_current_student_id() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_current_student_id() FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_current_student_id() TO authenticated;

CREATE OR REPLACE FUNCTION public.fn_student_in_current_school(p_student_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM students st
    WHERE st.student_id = p_student_id
      AND st.school_id  = fn_current_school_id()
  );
$$;
REVOKE EXECUTE ON FUNCTION public.fn_student_in_current_school(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_student_in_current_school(uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_student_in_current_school(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.fn_teaches_student(p_student_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT EXISTS (
        SELECT 1 FROM class_enrollments ce
        JOIN teaching_assignments ta ON ta.class_id = ce.class_id
        WHERE ce.student_id = p_student_id
          AND ta.user_id = fn_current_user_id()
          AND ta.is_active = true
          AND ce.withdrawn_at IS NULL
    );
$$;
REVOKE EXECUTE ON FUNCTION public.fn_teaches_student(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_teaches_student(uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_teaches_student(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.fn_wali_of_student(p_student_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT fn_wali_kelas_class_id() IS NOT NULL AND EXISTS (
        SELECT 1 FROM class_enrollments ce
        WHERE ce.student_id = p_student_id
          AND ce.class_id = fn_wali_kelas_class_id()
          AND ce.withdrawn_at IS NULL
    );
$$;
REVOKE EXECUTE ON FUNCTION public.fn_wali_of_student(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_wali_of_student(uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_wali_of_student(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.fn_guru_teaches_student(p_student_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM teaching_schedules ts
        JOIN class_enrollments  ce
          ON ce.class_id      = ts.class_id
         AND ce.academic_year  = ts.academic_year
        WHERE ts.scheduled_teacher_id = fn_current_user_id()
          AND ts.school_id            = fn_current_school_id()
          AND ce.student_id      = p_student_id
          AND ce.withdrawn_at   IS NULL
    );
$$;
REVOKE EXECUTE ON FUNCTION public.fn_guru_teaches_student(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_guru_teaches_student(uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_guru_teaches_student(uuid) TO authenticated;

-- SMA: fn_can_see_student — tanpa KAPRODI (tidak ada di SMA)
CREATE OR REPLACE FUNCTION public.fn_can_see_student(p_student_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT fn_is_schoolwide_observer()
        OR fn_teaches_student(p_student_id)
        OR fn_wali_of_student(p_student_id);
$$;
REVOKE EXECUTE ON FUNCTION public.fn_can_see_student(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_can_see_student(uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_can_see_student(uuid) TO authenticated;

-- ──────────────────────────────────────────────────────────
-- 3. SCHOOL / PERIOD HELPERS
-- ──────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.fn_is_period_closed(p_date date, p_school_id uuid)
RETURNS boolean LANGUAGE sql STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM academic_periods
        WHERE school_id   = p_school_id
          AND start_date <= p_date
          AND end_date   >= p_date
          AND status      = 'CLOSED'
    );
$$;
REVOKE EXECUTE ON FUNCTION public.fn_is_period_closed(date, uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_is_period_closed(date, uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_is_period_closed(date, uuid) TO authenticated;

-- ──────────────────────────────────────────────────────────
-- 5. CASE HELPERS
-- ──────────────────────────────────────────────────────────

-- SMA: fn_is_internal_case_actor — tanpa KAPRODI
CREATE OR REPLACE FUNCTION public.fn_is_internal_case_actor()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT fn_current_user_role() = ANY (ARRAY['GURU','BK','WALI_KELAS','WAKA_KESISWAAN','KEPSEK']::role_type[])
        OR fn_is_bk() OR fn_is_kepsek() OR fn_is_waka_kesiswaan();
$$;
REVOKE EXECUTE ON FUNCTION public.fn_is_internal_case_actor() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_is_internal_case_actor() FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_is_internal_case_actor() TO authenticated;

CREATE OR REPLACE FUNCTION public.fn_is_case_subject_or_parent(p_case_id uuid, p_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT EXISTS (
        SELECT 1 FROM cases c
        JOIN students s ON s.student_id = c.student_id
        WHERE c.case_id   = p_case_id
          AND c.school_id = fn_current_school_id()
          AND (
              s.user_id = p_user_id
              OR EXISTS (
                  SELECT 1 FROM student_parents sp
                  WHERE sp.student_id    = s.student_id
                    AND sp.parent_user_id = p_user_id
              )
          )
    );
$$;
REVOKE EXECUTE ON FUNCTION public.fn_is_case_subject_or_parent(uuid, uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_is_case_subject_or_parent(uuid, uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_is_case_subject_or_parent(uuid, uuid) TO authenticated;

-- SMA: fn_matches_case_handler — tanpa cabang KAPRODI
CREATE OR REPLACE FUNCTION public.fn_matches_case_handler(p_handler_role role_type, p_student_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
    SELECT fn_current_user_role() = p_handler_role
        OR (p_handler_role = 'BK'::role_type             AND fn_is_bk())
        OR (p_handler_role = 'KEPSEK'::role_type         AND fn_is_kepsek())
        OR (p_handler_role = 'WAKA_KESISWAAN'::role_type AND fn_is_waka_kesiswaan())
        OR (p_handler_role = 'WAKA_KURIKULUM'::role_type AND fn_is_waka_kurikulum())
        -- WAKA_HUMAS tidak ada di SMA (enum tidak punya nilai ini)
        OR (p_handler_role = 'WALI_KELAS'::role_type     AND fn_wali_of_student(p_student_id));
$$;
REVOKE EXECUTE ON FUNCTION public.fn_matches_case_handler(role_type, uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_matches_case_handler(role_type, uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_matches_case_handler(role_type, uuid) TO authenticated;

-- SMA: fn_can_see_case — tanpa DUDI, tanpa RESTRICTED audience
-- (case_audience_members belum ada di schema SMA)
CREATE OR REPLACE FUNCTION public.fn_can_see_case(p_case_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM cases c
    WHERE c.case_id   = p_case_id
      AND c.school_id = fn_current_school_id()
      AND (
        fn_involved_in_case(p_case_id)
        OR (
          c.audience != 'PRIVATE'
          AND fn_matches_case_handler(c.current_handler_role, c.student_id)
        )
        OR (c.audience = 'PUBLIC' AND fn_is_internal_case_actor())
      )
  )
$$;
REVOKE EXECUTE ON FUNCTION public.fn_can_see_case(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_can_see_case(uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_can_see_case(uuid) TO authenticated;

-- ──────────────────────────────────────────────────────────
-- 6. FORUM HELPERS
-- ──────────────────────────────────────────────────────────

-- SMA: fn_get_forum_members — tanpa cabang KAPRODI (kaprodi_program_id tidak ada)
CREATE OR REPLACE FUNCTION public.fn_get_forum_members(p_class_id uuid, p_academic_year text, p_visibility text DEFAULT 'INTERNAL')
RETURNS TABLE(user_id uuid) LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_school_id  UUID;
BEGIN
    SELECT c.school_id INTO v_school_id
    FROM   classes c WHERE c.class_id = p_class_id;

    IF v_school_id IS NULL THEN RETURN; END IF;

    RETURN QUERY

    -- 1. Wali Kelas
    SELECT DISTINCT u.user_id FROM users u
    WHERE  u.wali_kelas_class_id = p_class_id
      AND  u.school_id = v_school_id AND u.is_active = true AND u.deleted_at IS NULL

    UNION

    -- 2. Guru Mapel
    SELECT DISTINCT ta.user_id FROM teaching_assignments ta
    WHERE  ta.class_id = p_class_id AND ta.academic_year = p_academic_year
      AND  ta.is_active = true AND ta.school_id = v_school_id

    UNION

    -- 3. Guru Wali
    SELECT DISTINCT gwa.guru_user_id FROM guru_wali_assignments gwa
    WHERE  gwa.academic_year = p_academic_year AND gwa.is_active = true
      AND  gwa.school_id = v_school_id
      AND  gwa.student_id IN (
               SELECT ce.student_id FROM class_enrollments ce
               WHERE  ce.class_id = p_class_id AND ce.academic_year = p_academic_year
                 AND  ce.withdrawn_at IS NULL AND ce.school_id = v_school_id
           )

    UNION

    -- 4. BK yang ditugaskan ke kelas ini
    SELECT DISTINCT bca.bk_user_id FROM bk_class_assignments bca
    WHERE  bca.class_id = p_class_id AND bca.academic_year = p_academic_year
      AND  bca.is_active = true AND bca.school_id = v_school_id

    UNION

    -- 5. Waka Kesiswaan, Kepsek, Administrative
    SELECT DISTINCT u.user_id FROM users u
    WHERE  u.school_id = v_school_id AND u.is_active = true AND u.deleted_at IS NULL
      AND  (
               u.role_type IN ('WAKA_KESISWAAN','KEPSEK','ADMINISTRATIVE')
               OR u.is_waka_kesiswaan = true OR u.is_kepsek = true
           )

    UNION

    -- 6. Ortu siswa aktif di kelas (hanya jika PARENT_VISIBLE)
    SELECT DISTINCT sp.parent_user_id
    FROM   student_parents sp
    JOIN   class_enrollments ce ON ce.student_id = sp.student_id
    WHERE  p_visibility = 'PARENT_VISIBLE'
      AND  ce.class_id = p_class_id AND ce.academic_year = p_academic_year
      AND  ce.withdrawn_at IS NULL AND ce.school_id = v_school_id
      AND  sp.school_id = v_school_id;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.fn_get_forum_members(uuid, text, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_get_forum_members(uuid, text, text) FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_get_forum_members(uuid, text, text) TO authenticated;
