import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Small colored pill showing an order status (`on_process` / `served` / `paid`).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      OrderStatus.onProcess => (const Color(0xFFB25E00), 'Diproses'),
      OrderStatus.served => (const Color(0xFF1D5FBF), 'Dihidangkan'),
      OrderStatus.paid => (const Color(0xFF1E7A5F), 'Lunas'),
      OrderStatus.cancelled => (const Color(0xFFC62828), 'Dibatalkan'),
      _ => (Colors.grey, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
