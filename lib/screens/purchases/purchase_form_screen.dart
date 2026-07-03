import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/ingredient.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ingredient_provider.dart';
import '../../providers/purchase_draft_provider.dart';
import '../../providers/purchase_provider.dart';

/// Builds one shopping-trip transaction with any number of ingredient lines
/// before submitting it as a single batch (mirrors the cashier's cart flow).
class PurchaseFormScreen extends ConsumerStatefulWidget {
  const PurchaseFormScreen({super.key});

  @override
  ConsumerState<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends ConsumerState<PurchaseFormScreen> {
  final _lineFormKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _notesController = TextEditingController();
  String? _ingredientId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Start each purchase form from a clean slate. Deferred to a post-frame
    // callback so this mutation happens strictly after the current build
    // pass finishes (see edit_order_screen.dart for why Future.microtask
    // alone isn't reliably late enough).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(purchaseDraftProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final draft = ref.read(purchaseDraftProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.purchaseDate,
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime.now(),
    );
    if (picked != null) ref.read(purchaseDraftProvider.notifier).setPurchaseDate(picked);
  }

  void _addLine(List<Ingredient> ingredients) {
    if (!(_lineFormKey.currentState?.validate() ?? false) || _ingredientId == null) return;

    final ingredient = ingredients.firstWhere((i) => i.id == _ingredientId);
    ref.read(purchaseDraftProvider.notifier).upsertLine(
          ingredient,
          num.parse(_quantityController.text.trim()),
          num.parse(_unitPriceController.text.trim()),
        );

    setState(() {
      _ingredientId = null;
      _quantityController.clear();
      _unitPriceController.clear();
    });
  }

  Future<void> _submit() async {
    final createdBy = ref.read(currentProfileProvider).value?.id;
    if (createdBy == null) return;

    ref.read(purchaseDraftProvider.notifier).setNotes(_notesController.text);

    setState(() => _saving = true);
    final ok = await ref.read(purchaseControllerProvider.notifier).submitPurchase(createdBy);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belanja berhasil dicatat.')),
      );
    } else {
      final error = ref.read(purchaseControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: ${error ?? 'lengkapi minimal 1 bahan'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredientsAsync = ref.watch(ingredientsProvider);
    final draft = ref.watch(purchaseDraftProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catat Belanja Bahan Baku')),
      body: AsyncValueWidget(
        value: ingredientsAsync,
        data: (ingredients) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tanggal belanja'),
              subtitle: Text(AppFormat.dateLong(draft.purchaseDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text('Tambah Bahan', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Form(
              key: _lineFormKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _ingredientId,
                    decoration: const InputDecoration(labelText: 'Bahan baku'),
                    items: [
                      for (final i in ingredients)
                        DropdownMenuItem(value: i.id, child: Text('${i.name} (${i.unit})')),
                    ],
                    onChanged: (value) => setState(() => _ingredientId = value),
                    validator: (v) => v == null ? 'Pilih bahan baku' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Jumlah'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                            if (num.tryParse(v.trim()) == null) return 'Tidak valid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _unitPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Harga satuan', prefixText: 'Rp '),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                            if (num.tryParse(v.trim()) == null) return 'Tidak valid';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _addLine(ingredients),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah ke Daftar'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Daftar Belanja (${draft.lines.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (draft.lines.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: EmptyState(
                  icon: Icons.playlist_add_outlined,
                  title: 'Belum ada bahan ditambahkan',
                ),
              )
            else
              for (final line in draft.lines)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(line.ingredient.name),
                    subtitle: Text('${line.quantity} ${line.ingredient.unit} × ${AppFormat.rupiah(line.unitPrice)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppFormat.rupiah(line.subtotal), style: const TextStyle(fontWeight: FontWeight.w700)),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () =>
                              ref.read(purchaseDraftProvider.notifier).removeLine(line.ingredient.id),
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
                  : const Text('Simpan Belanja'),
            ),
          ],
        ),
      ),
    );
  }
}
