-- Migration: tambah WAKA_HUMAS ke rls_users_read_staff
-- Sebelumnya: 7 role (GURU, BK, WALI_KELAS, KEPSEK, WAKA_KURIKULUM, WAKA_KESISWAAN, ADMINISTRATIVE)
-- Sesudah:    8 role (tambah WAKA_HUMAS)

DROP POLICY IF EXISTS rls_users_read_staff ON users;

CREATE POLICY rls_users_read_staff ON users
FOR SELECT USING (
    school_id = fn_current_school_id()
    AND (
        -- Staf membaca sesama staf
        (
            fn_current_user_role() = ANY (ARRAY[
                'GURU'::role_type, 'BK'::role_type, 'WALI_KELAS'::role_type,
                'KEPSEK'::role_type, 'WAKA_KURIKULUM'::role_type,
                'WAKA_KESISWAAN'::role_type, 'ADMINISTRATIVE'::role_type,
                'WAKA_HUMAS'::role_type
            ])
            AND role_type = ANY (ARRAY[
                'GURU'::role_type, 'BK'::role_type, 'WALI_KELAS'::role_type,
                'KEPSEK'::role_type, 'WAKA_KURIKULUM'::role_type,
                'WAKA_KESISWAAN'::role_type, 'ADMINISTRATIVE'::role_type,
                'WAKA_HUMAS'::role_type
            ])
        )
        -- Self-read
        OR (auth_user_id = auth.uid())
        -- Staf membaca SISWA dan ORTU
        OR (
            fn_current_user_role() = ANY (ARRAY[
                'GURU'::role_type, 'BK'::role_type, 'WALI_KELAS'::role_type,
                'KEPSEK'::role_type, 'WAKA_KURIKULUM'::role_type,
                'WAKA_KESISWAAN'::role_type, 'ADMINISTRATIVE'::role_type,
                'WAKA_HUMAS'::role_type
            ])
            AND role_type = ANY (ARRAY['SISWA'::role_type, 'ORTU'::role_type])
        )
    )
);
