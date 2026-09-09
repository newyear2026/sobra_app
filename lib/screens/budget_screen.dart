import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/expense_entry.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/pixel_ui.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

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
    builder: (_) =>
        _AmountDialog(title: title, currentCentavos: currentCentavos),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
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
              onTap: () async {
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
                            formatMoney(
                              currency,
                              store.cycleBudgetExtrasCentavos,
                            ),
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
                      () => store.setTotalBudget(
                        value,
                        adjustCategoryLimits: adjust,
                      ),
                    );
                  }
                }
              },
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
                                  child: Text(
                                    category.label(l10n),
                                    style: pixelText(size: 15, bold: true),
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
                  CatSprite(
                    motion: CatMotion.saving,
                    width: 128,
                    loop: false,
                    playToken: motionToken,
                    animate: !reducedMotionOf(context),
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

/// The amount prompt behind every "editar" on this screen.
///
/// The controller lives in a State rather than beside the `showDialog` call:
/// the dialog keeps building while its route animates out, so a controller
/// disposed the moment `showDialog` returns would be read after disposal and
/// take the frame — and the app — down with it.
class _AmountDialog extends StatefulWidget {
  const _AmountDialog({required this.title, required this.currentCentavos});

  final String title;
  final int currentCentavos;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: (widget.currentCentavos / 100).toStringAsFixed(0),
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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          suffixText: SobraScope.of(context).currency.code,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, parseAmount(_controller.text)),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
