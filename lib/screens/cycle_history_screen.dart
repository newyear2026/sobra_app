import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/cycle_record.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_ui.dart';

/// Every cycle that has closed, newest first.
///
/// A screen of its own rather than a section of Ajustes or of Presupuesto:
/// the budget screen's job is setting limits for the cycle running now, and a
/// growing list of finished ones would push that work further down every
/// fortnight. This is the same shape XP history takes — a strip that sums it
/// up where you are, and the whole list a tap away.
class CycleHistoryScreen extends StatelessWidget {
  const CycleHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    final l10n = AppLocalizations.of(context);
    final records = store.cycleRecords;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              children: [
                PixelTopBar(
                  title: l10n.cycleHistoryTitle,
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 18),
                if (records.isEmpty)
                  PixelEmptyState(
                    icon: Icons.history,
                    title: l10n.cycleHistoryTitle,
                    message: l10n.cycleHistoryEmpty,
                  )
                else ...[
                  CycleHistorySummary(records: records),
                  const SizedBox(height: 14),
                  for (final record in records)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CycleRow(record: record),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The one line that answers "am I doing better than last time".
class CycleHistorySummary extends StatelessWidget {
  const CycleHistorySummary({super.key, required this.records});

  final List<CycleRecord> records;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final green = records.where((record) => record.successful).length;
    // Green for a majority, cash for the rest: the warm tone reads as "worth
    // a look" without scolding, which is the voice the rest of the app uses
    // when a number is not where the user wanted it.
    final mostlyGreen = green * 2 >= records.length;

    return PixelCard(
      elevation: PixelElevation.none,
      color: mostlyGreen ? AppColors.tealSoft : AppColors.cashSoft,
      borderColor: mostlyGreen ? AppColors.tealInk : AppColors.cashInk,
      child: Row(
        children: [
          Icon(
            mostlyGreen ? Icons.trending_up : Icons.trending_flat,
            color: mostlyGreen ? AppColors.tealInk : AppColors.cashInk,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.cycleHistorySummary(green, records.length),
              style: pixelText(
                size: 14,
                bold: true,
                color: mostlyGreen ? AppColors.tealInk : AppColors.cashInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleRow extends StatelessWidget {
  const _CycleRow({required this.record});

  final CycleRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = SobraScope.of(context).currency;
    final good = record.successful;
    final ink = good ? AppColors.tealInk : AppColors.dangerInk;

    return PixelCard(
      elevation: PixelElevation.none,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: good ? AppColors.tealSoft : AppColors.dangerSoft,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: Icon(
              good ? Icons.check : Icons.priority_high,
              size: 20,
              color: ink,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cycleDateRange(l10n, record.start, record.end),
                  style: pixelText(size: 14, bold: true),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.cycleHistoryAmounts(
                    formatMoney(
                      currency,
                      record.budgetCentavos,
                      showCode: false,
                    ),
                    formatMoney(
                      currency,
                      record.spentCentavos,
                      showCode: false,
                    ),
                  ),
                  style: pixelText(size: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  switch (record.averageSpentPerDayCentavos) {
                    final average? => l10n.cycleHistoryAverage(
                      formatMoney(currency, average, showCode: false),
                    ),
                    // A cycle shorter than the minimum. Rare, but a pay
                    // schedule that moves can cut one.
                    null => l10n.cycleHistoryAveragePending,
                  },
                  style: pixelText(size: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${good ? '+' : minusSign}'
            '${formatMoney(currency, record.resultCentavos.abs(), showCode: false)}',
            style: pixelText(size: 15, bold: true, color: ink),
          ),
        ],
      ),
    );
  }
}
