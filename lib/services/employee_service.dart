import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/profile.dart';
import 'supabase_client.dart';

/// Employee (kasir/karyawan) account management for the owner.
///
/// Creating/deleting an `auth.users` row requires the Supabase service-role
/// key, which must never live on the client. Both operations are delegated
/// to Edge Functions (`supabase/functions/create-employee`,
/// `supabase/functions/delete-employee`) that run with that key server-side
/// and verify the caller is an owner before acting.
class EmployeeService {
  final SupabaseClient _db = AppSupabase.client;

  Future<List<Profile>> fetchEmployees() async {
    final rows = await _db
        .from(SupaTables.profiles)
        .select()
        .inFilter('role', [AppRole.kasir, AppRole.karyawan])
        .order('full_name');
    return rows.map(Profile.fromJson).toList();
  }

  Future<void> createEmployee({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final res = await _db.functions.invoke(
      'create-employee',
      body: {'full_name': fullName, 'email': email, 'password': password, 'role': role},
    );
    if (res.status != 200) {
      throw Exception(res.data?['error'] ?? 'Gagal membuat akun karyawan.');
    }
  }

  Future<void> updateEmployeeRole(String profileId, String role) async {
    await _db.from(SupaTables.profiles).update({'role': role}).eq('id', profileId);
  }

  Future<void> deleteEmployee(String profileId) async {
    final res = await _db.functions.invoke(
      'delete-employee',
      body: {'profile_id': profileId},
    );
    if (res.status != 200) {
      throw Exception(res.data?['error'] ?? 'Gagal menghapus akun karyawan.');
    }
  }
}
