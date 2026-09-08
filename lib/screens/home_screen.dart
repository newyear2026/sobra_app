import 'package:flutter/material.dart';

import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/gamification_ui.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/transaction_row.dart';
import 'app_shell.dart';
import 'cash_count_screen.dart';
import 'xp_history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    final shell = AppShellScope.of(context);
    final recent = store.movements.take(3).toList();
    // Over budget the headline stops being about today and reports the
    // cycle's own deficit, so the label and the colour follow it.
    final overCycleBudget = store.remainingBudgetCentavos < 0;
    // The cat still reacts to the day itself: the headline now floors at
    // zero, so it can no longer tell a spent day from an untouched one.
    final onTrack =
        !overCycleBudget &&
        store.spentTodayCentavos <= store.dailyAllowanceCentavos;
    final xp = store.xpProgress;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: const PageStorageKey('home-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            sliver: SliverList.list(
              children: [
                PixelTopBar(
                  title: 'Sobra',
                  trailing: IconButton(
                    tooltip: 'Ajustes',
                    onPressed: () => shell.select(AppTab.settings),
                    icon: const Icon(Icons.settings, size: 28),
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  overCycleBudget ? 'Saldo del ciclo' : 'Hoy te queda',
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatMoney(store.todayRemainingCentavos),
                    style: textTheme.displayLarge?.copyWith(
                      color: overCycleBudget
                          ? AppColors.dangerInk
                          : AppColors.teal,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Whichever figure the headline carries, the other one goes
                // right under it: a zero day is only readable next to the
                // limit it ran out of, and a deficit next to the budget it
                // came from.
                Text(
                  overCycleBudget
                      ? 'Te pasaste del presupuesto de '
                            '${formatMoney(store.totalBudgetCentavos, currency: false)}'
                            ' de este ciclo'
                      : 'Límite de hoy '
                            '${formatMoney(store.dailyAllowanceCentavos, currency: false)}'
                            ' · Quedan '
                            '${formatMoney(store.remainingBudgetCentavos, currency: false)}'
                            ' en el ciclo',
                  style: textTheme.bodySmall?.copyWith(
                    color: overCycleBudget
                        ? AppColors.dangerInk
                        : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 18),
                LevelStrip(
                  level: xp.level,
                  title: xp.title,
                  subtitle: '${xp.totalXp} XP totales',
                  currentXp: xp.currentLevelXp,
                  targetXp: xp.targetLevelXp,
                  trailingLabel: xp.isMaxLevel
                      ? 'Nivel máximo'
                      : 'Faltan ${xp.remainingXp} XP',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const XpHistoryScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Avance del ciclo', style: textTheme.titleSmall),
                    Text(
                      '${store.daysRemaining} días',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedProgress(
                  value: store.budgetProgress,
                  danger: store.budgetProgress > 1,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _BudgetFigure(
                        label: 'Presupuesto',
                        value: formatMoney(
                          store.totalBudgetCentavos,
                          currency: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BudgetFigure(
                        label: 'Gastado',
                        value: formatMoney(
                          store.totalSpentCentavos,
                          currency: false,
                        ),
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                PixelCard(
                  // The one card on the screen that leads somewhere else, so
                  // it takes the single hero depth step.
                  elevation: PixelElevation.hero,
                  color: AppColors.cashSoft,
                  borderColor: AppColors.cashInk,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CashCountScreen(),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.cashInk,
                        size: 34,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.hasCashBaseline
                                  ? 'Efectivo estimado'
                                  : 'Efectivo sin configurar',
                              style: pixelText(
                                size: 13,
                                bold: true,
                                color: AppColors.cashInk,
                              ),
                            ),
                            if (store.hasCashBaseline) ...[
                              Text(
                                formatMoney(store.expectedCashCentavos),
                                style: pixelText(
                                  size: 23,
                                  bold: true,
                                  color: AppColors.cashInk,
                                ),
                              ),
                              Text(
                                'Último conteo: '
                                '${formatMoney(store.countedCashCentavos, currency: false)}',
                                style: pixelText(
                                  size: 12,
                                  color: AppColors.cashInk,
                                ),
                              ),
                            ] else
                              Text(
                                'Haz un primer conteo para empezar.',
                                style: pixelText(
                                  size: 12,
                                  color: AppColors.cashInk,
                                  height: 1.45,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.cashInk),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Movimientos recientes',
                        style: textTheme.titleMedium,
                      ),
                    ),
                    if (recent.isNotEmpty)
                      TextButton(
                        onPressed: () => shell.select(AppTab.movements),
                        child: const Text('Ver todos'),
                      ),
                  ],
                ),
                if (recent.isEmpty) ...[
                  const SizedBox(height: 6),
                  const PixelEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Aún no hay movimientos',
                    message:
                        'Registra tu primer gasto y aquí verás el resumen '
                        'del ciclo.',
                  ),
                ] else
                  ...recent.map((entry) => MovementRow(movement: entry)),
                const SizedBox(height: 16),
                PixelCard(
                  color: AppColors.beige,
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 22),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(
                              color: AppColors.ink,
                              width: 2.5,
                            ),
                          ),
                          child: Text(
                            onTrack ? 'Vas muy bien' : 'Ajustemos con calma',
                            style: pixelText(size: 14, bold: true),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CatSprite(
                        motion: overCycleBudget
                            ? CatMotion.concern
                            : CatMotion.idle,
                        width: 106,
                        animate: !reducedMotionOf(context),
                        loop: !overCycleBudget,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One half of the budget line under the progress bar.
///
/// The label stays quiet and the number takes the ink, so the pair reads at a
/// glance without either half dropping under the minimum legible size.
class _BudgetFigure extends StatelessWidget {
  const _BudgetFigure({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: pixelText(size: 12, color: AppColors.muted),
          ),
          TextSpan(text: value, style: pixelText(size: 12, bold: true)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
    );
  }
}
