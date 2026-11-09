import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/ledger_export.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';

/// Runs the CSV export and says so when it could not happen.
///
/// The share sheet is its own feedback when it opens, so success says
/// nothing; an empty ledger and a sheet that would not open each get a line,
/// because a tap that silently does nothing reads like an export that worked.
Future<void> exportLedger(
  BuildContext context,
  LedgerExportOrigin origin,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final store = SobraScope.of(context);
  final result = await LedgerExport.instance.share(l10n, store, origin);
  final message = switch (result) {
    LedgerExportResult.empty => l10n.csvExportEmpty,
    LedgerExportResult.failed => l10n.csvExportFailed,
    _ => null,
  };
  if (message == null) return;
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

/// The export icon in the ledger's top bar.
///
/// Drawn like the app's icon boxes — ink border, hard offset shadow — so it
/// reads as a pixel button rather than a stray Material icon. Ignores taps
/// while an export is underway, so a double tap opens one sheet, not two.
class LedgerExportButton extends StatefulWidget {
  const LedgerExportButton({super.key});

  @override
  State<LedgerExportButton> createState() => _LedgerExportButtonState();
}

class _LedgerExportButtonState extends State<LedgerExportButton> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await exportLedger(context, LedgerExportOrigin.movements);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.csvExportTooltip,
      child: Semantics(
        button: true,
        label: l10n.csvExportTooltip,
        excludeSemantics: true,
        child: GestureDetector(
          key: const Key('ledger-export'),
          behavior: HitTestBehavior.opaque,
          onTap: _export,
          // 48 dp of touch target around a 38 dp box.
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  border: Border.all(color: AppColors.ink, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: AppColors.ink, offset: Offset(3, 3)),
                  ],
                ),
                child: const Icon(
                  Icons.ios_share,
                  color: AppColors.tealInk,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
