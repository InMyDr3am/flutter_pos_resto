import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/profile.dart';
import '../../providers/employee_provider.dart';
import 'employee_form_sheet.dart';

class EmployeeListScreen extends ConsumerWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Karyawan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const EmployeeFormSheet(),
        ),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Tambah Akun'),
      ),
      body: AsyncValueWidget(
        value: employeesAsync,
        data: (employees) {
          if (employees.isEmpty) {
            return const EmptyState(
              icon: Icons.badge_outlined,
              title: 'Belum ada akun kasir/karyawan',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: employees.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _EmployeeCard(profile: employees[index]),
          );
        },
      ),
    );
  }
}

class _EmployeeCard extends ConsumerWidget {
  const _EmployeeCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          child: Text(profile.fullName.trim().isNotEmpty ? profile.fullName.trim()[0].toUpperCase() : '?'),
        ),
        title: Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(AppRole.label(profile.role)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              value: profile.role,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: AppRole.kasir, child: Text('Kasir')),
                DropdownMenuItem(value: AppRole.karyawan, child: Text('Karyawan')),
              ],
              onChanged: (role) {
                if (role != null) {
                  ref.read(employeeControllerProvider.notifier).updateRole(profile.id, role);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Hapus akun?',
                  message: 'Akun "${profile.fullName}" akan dihapus permanen dan tidak bisa masuk lagi.',
                );
                if (confirmed) {
                  await ref.read(employeeControllerProvider.notifier).delete(profile.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
