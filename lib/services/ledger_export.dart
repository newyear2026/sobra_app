import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../state/sobra_store.dart';
import 'app_telemetry.dart';
import 'ledger_csv.dart';
import 'ledger_export_data.dart';
import 'ledger_xlsx.dart';

/// Where the export was started from.
enum LedgerExportOrigin { movements, settings }

enum LedgerExportFormat {
  csv('csv', 'text/csv'),
  xlsx(
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );

  const LedgerExportFormat(this.extension, this.mimeType);
  final String extension;
  final String mimeType;
}

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

// Serialize cache replacement even if a caller bypasses the shared service.
// A failed write must not prevent the next export from trying again.
Future<void> _fileWrites = Future<void>.value();

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
) {
  final write = _fileWrites.then((_) async {
    if (await folder.exists()) await folder.delete(recursive: true);
    await folder.create(recursive: true);
    final file = File('${folder.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  });
  _fileWrites = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
  return write;
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
    ShareParams(
      files: [
        XFile(
          file.path,
          mimeType: LedgerExportFormat.values
              .firstWhere((format) => fileName.endsWith('.${format.extension}'))
              .mimeType,
        ),
      ],
    ),
  );
  return result.status;
}

/// Shares one export at a time, including while its format picker is open.
class LedgerExport extends ChangeNotifier {
  LedgerExport({LedgerFileSender? send, DateTime Function()? clock})
    : _send = send ?? _shareWithPlatform,
      _clock = clock ?? DateTime.now;

  static LedgerExport instance = LedgerExport();

  final LedgerFileSender _send;
  final DateTime Function() _clock;
  Future<LedgerExportResult>? _pending;

  /// Shared by both entry points, including while the native sheet is open.
  bool get isSharing => _pending != null;

  Future<LedgerExportResult> share(
    AppLocalizations l10n,
    SobraStore store,
    LedgerExportOrigin origin, {
    LedgerExportFormat format = LedgerExportFormat.csv,
    Future<LedgerExportFormat?> Function()? chooseFormat,
  }) {
    final pending = _pending;
    if (pending != null) return pending;
    final completion = Completer<LedgerExportResult>();
    _pending = completion.future;
    notifyListeners();
    unawaited(
      _finishShare(l10n, store, origin, completion, format, chooseFormat),
    );
    return completion.future;
  }

  Future<void> _finishShare(
    AppLocalizations l10n,
    SobraStore store,
    LedgerExportOrigin origin,
    Completer<LedgerExportResult> completion,
    LedgerExportFormat format,
    Future<LedgerExportFormat?> Function()? chooseFormat,
  ) async {
    try {
      LedgerExportResult result;
      if (store.transactions.isEmpty && store.incomes.isEmpty) {
        result = LedgerExportResult.empty;
      } else {
        final selected = chooseFormat == null ? format : await chooseFormat();
        result = selected == null
            ? LedgerExportResult.dismissed
            : await _share(l10n, store, selected);
      }
      await AppTelemetry.instance.event(TelemetryEvent.ledgerExported, {
        'origin': origin,
        'result': result,
      });
      completion.complete(result);
    } catch (error) {
      debugPrint('Sobra: could not choose an export: ${error.runtimeType}');
      completion.complete(LedgerExportResult.failed);
    } finally {
      _pending = null;
      notifyListeners();
    }
  }

  Future<LedgerExportResult> _share(
    AppLocalizations l10n,
    SobraStore store,
    LedgerExportFormat format,
  ) async {
    final expenses = store.transactions;
    final incomes = store.incomes;
    if (expenses.isEmpty && incomes.isEmpty) return LedgerExportResult.empty;
    try {
      final bytes = switch (format) {
        LedgerExportFormat.csv => Uint8List.fromList(
          utf8.encode(
            ledgerCsv(
              l10n: l10n,
              currency: store.currency,
              expenses: expenses,
              incomes: incomes,
            ),
          ),
        ),
        LedgerExportFormat.xlsx => await compute(
          ledgerXlsx,
          LedgerExportData(
            l10n: l10n,
            currency: store.currency,
            expenses: expenses,
            incomes: incomes,
          ),
        ),
      };
      final status = await _send(
        bytes,
        ledgerCsvFileName(
          _clock(),
        ).replaceFirst(RegExp(r'\.csv$'), '.${format.extension}'),
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
