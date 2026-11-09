import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../state/sobra_store.dart';
import 'app_telemetry.dart';
import 'ledger_csv.dart';

/// Where the export was started from.
enum LedgerExportOrigin { movements, settings }

/// How an export ended, for the caller's message and for telemetry.
enum LedgerExportResult {
  /// The share sheet closed after the user picked a target.
  shared,

  /// The share sheet closed without a target.
  dismissed,

  /// The platform cannot say how the sheet ended — most Android targets.
  unavailable,

  /// No expense or income yet, so there was nothing to put in a file.
  empty,

  /// The sheet could not be opened.
  failed,
}

/// Opens the platform share sheet on a file and reports how it ended.
typedef LedgerFileSender =
    Future<ShareResultStatus> Function(Uint8List bytes, String fileName);

/// The cache folder the export is written to, under the app's temp directory.
const ledgerExportFolder = 'ledger_export';

/// Writes [bytes] as [fileName] in [folder], leaving nothing else in it.
///
/// One file at a time, deliberately: handing share_plus bytes instead of a
/// path makes it write each export into a fresh random folder it never
/// cleans up, so every tap left another copy of the user's ledger in the
/// cache. Clearing first also drops yesterday's differently named file.
Future<File> writeLedgerExportFile(
  Directory folder,
  Uint8List bytes,
  String fileName,
) async {
  if (await folder.exists()) await folder.delete(recursive: true);
  await folder.create(recursive: true);
  final file = File('${folder.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

Future<ShareResultStatus> _shareWithPlatform(
  Uint8List bytes,
  String fileName,
) async {
  final temp = await getTemporaryDirectory();
  final file = await writeLedgerExportFile(
    Directory('${temp.path}/$ledgerExportFolder'),
    bytes,
    fileName,
  );
  final result = await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path, mimeType: 'text/csv')]),
  );
  return result.status;
}

/// "Export to CSV": builds the file and hands it straight to the share
/// sheet, with no screen in between — the same shape as "tell a friend".
class LedgerExport {
  LedgerExport({LedgerFileSender? send, DateTime Function()? clock})
    : _send = send ?? _shareWithPlatform,
      _clock = clock ?? DateTime.now;

  static LedgerExport instance = LedgerExport();

  final LedgerFileSender _send;
  final DateTime Function() _clock;

  Future<LedgerExportResult> share(
    AppLocalizations l10n,
    SobraStore store,
    LedgerExportOrigin origin,
  ) async {
    final result = await _share(l10n, store);
    await AppTelemetry.instance.event(TelemetryEvent.ledgerExported, {
      'origin': origin,
      'result': result,
    });
    return result;
  }

  Future<LedgerExportResult> _share(
    AppLocalizations l10n,
    SobraStore store,
  ) async {
    final expenses = store.transactions;
    final incomes = store.incomes;
    if (expenses.isEmpty && incomes.isEmpty) return LedgerExportResult.empty;
    try {
      final csv = ledgerCsv(
        l10n: l10n,
        currency: store.currency,
        expenses: expenses,
        incomes: incomes,
      );
      final status = await _send(
        Uint8List.fromList(utf8.encode(csv)),
        ledgerCsvFileName(_clock()),
      );
      return switch (status) {
        ShareResultStatus.success => LedgerExportResult.shared,
        ShareResultStatus.dismissed => LedgerExportResult.dismissed,
        ShareResultStatus.unavailable => LedgerExportResult.unavailable,
      };
    } on Object catch (error) {
      // The type only: the message can carry a path or a piece of the file.
      debugPrint('Sobra: could not export the ledger: ${error.runtimeType}');
      return LedgerExportResult.failed;
    }
  }
}
