import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/menu_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import 'order_checkout_sheet.dart';

/// Menu-picking tab of the cashier flow. Tapping a menu card adds it to the
/// shared [cartProvider]; a summary bar (built by [KasirHomeScreen]) shows
/// the running total and opens [OrderCheckoutSheet].
class NewOrderTab extends ConsumerStatefulWidget {
  const NewOrderTab({super.key});

  @override
  ConsumerState<NewOrderTab> createState() => _NewOrderTabState();
}

class _NewOrderTabState extends ConsumerState<NewOrderTab> {
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
    final cart = ref.watch(cartProvider);

    return Column(
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
              final available = items.where((i) => i.isAvailable).toList();
              if (available.isEmpty) {
                return const EmptyState(icon: Icons.no_food_outlined, title: 'Tidak ada menu tersedia');
              }
              return GridView.builder(
                padding: EdgeInsets.fromLTRB(16, 0, 16, cart.lines.isEmpty ? 16 : 90),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: available.length,
                itemBuilder: (context, index) => _MenuPickCard(item: available[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MenuPickCard extends ConsumerWidget {
  const _MenuPickCard({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(cartProvider.select((c) {
      for (final line in c.lines) {
        if (line.menuItem.id == item.id) return line.quantity;
      }
      return 0;
    }));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: item.imageUrl != null
                ? CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover)
                : Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    child: const Icon(Icons.restaurant_rounded, size: 32),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(AppFormat.rupiah(item.price), style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                if (qty == 0)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
                      onPressed: () => ref.read(cartProvider.notifier).increment(item),
                      child: const Text('Tambah'),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filledTonal(
                        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: () => ref.read(cartProvider.notifier).decrement(item.id),
                      ),
                      Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700)),
                      IconButton.filledTonal(
                        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () => ref.read(cartProvider.notifier).increment(item),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
