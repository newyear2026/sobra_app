import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/expense_entry.dart';
import '../models/pay_schedule.dart';
import '../models/recurring_expense.dart';
import '../services/fixed_reminders.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_ui.dart';

/// Adds a fixed expense, or edits one when [existing] is given.
///
/// Pops with the saved [RecurringExpense], or with nothing when the user backs
/// out or deletes it.
class FixedExpenseFormScreen extends StatefulWidget {
  const FixedExpenseFormScreen({super.key, this.existing});

  final RecurringExpense? existing;

  @override
  State<FixedExpenseFormScreen> createState() => _FixedExpenseFormScreenState();
}

class _FixedExpenseFormScreenState extends State<FixedExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _name = TextEditingController();
  FixedFrequency _frequency = FixedFrequency.monthly;
  ExpenseCategory _category = ExpenseCategory.home;
  PaymentMethod _method = PaymentMethod.cash;
  bool _variable = false;
  FixedReminder _reminder = FixedFrequency.monthly.defaultReminder;

  /// Whether the user picked the reminder. Until then it follows the
  /// frequency's default, so choosing "Cada semana" quietly turns it off.
  bool _reminderChosen = false;
  DateTime? _nextDue;
  bool _saving = false;
  bool _started = false;

  RecurringExpense? get _existing => widget.existing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Here rather than in initState: the opening figures need the store's
    // currency and today, which live in an inherited widget.
    if (_started) return;
    _started = true;
    final store = SobraScope.of(context);
    final existing = _existing;
    if (existing == null) {
      _nextDue = store.today;
      return;
    }
    _amount.text = amountFieldText(store.currency, existing.amountCentavos);
    _name.text = existing.name;
    _frequency = existing.frequency ?? FixedFrequency.monthly;
    _category = existing.category;
    _method = existing.paymentMethod;
    _variable = existing.isVariable;
    _reminder = existing.reminder;
    _reminderChosen = true;
    _nextDue =
        store.nextUnpaidOccurrence(existing)?.date ??
        dateOnly(existing.anchorDate);
  }

  @override
  void dispose() {
    _amount.dispose();
    _name.dispose();
    super.dispose();
  }

  /// The schedule the form describes right now, for the preview and the save.
  ///
  /// Editing keeps the original anchor whenever the chosen date still lands
  /// on it. Re-anchoring on every save would drop this month's earlier dates
  /// — and the payments filed against them — out of the month's list.
  RecurringExpense _draft(int amountCentavos) {
    final nextDue = _nextDue!;
    final base =
        _existing ??
        RecurringExpense(
          id: '',
          name: '',
          amountCentavos: amountCentavos,
          category: _category,
          paymentMethod: _method,
          unit: _frequency.unit,
          interval: _frequency.interval,
          anchorDate: nextDue,
        );
    final sameSchedule =
        _existing != null &&
        _existing!.frequency == _frequency &&
        _existing!.isOccurrence(nextDue);
    return base.copyWith(
      name: _name.text.trim(),
      amountCentavos: amountCentavos,
      category: _category,
      paymentMethod: _method,
      unit: _frequency.unit,
      interval: _frequency.interval,
      anchorDate: sameSchedule ? base.anchorDate : nextDue,
      isVariable: _variable,
      reminder: _reminder,
    );
  }

  Future<void> _pickDate(SobraStore store) async {
    final today = store.today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDue ?? today,
      // A little of the past, for a bill that is already late when it is
      // first written down; up to two years ahead for anything yearly-ish.
      firstDate: DateTime(today.year, today.month - 2, today.day),
      lastDate: DateTime(today.year + 2, today.month, today.day),
    );
    if (picked != null && mounted) setState(() => _nextDue = dateOnly(picked));
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final store = SobraScope.of(context);
    final amount = parseAmount(store.currency, _amount.text);
    if (amount == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    RecurringExpense? saved;
    final ok = await guardStoreWrite(messenger, l10n, () async {
      final existing = _existing;
      if (existing == null) {
        saved = await store.addRecurringExpense(
          name: _name.text,
          amountCentavos: amount,
          category: _category,
          paymentMethod: _method,
          frequency: _frequency,
          firstDueDate: _nextDue!,
          isVariable: _variable,
          reminder: _reminder,
        );
      } else {
        saved = _draft(amount);
        await store.updateRecurringExpense(saved!);
      }
    });
    if (!mounted) return;
    // Asked when a reminder is actually wanted, not when the screen opens:
    // Android shows its prompt once or twice at most, and it should land
    // where the reason for it is obvious.
    if (ok &&
        _reminder != FixedReminder.none &&
        !await SobraFixedReminders.requestPermission()) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.fixedReminderBlocked)),
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) navigator.pop(saved);
  }

  Future<void> _delete() async {
    final existing = _existing!;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.fixedDeleteTitle(existing.name)),
        content: Text(l10n.fixedDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final store = SobraScope.of(context);
    final navigator = Navigator.of(context);
    final ok = await guardStoreWrite(
      ScaffoldMessenger.of(context),
      l10n,
      () => store.deleteRecurringExpense(existing.id),
    );
    if (ok && mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    final currency = store.currency;
    final textTheme = Theme.of(context).textTheme;
    final preview = _draft(1);
    final nextDue = _nextDue!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                children: [
                  PixelTopBar(
                    title: _existing == null
                        ? l10n.fixedFormNewTitle
                        : l10n.fixedFormEditTitle,
                    onBack: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 18),
                  Text(l10n.amount, style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amount,
                    keyboardType: amountKeyboardType(currency),
                    inputFormatters: amountInputFormattersFor(currency),
                    style: pixelText(size: 30, bold: true),
                    decoration: InputDecoration(
                      hintText: '${currency.symbol}0',
                      hintStyle: pixelText(
                        size: 30,
                        bold: true,
                        color: AppColors.muted,
                      ),
                      suffixText: currency.code,
                    ),
                    validator: (value) =>
                        parseAmount(currency, value ?? '') == null
                        ? l10n.registerAmountAboveZero
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.fixedName, style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(hintText: l10n.fixedNameHint),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? l10n.fixedNameRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.fixedHowOften, style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _FrequencyGrid(
                    selected: _frequency,
                    onChanged: (value) => setState(() {
                      _frequency = value;
                      if (!_reminderChosen) _reminder = value.defaultReminder;
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.fixedNextDue, style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  PixelCard(
                    elevation: PixelElevation.none,
                    onTap: () => _pickDate(store),
                    child: Row(
                      children: [
                        const Icon(Icons.event, color: AppColors.violet),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fullDate(l10n, nextDue),
                            style: pixelText(size: 15, bold: true),
                          ),
                        ),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.fixedThenDates(
                      _followingDates(l10n, preview, nextDue),
                    ),
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ExpenseCategory>(
                    initialValue: _category,
                    decoration: InputDecoration(labelText: l10n.category),
                    items: [
                      for (final category in ExpenseCategory.values)
                        DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                categoryIcon(category),
                                color: categoryColor(category),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(category.label(l10n)),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.registerPayment, style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  PixelSegmented<PaymentMethod>(
                    segments: [
                      PixelSegment(
                        value: PaymentMethod.cash,
                        label: PaymentMethod.cash.label(l10n),
                        icon: Icons.payments,
                      ),
                      PixelSegment(
                        value: PaymentMethod.card,
                        label: PaymentMethod.card.label(l10n),
                        icon: Icons.account_balance,
                      ),
                    ],
                    selected: _method,
                    onChanged: (value) => setState(() => _method = value),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.fixedVariable,
                              style: pixelText(size: 14, bold: true),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.fixedVariableHint,
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      PixelSwitch(
                        value: _variable,
                        semanticLabel: l10n.fixedVariable,
                        onChanged: (value) => setState(() => _variable = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<FixedReminder>(
                    // Keyed on the value: the field only reads its initial
                    // value once, and a frequency change can move it.
                    key: ValueKey(_reminder),
                    initialValue: _reminder,
                    decoration: InputDecoration(
                      labelText: l10n.fixedReminderLabel,
                      helperText: _reminder == FixedReminder.none
                          ? null
                          : l10n.fixedReminderHint,
                    ),
                    items: [
                      for (final option in FixedReminder.values)
                        DropdownMenuItem(
                          value: option,
                          child: Row(
                            children: [
                              Icon(
                                option == FixedReminder.none
                                    ? Icons.notifications_off_outlined
                                    : Icons.notifications_active_outlined,
                                size: 20,
                                color: AppColors.inkSoft,
                              ),
                              const SizedBox(width: 10),
                              Text(option.label(l10n)),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _reminder = value;
                        _reminderChosen = true;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  PixelHint(tone: PixelHintTone.teal, text: l10n.fixedFormNote),
                  const SizedBox(height: 22),
                  PixelButton(
                    label: _saving ? l10n.saving : l10n.fixedSave,
                    icon: Icons.save,
                    onPressed: _saving ? null : _save,
                  ),
                  if (_existing != null) ...[
                    const SizedBox(height: 8),
                    PixelButton(
                      label: l10n.fixedDelete,
                      icon: Icons.delete_outline,
                      variant: PixelButtonVariant.danger,
                      onPressed: _saving ? null : _delete,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The three due dates after [from], joined for the preview line.
String _followingDates(
  AppLocalizations l10n,
  RecurringExpense schedule,
  DateTime from,
) {
  final later = schedule
      .occurrencesBetween(
        from.add(const Duration(days: 1)),
        DateTime(from.year + 1, from.month, from.day),
      )
      .take(3);
  return later.map((date) => shortCycleDate(l10n, date)).join(', ');
}

/// The four frequencies as a two-by-two grid.
///
/// A single row cannot fit "Cada quincena" beside three others at a legible
/// size on a 360 px phone, and splitting it into two segmented controls would
/// read as two separate questions.
class _FrequencyGrid extends StatelessWidget {
  const _FrequencyGrid({required this.selected, required this.onChanged});

  final FixedFrequency selected;
  final ValueChanged<FixedFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget cell(FixedFrequency value, {required Border border}) {
      final on = value == selected;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: value.label(l10n),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(value),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: on ? AppColors.tealSoft : AppColors.surface,
                border: border,
              ),
              child: Text(
                value.label(l10n),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: pixelText(
                  size: 14,
                  bold: true,
                  color: on ? AppColors.tealInk : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      );
    }

    const line = BorderSide(color: AppColors.ink, width: 2.5);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              cell(FixedFrequency.weekly, border: const Border()),
              cell(
                FixedFrequency.semiMonthly,
                border: const Border(left: line),
              ),
            ],
          ),
          Row(
            children: [
              cell(FixedFrequency.monthly, border: const Border(top: line)),
              cell(
                FixedFrequency.bimonthly,
                border: const Border(top: line, left: line),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
