import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/ledger_export.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import 'ledger_export_dialog.dart';

/// Chooses a format, shares the export and reports any failure.
///
/// The share sheet is its own feedback when it opens, so success says
/// nothing; an empty ledger and a sheet that would not open each get a line,
/// because a tap that silently does nothing reads like an export that worked.
Future<void> exportLedger(
  BuildContext context,
  LedgerExportOrigin origin,
) async {
  final exporter = LedgerExport.instance;
  // Also covers taps before the disabled appearance has rebuilt, and avoids
  // duplicate snackbars when both screens try to export the same empty ledger.
  if (exporter.isSharing) return;
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final store = SobraScope.of(context);
  final result = await exporter.share(
    l10n,
    store,
    origin,
    chooseFormat: () => showDialog<LedgerExportFormat>(
      context: context,
      builder: (_) => const LedgerExportDialog(),
    ),
  );
  final message = switch (result) {
    LedgerExportResult.empty => l10n.csvExportEmpty,
    LedgerExportResult.failed => l10n.csvExportFailed,
    _ => null,
  };
  if (message == null || !messenger.mounted) return;
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

/// The export icon in the ledger's top bar.
///
/// Drawn like the app's icon boxes — ink border, hard offset shadow — so it
/// reads as a pixel button rather than a stray Material icon. Ignores taps
/// while an export is underway, so a double tap opens one sheet, not two.
class LedgerExportButton extends StatelessWidget {
  const LedgerExportButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final exporter = LedgerExport.instance;
    return ListenableBuilder(
      listenable: exporter,
      builder: (context, _) {
        final busy = exporter.isSharing;
        final label = busy ? l10n.csvExportPreparing : l10n.csvExportTooltip;
        return Tooltip(
          message: label,
          child: Semantics(
            button: true,
            enabled: !busy,
            label: label,
            excludeSemantics: true,
            child: GestureDetector(
              key: const Key('ledger-export'),
              behavior: HitTestBehavior.opaque,
              onTap: busy
                  ? null
                  : () => exportLedger(context, LedgerExportOrigin.movements),
              // 48 dp of touch target around a 38 dp box.
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: busy ? AppColors.beige : AppColors.tealSoft,
                      border: Border.all(color: AppColors.ink, width: 2.5),
                      boxShadow: const [
                        BoxShadow(color: AppColors.ink, offset: Offset(3, 3)),
                      ],
                    ),
                    child: Icon(
                      busy ? Icons.hourglass_top : Icons.ios_share,
                      color: busy ? AppColors.muted : AppColors.tealInk,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
