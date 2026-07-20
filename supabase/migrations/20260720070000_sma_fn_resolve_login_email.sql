DROP FUNCTION IF EXISTS public.fn_resolve_login_email(TEXT);
CREATE OR REPLACE FUNCTION public.fn_resolve_login_email(
    p_identifier TEXT,
    p_school_id  UUID DEFAULT NULL
)
RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    SELECT email FROM users
    WHERE login_identifier = p_identifier
      AND is_active = TRUE
      AND (p_school_id IS NULL OR school_id = p_school_id)
    LIMIT 1;
$$;
REVOKE EXECUTE ON FUNCTION public.fn_resolve_login_email(TEXT, UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.fn_resolve_login_email(TEXT, UUID) TO anon;
GRANT  EXECUTE ON FUNCTION public.fn_resolve_login_email(TEXT, UUID) TO authenticated;
