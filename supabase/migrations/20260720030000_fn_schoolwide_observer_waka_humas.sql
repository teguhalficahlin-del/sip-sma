-- Tambah WAKA_HUMAS ke fn_is_schoolwide_observer.
-- Waka Humas SMA perlu akses baca data siswa untuk
-- keperluan publikasi, PPDB, dan laporan ke pemda/perguruan tinggi.
CREATE OR REPLACE FUNCTION fn_is_schoolwide_observer()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM users u
        WHERE u.auth_user_id = auth.uid()
          AND ( u.role_type IN ('BK','KEPSEK','WAKA_KURIKULUM','WAKA_KESISWAAN','WAKA_HUMAS')
                OR u.is_bk OR u.is_kepsek OR u.is_waka_kurikulum OR u.is_waka_kesiswaan OR u.is_waka_humas )
    );
$$;
