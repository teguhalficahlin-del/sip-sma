-- SIP SMA: Views
-- Diadaptasi dari SIP SMK — referensi vocational dihapus

-- ──────────────────────────────────────────────────────────
-- v_core_subjects
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.v_core_subjects AS
SELECT subject_id, code, name, subject_type, is_generatable
FROM core.subjects
ORDER BY subject_type, name;

-- ──────────────────────────────────────────────────────────
-- v_cp_for_generate  ← dipakai generate-atp-v2
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.v_cp_for_generate AS
SELECT
    sp.subject_id   AS core_subject_id,
    sp.phase_id,
    p.code          AS fase_code,
    s.name          AS subject_name,
    s.code          AS subject_code,
    s.subject_type,
    cp.cp_umum,
    cp.rasional,
    cp.tujuan,
    cp.karakteristik,
    COALESCE(
        json_agg(
            json_build_object(
                'urutan', e.element_order,
                'nama',   e.nama_elemen,
                'deskripsi', e.deskripsi_cp
            ) ORDER BY e.element_order
        ) FILTER (WHERE e.element_id IS NOT NULL AND e.is_active = true),
        '[]'::json
    ) AS elemen
FROM core.subject_phases sp
JOIN core.phases               p  ON p.phase_id        = sp.phase_id
JOIN core.subjects             s  ON s.subject_id       = sp.subject_id
JOIN core.capaian_pembelajaran cp ON cp.subject_phase_id = sp.subject_phase_id
LEFT JOIN core.cp_elements     e  ON e.cp_id            = cp.cp_id
WHERE s.is_active = true
GROUP BY sp.subject_id, sp.phase_id, p.code, s.name, s.code,
         s.subject_type, cp.cp_umum, cp.rasional, cp.tujuan, cp.karakteristik;

-- ──────────────────────────────────────────────────────────
-- v_users_staff_directory  ← dipakai portal guru/admin
-- SMA: hapus dudi_org_name (kolom tidak ada di users SMA)
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.v_users_staff_directory AS
SELECT
    user_id,
    school_id,
    full_name,
    role_type,
    teacher_code,
    program_id,
    is_active
FROM users;

-- ──────────────────────────────────────────────────────────
-- v_attendance_daily_summary
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.v_attendance_daily_summary AS
SELECT
    ts.schedule_id,
    ts.session_date,
    ts.class_id,
    c.name          AS class_name,
    ts.scheduled_teacher_id,
    u.full_name     AS teacher_name,
    ts.meeting_status,
    ts.teacher_indicator,
    count(a.attendance_id) FILTER (WHERE a.is_void = false)                                     AS total_students,
    count(a.attendance_id) FILTER (WHERE a.status = 'HADIR'::attendance_status  AND a.is_void = false) AS hadir,
    count(a.attendance_id) FILTER (WHERE a.status = 'ALPA'::attendance_status   AND a.is_void = false) AS tidak_hadir,
    count(a.attendance_id) FILTER (WHERE a.status = 'IZIN'::attendance_status   AND a.is_void = false) AS izin,
    count(a.attendance_id) FILTER (WHERE a.status = 'SAKIT'::attendance_status  AND a.is_void = false) AS sakit,
    round(
        (count(a.attendance_id) FILTER (WHERE a.status = 'HADIR'::attendance_status AND a.is_void = false))::numeric
        / NULLIF(count(a.attendance_id) FILTER (WHERE a.is_void = false), 0)::numeric
        * 100, 1
    ) AS hadir_pct
FROM teaching_schedules ts
JOIN classes c ON c.class_id = ts.class_id
JOIN users   u ON u.user_id  = ts.scheduled_teacher_id
LEFT JOIN attendance a ON a.schedule_id = ts.schedule_id
GROUP BY ts.schedule_id, ts.session_date, ts.class_id, c.name,
         ts.scheduled_teacher_id, u.full_name, ts.meeting_status, ts.teacher_indicator;

-- ──────────────────────────────────────────────────────────
-- v_case_timeline
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.v_case_timeline AS
SELECT
    ce.event_id,
    ce.case_id,
    ce.event_type,
    ce.privacy_level,
    ce.created_at,
    ce.author_user_id,
    u.full_name         AS author_name,
    ce.author_role_at_time,
    ce.previous_handler_role,
    ce.new_handler_role,
    ce.previous_status,
    ce.new_status,
    ce.payload,
    su.content          AS student_update_content
FROM case_events ce
JOIN users       u  ON u.user_id         = ce.author_user_id
LEFT JOIN student_updates su ON su.case_event_id = ce.event_id
ORDER BY ce.case_id, ce.created_at;

-- ──────────────────────────────────────────────────────────
-- v_student_portal_positif
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.v_student_portal_positif AS
SELECT
    o.observation_id,
    o.student_id,
    o.dimension,
    o.content,
    o.observed_at,
    u.full_name  AS author_name,
    u.role_type  AS author_role
FROM observations o
JOIN users u ON u.user_id = o.author_user_id
WHERE o.sentiment  = 'POSITIF'::observation_sentiment
  AND o.visibility = 'STUDENT_VISIBLE'::visibility_level
ORDER BY o.observed_at DESC;

-- ──────────────────────────────────────────────────────────
-- v_academic_year_drift  (monitoring drift konfigurasi)
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.v_academic_year_drift AS
SELECT
    sc.school_id,
    sc.current_academic_year                                     AS config_year,
    ap.academic_year                                             AS active_period_year,
    (sc.current_academic_year::text IS DISTINCT FROM ap.academic_year::text) AS config_vs_period_drift,
    (
        SELECT count(*) FROM classes c
        WHERE c.school_id = sc.school_id AND c.is_active = true
          AND c.academic_year::text IS DISTINCT FROM ap.academic_year::text
    ) AS active_classes_lagging
FROM school_config sc
LEFT JOIN LATERAL (
    SELECT p.academic_year FROM academic_periods p
    WHERE p.school_id = sc.school_id AND p.status::text = 'ACTIVE'
    ORDER BY p.start_date DESC LIMIT 1
) ap ON true;

-- ──────────────────────────────────────────────────────────
-- v_kepsek_exception_dashboard
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.v_kepsek_exception_dashboard AS
SELECT 'LOW_ATTENDANCE'::text AS exception_type,
    (ads.class_id)::text   AS entity_id,
    ads.class_name          AS entity_label,
    (ads.session_date)::text AS context_date,
    ('Kehadiran ' || ads.hadir_pct || '%') AS detail
FROM v_attendance_daily_summary ads
WHERE ads.session_date = CURRENT_DATE
  AND ads.meeting_status = 'NORMAL'::meeting_status
  AND ads.hadir_pct < 80

UNION ALL

SELECT 'STALE_CASE'::text,
    (c.case_id)::text,
    c.title,
    ((c.updated_at)::date)::text,
    ('Handler: ' || c.current_handler_role::text || ' · ' || EXTRACT(day FROM now() - c.updated_at)::integer::text || ' hari')
FROM cases c
WHERE c.status <> 'CLOSED'::case_status
  AND c.updated_at < (now() - '3 days'::interval)

UNION ALL

SELECT 'TEACHER_ABSENT'::text,
    (ts.scheduled_teacher_id)::text,
    u.full_name,
    (ts.session_date)::text,
    ('Kelas: ' || c.name::text)
FROM teaching_schedules ts
JOIN users   u ON u.user_id  = ts.scheduled_teacher_id
JOIN classes c ON c.class_id = ts.class_id
WHERE ts.session_date = CURRENT_DATE
  AND ts.teacher_indicator = 'TIDAK_HADIR'::teacher_attendance_indicator
  AND ts.meeting_status = 'NORMAL'::meeting_status
  AND NOT EXISTS (SELECT 1 FROM substitute_schedules ss WHERE ss.schedule_id = ts.schedule_id);

-- ──────────────────────────────────────────────────────────
-- v_offline_sync_manifest_guru
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.v_offline_sync_manifest_guru AS
SELECT
    ts.schedule_id,
    ts.session_date,
    ts.session_start,
    ts.session_end,
    ts.class_id,
    c.name     AS class_name,
    ts.subject_id,
    s.name     AS subject_name,
    ts.scheduled_teacher_id,
    ts.meeting_status,
    json_agg(
        json_build_object(
            'student_id', st.student_id,
            'nis',        st.nis,
            'full_name',  st.full_name,
            'att_status', COALESCE(a.status, 'HADIR'::attendance_status),
            'att_source', COALESCE(a.source::text, 'AUTO_DETECTED'),
            'att_id',     a.attendance_id
        ) ORDER BY st.full_name
    ) AS students_json
FROM teaching_schedules ts
JOIN classes          c  ON c.class_id   = ts.class_id
JOIN subjects         s  ON s.subject_id = ts.subject_id
JOIN class_enrollments ce ON ce.class_id = ts.class_id AND ce.academic_year::text = ts.academic_year::text AND ce.semester = ts.semester AND ce.withdrawn_at IS NULL
JOIN students         st ON st.student_id = ce.student_id AND st.student_status = 'AKTIF'::student_status
LEFT JOIN attendance  a  ON a.schedule_id = ts.schedule_id AND a.student_id = st.student_id AND a.is_void = false
WHERE ts.session_date >= CURRENT_DATE
  AND ts.session_date <= (CURRENT_DATE + '7 days'::interval)
GROUP BY ts.schedule_id, ts.session_date, ts.session_start, ts.session_end,
         ts.class_id, c.name, ts.subject_id, s.name, ts.scheduled_teacher_id, ts.meeting_status;

-- ──────────────────────────────────────────────────────────
-- v_offline_sync_manifest_substitute
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW public.v_offline_sync_manifest_substitute AS
SELECT
    ts.schedule_id,
    ts.session_date,
    ts.session_start,
    ts.session_end,
    ts.class_id,
    c.name             AS class_name,
    ts.subject_id,
    s.name             AS subject_name,
    ss.substitute_user_id,
    ss.sync_token,
    ss.sync_token_expires_at,
    ts.meeting_status,
    json_agg(
        json_build_object(
            'student_id', st.student_id,
            'nis',        st.nis,
            'full_name',  st.full_name,
            'att_status', COALESCE(a.status, 'HADIR'::attendance_status),
            'att_source', COALESCE(a.source::text, 'AUTO_DETECTED'),
            'att_id',     a.attendance_id
        ) ORDER BY st.full_name
    ) AS students_json
FROM substitute_schedules ss
JOIN teaching_schedules ts ON ts.schedule_id = ss.schedule_id
JOIN classes           c   ON c.class_id     = ts.class_id
JOIN subjects          s   ON s.subject_id   = ts.subject_id
JOIN class_enrollments ce  ON ce.class_id    = ts.class_id AND ce.academic_year::text = ts.academic_year::text AND ce.semester = ts.semester AND ce.withdrawn_at IS NULL
JOIN students          st  ON st.student_id  = ce.student_id AND st.student_status = 'AKTIF'::student_status
LEFT JOIN attendance   a   ON a.schedule_id  = ts.schedule_id AND a.student_id = st.student_id AND a.is_void = false
WHERE ss.sync_token_expires_at > now()
GROUP BY ts.schedule_id, ts.session_date, ts.session_start, ts.session_end,
         ts.class_id, c.name, ts.subject_id, s.name,
         ss.substitute_user_id, ss.sync_token, ss.sync_token_expires_at, ts.meeting_status;
