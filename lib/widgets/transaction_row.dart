import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/expense_entry.dart';
import '../models/money_movement.dart';
import '../state/sobra_store.dart';
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
    final l10n = AppLocalizations.of(context);
    final currency = SobraScope.of(context).currency;
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
                    expenseTitle(l10n, entry),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: pixelText(size: 14, bold: true),
                  ),
                  const SizedBox(height: 2),
                  _SubtitleLine(
                    // Same rule as a movement row: a headline that already
                    // says the category leaves the second line to the clock.
                    text: entry.note.trim().isEmpty
                        ? shortTime(entry.occurredAt)
                        : l10n.movementSubtitle(
                            entry.category.label(l10n),
                            shortTime(entry.occurredAt),
                          ),
                    style: Theme.of(context).textTheme.bodySmall,
                    hasReceipt: entry.hasReceipt,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$minusSign'
              '${formatMoney(currency, entry.amountCentavos, showCode: false)}',
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
    final l10n = AppLocalizations.of(context);
    final currency = SobraScope.of(context).currency;
    final positive = movement.amountCentavos >= 0;
    final isAdjustment = movement.type == MovementType.adjustment;
    // The icon can take the plain accent; the amount and subtitle beside it
    // need the darker `Ink` variant to stay legible on paper.
    final color = movement.isPending
        ? AppColors.cash
        : positive
        ? AppColors.teal
        : AppColors.ink;
    final textColor = movement.isPending || isAdjustment
        ? AppColors.cashInk
        : positive
        ? AppColors.tealInk
        : AppColors.ink;
    final tint = movement.isPending || isAdjustment
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
    final iconColor = expense != null
        ? categoryColor(expense.category)
        : isAdjustment
        ? AppColors.cashInk
        : color;
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
                    movementTitle(l10n, movement),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: pixelText(size: 14, bold: true),
                  ),
                  const SizedBox(height: 2),
                  _SubtitleLine(
                    text: movementSubtitle(l10n, movement),
                    style: pixelText(
                      size: 12,
                      bold: movement.isPending,
                      color: movement.isPending
                          ? AppColors.cashInk
                          : AppColors.muted,
                    ),
                    hasReceipt: expense?.hasReceipt ?? false,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              // An adjustment carries no sign. It records what a cash count
              // settled, and showing "+\$300" next to a budget that did not
              // move reads as money arriving when none did.
              '${isAdjustment
                  ? ''
                  : positive
                  ? '+'
                  : minusSign}'
              '${formatMoney(currency, movement.amountCentavos.abs(), showCode: false)}',
              style: pixelText(size: 15, bold: true, color: textColor),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// The row's second line, with a quiet marker when a photo is attached.
///
/// A glyph rather than the photo itself. At the size a list row can spare, a
/// receipt crop is unreadable — it only ever said "there is a photo" — while
/// costing the visual weight of the one photographic element in a pixel-art
/// list. The marker says the same thing in the row's own language, and adds no
/// width to a row that already runs tight on a 360 px phone. The photo opens
/// full size from the row's edit sheet.
class _SubtitleLine extends StatelessWidget {
  const _SubtitleLine({
    required this.text,
    required this.style,
    required this.hasReceipt,
  });

  final String text;
  final TextStyle? style;
  final bool hasReceipt;

  @override
  Widget build(BuildContext context) {
    final line = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
    if (!hasReceipt) return line;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Flexible, not Expanded: the line should keep its natural width so
        // the glyph sits against the text rather than across the row.
        Flexible(child: line),
        const SizedBox(width: 5),
        Semantics(
          label: AppLocalizations.of(context).receiptAttached,
          child: Icon(
            Icons.receipt_long,
            size: 14,
            color: style?.color ?? AppColors.muted,
          ),
        ),
      ],
    );
  }
}
