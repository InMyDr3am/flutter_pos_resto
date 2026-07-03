import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/profile.dart';
import 'supabase_client.dart';

class AuthService {
  final SupabaseClient _db = AppSupabase.client;

  Stream<AuthState> get authStateChanges => _db.auth.onAuthStateChange;

  User? get currentUser => _db.auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    await _db.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _db.auth.signOut();

  Future<Profile> fetchCurrentProfile() async {
    final userId = currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user.');
    }
    final row = await _db.from(SupaTables.profiles).select().eq('id', userId).single();
    return Profile.fromJson(row);
  }
}
