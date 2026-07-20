-- SIP SMA: RPC functions untuk branding dan maintenance status
-- Dipanggil SEBELUM login (anon) oleh shared/branding.js

-- ══════════════════════════════════════════════════════════
-- fn_school_branding
-- Input : p_slug text
-- Output: TABLE(school_id, name, logo_url, primary_color,
--               secondary_color, slug)
-- Dipanggil anon → wajib SECURITY DEFINER (bypass RLS schools)
-- ══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.fn_school_branding(p_slug text)
RETURNS TABLE(
    school_id       uuid,
    name            text,
    logo_url        text,
    primary_color   text,
    secondary_color text,
    slug            text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT school_id, name, logo_url, primary_color, secondary_color, slug
    FROM   public.schools
    WHERE  slug = p_slug
      AND  is_active = true
    LIMIT  1;
$$;

REVOKE EXECUTE ON FUNCTION public.fn_school_branding(text) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.fn_school_branding(text) TO anon;
GRANT  EXECUTE ON FUNCTION public.fn_school_branding(text) TO authenticated;

-- ══════════════════════════════════════════════════════════
-- platform_config — tabel singleton untuk flag maintenance
-- Satu baris (id=1), hanya ditulis oleh edge fn set-maintenance
-- via service-role. Dibaca publik via fn_maintenance_status.
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.platform_config (
    id                  SMALLINT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    maintenance_active  BOOLEAN  NOT NULL DEFAULT FALSE,
    maintenance_message TEXT,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO public.platform_config (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.platform_config ENABLE ROW LEVEL SECURITY;

-- ══════════════════════════════════════════════════════════
-- fn_maintenance_status
-- Output: jsonb { active bool, message text }
-- Dipanggil anon → SECURITY DEFINER (bypass RLS platform_config)
-- ══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.fn_maintenance_status()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT jsonb_build_object(
        'active',  COALESCE(maintenance_active, FALSE),
        'message', maintenance_message
    )
    FROM public.platform_config
    WHERE id = 1;
$$;

REVOKE EXECUTE ON FUNCTION public.fn_maintenance_status() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.fn_maintenance_status() TO anon;
GRANT  EXECUTE ON FUNCTION public.fn_maintenance_status() TO authenticated;
