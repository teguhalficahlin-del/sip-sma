/**
 * @file delete-user/index.ts
 * @edge-function delete-user
 *
 * Soft-delete user: ban Auth account + set deleted_at + is_active=false.
 * Data historis (absensi, observasi, kasus) tetap utuh.
 * Admin bisa restore via edge fn restore-user dalam 30 hari.
 *
 * CONTRACT:
 *   DELETE /functions/v1/delete-user
 *   Body: { "user_id": "<uuid>" }
 *   Caller: ADMINISTRATIVE only
 *
 * URUTAN:
 *   1. Validasi — user ada, sekolah sama, bukan ADMINISTRATIVE, bukan diri sendiri
 *   2. Ban Auth account (bukan hapus) agar tidak bisa login
 *   3. Set users.deleted_at = now(), is_active = false
 */

import { handleCors, corsHeaders }  from '../_shared/cors.ts';
import { ok, badRequest, forbidden,
         internalError,
         checkSchemaVersion }        from '../_shared/response.ts';
import { resolveAuth, isAuthError }  from '../_shared/auth.ts';
import { getAdminClient }            from '../_shared/db.ts';

const BAN_DURATION = '876600h'; // ~100 tahun = ban permanen efektif

Deno.serve(async (req: Request): Promise<Response> => {

    if (req.method === 'OPTIONS') return handleCors();
    if (req.method !== 'DELETE') {
        return new Response('Method Not Allowed',
            { status: 405, headers: corsHeaders });
    }

    try {
        const versionError = checkSchemaVersion(req);
        if (versionError) return versionError;

        const admin      = getAdminClient();
        const authResult = await resolveAuth(req, admin);
        if (isAuthError(authResult)) return authResult;
        const { user } = authResult;

        if (user.role_type !== 'ADMINISTRATIVE') {
            return forbidden('Hanya ADMINISTRATIVE yang dapat menghapus pengguna');
        }

        let body: { user_id?: string };
        try {
            body = await req.json();
        } catch {
            return badRequest('Body harus berformat JSON: { "user_id": "<uuid>" }');
        }

        const { user_id } = body;
        if (!user_id) return badRequest('Field user_id wajib diisi');

        if (user_id === user.user_id) {
            return forbidden('Tidak dapat menghapus akun Anda sendiri');
        }

        // 1. Ambil target user — filter school_id mencegah hapus user sekolah lain
        const { data: targetUser, error: fetchErr } = await admin
            .from('users')
            .select('auth_user_id, role_type, full_name, school_id, deleted_at')
            .eq('user_id', user_id)
            .eq('school_id', user.school_id)
            .maybeSingle();

        if (fetchErr) return internalError(fetchErr);
        if (!targetUser) {
            return badRequest(`Pengguna dengan user_id "${user_id}" tidak ditemukan di sekolah ini`);
        }
        if (targetUser.role_type === 'ADMINISTRATIVE') {
            return forbidden('Akun ADMINISTRATIVE tidak dapat dihapus melalui panel ini');
        }
        if (targetUser.deleted_at) {
            return badRequest('Pengguna ini sudah dihapus sebelumnya. Gunakan restore-user untuk memulihkan.');
        }

        // 2. Ban Auth account agar tidak bisa login (bukan dihapus — bisa di-unban saat restore)
        if (targetUser.auth_user_id) {
            const { error: banErr } = await admin.auth.admin
                .updateUserById(targetUser.auth_user_id, { ban_duration: BAN_DURATION });
            if (banErr) {
                if (!banErr.message?.includes('not found') && !banErr.message?.includes('User not found')) {
                    console.error('[delete-user] Auth ban failed:', banErr);
                    return internalError(banErr);
                }
                console.warn('[delete-user] Auth user not found, skipping ban:', targetUser.auth_user_id);
            }
        }

        // 3. Soft-delete: tandai deleted_at + nonaktifkan
        const { error: updateErr } = await admin
            .from('users')
            .update({ deleted_at: new Date().toISOString(), is_active: false })
            .eq('user_id', user_id);

        if (updateErr) return internalError(updateErr);

        return ok({
            deleted: true,
            soft: true,
            user_id,
            full_name: targetUser.full_name,
            note: 'Pengguna dihapus sementara. Bisa dipulihkan dalam 30 hari melalui Recycle Bin.',
        });

    } catch (err) {
        return internalError(err);
    }
});
