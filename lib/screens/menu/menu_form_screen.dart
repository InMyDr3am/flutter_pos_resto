import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/async_value_widget.dart';
import '../../models/menu_category.dart';
import '../../models/menu_item.dart';
import '../../providers/menu_provider.dart';

/// Create/edit form for a single menu item. Pass [existing] to edit.
class MenuFormScreen extends ConsumerStatefulWidget {
  const MenuFormScreen({super.key, this.existing});

  final MenuItem? existing;

  @override
  ConsumerState<MenuFormScreen> createState() => _MenuFormScreenState();
}

class _MenuFormScreenState extends ConsumerState<MenuFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  String? _categoryId;
  bool _isAvailable = true;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _priceController = TextEditingController(text: existing?.price.toString() ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _categoryId = existing?.categoryId;
    _isAvailable = existing?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedImageBytes = bytes;
      _pickedImageName = picked.name;
    });
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategori baru'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(menuControllerProvider.notifier).addCategory(name);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      String? imageUrl = widget.existing?.imageUrl;
      if (_pickedImageBytes != null) {
        imageUrl = await ref
            .read(menuControllerProvider.notifier)
            .uploadPhoto(_pickedImageBytes!, _pickedImageName ?? 'menu.jpg');
      }

      final price = num.parse(_priceController.text.trim());

      if (widget.existing == null) {
        await ref.read(menuControllerProvider.notifier).createMenuItem(MenuItem(
              id: '',
              categoryId: _categoryId,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              price: price,
              imageUrl: imageUrl,
              isAvailable: _isAvailable,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));
      } else {
        await ref.read(menuControllerProvider.notifier).updateMenuItem(widget.existing!.id, {
          'category_id': _categoryId,
          'name': _nameController.text.trim(),
          'description':
              _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          'price': price,
          'image_url': imageUrl,
          'is_available': _isAvailable,
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
    final categoriesAsync = ref.watch(menuCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Menu Baru' : 'Ubah Menu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _pickedImageBytes != null
                      ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                      : widget.existing?.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.existing!.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, size: 32),
                                  SizedBox(height: 8),
                                  Text('Tambah foto menu'),
                                ],
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama menu'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Harga', prefixText: 'Rp '),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Harga wajib diisi';
                  if (num.tryParse(v.trim()) == null) return 'Harga tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AsyncValueWidget<List<MenuCategory>>(
                value: categoriesAsync,
                data: (categories) => Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _categoryId,
                        decoration: const InputDecoration(labelText: 'Kategori'),
                        items: [
                          for (final c in categories)
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (value) => setState(() => _categoryId = value),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: _addCategory,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tersedia'),
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
              ),
              const SizedBox(height: 16),
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
      ),
    );
  }
}
