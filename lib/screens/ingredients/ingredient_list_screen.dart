import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/ingredient.dart';
import '../../providers/ingredient_provider.dart';
import 'ingredient_form_sheet.dart';

class IngredientListScreen extends ConsumerStatefulWidget {
  const IngredientListScreen({super.key});

  @override
  ConsumerState<IngredientListScreen> createState() => _IngredientListScreenState();
}

class _IngredientListScreenState extends ConsumerState<IngredientListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ingredientsAsync = ref.watch(ingredientsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bahan Baku')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const IngredientFormSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Bahan Baru'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari bahan baku...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => ref.read(ingredientSearchProvider.notifier).set(value),
            ),
          ),
          Expanded(
            child: AsyncValueWidget(
              value: ingredientsAsync,
              data: (ingredients) {
                if (ingredients.isEmpty) {
                  return const EmptyState(
                    icon: Icons.egg_alt_outlined,
                    title: 'Belum ada bahan baku',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: ingredients.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _IngredientCard(ingredient: ingredients[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientCard extends ConsumerWidget {
  const _IngredientCard({required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(ingredient.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('Stok: ${ingredient.stockQuantity} ${ingredient.unit}'),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => IngredientFormSheet(existing: ingredient),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () async {
            final confirmed = await showConfirmDialog(
              context,
              title: 'Hapus bahan baku?',
              message: '"${ingredient.name}" akan dihapus permanen.',
            );
            if (confirmed) {
              await ref.read(ingredientControllerProvider.notifier).delete(ingredient.id);
            }
          },
        ),
      ),
    );
  }
}
