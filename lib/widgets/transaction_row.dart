import 'package:flutter/material.dart';

import '../models/expense_entry.dart';
import '../models/money_movement.dart';
import '../theme/app_theme.dart';
import 'pixel_ui.dart';

class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.entry,
    this.onTap,
    this.trailing,
  });

  final ExpenseEntry entry;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            CategoryIconBox(category: entry.category),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: pixelText(size: 14, bold: true),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.category.label} · ${shortTime(entry.occurredAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$minusSign'
              '${formatMoney(entry.amountCentavos, currency: false)}',
              style: pixelText(size: 15, bold: true),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class MovementRow extends StatelessWidget {
  const MovementRow({
    super.key,
    required this.movement,
    this.onTap,
    this.trailing,
  });

  final MoneyMovement movement;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final positive = movement.amountCentavos >= 0;
    // The icon can take the plain accent; the amount and subtitle beside it
    // need the darker `Ink` variant to stay legible on paper.
    final color = movement.isPending
        ? AppColors.cash
        : positive
        ? AppColors.teal
        : AppColors.ink;
    final textColor = movement.isPending
        ? AppColors.cashInk
        : positive
        ? AppColors.tealInk
        : AppColors.ink;
    final tint = movement.isPending
        ? AppColors.cashSoft
        : positive
        ? AppColors.tealSoft
        : AppColors.beige;
    // An expense shows its category, the way the same row does on Inicio.
    // One generic bag for every expense made the list unscannable.
    final expense = movement.isPending ? null : movement.expense;
    final icon = expense != null
        ? categoryIcon(expense.category)
        : switch (movement.type) {
            MovementType.expense => Icons.help_outline,
            MovementType.income => Icons.arrow_upward,
            MovementType.adjustment => Icons.sync_alt,
          };
    final iconColor = expense != null ? categoryColor(expense.category) : color;
    final iconTint = expense != null
        ? categorySoftColor(expense.category)
        : tint;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconTint,
                border: Border.all(color: AppColors.ink, width: 2.5),
              ),
              child: Icon(icon, color: iconColor, size: 23),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movement.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: pixelText(size: 14, bold: true),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    movement.subtitle,
                    style: pixelText(
                      size: 12,
                      bold: movement.isPending,
                      color: movement.isPending
                          ? AppColors.cashInk
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${positive ? '+' : minusSign}'
              '${formatMoney(movement.amountCentavos.abs(), currency: false)}',
              style: pixelText(size: 15, bold: true, color: textColor),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
