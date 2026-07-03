import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_draft_provider.dart';
import '../../providers/expense_provider.dart';

/// Builds one expense report with any number of line items before
/// submitting it as a single batch (mirrors the purchase flow).
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _lineFormKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Deferred to a post-frame callback so this mutation happens strictly
    // after the current build pass finishes (see edit_order_screen.dart for
    // why Future.microtask alone isn't reliably late enough).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(expenseDraftProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final draft = ref.read(expenseDraftProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.expenseDate,
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime.now(),
    );
    if (picked != null) ref.read(expenseDraftProvider.notifier).setExpenseDate(picked);
  }

  void _addLine() {
    if (!(_lineFormKey.currentState?.validate() ?? false)) return;

    ref.read(expenseDraftProvider.notifier).addLine(ExpenseDraftLine(
          category: _categoryController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          amount: num.parse(_amountController.text.trim()),
        ));

    setState(() {
      _categoryController.clear();
      _descriptionController.clear();
      _amountController.clear();
    });
  }

  Future<void> _submit() async {
    final createdBy = ref.read(currentProfileProvider).value?.id;
    if (createdBy == null) return;

    ref.read(expenseDraftProvider.notifier).setNotes(_notesController.text);

    setState(() => _saving = true);
    final ok = await ref.read(expenseControllerProvider.notifier).submitExpense(createdBy);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengeluaran berhasil dicatat.')),
      );
    } else {
      final error = ref.read(expenseControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: ${error ?? 'lengkapi minimal 1 pengeluaran'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(expenseDraftProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengeluaran Baru')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tanggal'),
            subtitle: Text(AppFormat.dateLong(draft.expenseDate)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickDate,
          ),
          const Divider(),
          const SizedBox(height: 8),
          Text('Tambah Pengeluaran', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Form(
            key: _lineFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Kategori (mis. Gaji, Alat Masak)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Kategori wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Nominal', prefixText: 'Rp '),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nominal wajib diisi';
                    if (num.tryParse(v.trim()) == null) return 'Angka tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addLine,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah ke Daftar'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Daftar Pengeluaran (${draft.lines.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (draft.lines.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: EmptyState(
                icon: Icons.playlist_add_outlined,
                title: 'Belum ada pengeluaran ditambahkan',
              ),
            )
          else
            for (var i = 0; i < draft.lines.length; i++)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(draft.lines[i].category),
                  subtitle: draft.lines[i].description != null
                      ? Text(draft.lines[i].description!)
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppFormat.rupiah(draft.lines[i].amount),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => ref.read(expenseDraftProvider.notifier).removeLineAt(i),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text(
                AppFormat.rupiah(draft.total),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (_saving || !draft.isValid) ? null : _submit,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Simpan Pengeluaran'),
          ),
        ],
      ),
    );
  }
}
