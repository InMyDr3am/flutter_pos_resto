import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile.dart';
import 'service_providers.dart';

final employeesProvider = FutureProvider<List<Profile>>((ref) {
  return ref.watch(employeeServiceProvider).fetchEmployees();
});

class EmployeeController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    ref.invalidate(employeesProvider);
  }

  Future<void> create({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) =>
      _run(() => ref.read(employeeServiceProvider).createEmployee(
            fullName: fullName,
            email: email,
            password: password,
            role: role,
          ));

  Future<void> updateRole(String profileId, String role) =>
      _run(() => ref.read(employeeServiceProvider).updateEmployeeRole(profileId, role));

  Future<void> delete(String profileId) =>
      _run(() => ref.read(employeeServiceProvider).deleteEmployee(profileId));
}

final employeeControllerProvider =
    AsyncNotifierProvider<EmployeeController, void>(EmployeeController.new);
