import 'package:flutter/material.dart';

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
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cambiaste tu presupuesto'),
          content: const Text('¿Qué hacemos con los límites por categoría?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Conservarlos'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ajustarlos proporcionalmente'),
            ),
          ],
        ),
      );

  Future<int?> _requestAmount(
    BuildContext context, {
    required String title,
    required int currentCentavos,
  }) async {
    final controller = TextEditingController(
      text: (currentCentavos / 100).toStringAsFixed(0),
    );
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'MXN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, parsePesos(controller.text)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
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
            const PixelTopBar(title: 'Presupuesto'),
            const SizedBox(height: 18),
            Text(
              'Total del ciclo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            PixelCard(
              elevation: PixelElevation.hero,
              onTap: () async {
                final value = await _requestAmount(
                  context,
                  title: 'Presupuesto total',
                  currentCentavos: store.totalBudgetCentavos,
                );
                if (value != null && context.mounted) {
                  final adjust = await _requestCategoryPolicy(context);
                  if (adjust != null) {
                    await store.setTotalBudget(
                      value,
                      adjustCategoryLimits: adjust,
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
                        formatMoney(store.totalBudgetCentavos),
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
              'Presupuesto por categoría',
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
                      title: 'Límite de ${category.label}',
                      currentCentavos: limit,
                    );
                    if (value != null) {
                      await store.setCategoryLimit(category, value);
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
                                    category.label,
                                    style: pixelText(size: 15, bold: true),
                                  ),
                                ),
                                Text(
                                  '${formatMoney(spent, currency: false)} / '
                                  '${formatMoney(limit, currency: false)}',
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
                          'Proyección al cierre',
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
                            formatMoney(store.projectedRemainderCentavos),
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
                              ? 'Estimado que te quedará'
                              : 'Ajusta una categoría con calma',
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
