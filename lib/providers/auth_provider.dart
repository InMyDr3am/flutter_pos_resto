import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

import '../models/profile.dart';
import 'service_providers.dart';

/// Raw Supabase auth stream — used to trigger rebuilds of [currentProfileProvider]
/// and to drive the router's redirect logic.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// The signed-in user's `profiles` row (with their role), or `null` when
/// signed out. This is the single source of truth for role-based UI/routing.
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(authStateChangesProvider);
  final auth = ref.read(authServiceProvider);
  if (auth.currentUser == null) return null;
  try {
    return await auth.fetchCurrentProfile();
  } catch (_) {
    return null;
  }
});

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signIn(email: email, password: password),
    );
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);
