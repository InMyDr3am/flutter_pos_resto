import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/menu_item.dart';
import '../../providers/menu_provider.dart';
import 'menu_form_screen.dart';

class MenuListScreen extends ConsumerStatefulWidget {
  const MenuListScreen({super.key});

  @override
  ConsumerState<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends ConsumerState<MenuListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(menuCategoriesProvider);
    final menuFilter = ref.watch(menuFilterProvider);
    final menuItemsAsync = ref.watch(menuItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Menu')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MenuFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Menu Baru'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari menu...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => ref.read(menuFilterProvider.notifier).setSearch(value),
            ),
          ),
          SizedBox(
            height: 44,
            child: AsyncValueWidget(
              value: categoriesAsync,
              data: (categories) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Semua'),
                      selected: menuFilter.categoryId == null,
                      onSelected: (_) => ref.read(menuFilterProvider.notifier).setCategory(null),
                    ),
                  ),
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category.name),
                        selected: menuFilter.categoryId == category.id,
                        onSelected: (_) =>
                            ref.read(menuFilterProvider.notifier).setCategory(category.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AsyncValueWidget(
              value: menuItemsAsync,
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Belum ada menu',
                    message: 'Tambahkan menu pertama Anda dengan tombol di bawah.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _MenuItemCard(item: items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemCard extends ConsumerWidget {
  const _MenuItemCard({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MenuFormScreen(existing: item)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: item.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => const Icon(Icons.image_not_supported),
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                          child: const Icon(Icons.restaurant_rounded),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(AppFormat.rupiah(item.price)),
                    if (item.categoryName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.categoryName!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  Switch(
                    value: item.isAvailable,
                    onChanged: (value) => ref
                        .read(menuControllerProvider.notifier)
                        .updateMenuItem(item.id, {'is_available': value}),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: 'Hapus menu?',
                        message: '"${item.name}" akan dihapus permanen.',
                      );
                      if (confirmed) {
                        await ref.read(menuControllerProvider.notifier).deleteMenuItem(item.id);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
