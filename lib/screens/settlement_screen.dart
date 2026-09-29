import 'package:flutter/material.dart';

import '../l10n/catalog_labels.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/cycle_record.dart';
import '../models/xp_event.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_ui.dart';
import 'collection_screen.dart';

/// The moment a cycle closes, not the list of past ones.
///
/// Plays no ads. The optional card only opens the collection on the
/// recommended entry; the rewarded view still starts there.
class SettlementScreen extends StatelessWidget {
  const SettlementScreen({
    super.key,
    required this.notice,
    this.record,
  });

  final XpNotice notice;
  final CycleRecord? record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    final currency = store.currency;
    final recommended = store.recommendedRewardedAdEntry;
    final closed = record;
    final leftover = closed?.resultCentavos ?? 0;
    final good = closed == null || leftover >= 0;

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
                  title: l10n.settlementTitle,
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 18),
                PixelCard(
                  elevation: PixelElevation.hero,
                  color: good ? AppColors.tealSoft : AppColors.cashSoft,
                  borderColor: good ? AppColors.tealInk : AppColors.cashInk,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        xpNoticeTitle(l10n, notice),
                        style: pixelText(size: 18, bold: true),
                      ),
                      if (closed != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          cycleDateRange(l10n, closed.start, closed.end),
                          style: pixelText(size: 13, color: AppColors.inkSoft),
                        ),
                        const SizedBox(height: 14),
                        _AmountLine(
                          label: l10n.settlementSpent,
                          value: formatMoney(currency, closed.spentCentavos),
                        ),
                        const SizedBox(height: 8),
                        _AmountLine(
                          label: leftover >= 0
                              ? l10n.settlementLeft
                              : l10n.settlementOver,
                          value: formatMoney(currency, leftover.abs()),
                          emphasize: true,
                          color: leftover >= 0
                              ? AppColors.tealInk
                              : AppColors.dangerInk,
                        ),
                        const SizedBox(height: 8),
                        _AmountLine(
                          label: l10n.settlementAverage,
                          value: switch (closed.averageSpentPerDayCentavos) {
                            final average? => formatMoney(currency, average),
                            null => l10n.cycleHistoryAveragePending,
                          },
                        ),
                      ],
                      if (notice.xp > 0) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.xpAmount(notice.xp),
                          style: pixelText(
                            size: 16,
                            bold: true,
                            color: AppColors.tealInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          xpNoticeDetail(l10n, notice),
                          style: pixelText(size: 13, color: AppColors.inkSoft),
                        ),
                      ],
                    ],
                  ),
                ),
                if (recommended != null) ...[
                  const SizedBox(height: 14),
                  PixelCard(
                    color: AppColors.paperLight,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CollectionScreen(
                          initialEntryId: recommended.id,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const _IconTile(
                          icon: Icons.auto_awesome,
                          color: AppColors.violet,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.settlementCtaTitle,
                                style: pixelText(size: 15, bold: true),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                catalogEntryDisplayName(l10n, recommended),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.settlementCtaAction,
                          style: pixelText(
                            size: 13,
                            bold: true,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: AppColors.ink),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                PixelButton(
                  label: l10n.settlementContinue,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountLine extends StatelessWidget {
  const _AmountLine({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.color,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: pixelText(size: 13, color: AppColors.inkSoft),
          ),
        ),
        Text(
          value,
          style: pixelText(
            size: emphasize ? 17 : 14,
            bold: true,
            color: color ?? AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: Icon(icon, color: color),
    );
  }
}
