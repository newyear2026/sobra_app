import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/currency.dart';
import '../models/expense_entry.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/fixed_expenses.dart';
import '../widgets/pixel_ui.dart';
import 'cycle_history_screen.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key, this.active = true});

  /// IndexedStack keeps this tab mounted while another tab is visible.
  final bool active;

  Future<bool?> _requestCategoryPolicy(BuildContext context) =>
      showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final l10n = AppLocalizations.of(dialogContext);
          return AlertDialog(
            title: Text(l10n.budgetChangedTitle),
            content: Text(l10n.budgetChangedBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.budgetKeepLimits),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.budgetScaleLimits),
              ),
            ],
          );
        },
      );

  Future<int?> _requestAmount(
    BuildContext context, {
    required String title,
    required int currentCentavos,
  }) => showDialog<int>(
    context: context,
    builder: (_) => _AmountDialog(
      title: title,
      currentCentavos: currentCentavos,
      currency: SobraScope.of(context).currency,
    ),
  );

  Future<void> _editTotalBudget(
    BuildContext context,
    SobraStore store,
    AppLocalizations l10n,
  ) async {
    final value = await _requestAmount(
      context,
      title: l10n.budgetTotal,
      currentCentavos: store.totalBudgetCentavos,
    );
    if (value != null && context.mounted) {
      if (value <= store.cycleBudgetExtrasCentavos) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.budgetTooLow(
                formatMoney(store.currency, store.cycleBudgetExtrasCentavos),
              ),
            ),
          ),
        );
        return;
      }
      final adjust = await _requestCategoryPolicy(context);
      if (adjust != null && context.mounted) {
        await guardStoreWrite(
          ScaffoldMessenger.of(context),
          l10n,
          () => store.setTotalBudget(value, adjustCategoryLimits: adjust),
        );
      }
    }
  }

  Widget _budgetPrompt(
    BuildContext context,
    SobraStore store,
    AppLocalizations l10n,
  ) => SafeArea(
    bottom: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PixelTopBar(title: l10n.budgetTitle),
          const SizedBox(height: 18),
          PixelEmptyState(
            icon: Icons.savings_outlined,
            title: l10n.budgetNotSetTitle,
            message: l10n.budgetNotSetBody,
          ),
          const SizedBox(height: 16),
          PixelButton(
            label: l10n.budgetSetAction,
            icon: Icons.add,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final value = await _requestAmount(
                context,
                title: l10n.budgetTotal,
                currentCentavos: 0,
              );
              if (value == null) return;
              await guardStoreWrite(
                messenger,
                l10n,
                // The limits still hold the stock split of the default
                // figure, and scaling that split reproduces it at whatever
                // the first real budget turns out to be.
                () => store.setTotalBudget(value, adjustCategoryLimits: true),
              );
            },
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    // Nothing on this screen survives a missing budget: the ring, the
    // projection and every category limit are shares of a number that was
    // never chosen. One prompt is the whole screen until it exists.
    if (!store.hasBudget) return _budgetPrompt(context, store, l10n);
    final currency = store.currency;
    final projectionPositive = store.projectedRemainderCentavos >= 0;
    final motionToken = Object.hashAll([
      store.totalBudgetCentavos,
      ...store.categoryLimits.values,
      store.totalSpentCentavos,
    ]);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        key: const PageStorageKey('budget-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PixelTopBar(title: l10n.budgetTitle),
            const SizedBox(height: 18),
            Text(
              l10n.budgetCycleTotal,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            PixelCard(
              elevation: PixelElevation.hero,
              onTap: () => _editTotalBudget(context, store, l10n),
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatMoney(currency, store.totalBudgetCentavos),
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ),
                  ),
                  const Icon(Icons.edit, color: AppColors.teal),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _CycleRingCard(store: store),
            // Only once there is a closed cycle to look back at: an empty
            // history says nothing the rest of this screen does not.
            if (store.cycleRecords.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CycleHistoryScreen(),
                  ),
                ),
                child: CycleHistorySummary(records: store.cycleRecords),
              ),
            ],
            const SizedBox(height: 24),
            FixedExpensesSection(
              onAdjustBudget: () => _editTotalBudget(context, store, l10n),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.budgetByCategory,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ...ExpenseCategory.values.map((category) {
              final spent = store.spentFor(category);
              final limit = store.categoryLimits[category] ?? 0;
              final progress = limit == 0 ? 0.0 : spent / limit;
              final over = progress > 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PixelCard(
                  elevation: PixelElevation.none,
                  onTap: () async {
                    final value = await _requestAmount(
                      context,
                      title: l10n.budgetCategoryLimit(category.label(l10n)),
                      currentCentavos: limit,
                    );
                    if (value != null && context.mounted) {
                      await guardStoreWrite(
                        ScaffoldMessenger.of(context),
                        l10n,
                        () => store.setCategoryLimit(category, value),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      CategoryIconBox(category: category),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          category.label(l10n),
                                          style: pixelText(
                                            size: 15,
                                            bold: true,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (spent > 0) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          l10n.budgetCategoryShare(
                                            _shareOfSpending(store, spent),
                                          ),
                                          style: pixelText(
                                            size: 12,
                                            bold: true,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  l10n.budgetSpentOfLimit(
                                    formatMoney(
                                      currency,
                                      spent,
                                      showCode: false,
                                    ),
                                    formatMoney(
                                      currency,
                                      limit,
                                      showCode: false,
                                    ),
                                  ),
                                  style: pixelText(
                                    size: 12,
                                    bold: true,
                                    color: over
                                        ? AppColors.dangerInk
                                        : AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            SegmentedProgress(value: progress, danger: over),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.edit, size: 16, color: AppColors.muted),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            PixelCard(
              color: AppColors.cashSoft,
              borderColor: AppColors.cashInk,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.budgetProjection,
                          style: pixelText(
                            size: 15,
                            bold: true,
                            color: AppColors.cashInk,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatMoney(
                              currency,
                              store.projectedRemainderCentavos,
                            ),
                            style: pixelText(
                              size: 28,
                              bold: true,
                              color: projectionPositive
                                  ? AppColors.tealInk
                                  : AppColors.dangerInk,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          projectionPositive
                              ? l10n.budgetEstimatedLeft
                              : l10n.homeAdjustCalmly,
                          style: pixelText(
                            size: 12,
                            color: AppColors.cashInk,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _BudgetCompanion(
                    characterId: store.characterId,
                    motionToken: motionToken,
                    active: active,
                    reducedMotion: reducedMotionOf(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Plays the saving reaction once, then keeps the companion quietly alive.
/// Leaving this tab pauses its ticker; returning is a new budget visit.
class _BudgetCompanion extends StatefulWidget {
  const _BudgetCompanion({
    required this.characterId,
    required this.motionToken,
    required this.active,
    required this.reducedMotion,
  });

  final String characterId;
  final int motionToken;
  final bool active;
  final bool reducedMotion;

  @override
  State<_BudgetCompanion> createState() => _BudgetCompanionState();
}

class _BudgetCompanionState extends State<_BudgetCompanion> {
  late bool _saving = widget.active && !widget.reducedMotion;

  @override
  void didUpdateWidget(covariant _BudgetCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active || widget.reducedMotion) {
      _saving = false;
    } else if (!oldWidget.active ||
        oldWidget.reducedMotion ||
        oldWidget.characterId != widget.characterId ||
        oldWidget.motionToken != widget.motionToken) {
      _saving = true;
    }
  }

  @override
  Widget build(BuildContext context) => CatSprite(
    characterId: widget.characterId,
    motion: _saving ? CatMotion.saving : CatMotion.idle,
    width: 128,
    loop: !_saving,
    playToken: widget.motionToken,
    animate: widget.active && !widget.reducedMotion,
    onComplete: _saving
        ? () {
            if (!mounted || !widget.active || widget.reducedMotion) return;
            setState(() => _saving = false);
          }
        : null,
  );
}

/// The amount prompt behind every "editar" on this screen.
///
/// The controller lives in a State rather than beside the `showDialog` call:
/// the dialog keeps building while its route animates out, so a controller
/// disposed the moment `showDialog` returns would be read after disposal and
/// take the frame — and the app — down with it.
class _AmountDialog extends StatefulWidget {
  const _AmountDialog({
    required this.title,
    required this.currentCentavos,
    required this.currency,
  });

  final String title;
  final int currentCentavos;

  /// Handed in rather than read from the scope, because the figure the field
  /// opens on is spelled in [initState], where an inherited widget is out of
  /// reach.
  final Currency currency;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: amountFieldText(widget.currency, widget.currentCentavos),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: amountKeyboardType(widget.currency),
        inputFormatters: amountInputFormattersFor(widget.currency),
        decoration: InputDecoration(suffixText: widget.currency.code),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            parseAmount(widget.currency, _controller.text),
          ),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// A category's share of everything spent this cycle, rounded for reading.
///
/// Floors at 1 for anything that was actually spent: a row showing a figure
/// beside "0%" reads as a bug rather than as a small number.
int _shareOfSpending(SobraStore store, int spent) {
  final total = store.totalSpentCentavos;
  if (total <= 0 || spent <= 0) return 0;
  final share = spent * 100 / total;
  return share < 1 ? 1 : share.round();
}

/// The whole cycle in one ring, with the figures it cannot draw beside it.
class _CycleRingCard extends StatelessWidget {
  const _CycleRingCard({required this.store});

  final SobraStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = store.currency;
    final budget = store.totalBudgetCentavos;
    final spent = store.totalSpentCentavos;
    final remaining = store.remainingBudgetCentavos;
    final percent = budget <= 0 ? 0 : (spent * 100 / budget).round();
    // Past a hundred the ring is full and has nothing left to say — and worse,
    // what it says depends on which categories the money went to. Overspend
    // mostly on Hogar and the full ring comes out teal, which is the colour
    // this app uses for going well. So the card carries the warning: a wash of
    // colour behind everything, rather than one small line of red text losing
    // an argument with a big teal circle.
    final over = remaining < 0;
    final ink = over ? AppColors.dangerInk : AppColors.ink;

    return PixelCard(
      elevation: PixelElevation.none,
      color: over ? AppColors.dangerSoft : AppColors.surface,
      borderColor: ink,
      child: Row(
        children: [
          CategoryRing(
            spentByCategory: {
              for (final category in ExpenseCategory.values)
                category: store.spentFor(category),
            },
            budgetCentavos: budget,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.budgetSpentShare(percent),
                  style: pixelText(size: 15, bold: true, color: ink),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.budgetRingSpent(formatMoney(currency, spent)),
                  style: pixelText(
                    size: 12,
                    color: over ? AppColors.dangerInk : AppColors.muted,
                  ),
                ),
                Text(
                  l10n.budgetRingLeft(formatMoney(currency, remaining)),
                  style: pixelText(
                    size: 12,
                    color: over ? AppColors.dangerInk : AppColors.muted,
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
