import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/ledger_export.dart';
import '../theme/app_theme.dart';

class LedgerExportDialog extends StatefulWidget {
  const LedgerExportDialog({super.key});

  @override
  State<LedgerExportDialog> createState() => _LedgerExportDialogState();
}

class _LedgerExportDialogState extends State<LedgerExportDialog> {
  bool _chosen = false;

  void _choose(LedgerExportFormat format) {
    // A second tap during the dialog's exit animation must not pop the page.
    if (_chosen) return;
    setState(() => _chosen = true);
    Navigator.of(context).pop(format);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.exportFormatTitle),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.exportAllHistory,
                style: pixelText(size: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              _option(
                LedgerExportFormat.csv,
                Icons.description_outlined,
                l10n.exportCsvTitle,
                l10n.exportCsvDescription,
              ),
              const SizedBox(height: 12),
              _option(
                LedgerExportFormat.xlsx,
                Icons.table_chart_outlined,
                l10n.exportExcelTitle,
                l10n.exportExcelDescription,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _chosen ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }

  Widget _option(
    LedgerExportFormat format,
    IconData icon,
    String title,
    String description,
  ) => OutlinedButton(
    key: Key('ledger-export-${format.extension}'),
    onPressed: _chosen ? null : () => _choose(format),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.all(14),
      foregroundColor: AppColors.ink,
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.ink, width: 2),
      shape: const RoundedRectangleBorder(),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.tealInk),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: pixelText(size: 16, bold: true)),
              const SizedBox(height: 4),
              Text(
                description,
                style: pixelText(size: 13, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
