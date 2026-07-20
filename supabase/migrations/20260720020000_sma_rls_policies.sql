-- SIP SMA: RLS Policies + Enable RLS
-- Diadaptasi dari SIP SMK — referensi DUDI, KAPRODI, PKL dihapus
-- Tabel yang belum punya RLS di-enable di sini

-- ──────────────────────────────────────────────────────────
-- ENABLE RLS pada tabel yang belum aktif
-- ──────────────────────────────────────────────────────────
ALTER TABLE public.evaluation_logs              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_post_acknowledgements  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_post_audience          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_post_comments          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_post_subjects          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_posts                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.generation_jobs              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ld_prompt_templates          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prompt_templates             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_document_approvals   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_document_classes     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_documents            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_profiles             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teaching_contexts            ENABLE ROW LEVEL SECURITY;

-- core schema
ALTER TABLE core.capaian_pembelajaran           ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.cp_elements                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.curriculum_versions            ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.education_levels               ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.knowledge_national             ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.phases                         ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.subject_phases                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.subjects                       ENABLE ROW LEVEL SECURITY;

-- ──────────────────────────────────────────────────────────
-- CORE SCHEMA: read-only untuk semua authenticated
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS core_capaian_pembelajaran_read   ON core.capaian_pembelajaran;
DROP POLICY IF EXISTS core_cp_elements_read            ON core.cp_elements;
DROP POLICY IF EXISTS core_curriculum_versions_read    ON core.curriculum_versions;
DROP POLICY IF EXISTS core_education_levels_read       ON core.education_levels;
DROP POLICY IF EXISTS core_knowledge_national_read     ON core.knowledge_national;
DROP POLICY IF EXISTS core_phases_read                 ON core.phases;
DROP POLICY IF EXISTS core_subject_phases_read         ON core.subject_phases;
DROP POLICY IF EXISTS core_subjects_read               ON core.subjects;

CREATE POLICY core_capaian_pembelajaran_read  ON core.capaian_pembelajaran  FOR SELECT TO authenticated USING (true);
CREATE POLICY core_cp_elements_read           ON core.cp_elements           FOR SELECT TO authenticated USING (true);
CREATE POLICY core_curriculum_versions_read   ON core.curriculum_versions   FOR SELECT TO authenticated USING (true);
CREATE POLICY core_education_levels_read      ON core.education_levels      FOR SELECT TO authenticated USING (true);
CREATE POLICY core_knowledge_national_read    ON core.knowledge_national    FOR SELECT TO authenticated USING (true);
CREATE POLICY core_phases_read               ON core.phases                FOR SELECT TO authenticated USING (true);
CREATE POLICY core_subject_phases_read        ON core.subject_phases        FOR SELECT TO authenticated USING (true);
CREATE POLICY core_subjects_read             ON core.subjects              FOR SELECT TO authenticated USING (true);

-- ──────────────────────────────────────────────────────────
-- USERS
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_users_read_own             ON public.users;
DROP POLICY IF EXISTS rls_users_read_staff           ON public.users;
DROP POLICY IF EXISTS rls_users_read_staff_names     ON public.users;
DROP POLICY IF EXISTS rls_users_read_administrative  ON public.users;
DROP POLICY IF EXISTS rls_users_read_waka            ON public.users;
DROP POLICY IF EXISTS rls_users_update_own           ON public.users;
DROP POLICY IF EXISTS rls_users_write_administrative ON public.users;

-- Self read
CREATE POLICY rls_users_read_own ON public.users FOR SELECT
USING (auth_user_id = auth.uid());

-- Staff baca staff lain + bisa baca siswa/ortu
-- SMA: hapus KAPRODI, DUDI dari daftar role pembaca
CREATE POLICY rls_users_read_staff ON public.users FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND (
    (
      fn_current_user_role() = ANY (ARRAY[
        'GURU','BK','WALI_KELAS','KEPSEK',
        'WAKA_KURIKULUM','WAKA_KESISWAAN','ADMINISTRATIVE'
      ]::role_type[])
      AND role_type = ANY (ARRAY[
        'GURU','BK','WALI_KELAS','KEPSEK',
        'WAKA_KURIKULUM','WAKA_KESISWAAN','ADMINISTRATIVE'
      ]::role_type[])
    )
    OR auth_user_id = auth.uid()
    OR (
      fn_current_user_role() = ANY (ARRAY[
        'GURU','BK','WALI_KELAS','KEPSEK',
        'WAKA_KURIKULUM','WAKA_KESISWAAN','ADMINISTRATIVE'
      ]::role_type[])
      AND role_type = ANY (ARRAY['SISWA','ORTU']::role_type[])
    )
  )
);

-- Siswa/ortu bisa baca nama guru
CREATE POLICY rls_users_read_staff_names ON public.users FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = ANY (ARRAY['SISWA','ORTU']::role_type[])
  AND role_type = ANY (ARRAY['GURU','BK','WALI_KELAS','KEPSEK','WAKA_KURIKULUM','WAKA_KESISWAAN']::role_type[])
);

-- Administrative baca semua
CREATE POLICY rls_users_read_administrative ON public.users FOR SELECT
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

-- Waka baca semua
CREATE POLICY rls_users_read_waka ON public.users FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = ANY (ARRAY['WAKA_KURIKULUM','WAKA_KESISWAAN']::role_type[])
);

-- Self update
CREATE POLICY rls_users_update_own ON public.users FOR UPDATE
USING (auth_user_id = auth.uid())
WITH CHECK (auth_user_id = auth.uid() AND school_id = fn_current_school_id());

-- Administrative full write
CREATE POLICY rls_users_write_administrative ON public.users FOR ALL
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type)
WITH CHECK (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

-- ──────────────────────────────────────────────────────────
-- SCHOOLS
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_schools_read_own  ON public.schools;
DROP POLICY IF EXISTS rls_schools_read_all  ON public.schools;

CREATE POLICY rls_schools_read_own ON public.schools FOR SELECT TO authenticated
USING (school_id = (SELECT users.school_id FROM users WHERE users.auth_user_id = auth.uid() LIMIT 1));

-- ──────────────────────────────────────────────────────────
-- ACADEMIC PERIODS
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_academic_periods_read              ON public.academic_periods;
DROP POLICY IF EXISTS rls_academic_periods_read_all          ON public.academic_periods;
DROP POLICY IF EXISTS rls_academic_periods_insert_administrative ON public.academic_periods;
DROP POLICY IF EXISTS rls_academic_periods_update_administrative ON public.academic_periods;

CREATE POLICY rls_academic_periods_read_all ON public.academic_periods FOR SELECT
USING (school_id = fn_current_school_id() AND auth.uid() IS NOT NULL);

CREATE POLICY rls_academic_periods_insert_administrative ON public.academic_periods FOR INSERT
WITH CHECK (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

CREATE POLICY rls_academic_periods_update_administrative ON public.academic_periods FOR UPDATE
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

-- ──────────────────────────────────────────────────────────
-- STUDENTS
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_students_read_staff          ON public.students;
DROP POLICY IF EXISTS rls_students_read_administrative ON public.students;
DROP POLICY IF EXISTS rls_students_read_own            ON public.students;
DROP POLICY IF EXISTS rls_students_read_parent         ON public.students;
DROP POLICY IF EXISTS rls_students_write_admin         ON public.students;
DROP POLICY IF EXISTS rls_students_write_administrative ON public.students;

CREATE POLICY rls_students_read_staff ON public.students FOR SELECT
USING (school_id = fn_current_school_id() AND fn_can_see_student(student_id));

CREATE POLICY rls_students_read_administrative ON public.students FOR SELECT
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

CREATE POLICY rls_students_read_own ON public.students FOR SELECT
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'SISWA'::role_type AND user_id = fn_current_user_id());

CREATE POLICY rls_students_read_parent ON public.students FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = 'ORTU'::role_type
  AND EXISTS (SELECT 1 FROM student_parents sp WHERE sp.student_id = students.student_id AND sp.parent_user_id = fn_current_user_id())
);

-- SMA: hanya KEPSEK yang bisa write (tidak ada KAPRODI)
CREATE POLICY rls_students_write_admin ON public.students FOR ALL
USING (school_id = fn_current_school_id() AND fn_is_kepsek())
WITH CHECK (school_id = fn_current_school_id() AND fn_is_kepsek());

CREATE POLICY rls_students_write_administrative ON public.students FOR ALL
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type)
WITH CHECK (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

-- ──────────────────────────────────────────────────────────
-- CLASSES
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_classes_read     ON public.classes;
DROP POLICY IF EXISTS rls_classes_read_all ON public.classes;
DROP POLICY IF EXISTS rls_classes_write_admin ON public.classes;

CREATE POLICY rls_classes_read_all ON public.classes FOR SELECT
USING (school_id = fn_current_school_id() AND auth.uid() IS NOT NULL);

CREATE POLICY rls_classes_write_admin ON public.classes FOR ALL
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type)
WITH CHECK (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

-- ──────────────────────────────────────────────────────────
-- CLASS ENROLLMENTS
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_enrollments_read_staff        ON public.class_enrollments;
DROP POLICY IF EXISTS rls_enrollments_read_student      ON public.class_enrollments;
DROP POLICY IF EXISTS rls_enrollments_read_parent       ON public.class_enrollments;
DROP POLICY IF EXISTS rls_enrollments_write_admin       ON public.class_enrollments;
DROP POLICY IF EXISTS rls_enrollments_write_administrative ON public.class_enrollments;

CREATE POLICY rls_enrollments_read_staff ON public.class_enrollments FOR SELECT
USING (school_id = fn_current_school_id() AND fn_can_see_student(student_id));

CREATE POLICY rls_enrollments_read_student ON public.class_enrollments FOR SELECT
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'SISWA'::role_type AND student_id = fn_current_student_id());

CREATE POLICY rls_enrollments_read_parent ON public.class_enrollments FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = 'ORTU'::role_type
  AND EXISTS (SELECT 1 FROM student_parents sp WHERE sp.student_id = class_enrollments.student_id AND sp.parent_user_id = fn_current_user_id())
);

-- SMA: hanya KEPSEK (tidak ada KAPRODI)
CREATE POLICY rls_enrollments_write_admin ON public.class_enrollments FOR ALL
USING (school_id = fn_current_school_id() AND fn_is_kepsek())
WITH CHECK (school_id = fn_current_school_id() AND fn_is_kepsek());

CREATE POLICY rls_enrollments_write_administrative ON public.class_enrollments FOR ALL
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type)
WITH CHECK (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

-- ──────────────────────────────────────────────────────────
-- STUDENT PARENTS
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_student_parents_read_own            ON public.student_parents;
DROP POLICY IF EXISTS rls_student_parents_read_staff          ON public.student_parents;
DROP POLICY IF EXISTS rls_student_parents_write_administrative ON public.student_parents;

CREATE POLICY rls_student_parents_read_own ON public.student_parents FOR SELECT
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ORTU'::role_type AND parent_user_id = fn_current_user_id());

-- SMA: hapus KAPRODI dari pembaca
CREATE POLICY rls_student_parents_read_staff ON public.student_parents FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = ANY (ARRAY['GURU','BK','WALI_KELAS','KEPSEK']::role_type[])
);

CREATE POLICY rls_student_parents_write_administrative ON public.student_parents FOR ALL
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type)
WITH CHECK (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

-- ──────────────────────────────────────────────────────────
-- ATTENDANCE
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_attendance_read_staff     ON public.attendance;
DROP POLICY IF EXISTS rls_attendance_read_student   ON public.attendance;
DROP POLICY IF EXISTS rls_attendance_read_parent    ON public.attendance;
DROP POLICY IF EXISTS rls_attendance_rw_guru        ON public.attendance;
DROP POLICY IF EXISTS rls_attendance_rw_substitute  ON public.attendance;

CREATE POLICY rls_attendance_read_staff ON public.attendance FOR SELECT
USING (school_id = fn_current_school_id() AND is_void = false AND fn_can_see_student(student_id));

CREATE POLICY rls_attendance_read_student ON public.attendance FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = 'SISWA'::role_type
  AND student_id = (SELECT s.student_id FROM students s WHERE s.user_id = fn_current_user_id())
  AND is_void = false
);

CREATE POLICY rls_attendance_read_parent ON public.attendance FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = 'ORTU'::role_type
  AND is_void = false
  AND EXISTS (SELECT 1 FROM student_parents sp WHERE sp.student_id = attendance.student_id AND sp.parent_user_id = fn_current_user_id())
);

CREATE POLICY rls_attendance_rw_guru ON public.attendance FOR ALL
USING (
  school_id = fn_current_school_id()
  AND EXISTS (
    SELECT 1 FROM teaching_schedules ts
    WHERE ts.schedule_id = attendance.schedule_id
      AND (ts.scheduled_teacher_id = fn_current_user_id()
           OR EXISTS (SELECT 1 FROM teaching_assignments ta WHERE ta.assignment_id = ts.assignment_id AND ta.user_id = fn_current_user_id() AND ta.is_active = true))
  )
)
WITH CHECK (
  school_id = fn_current_school_id()
  AND EXISTS (
    SELECT 1 FROM teaching_schedules ts
    WHERE ts.schedule_id = attendance.schedule_id
      AND (ts.scheduled_teacher_id = fn_current_user_id()
           OR EXISTS (SELECT 1 FROM teaching_assignments ta WHERE ta.assignment_id = ts.assignment_id AND ta.user_id = fn_current_user_id() AND ta.is_active = true))
  )
);

CREATE POLICY rls_attendance_rw_substitute ON public.attendance FOR ALL
USING (
  school_id = fn_current_school_id()
  AND EXISTS (SELECT 1 FROM substitute_schedules ss WHERE ss.schedule_id = attendance.schedule_id AND ss.substitute_user_id = fn_current_user_id() AND ss.sync_token_expires_at > now())
)
WITH CHECK (
  school_id = fn_current_school_id()
  AND EXISTS (SELECT 1 FROM substitute_schedules ss WHERE ss.schedule_id = attendance.schedule_id AND ss.substitute_user_id = fn_current_user_id() AND ss.sync_token_expires_at > now())
);

-- ──────────────────────────────────────────────────────────
-- TEACHING SCHEDULES
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_schedules_read_staff          ON public.teaching_schedules;
DROP POLICY IF EXISTS rls_schedules_read_student        ON public.teaching_schedules;
DROP POLICY IF EXISTS rls_schedules_read_parent         ON public.teaching_schedules;
DROP POLICY IF EXISTS rls_schedules_read_administrative ON public.teaching_schedules;
DROP POLICY IF EXISTS rls_schedules_read_waka           ON public.teaching_schedules;
DROP POLICY IF EXISTS rls_schedules_write_admin         ON public.teaching_schedules;
DROP POLICY IF EXISTS rls_schedules_write_administrative ON public.teaching_schedules;

-- SMA: hapus KAPRODI
CREATE POLICY rls_schedules_read_staff ON public.teaching_schedules FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = ANY (ARRAY['GURU','BK','WALI_KELAS','KEPSEK']::role_type[])
);

CREATE POLICY rls_schedules_read_waka ON public.teaching_schedules FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = ANY (ARRAY['WAKA_KURIKULUM','WAKA_KESISWAAN']::role_type[])
);

CREATE POLICY rls_schedules_read_administrative ON public.teaching_schedules FOR SELECT
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

CREATE POLICY rls_schedules_read_student ON public.teaching_schedules FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = 'SISWA'::role_type
  AND EXISTS (SELECT 1 FROM class_enrollments ce WHERE ce.class_id = teaching_schedules.class_id AND ce.student_id = fn_current_student_id() AND ce.school_id = fn_current_school_id() AND ce.withdrawn_at IS NULL)
);

CREATE POLICY rls_schedules_read_parent ON public.teaching_schedules FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = 'ORTU'::role_type
  AND EXISTS (
    SELECT 1 FROM class_enrollments ce JOIN student_parents sp ON sp.student_id = ce.student_id
    WHERE ce.class_id = teaching_schedules.class_id AND ce.school_id = fn_current_school_id()
      AND ce.withdrawn_at IS NULL AND sp.parent_user_id = fn_current_user_id()
  )
);

-- SMA: hapus KAPRODI
CREATE POLICY rls_schedules_write_admin ON public.teaching_schedules FOR ALL
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'KEPSEK'::role_type)
WITH CHECK (school_id = fn_current_school_id() AND fn_current_user_role() = 'KEPSEK'::role_type);

CREATE POLICY rls_schedules_write_administrative ON public.teaching_schedules FOR ALL
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type)
WITH CHECK (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

-- ──────────────────────────────────────────────────────────
-- TEACHING ASSIGNMENTS
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_assignments_read_all_staff    ON public.teaching_assignments;
DROP POLICY IF EXISTS rls_assignments_read_waka         ON public.teaching_assignments;
DROP POLICY IF EXISTS rls_assignments_read_administrative ON public.teaching_assignments;
DROP POLICY IF EXISTS rls_assignments_write_admin       ON public.teaching_assignments;
DROP POLICY IF EXISTS rls_assignments_write_administrative ON public.teaching_assignments;

-- SMA: hapus KAPRODI
CREATE POLICY rls_assignments_read_all_staff ON public.teaching_assignments FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = ANY (ARRAY['GURU','BK','WALI_KELAS','KEPSEK']::role_type[])
);

CREATE POLICY rls_assignments_read_waka ON public.teaching_assignments FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = ANY (ARRAY['WAKA_KURIKULUM','WAKA_KESISWAAN']::role_type[])
);

CREATE POLICY rls_assignments_read_administrative ON public.teaching_assignments FOR SELECT
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

-- SMA: hapus KAPRODI dari write
CREATE POLICY rls_assignments_write_admin ON public.teaching_assignments FOR ALL
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'KEPSEK'::role_type)
WITH CHECK (school_id = fn_current_school_id() AND fn_current_user_role() = 'KEPSEK'::role_type);

CREATE POLICY rls_assignments_write_administrative ON public.teaching_assignments FOR ALL
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type)
WITH CHECK (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

-- ──────────────────────────────────────────────────────────
-- SCHEDULE TEMPLATES
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_schedule_templates_read_staff         ON public.schedule_templates;
DROP POLICY IF EXISTS rls_schedule_templates_write_administrative ON public.schedule_templates;

-- SMA: hapus KAPRODI
CREATE POLICY rls_schedule_templates_read_staff ON public.schedule_templates FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = ANY (ARRAY['GURU','BK','WALI_KELAS','KEPSEK']::role_type[])
);

CREATE POLICY rls_schedule_templates_write_administrative ON public.schedule_templates FOR ALL
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type)
WITH CHECK (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

-- ──────────────────────────────────────────────────────────
-- SUBSTITUTE SCHEDULES
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_substitute_read_own        ON public.substitute_schedules;
DROP POLICY IF EXISTS rls_substitute_write_admin     ON public.substitute_schedules;
DROP POLICY IF EXISTS rls_substitute_write_administrative ON public.substitute_schedules;

CREATE POLICY rls_substitute_read_own ON public.substitute_schedules FOR SELECT
USING (school_id = fn_current_school_id() AND substitute_user_id = fn_current_user_id());

-- SMA: hapus KAPRODI
CREATE POLICY rls_substitute_write_admin ON public.substitute_schedules FOR ALL
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'KEPSEK'::role_type)
WITH CHECK (school_id = fn_current_school_id() AND fn_current_user_role() = 'KEPSEK'::role_type);

CREATE POLICY rls_substitute_write_administrative ON public.substitute_schedules FOR ALL
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type)
WITH CHECK (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

-- ──────────────────────────────────────────────────────────
-- OBSERVATIONS
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_observations_insert        ON public.observations;
DROP POLICY IF EXISTS rls_observations_read_guru     ON public.observations;
DROP POLICY IF EXISTS rls_observations_read_student  ON public.observations;
DROP POLICY IF EXISTS rls_observations_read_parent   ON public.observations;
DROP POLICY IF EXISTS rls_observations_update_author ON public.observations;
DROP POLICY IF EXISTS rls_observations_void_admin    ON public.observations;

CREATE POLICY rls_observations_insert ON public.observations FOR INSERT
WITH CHECK (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = 'GURU'::role_type
  AND author_user_id = fn_current_user_id()
  AND visibility = ANY (ARRAY['SISWA_SAJA','ORTU_SAJA','SISWA_DAN_ORTU']::visibility_level[])
  AND fn_guru_teaches_student(student_id)
);

CREATE POLICY rls_observations_read_guru ON public.observations FOR SELECT
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'GURU'::role_type AND author_user_id = fn_current_user_id());

CREATE POLICY rls_observations_read_student ON public.observations FOR SELECT
USING (
  fn_current_user_role() = 'SISWA'::role_type
  AND visibility = ANY (ARRAY['SISWA_SAJA','SISWA_DAN_ORTU']::visibility_level[])
  AND is_void = false
  AND EXISTS (SELECT 1 FROM students s WHERE s.student_id = observations.student_id AND s.user_id = fn_current_user_id() AND s.school_id = fn_current_school_id())
);

CREATE POLICY rls_observations_read_parent ON public.observations FOR SELECT
USING (
  fn_current_user_role() = 'ORTU'::role_type
  AND visibility = ANY (ARRAY['ORTU_SAJA','SISWA_DAN_ORTU']::visibility_level[])
  AND is_void = false
  AND EXISTS (SELECT 1 FROM student_parents sp WHERE sp.student_id = observations.student_id AND sp.parent_user_id = fn_current_user_id())
);

CREATE POLICY rls_observations_update_author ON public.observations FOR UPDATE
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'GURU'::role_type AND author_user_id = fn_current_user_id())
WITH CHECK (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = 'GURU'::role_type
  AND author_user_id = fn_current_user_id()
  AND visibility = ANY (ARRAY['SISWA_SAJA','ORTU_SAJA','SISWA_DAN_ORTU']::visibility_level[])
);

CREATE POLICY rls_observations_void_admin ON public.observations FOR UPDATE
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type)
WITH CHECK (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

-- ──────────────────────────────────────────────────────────
-- CASES
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_cases_read_staff        ON public.cases;
DROP POLICY IF EXISTS rls_cases_insert            ON public.cases;
DROP POLICY IF EXISTS rls_cases_delete_administrative ON public.cases;
DROP POLICY IF EXISTS rls_cases_update_audience   ON public.cases;
DROP POLICY IF EXISTS rls_cases_update_sync       ON public.cases;

CREATE POLICY rls_cases_read_staff ON public.cases FOR SELECT
USING (school_id = fn_current_school_id() AND fn_can_see_case(case_id));

-- SMA: hapus DUDI branch, hapus fn_student_is_on_pkl
CREATE POLICY rls_cases_insert ON public.cases FOR INSERT
WITH CHECK (
  school_id = fn_current_school_id()
  AND fn_student_in_current_school(student_id)
  AND (
    fn_current_user_role() = ANY (ARRAY['GURU','BK','WALI_KELAS','KEPSEK','WAKA_KESISWAAN']::role_type[])
    OR fn_is_bk()
    OR fn_is_kepsek()
    OR fn_is_waka_kesiswaan()
  )
);

CREATE POLICY rls_cases_delete_administrative ON public.cases FOR DELETE
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

CREATE POLICY rls_cases_update_audience ON public.cases FOR UPDATE
USING (
  school_id = fn_current_school_id()
  AND (fn_matches_case_handler(current_handler_role, student_id) OR fn_is_kepsek() OR created_by_user_id = fn_current_user_id())
)
WITH CHECK (
  school_id = fn_current_school_id()
  AND (fn_matches_case_handler(current_handler_role, student_id) OR fn_is_kepsek() OR created_by_user_id = fn_current_user_id())
);

CREATE POLICY rls_cases_update_sync ON public.cases FOR UPDATE
USING (
  school_id = fn_current_school_id()
  AND (
    fn_matches_case_handler(current_handler_role, student_id)
    OR (fn_is_kepsek() AND status <> 'CLOSED'::case_status)
    OR (current_setting('app.case_sync_active', true) = 'true')
  )
);

-- CASE AUDIENCE MEMBERS: tabel ini belum ada di schema SMA — SKIP

-- ──────────────────────────────────────────────────────────
-- CASE EVENTS
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_case_events_read_staff          ON public.case_events;
DROP POLICY IF EXISTS rls_case_events_read_student        ON public.case_events;
DROP POLICY IF EXISTS rls_case_events_read_parent         ON public.case_events;
DROP POLICY IF EXISTS rls_case_events_insert_handler      ON public.case_events;
DROP POLICY IF EXISTS rls_case_events_insert_kepsek       ON public.case_events;
DROP POLICY IF EXISTS rls_case_events_delete_administrative ON public.case_events;

CREATE POLICY rls_case_events_read_staff ON public.case_events FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() <> ALL (ARRAY['SISWA','ORTU']::role_type[])
  AND fn_can_see_case(case_id)
);

CREATE POLICY rls_case_events_read_student ON public.case_events FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = 'SISWA'::role_type
  AND privacy_level = 'STUDENT_VISIBLE'::visibility_level
  AND fn_can_see_case(case_id)
);

CREATE POLICY rls_case_events_read_parent ON public.case_events FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = 'ORTU'::role_type
  AND privacy_level = 'STUDENT_VISIBLE'::visibility_level
  AND fn_can_see_case(case_id)
);

CREATE POLICY rls_case_events_insert_handler ON public.case_events FOR INSERT
WITH CHECK (
  school_id = fn_current_school_id()
  AND author_user_id = fn_current_user_id()
  AND author_role_at_time = fn_current_user_role()
  AND EXISTS (
    SELECT 1 FROM cases c
    WHERE c.case_id = case_events.case_id
      AND fn_matches_case_handler(c.current_handler_role, c.student_id)
      AND c.status <> 'CLOSED'::case_status
  )
);

CREATE POLICY rls_case_events_insert_kepsek ON public.case_events FOR INSERT
WITH CHECK (
  school_id = fn_current_school_id()
  AND fn_is_kepsek()
  AND author_user_id = fn_current_user_id()
  AND author_role_at_time = fn_current_user_role()
);

CREATE POLICY rls_case_events_delete_administrative ON public.case_events FOR DELETE
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

-- ──────────────────────────────────────────────────────────
-- STUDENT UPDATES
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_student_updates_insert      ON public.student_updates;
DROP POLICY IF EXISTS rls_student_updates_read_staff  ON public.student_updates;
DROP POLICY IF EXISTS rls_student_updates_read_student ON public.student_updates;
DROP POLICY IF EXISTS rls_student_updates_read_parent ON public.student_updates;

CREATE POLICY rls_student_updates_insert ON public.student_updates FOR INSERT
WITH CHECK (
  school_id = fn_current_school_id()
  AND author_user_id = fn_current_user_id()
  AND EXISTS (
    SELECT 1 FROM cases c
    WHERE c.case_id = student_updates.case_id
      AND fn_matches_case_handler(c.current_handler_role, c.student_id)
      AND c.status <> 'CLOSED'::case_status
  )
);

-- SMA: hapus DUDI dari read_staff
CREATE POLICY rls_student_updates_read_staff ON public.student_updates FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = ANY (ARRAY['GURU','BK','WALI_KELAS','KEPSEK']::role_type[])
);

CREATE POLICY rls_student_updates_read_student ON public.student_updates FOR SELECT
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'SISWA'::role_type AND fn_can_see_case(case_id));

CREATE POLICY rls_student_updates_read_parent ON public.student_updates FOR SELECT
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ORTU'::role_type AND fn_can_see_case(case_id));

-- ──────────────────────────────────────────────────────────
-- BK CLASS ASSIGNMENTS
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_bk_class_read  ON public.bk_class_assignments;
DROP POLICY IF EXISTS rls_bk_class_write ON public.bk_class_assignments;

CREATE POLICY rls_bk_class_read ON public.bk_class_assignments FOR SELECT
USING (school_id = fn_current_school_id());

-- SMA: hapus KAPRODI
CREATE POLICY rls_bk_class_write ON public.bk_class_assignments FOR ALL
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = ANY (ARRAY['KEPSEK','WAKA_KESISWAAN','ADMINISTRATIVE']::role_type[])
)
WITH CHECK (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = ANY (ARRAY['KEPSEK','WAKA_KESISWAAN','ADMINISTRATIVE']::role_type[])
);

-- ──────────────────────────────────────────────────────────
-- GURU WALI ASSIGNMENTS
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_guru_wali_read  ON public.guru_wali_assignments;
DROP POLICY IF EXISTS rls_guru_wali_write ON public.guru_wali_assignments;

CREATE POLICY rls_guru_wali_read ON public.guru_wali_assignments FOR SELECT
USING (school_id = fn_current_school_id());

CREATE POLICY rls_guru_wali_write ON public.guru_wali_assignments FOR ALL TO authenticated
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type)
WITH CHECK (school_id = fn_current_school_id() AND fn_current_user_role() = 'ADMINISTRATIVE'::role_type);

-- ──────────────────────────────────────────────────────────
-- PROGRAMS
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_programs_read       ON public.programs;
DROP POLICY IF EXISTS rls_programs_read_all   ON public.programs;
DROP POLICY IF EXISTS rls_programs_write_admin ON public.programs;

CREATE POLICY rls_programs_read_all ON public.programs FOR SELECT
USING (school_id = fn_current_school_id() AND auth.uid() IS NOT NULL);

-- SMA: hapus KAPRODI dari write
CREATE POLICY rls_programs_write_admin ON public.programs FOR ALL
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = ANY (ARRAY['KEPSEK','ADMINISTRATIVE']::role_type[])
)
WITH CHECK (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = ANY (ARRAY['KEPSEK','ADMINISTRATIVE']::role_type[])
);

-- ──────────────────────────────────────────────────────────
-- SUBJECTS (public schema — bukan core)
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_subjects_read       ON public.subjects;
DROP POLICY IF EXISTS rls_subjects_read_all   ON public.subjects;
DROP POLICY IF EXISTS rls_subjects_write_admin ON public.subjects;

CREATE POLICY rls_subjects_read_all ON public.subjects FOR SELECT
USING (school_id = fn_current_school_id() AND auth.uid() IS NOT NULL);

-- SMA: hapus KAPRODI dari write
CREATE POLICY rls_subjects_write_admin ON public.subjects FOR ALL
USING (school_id = fn_current_school_id() AND fn_current_user_role() = 'KEPSEK'::role_type)
WITH CHECK (school_id = fn_current_school_id() AND fn_current_user_role() = 'KEPSEK'::role_type);

-- ──────────────────────────────────────────────────────────
-- SCHOOL CONFIG
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_school_config_read       ON public.school_config;
DROP POLICY IF EXISTS rls_school_config_read_all   ON public.school_config;
DROP POLICY IF EXISTS rls_school_config_write_admin ON public.school_config;

CREATE POLICY rls_school_config_read_all ON public.school_config FOR SELECT
USING (school_id = fn_current_school_id() AND auth.uid() IS NOT NULL);

CREATE POLICY rls_school_config_write_admin ON public.school_config FOR ALL
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = ANY (ARRAY['ADMINISTRATIVE','KEPSEK']::role_type[])
)
WITH CHECK (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = ANY (ARRAY['ADMINISTRATIVE','KEPSEK']::role_type[])
);

-- ──────────────────────────────────────────────────────────
-- CAPAIAN PEMBELAJARAN (public schema — legacy)
-- ──────────────────────────────────────────────────────────
-- Sudah ada di SMA, update dengan menambah write policy yang benar
DROP POLICY IF EXISTS rls_cp_write ON public.capaian_pembelajaran;

-- SMA: hapus KAPRODI, WAKA_HUMAS dari writer
CREATE POLICY rls_cp_write ON public.capaian_pembelajaran FOR ALL
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = ANY (ARRAY[
    'ADMINISTRATIVE','GURU','WALI_KELAS','BK',
    'WAKA_KURIKULUM','WAKA_KESISWAAN','KEPSEK'
  ]::role_type[])
);

-- ──────────────────────────────────────────────────────────
-- TUJUAN PEMBELAJARAN
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_tp_write ON public.tujuan_pembelajaran;

-- SMA: hapus KAPRODI, WAKA_HUMAS dari writer
CREATE POLICY rls_tp_write ON public.tujuan_pembelajaran FOR ALL
USING (
  school_id = fn_current_school_id()
  AND fn_current_user_role() = ANY (ARRAY[
    'ADMINISTRATIVE','GURU','WALI_KELAS','BK',
    'WAKA_KURIKULUM','WAKA_KESISWAAN','KEPSEK'
  ]::role_type[])
);

-- ──────────────────────────────────────────────────────────
-- AUDIT LOG
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_audit_log_read ON public.audit_log;

-- SMA: hapus KAPRODI, WAKA_HUMAS
CREATE POLICY rls_audit_log_read ON public.audit_log FOR SELECT
USING (
  school_id = fn_current_school_id()::text
  AND fn_current_user_role() = ANY (ARRAY['KEPSEK','WAKA_KESISWAAN','ADMINISTRATIVE']::role_type[])
);

-- ──────────────────────────────────────────────────────────
-- TEACHER ATTENDANCE LOG
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_teacher_att_log_read_own ON public.teacher_attendance_log;

CREATE POLICY rls_teacher_att_log_read_own ON public.teacher_attendance_log FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND (user_id = fn_current_user_id() OR fn_current_user_role() = 'KEPSEK'::role_type)
);

-- ──────────────────────────────────────────────────────────
-- TEACHER JOURNALS
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_journals_owner ON public.teacher_journals;

CREATE POLICY rls_journals_owner ON public.teacher_journals FOR ALL
USING (school_id = fn_current_school_id() AND owner_user_id = fn_current_user_id())
WITH CHECK (school_id = fn_current_school_id() AND owner_user_id = fn_current_user_id());

-- ──────────────────────────────────────────────────────────
-- TEACHER DOCUMENTS (Tab Perangkat Ajar)
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS td_select ON public.teacher_documents;
DROP POLICY IF EXISTS td_insert ON public.teacher_documents;
DROP POLICY IF EXISTS td_update ON public.teacher_documents;
DROP POLICY IF EXISTS td_delete ON public.teacher_documents;

CREATE POLICY td_select ON public.teacher_documents FOR SELECT
USING (
  school_id = fn_current_school_id()
  AND (teacher_user_id = auth.uid() OR fn_is_kepsek() OR fn_is_waka_kurikulum())
);

CREATE POLICY td_insert ON public.teacher_documents FOR INSERT
WITH CHECK (school_id = fn_current_school_id() AND teacher_user_id = auth.uid());

CREATE POLICY td_update ON public.teacher_documents FOR UPDATE
USING (school_id = fn_current_school_id() AND teacher_user_id = auth.uid());

CREATE POLICY td_delete ON public.teacher_documents FOR DELETE TO authenticated
USING (school_id = fn_current_school_id() AND teacher_user_id = auth.uid() AND status::text <> 'DISAHKAN_WAKA');

-- ──────────────────────────────────────────────────────────
-- TEACHER DOCUMENT APPROVALS
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS tda_select ON public.teacher_document_approvals;
DROP POLICY IF EXISTS tda_insert ON public.teacher_document_approvals;
DROP POLICY IF EXISTS tda_delete ON public.teacher_document_approvals;

CREATE POLICY tda_select ON public.teacher_document_approvals FOR SELECT
USING (school_id = fn_current_school_id());

CREATE POLICY tda_insert ON public.teacher_document_approvals FOR INSERT
WITH CHECK (school_id = fn_current_school_id() AND fn_is_kepsek());

CREATE POLICY tda_delete ON public.teacher_document_approvals FOR DELETE TO authenticated
USING (
  school_id = fn_current_school_id()
  AND doc_id IN (
    SELECT teacher_documents.doc_id FROM teacher_documents
    WHERE teacher_documents.teacher_user_id = auth.uid()
      AND teacher_documents.status::text <> 'DISAHKAN_WAKA'
  )
);

-- ──────────────────────────────────────────────────────────
-- TEACHER DOCUMENT CLASSES
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS tdc_select ON public.teacher_document_classes;
DROP POLICY IF EXISTS tdc_insert ON public.teacher_document_classes;
DROP POLICY IF EXISTS tdc_delete ON public.teacher_document_classes;

CREATE POLICY tdc_select ON public.teacher_document_classes FOR SELECT USING (school_id = fn_current_school_id());
CREATE POLICY tdc_insert ON public.teacher_document_classes FOR INSERT WITH CHECK (school_id = fn_current_school_id());
CREATE POLICY tdc_delete ON public.teacher_document_classes FOR DELETE USING (school_id = fn_current_school_id());

-- ──────────────────────────────────────────────────────────
-- TEACHER PROFILES
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS tp_select ON public.teacher_profiles;
DROP POLICY IF EXISTS tp_insert ON public.teacher_profiles;
DROP POLICY IF EXISTS tp_update ON public.teacher_profiles;

CREATE POLICY tp_select ON public.teacher_profiles FOR SELECT USING (school_id = fn_current_school_id() AND teacher_user_id = auth.uid());
CREATE POLICY tp_insert ON public.teacher_profiles FOR INSERT WITH CHECK (school_id = fn_current_school_id() AND teacher_user_id = auth.uid());
CREATE POLICY tp_update ON public.teacher_profiles FOR UPDATE USING (school_id = fn_current_school_id() AND teacher_user_id = auth.uid());

-- ──────────────────────────────────────────────────────────
-- TEACHING CONTEXTS (AI Pipeline)
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS tc_select ON public.teaching_contexts;
DROP POLICY IF EXISTS tc_insert ON public.teaching_contexts;
DROP POLICY IF EXISTS tc_update ON public.teaching_contexts;

CREATE POLICY tc_select ON public.teaching_contexts FOR SELECT USING (school_id = fn_current_school_id() AND teacher_user_id = auth.uid());
CREATE POLICY tc_insert ON public.teaching_contexts FOR INSERT WITH CHECK (school_id = fn_current_school_id() AND teacher_user_id = auth.uid());
CREATE POLICY tc_update ON public.teaching_contexts FOR UPDATE USING (school_id = fn_current_school_id() AND teacher_user_id = auth.uid());

-- ──────────────────────────────────────────────────────────
-- GENERATION JOBS (AI Pipeline)
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS gj_select ON public.generation_jobs;
DROP POLICY IF EXISTS gj_insert ON public.generation_jobs;
DROP POLICY IF EXISTS gj_update ON public.generation_jobs;

CREATE POLICY gj_select ON public.generation_jobs FOR SELECT USING (school_id = fn_current_school_id() AND teacher_user_id = auth.uid());
CREATE POLICY gj_insert ON public.generation_jobs FOR INSERT WITH CHECK (school_id = fn_current_school_id() AND teacher_user_id = auth.uid());
CREATE POLICY gj_update ON public.generation_jobs FOR UPDATE USING (school_id = fn_current_school_id() AND teacher_user_id = auth.uid());

-- ──────────────────────────────────────────────────────────
-- EVALUATION LOGS (AI Pipeline)
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS el_select ON public.evaluation_logs;
DROP POLICY IF EXISTS el_insert ON public.evaluation_logs;

CREATE POLICY el_select ON public.evaluation_logs FOR SELECT USING (school_id = fn_current_school_id());
CREATE POLICY el_insert ON public.evaluation_logs FOR INSERT WITH CHECK (school_id = fn_current_school_id());

-- ──────────────────────────────────────────────────────────
-- PROMPT TEMPLATES
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS pt_select         ON public.prompt_templates;
DROP POLICY IF EXISTS prompt_templates_read_authenticated ON public.prompt_templates;

CREATE POLICY pt_select ON public.prompt_templates FOR SELECT TO authenticated USING (true);

-- ld_prompt_templates
DROP POLICY IF EXISTS prompt_templates_read_authenticated ON public.ld_prompt_templates;
CREATE POLICY prompt_templates_read_authenticated ON public.ld_prompt_templates FOR SELECT TO authenticated USING (true);

-- ──────────────────────────────────────────────────────────
-- HELPER: fn_can_read_forum_post
-- (tidak ada di migration 1 — didefinisikan di sini sebelum forum policies)
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_can_read_forum_post(p_post_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM forum_posts fp
    WHERE fp.post_id = p_post_id
      AND fp.school_id = fn_current_school_id()
      AND (
        fp.visibility <> 'TERBATAS'
        OR fp.author_user_id = fn_current_user_id()
        OR EXISTS (
          SELECT 1 FROM forum_post_audience fpa
          WHERE fpa.post_id = fp.post_id
            AND fpa.user_id = fn_current_user_id()
        )
      )
  )
$$;

REVOKE EXECUTE ON FUNCTION public.fn_can_read_forum_post(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.fn_can_read_forum_post(uuid) FROM anon;
GRANT  EXECUTE ON FUNCTION public.fn_can_read_forum_post(uuid) TO authenticated;

-- ──────────────────────────────────────────────────────────
-- FORUM POSTS
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_forum_posts_read   ON public.forum_posts;
DROP POLICY IF EXISTS rls_forum_posts_insert ON public.forum_posts;
DROP POLICY IF EXISTS rls_forum_posts_update ON public.forum_posts;
DROP POLICY IF EXISTS rls_forum_posts_delete ON public.forum_posts;

CREATE POLICY rls_forum_posts_read ON public.forum_posts FOR SELECT
USING (school_id = fn_current_school_id() AND fn_can_read_forum_post(post_id));

CREATE POLICY rls_forum_posts_insert ON public.forum_posts FOR INSERT
WITH CHECK (school_id = fn_current_school_id() AND author_user_id = fn_current_user_id());

CREATE POLICY rls_forum_posts_update ON public.forum_posts FOR UPDATE
USING (school_id = fn_current_school_id() AND author_user_id = fn_current_user_id())
WITH CHECK (
  school_id = fn_current_school_id() AND author_user_id = fn_current_user_id()
  AND class_id = (SELECT fp2.class_id FROM forum_posts fp2 WHERE fp2.post_id = forum_posts.post_id)
  AND visibility = (SELECT fp2.visibility FROM forum_posts fp2 WHERE fp2.post_id = forum_posts.post_id)
  AND academic_year = (SELECT fp2.academic_year FROM forum_posts fp2 WHERE fp2.post_id = forum_posts.post_id)
);

CREATE POLICY rls_forum_posts_delete ON public.forum_posts FOR DELETE
USING (
  school_id = fn_current_school_id()
  AND (author_user_id = fn_current_user_id() OR fn_current_user_role() = ANY (ARRAY['KEPSEK','WAKA_KESISWAAN']::role_type[]))
);

-- ──────────────────────────────────────────────────────────
-- FORUM POST COMMENTS
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_forum_comments_read   ON public.forum_post_comments;
DROP POLICY IF EXISTS rls_forum_comments_insert ON public.forum_post_comments;
DROP POLICY IF EXISTS rls_forum_comments_update ON public.forum_post_comments;
DROP POLICY IF EXISTS rls_forum_comments_delete ON public.forum_post_comments;

CREATE POLICY rls_forum_comments_read ON public.forum_post_comments FOR SELECT
USING (school_id = fn_current_school_id() AND fn_can_read_forum_post(post_id));

-- SMA: hapus KAPRODI, WAKA_HUMAS dari commenter
CREATE POLICY rls_forum_comments_insert ON public.forum_post_comments FOR INSERT
WITH CHECK (
  school_id = fn_current_school_id()
  AND author_user_id = fn_current_user_id()
  AND fn_can_read_forum_post(post_id)
  AND fn_current_user_role() = ANY (ARRAY[
    'GURU','BK','WALI_KELAS','KEPSEK','ADMINISTRATIVE',
    'WAKA_KURIKULUM','WAKA_KESISWAAN','ORTU'
  ]::role_type[])
);

CREATE POLICY rls_forum_comments_update ON public.forum_post_comments FOR UPDATE
USING (school_id = fn_current_school_id() AND author_user_id = fn_current_user_id())
WITH CHECK (school_id = fn_current_school_id() AND author_user_id = fn_current_user_id());

CREATE POLICY rls_forum_comments_delete ON public.forum_post_comments FOR DELETE
USING (
  school_id = fn_current_school_id()
  AND (author_user_id = fn_current_user_id() OR fn_current_user_role() = ANY (ARRAY['KEPSEK','WAKA_KESISWAAN']::role_type[]))
);

-- ──────────────────────────────────────────────────────────
-- FORUM POST AUDIENCE / SUBJECTS / ACKNOWLEDGEMENTS
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS rls_forum_aud_read    ON public.forum_post_audience;
DROP POLICY IF EXISTS rls_forum_subj_read   ON public.forum_post_subjects;
DROP POLICY IF EXISTS rls_forum_subj_write  ON public.forum_post_subjects;
DROP POLICY IF EXISTS rls_forum_ack_read    ON public.forum_post_acknowledgements;
DROP POLICY IF EXISTS rls_forum_ack_insert  ON public.forum_post_acknowledgements;
DROP POLICY IF EXISTS rls_forum_ack_delete  ON public.forum_post_acknowledgements;

CREATE POLICY rls_forum_aud_read ON public.forum_post_audience FOR SELECT
USING (school_id = fn_current_school_id() AND fn_can_read_forum_post(post_id));

CREATE POLICY rls_forum_subj_read ON public.forum_post_subjects FOR SELECT
USING (school_id = fn_current_school_id() AND fn_can_read_forum_post(post_id));

CREATE POLICY rls_forum_subj_write ON public.forum_post_subjects FOR ALL
USING (school_id = fn_current_school_id())
WITH CHECK (school_id = fn_current_school_id());

CREATE POLICY rls_forum_ack_read ON public.forum_post_acknowledgements FOR SELECT
USING (school_id = fn_current_school_id() AND fn_can_read_forum_post(post_id));

CREATE POLICY rls_forum_ack_insert ON public.forum_post_acknowledgements FOR INSERT
WITH CHECK (school_id = fn_current_school_id() AND user_id = fn_current_user_id() AND fn_can_read_forum_post(post_id));

CREATE POLICY rls_forum_ack_delete ON public.forum_post_acknowledgements FOR DELETE
USING (school_id = fn_current_school_id() AND user_id = fn_current_user_id());

-- ──────────────────────────────────────────────────────────
-- LD_CONTEXT_SNAPSHOTS (sudah ada snapshot_school_read, tambah owner write)
-- ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS snapshot_owner_write ON public.ld_context_snapshots;
CREATE POLICY snapshot_owner_write ON public.ld_context_snapshots FOR ALL
USING (created_by = auth.uid());
