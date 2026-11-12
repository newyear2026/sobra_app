import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/backup_summary.dart';
import '../services/purchase_service.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_ui.dart';

class BackupImportScreen extends StatefulWidget {
  const BackupImportScreen({super.key});

  @override
  State<BackupImportScreen> createState() => _BackupImportScreenState();
}

class _BackupImportScreenState extends State<BackupImportScreen> {
  final _text = TextEditingController();
  BackupSummary? _summary;
  String? _reviewedJson;
  String? _error;
  bool _working = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _preview() {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _summary = null;
      _reviewedJson = null;
      _error = null;
    });
    try {
      final raw = _text.text.trim();
      final summary = SobraScope.of(context).inspectBackup(raw);
      FocusScope.of(context).unfocus();
      setState(() {
        _summary = summary;
        _reviewedJson = raw;
        _error = null;
      });
    } on UnsupportedError {
      setState(() => _error = l10n.backupNewer);
    } on FormatException {
      setState(() => _error = l10n.backupInvalid);
    }
  }

  Future<void> _paste() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      _text.text = data?.text ?? '';
      _preview();
    } on Object {
      if (mounted) {
        setState(() {
          _summary = null;
          _reviewedJson = null;
          _error = AppLocalizations.of(context).backupInvalid;
        });
      }
    }
  }

  Future<void> _restore() async {
    final raw = _reviewedJson;
    if (_working || raw == null) return;
    final store = SobraScope.of(context);
    final purchases = PurchaseScope.maybeOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _working = true);
    final restored = await guardStoreWrite(
      messenger,
      l10n,
      () => store.importBackup(raw),
    );
    if (!mounted) return;
    setState(() => _working = false);
    if (!restored) return;
    // The current device's store, not the JSON file, delivers paid products.
    purchases?.refresh();
    Navigator.pop(context, true);
    messenger.showSnackBar(SnackBar(content: Text(l10n.backupImportSuccess)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = _summary;
    return PopScope(
      canPop: !_working,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                children: [
                  PixelTopBar(
                    title: l10n.backupImportTitle,
                    onBack: _working ? null : () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.backupImportHint),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('backup-json'),
                    controller: _text,
                    enabled: !_working,
                    minLines: 4,
                    maxLines: 8,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'JSON',
                      errorText: _error,
                      errorMaxLines: 4,
                    ),
                    onChanged: (_) => setState(() {
                      _summary = null;
                      _reviewedJson = null;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _working ? null : _paste,
                    icon: const Icon(Icons.content_paste),
                    label: Text(l10n.backupPaste),
                  ),
                  if (SobraScope.of(context).backupBeforeImportJson != null)
                    TextButton.icon(
                      onPressed: _working
                          ? null
                          : () {
                              _text.text = SobraScope.of(
                                context,
                              ).backupBeforeImportJson!;
                              _preview();
                            },
                      icon: const Icon(Icons.history),
                      label: Text(l10n.backupPrevious),
                    ),
                  PixelButton(
                    label: l10n.backupPreview,
                    onPressed: _working ? null : _preview,
                  ),
                  if (summary != null) ...[
                    const SizedBox(height: 24),
                    PixelCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.backupSummary(
                              summary.expenses,
                              summary.incomes,
                              summary.fixedExpenses,
                            ),
                            style: pixelText(size: 15, bold: true),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${l10n.settingsCurrency}: ${summary.currency.code}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${l10n.budgetTotal}: ${summary.budgetCentavos == null ? '—' : formatMoney(summary.currency, summary.budgetCentavos!)}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.backupReplaceWarning,
                      style: pixelText(size: 14, bold: true),
                    ),
                    const SizedBox(height: 10),
                    Text(l10n.receiptBackupNote),
                    const SizedBox(height: 10),
                    Text(l10n.backupPurchaseNote),
                    const SizedBox(height: 20),
                    PixelButton(
                      label: _working ? l10n.saving : l10n.backupRestore,
                      onPressed: _working ? null : _restore,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
