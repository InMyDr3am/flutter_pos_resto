import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ingredient.dart';

/// A single line in the owner's in-progress shopping trip (one entry per
/// ingredient, with its own quantity and unit price).
class PurchaseDraftLine {
  const PurchaseDraftLine({
    required this.ingredient,
    required this.quantity,
    required this.unitPrice,
  });

  final Ingredient ingredient;
  final num quantity;
  final num unitPrice;

  num get subtotal => quantity * unitPrice;
}

class PurchaseDraftState {
  PurchaseDraftState({List<PurchaseDraftLine>? lines, DateTime? purchaseDate, this.notes = ''})
      : lines = lines ?? const [],
        purchaseDate = purchaseDate ?? DateTime.now();

  final List<PurchaseDraftLine> lines;
  final DateTime purchaseDate;
  final String notes;

  num get total => lines.fold<num>(0, (sum, l) => sum + l.subtotal);

  bool get isValid => lines.isNotEmpty;

  PurchaseDraftState copyWith({
    List<PurchaseDraftLine>? lines,
    DateTime? purchaseDate,
    String? notes,
  }) =>
      PurchaseDraftState(
        lines: lines ?? this.lines,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        notes: notes ?? this.notes,
      );
}

class PurchaseDraftNotifier extends Notifier<PurchaseDraftState> {
  @override
  PurchaseDraftState build() => PurchaseDraftState();

  void upsertLine(Ingredient ingredient, num quantity, num unitPrice) {
    final lines = [...state.lines];
    final idx = lines.indexWhere((l) => l.ingredient.id == ingredient.id);
    final line = PurchaseDraftLine(ingredient: ingredient, quantity: quantity, unitPrice: unitPrice);
    if (idx == -1) {
      lines.add(line);
    } else {
      lines[idx] = line;
    }
    state = state.copyWith(lines: lines);
  }

  void removeLine(String ingredientId) {
    state = state.copyWith(lines: state.lines.where((l) => l.ingredient.id != ingredientId).toList());
  }

  void setPurchaseDate(DateTime date) => state = state.copyWith(purchaseDate: date);

  void setNotes(String notes) => state = state.copyWith(notes: notes);

  void clear() => state = PurchaseDraftState();
}

final purchaseDraftProvider =
    NotifierProvider<PurchaseDraftNotifier, PurchaseDraftState>(PurchaseDraftNotifier.new);
