-- ============================================================
-- SIP SMA — Base Operational Schema
-- Dibuat: 20 Juli 2026
-- Tujuan: Membangun schema operasional SMA dari nol karena
--         205 migration SMK lama tidak bisa dijalankan di DB fresh.
--         Schema ini adalah versi bersih tanpa domain vokasi.
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── ENUMS (SMA — tanpa KAPRODI, DUDI, WAKA_HUMAS, PKL) ───────────────────────

DO $$ BEGIN
  CREATE TYPE role_type AS ENUM (
    'GURU','BK','WALI_KELAS','KEPSEK','SISWA','ORTU',
    'ADMINISTRATIVE','STAKEHOLDER','WAKA_KURIKULUM','WAKA_KESISWAAN'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE semester AS ENUM ('1','2');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE student_status AS ENUM ('AKTIF','LULUS','KELUAR');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE case_status AS ENUM ('OPEN','UNDER_REVIEW','INTERVENTION','MONITORING','CLOSED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE case_track AS ENUM ('SEKOLAH');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE case_audience AS ENUM ('PRIVATE','RESTRICTED','PUBLIC');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE case_event_type AS ENUM (
    'COMMENT_ADDED','STATUS_CHANGED','DECISION_ESCALATE','DECISION_CLOSE',
    'FINAL_DECISION_MADE','STUDENT_UPDATE_ADDED','PARENT_MESSAGE_RECEIVED',
    'PARENT_MESSAGE_LINKED','PARENT_REPLY_SENT','CASE_LOCKED','CASE_UNLOCKED'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE attendance_status AS ENUM ('HADIR','ALPA','IZIN','SAKIT');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE attendance_source AS ENUM ('AUTO_DETECTED','MANUAL_OVERRIDE','TEACHER_DECLARED');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE meeting_status AS ENUM ('NORMAL','KEGIATAN_SEKOLAH','GURU_TIDAK_HADIR');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE teacher_attendance_indicator AS ENUM ('HADIR','TIDAK_HADIR','PENDING_EVALUATION');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE observation_sentiment AS ENUM ('POSITIF','NEGATIF');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE observation_dimension AS ENUM (
    'AKADEMIK','KEHADIRAN','PERILAKU','SOSIAL','AFEKTIF','BAKAT_MINAT','FISIK','LAINNYA'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE visibility_level AS ENUM (
    'PRIVATE','INTERNAL_SCHOOL','STUDENT_VISIBLE','RESTRICTED','PUBLIC',
    'SISWA_SAJA','ORTU_SAJA','SISWA_DAN_ORTU'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE day_of_week AS ENUM ('SENIN','SELASA','RABU','KAMIS','JUMAT','SABTU');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE message_direction AS ENUM ('INBOUND','OUTBOUND');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE message_link_type AS ENUM ('CASE_LINKED','STANDALONE');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE ld_document_status AS ENUM ('draft','published');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE ld_document_type AS ENUM (
    'atp','modul_ajar','rpp_ringkas','lkpd','soal','rubrik','observasi','remedial'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE ld_generation_source AS ENUM ('AI','MANUAL','HYBRID');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE ld_node_type AS ENUM (
    'tp_item','identitas','kompetensi_awal','profil_lulusan_dimensi','mindful','meaningful',
    'joyful','asesmen_diagnostik','asesmen_formatif','asesmen_sumatif','refleksi','lampiran',
    'petunjuk','aktivitas','pertanyaan','soal_pg','soal_uraian','soal_hots',
    'kriteria_pengetahuan','kriteria_keterampilan','kriteria_sikap','indikator_checklist',
    'aktivitas_remedial','aktivitas_pengayaan'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── LAYER 0: schools ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS schools (
    school_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          TEXT NOT NULL,
    npsn          TEXT UNIQUE,
    address       TEXT,
    phone         TEXT,
    logo_url      TEXT,
    primary_color TEXT NOT NULL DEFAULT '#1a56db',
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS rls_schools_read_all ON schools;
CREATE POLICY rls_schools_read_all ON schools FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- ── LAYER 1: programs (kelompok kelas SMA) ────────────────────────────────────

CREATE TABLE IF NOT EXISTS programs (
    program_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id  UUID NOT NULL REFERENCES schools(school_id),
    code       VARCHAR(20) NOT NULL,
    name       VARCHAR(100) NOT NULL,
    is_active  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE programs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS rls_programs_read ON programs;
CREATE POLICY rls_programs_read ON programs FOR SELECT USING (auth.uid() IS NOT NULL);

-- ── LAYER 2: users ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS users (
    user_id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_user_id          UUID NOT NULL UNIQUE,
    school_id             UUID NOT NULL REFERENCES schools(school_id),
    full_name             VARCHAR(150) NOT NULL,
    email                 VARCHAR(254) NOT NULL,
    login_identifier      VARCHAR(100) NOT NULL,
    identifier_type       VARCHAR(20) NOT NULL,
    role_type             role_type NOT NULL,
    program_id            UUID REFERENCES programs(program_id),
    wali_kelas_class_id   UUID,
    is_active             BOOLEAN NOT NULL DEFAULT TRUE,
    is_bk                 BOOLEAN NOT NULL DEFAULT FALSE,
    is_kepsek             BOOLEAN NOT NULL DEFAULT FALSE,
    is_waka_kurikulum     BOOLEAN NOT NULL DEFAULT FALSE,
    is_waka_kesiswaan     BOOLEAN NOT NULL DEFAULT FALSE,
    teacher_code          VARCHAR(20),
    allow_parallel_teaching BOOLEAN NOT NULL DEFAULT FALSE,
    must_change_password  BOOLEAN NOT NULL DEFAULT FALSE,
    password_changed_at   TIMESTAMPTZ,
    last_seen_at          TIMESTAMPTZ,
    last_seen_ua          TEXT,
    deleted_at            TIMESTAMPTZ,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (school_id, login_identifier)
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- ── LAYER 3: subjects (public — school-specific) ──────────────────────────────

CREATE TABLE IF NOT EXISTS subjects (
    subject_id      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id       UUID NOT NULL REFERENCES schools(school_id),
    code            VARCHAR(20) NOT NULL,
    name            VARCHAR(100) NOT NULL,
    kelompok_mapel  VARCHAR(20),
    fase_default    VARCHAR(1),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS rls_subjects_read ON subjects;
CREATE POLICY rls_subjects_read ON subjects FOR SELECT USING (auth.uid() IS NOT NULL);

-- ── LAYER 4: students ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS students (
    student_id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id               UUID NOT NULL REFERENCES schools(school_id),
    nis                     VARCHAR(20) NOT NULL,
    full_name               VARCHAR(150) NOT NULL,
    program_id              UUID NOT NULL REFERENCES programs(program_id),
    student_status          student_status NOT NULL DEFAULT 'AKTIF',
    user_id                 UUID REFERENCES users(user_id),
    graduated_at            TIMESTAMPTZ,
    graduated_academic_year VARCHAR(9),
    keluar_at               TIMESTAMPTZ,
    keluar_note             TEXT,
    anonymized_at           TIMESTAMPTZ,
    alumni_career_track     TEXT,
    alumni_career_note      TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (school_id, nis)
);

ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- ── LAYER 5: student_parents ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS student_parents (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id      UUID NOT NULL REFERENCES schools(school_id),
    student_id     UUID NOT NULL REFERENCES students(student_id),
    parent_user_id UUID NOT NULL REFERENCES users(user_id),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (student_id, parent_user_id)
);

ALTER TABLE student_parents ENABLE ROW LEVEL SECURITY;

-- ── LAYER 6: academic_periods ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS academic_periods (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id           UUID NOT NULL REFERENCES schools(school_id),
    academic_year       VARCHAR(9) NOT NULL,
    semester            semester NOT NULL,
    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    closed_at           TIMESTAMPTZ,
    closed_by_user_id   UUID REFERENCES users(user_id) ON DELETE RESTRICT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (school_id, academic_year, semester)
);

ALTER TABLE academic_periods ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS rls_academic_periods_read ON academic_periods;
CREATE POLICY rls_academic_periods_read ON academic_periods FOR SELECT USING (auth.uid() IS NOT NULL);

-- ── LAYER 7: classes ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS classes (
    class_id     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id    UUID NOT NULL REFERENCES schools(school_id),
    name         VARCHAR(50) NOT NULL,
    program_id   UUID NOT NULL REFERENCES programs(program_id),
    academic_year VARCHAR(9) NOT NULL,
    grade_level  SMALLINT NOT NULL,
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- FK wali_kelas_class_id dari users ke classes
ALTER TABLE users ADD CONSTRAINT users_wali_kelas_class_id_fkey
    FOREIGN KEY (wali_kelas_class_id) REFERENCES classes(class_id)
    ON DELETE SET NULL;

ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS rls_classes_read ON classes;
CREATE POLICY rls_classes_read ON classes FOR SELECT USING (auth.uid() IS NOT NULL);

-- ── LAYER 8: class_enrollments ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS class_enrollments (
    enrollment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id     UUID NOT NULL REFERENCES schools(school_id),
    student_id    UUID NOT NULL REFERENCES students(student_id),
    class_id      UUID NOT NULL REFERENCES classes(class_id),
    academic_year VARCHAR(9) NOT NULL,
    semester      semester NOT NULL,
    enrolled_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    withdrawn_at  TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE class_enrollments ENABLE ROW LEVEL SECURITY;

-- ── LAYER 9: teaching_assignments ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS teaching_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id     UUID NOT NULL REFERENCES schools(school_id),
    user_id       UUID NOT NULL REFERENCES users(user_id),
    class_id      UUID NOT NULL REFERENCES classes(class_id),
    subject_id    UUID NOT NULL REFERENCES subjects(subject_id),
    academic_year VARCHAR(9) NOT NULL,
    semester      semester NOT NULL,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE teaching_assignments ENABLE ROW LEVEL SECURITY;

-- ── LAYER 10: schedule_time_slots ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS schedule_time_slots (
    slot_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id    UUID NOT NULL REFERENCES schools(school_id),
    academic_year VARCHAR(9) NOT NULL,
    semester     semester NOT NULL,
    day_of_week  day_of_week NOT NULL,
    slot_number  INTEGER NOT NULL,
    start_time   TIME NOT NULL,
    end_time     TIME NOT NULL,
    is_break     BOOLEAN NOT NULL DEFAULT FALSE,
    break_label  VARCHAR(50),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE schedule_time_slots ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS rls_schedule_time_slots_read ON schedule_time_slots;
CREATE POLICY rls_schedule_time_slots_read ON schedule_time_slots FOR SELECT USING (auth.uid() IS NOT NULL);

-- ── LAYER 11: schedule_templates ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS schedule_templates (
    template_id   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id     UUID NOT NULL REFERENCES schools(school_id),
    academic_year VARCHAR(9) NOT NULL,
    semester      semester NOT NULL,
    day_of_week   day_of_week NOT NULL,
    start_time    TIME NOT NULL,
    end_time      TIME NOT NULL,
    class_id      UUID NOT NULL REFERENCES classes(class_id),
    teacher_id    UUID NOT NULL REFERENCES users(user_id),
    subject_id    UUID REFERENCES subjects(subject_id),
    subject_label VARCHAR(50),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE schedule_templates ENABLE ROW LEVEL SECURITY;

-- ── LAYER 12: teaching_schedules ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS teaching_schedules (
    schedule_id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id            UUID NOT NULL REFERENCES schools(school_id),
    assignment_id        UUID REFERENCES teaching_assignments(assignment_id),
    class_id             UUID NOT NULL REFERENCES classes(class_id),
    subject_id           UUID REFERENCES subjects(subject_id),
    scheduled_teacher_id UUID NOT NULL REFERENCES users(user_id),
    session_date         DATE NOT NULL,
    session_start        TIME NOT NULL,
    session_end          TIME NOT NULL,
    meeting_status       meeting_status NOT NULL DEFAULT 'NORMAL',
    teacher_indicator    teacher_attendance_indicator NOT NULL DEFAULT 'PENDING_EVALUATION',
    academic_year        VARCHAR(9) NOT NULL,
    semester             semester NOT NULL,
    subject_label        VARCHAR(50),
    block_group_id       UUID,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE teaching_schedules ENABLE ROW LEVEL SECURITY;

-- ── LAYER 13: attendance ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS attendance (
    attendance_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id           UUID NOT NULL REFERENCES schools(school_id),
    schedule_id         UUID NOT NULL REFERENCES teaching_schedules(schedule_id) ON DELETE RESTRICT,
    student_id          UUID NOT NULL REFERENCES students(student_id) ON DELETE RESTRICT,
    recorded_by_user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    status              attendance_status NOT NULL DEFAULT 'HADIR',
    source              attendance_source NOT NULL DEFAULT 'AUTO_DETECTED',
    is_void             BOOLEAN NOT NULL DEFAULT FALSE,
    void_reason         TEXT,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (schedule_id, student_id)
);

ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

-- ── LAYER 14: teacher_attendance_log ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS teacher_attendance_log (
    log_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id    UUID NOT NULL REFERENCES schools(school_id),
    schedule_id  UUID NOT NULL REFERENCES teaching_schedules(schedule_id),
    user_id      UUID NOT NULL REFERENCES users(user_id),
    activity_type VARCHAR(50) NOT NULL,
    activity_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (schedule_id, user_id, activity_type)
);

ALTER TABLE teacher_attendance_log ENABLE ROW LEVEL SECURITY;

-- ── LAYER 15: substitute_schedules ───────────────────────────────────────────

CREATE TABLE IF NOT EXISTS substitute_schedules (
    substitute_id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id             UUID NOT NULL REFERENCES schools(school_id),
    schedule_id           UUID NOT NULL REFERENCES teaching_schedules(schedule_id),
    substitute_user_id    UUID NOT NULL REFERENCES users(user_id),
    granted_by_user_id    UUID NOT NULL REFERENCES users(user_id),
    granted_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    sync_token            TEXT NOT NULL DEFAULT encode(gen_random_bytes(32),'hex'),
    sync_token_expires_at TIMESTAMPTZ NOT NULL,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE substitute_schedules ENABLE ROW LEVEL SECURITY;

-- ── LAYER 16: cases ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS cases (
    case_id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id            UUID NOT NULL REFERENCES schools(school_id),
    student_id           UUID NOT NULL REFERENCES students(student_id),
    created_by_user_id   UUID NOT NULL REFERENCES users(user_id),
    initiated_by_role    role_type NOT NULL,
    current_handler_role role_type NOT NULL,
    is_locked            BOOLEAN NOT NULL DEFAULT FALSE,
    locked_by_user_id    UUID REFERENCES users(user_id),
    locked_at            TIMESTAMPTZ,
    status               case_status NOT NULL DEFAULT 'OPEN',
    track                case_track NOT NULL,
    audience             case_audience NOT NULL DEFAULT 'PRIVATE',
    title                VARCHAR(200) NOT NULL,
    description          TEXT NOT NULL,
    closed_at            TIMESTAMPTZ,
    closed_by_user_id    UUID REFERENCES users(user_id),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE cases ENABLE ROW LEVEL SECURITY;

-- ── LAYER 17: case_events ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS case_events (
    event_id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id            UUID NOT NULL REFERENCES schools(school_id),
    case_id              UUID NOT NULL REFERENCES cases(case_id),
    event_type           case_event_type NOT NULL,
    author_user_id       UUID NOT NULL REFERENCES users(user_id),
    author_role_at_time  role_type NOT NULL,
    privacy_level        visibility_level NOT NULL DEFAULT 'INTERNAL_SCHOOL',
    previous_handler_role role_type,
    new_handler_role     role_type,
    previous_status      case_status,
    new_status           case_status,
    payload              JSONB NOT NULL DEFAULT '{}',
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE case_events ENABLE ROW LEVEL SECURITY;

-- ── LAYER 18: student_updates ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS student_updates (
    update_id      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id      UUID NOT NULL REFERENCES schools(school_id),
    case_id        UUID NOT NULL REFERENCES cases(case_id),
    author_user_id UUID NOT NULL REFERENCES users(user_id),
    content        TEXT NOT NULL,
    case_event_id  UUID REFERENCES case_events(event_id),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE student_updates ENABLE ROW LEVEL SECURITY;

-- ── LAYER 19: observations ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS observations (
    observation_id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id               UUID NOT NULL REFERENCES schools(school_id),
    student_id              UUID NOT NULL REFERENCES students(student_id),
    author_user_id          UUID NOT NULL REFERENCES users(user_id),
    sentiment               observation_sentiment NOT NULL,
    dimension               observation_dimension NOT NULL,
    content                 TEXT NOT NULL,
    visibility              visibility_level NOT NULL,
    visibility_override_flag BOOLEAN NOT NULL DEFAULT FALSE,
    class_id                UUID REFERENCES classes(class_id),
    schedule_id             UUID REFERENCES teaching_schedules(schedule_id),
    observed_at             DATE NOT NULL DEFAULT CURRENT_DATE,
    is_void                 BOOLEAN NOT NULL DEFAULT FALSE,
    void_reason             TEXT,
    voided_by               UUID REFERENCES users(user_id),
    voided_at               TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE observations ENABLE ROW LEVEL SECURITY;

-- ── LAYER 20: bk_class_assignments ───────────────────────────────────────────

CREATE TABLE IF NOT EXISTS bk_class_assignments (
    assignment_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id            UUID NOT NULL REFERENCES schools(school_id) ON DELETE RESTRICT,
    bk_user_id           UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    class_id             UUID NOT NULL REFERENCES classes(class_id) ON DELETE RESTRICT,
    academic_year        TEXT NOT NULL,
    is_active            BOOLEAN NOT NULL DEFAULT TRUE,
    assigned_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    assigned_by_user_id  UUID REFERENCES users(user_id) ON DELETE SET NULL,
    UNIQUE (school_id, bk_user_id, class_id, academic_year)
);

ALTER TABLE bk_class_assignments ENABLE ROW LEVEL SECURITY;

-- ── LAYER 21: guru_wali_assignments ──────────────────────────────────────────

CREATE TABLE IF NOT EXISTS guru_wali_assignments (
    assignment_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id            UUID NOT NULL REFERENCES schools(school_id),
    guru_user_id         UUID NOT NULL REFERENCES users(user_id),
    student_id           UUID NOT NULL REFERENCES students(student_id),
    academic_year        TEXT NOT NULL,
    is_active            BOOLEAN NOT NULL DEFAULT TRUE,
    assigned_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    assigned_by_user_id  UUID REFERENCES users(user_id)
);

ALTER TABLE guru_wali_assignments ENABLE ROW LEVEL SECURITY;

-- ── LAYER 22: teacher_journals ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS teacher_journals (
    journal_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id        UUID NOT NULL REFERENCES schools(school_id),
    owner_user_id    UUID NOT NULL REFERENCES users(user_id),
    schedule_id      UUID REFERENCES teaching_schedules(schedule_id),
    class_id         UUID REFERENCES classes(class_id),
    tp_id            UUID,
    entry_date       DATE NOT NULL DEFAULT CURRENT_DATE,
    content          TEXT NOT NULL,
    kondisi_kelas    VARCHAR(20),
    catatan_tambahan TEXT,
    tindak_lanjut    TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE teacher_journals ENABLE ROW LEVEL SECURITY;

-- ── LAYER 23: communication_categories ───────────────────────────────────────

CREATE TABLE IF NOT EXISTS communication_categories (
    category_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_code  TEXT NOT NULL UNIQUE,
    label_sekolah  TEXT NOT NULL,
    polarity       TEXT NOT NULL DEFAULT 'NEUTRAL',
    display_order  INTEGER NOT NULL DEFAULT 0,
    is_active      BOOLEAN NOT NULL DEFAULT TRUE
);

ALTER TABLE communication_categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS rls_comm_cat_read ON communication_categories;
CREATE POLICY rls_comm_cat_read ON communication_categories FOR SELECT USING (auth.uid() IS NOT NULL);

-- ── LAYER 24: school_config ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS school_config (
    config_id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id             UUID NOT NULL UNIQUE REFERENCES schools(school_id),
    school_name           VARCHAR(150) NOT NULL,
    address               TEXT,
    setup_completed       BOOLEAN NOT NULL DEFAULT FALSE,
    password_changed      BOOLEAN NOT NULL DEFAULT FALSE,
    current_academic_year VARCHAR(9),
    current_semester      semester,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE school_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS rls_school_config_read ON school_config;
CREATE POLICY rls_school_config_read ON school_config FOR SELECT USING (auth.uid() IS NOT NULL);

-- ── LAYER 25: platform_config ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS platform_config (
    id                  SMALLINT PRIMARY KEY DEFAULT 1,
    maintenance_active  BOOLEAN NOT NULL DEFAULT FALSE,
    maintenance_message TEXT,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT platform_config_singleton CHECK (id = 1)
);

INSERT INTO platform_config (id, maintenance_active)
VALUES (1, FALSE)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE platform_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS rls_platform_config_read ON platform_config;
CREATE POLICY rls_platform_config_read ON platform_config FOR SELECT USING (TRUE);

-- ── LAYER 26: sync_idempotency ────────────────────────────────────────────────
-- (juga ada di migration 20240115000000 yg sudah di-repair)

CREATE TABLE IF NOT EXISTS sync_idempotency (
    idempotency_key TEXT PRIMARY KEY,
    function_name   VARCHAR(100) NOT NULL,
    result_json     JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_idempotency_created ON sync_idempotency(created_at);
ALTER TABLE sync_idempotency ENABLE ROW LEVEL SECURITY;

-- ── INDEXES PENTING ───────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_users_auth_user_id ON users(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_users_school_id ON users(school_id);
CREATE INDEX IF NOT EXISTS idx_students_school_id ON students(school_id);
CREATE INDEX IF NOT EXISTS idx_students_program_id ON students(program_id);
CREATE INDEX IF NOT EXISTS idx_class_enrollments_student ON class_enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_class_enrollments_class ON class_enrollments(class_id);
CREATE INDEX IF NOT EXISTS idx_teaching_schedules_date ON teaching_schedules(session_date);
CREATE INDEX IF NOT EXISTS idx_teaching_schedules_class ON teaching_schedules(class_id);
CREATE INDEX IF NOT EXISTS idx_teaching_schedules_school ON teaching_schedules(school_id);
CREATE INDEX IF NOT EXISTS idx_attendance_schedule ON attendance(schedule_id);
CREATE INDEX IF NOT EXISTS idx_attendance_student ON attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_cases_student ON cases(student_id);
CREATE INDEX IF NOT EXISTS idx_cases_school ON cases(school_id);
CREATE INDEX IF NOT EXISTS idx_case_events_case ON case_events(case_id);
CREATE INDEX IF NOT EXISTS idx_observations_student ON observations(student_id);
CREATE INDEX IF NOT EXISTS idx_observations_school ON observations(school_id);
