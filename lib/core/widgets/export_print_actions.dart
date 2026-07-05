import 'package:flutter/material.dart';

/// Pair of AppBar actions ("Export Excel" / "Cetak") shared by every report
/// screen — shows a small spinner in place of the icons while the export or
/// print job is running, and surfaces failures as a snackbar.
class ExportPrintActions extends StatefulWidget {
  const ExportPrintActions({super.key, required this.onExport, required this.onPrint});

  final Future<void> Function() onExport;
  final Future<void> Function() onPrint;

  @override
  State<ExportPrintActions> createState() => _ExportPrintActionsState();
}

class _ExportPrintActionsState extends State<ExportPrintActions> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Export Excel',
          icon: const Icon(Icons.grid_on_rounded),
          onPressed: () => _run(widget.onExport),
        ),
        IconButton(
          tooltip: 'Cetak',
          icon: const Icon(Icons.print_outlined),
          onPressed: () => _run(widget.onPrint),
        ),
      ],
    );
  }
}
