import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ingredient.dart';
import '../../providers/ingredient_provider.dart';

class IngredientFormSheet extends ConsumerStatefulWidget {
  const IngredientFormSheet({super.key, this.existing});

  final Ingredient? existing;

  @override
  ConsumerState<IngredientFormSheet> createState() => _IngredientFormSheetState();
}

class _IngredientFormSheetState extends ConsumerState<IngredientFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _stockController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _unitController = TextEditingController(text: existing?.unit ?? '');
    _stockController = TextEditingController(text: existing?.stockQuantity.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      final unit = _unitController.text.trim();
      final stock = num.parse(_stockController.text.trim());

      if (widget.existing == null) {
        await ref
            .read(ingredientControllerProvider.notifier)
            .create(name: name, unit: unit, stockQuantity: stock);
      } else {
        await ref.read(ingredientControllerProvider.notifier).updateIngredient(widget.existing!.id, {
          'name': name,
          'unit': unit,
          'stock_quantity': stock,
        });
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Bahan Baku Baru' : 'Ubah Bahan Baku',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama bahan'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(labelText: 'Satuan (kg, liter, pcs, ...)'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Satuan wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Stok saat ini'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Stok wajib diisi';
                if (num.tryParse(v.trim()) == null) return 'Angka tidak valid';
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
