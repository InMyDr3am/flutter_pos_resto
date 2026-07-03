import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single line in the owner's in-progress expense report.
class ExpenseDraftLine {
  const ExpenseDraftLine({required this.category, this.description, required this.amount});

  final String category;
  final String? description;
  final num amount;
}

class ExpenseDraftState {
  ExpenseDraftState({List<ExpenseDraftLine>? lines, DateTime? expenseDate, this.notes = ''})
      : lines = lines ?? const [],
        expenseDate = expenseDate ?? DateTime.now();

  final List<ExpenseDraftLine> lines;
  final DateTime expenseDate;
  final String notes;

  num get total => lines.fold<num>(0, (sum, l) => sum + l.amount);

  bool get isValid => lines.isNotEmpty;

  ExpenseDraftState copyWith({
    List<ExpenseDraftLine>? lines,
    DateTime? expenseDate,
    String? notes,
  }) =>
      ExpenseDraftState(
        lines: lines ?? this.lines,
        expenseDate: expenseDate ?? this.expenseDate,
        notes: notes ?? this.notes,
      );
}

class ExpenseDraftNotifier extends Notifier<ExpenseDraftState> {
  @override
  ExpenseDraftState build() => ExpenseDraftState();

  void addLine(ExpenseDraftLine line) {
    state = state.copyWith(lines: [...state.lines, line]);
  }

  void removeLineAt(int index) {
    final lines = [...state.lines]..removeAt(index);
    state = state.copyWith(lines: lines);
  }

  void setExpenseDate(DateTime date) => state = state.copyWith(expenseDate: date);

  void setNotes(String notes) => state = state.copyWith(notes: notes);

  void clear() => state = ExpenseDraftState();
}

final expenseDraftProvider =
    NotifierProvider<ExpenseDraftNotifier, ExpenseDraftState>(ExpenseDraftNotifier.new);
