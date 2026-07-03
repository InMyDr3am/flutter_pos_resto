import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'empty_state.dart';

/// Renders an [AsyncValue] with consistent loading/error/data handling so
/// screens don't each reinvent the same switch statement.
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function()? loading;
  final Widget Function(Object error)? error;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading?.call() ?? const Center(child: CircularProgressIndicator()),
      error: (err, _) => error?.call(err) ??
          EmptyState(
            icon: Icons.error_outline,
            title: 'Terjadi kesalahan',
            message: err.toString(),
          ),
    );
  }
}
