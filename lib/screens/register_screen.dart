import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/expense_entry.dart';
import '../models/income_entry.dart';
import '../models/pay_schedule.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/receipt_field.dart';

enum RegisterMode { expense, income }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onSaved,
    this.initialMode = RegisterMode.expense,
    this.focusAmountOnOpen = false,
  });

  final VoidCallback onSaved;
  final RegisterMode initialMode;
  final bool focusAmountOnOpen;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocusNode = FocusNode();
  late RegisterMode _mode;
  ExpenseCategory _category = ExpenseCategory.food;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  IncomeKind _incomeKind = IncomeKind.salary;
  IncomeAllocation _incomeAllocation = IncomeAllocation.cycle;
  DateTime? _date;
  String? _receiptFileName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    if (widget.focusAmountOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _amountFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate(SobraStore store) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date ?? store.today,
      firstDate: DateTime(store.today.year - 1),
      lastDate: store.today,
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  DateTime _occurredAt(SobraStore store) {
    final date = _date ?? store.today;
    if (dateOnly(date) == store.today) return store.currentMoment;
    return DateTime(date.year, date.month, date.day, 12);
  }

  Future<bool> _shouldUsePendingDifference(
    SobraStore store,
    int amountCentavos,
  ) async {
    final pending = store.latestPendingCashExpense;
    if (_mode != RegisterMode.expense ||
        _paymentMethod != PaymentMethod.cash ||
        pending == null ||
        pending.amountCentavos != amountCentavos) {
      return false;
    }
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        final currency = SobraScope.of(context).currency;
        return AlertDialog(
          title: Text(l10n.registerReconcileQuestion),
          content: Text(
            l10n.registerReconcileBody(
              formatMoney(currency, pending.amountCentavos),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.registerReconcileNo),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.registerReconcileYes),
            ),
          ],
        );
      },
    );
    return answer == true;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final store = SobraScope.of(context);
    final amount = parseAmount(store.currency, _amountController.text);
    if (amount == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final reducedMotion = reducedMotionOf(context);
    final usePending = await _shouldUsePendingDifference(store, amount);
    if (!mounted) return;
    setState(() => _saving = true);
    // Whatever happens, the button comes back. Leaving _saving true on a throw
    // disables Guardar for the rest of the session with no way to recover.
    final bool saved;
    try {
      saved = await guardStoreWrite(messenger, l10n, () {
        if (usePending) {
          return store.classifyPendingCashExpense(
            expenseId: store.latestPendingCashExpense!.id,
            category: _category,
            note: _noteController.text,
          );
        }
        if (_mode == RegisterMode.expense) {
          return store.addExpense(
            amountCentavos: amount,
            category: _category,
            note: _noteController.text,
            occurredAt: _occurredAt(store),
            paymentMethod: _paymentMethod,
            receiptFileName: _receiptFileName,
          );
        }
        return store.addIncome(
          amountCentavos: amount,
          kind: _incomeKind,
          note: _noteController.text,
          occurredAt: _occurredAt(store),
          destination: _paymentMethod,
          allocation: _incomeAllocation,
        );
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    // Nothing was written, and guardStoreWrite has already said so. Celebrating
    // and clearing the form here would throw the entry away twice over.
    if (!saved || !mounted) return;
    // The dialog closes itself on a timer. Awaiting a dialog that something
    // else has to pop deadlocks: the await only finishes once the route is
    // gone, so the line that pops it never runs.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _SavedDialog(
        motion: _mode == RegisterMode.expense
            ? CatMotion.walk
            : CatMotion.celebrate,
        message: usePending
            ? l10n.registerDifferenceReconciled
            : _mode == RegisterMode.expense
            ? l10n.registerExpenseSaved
            : l10n.registerIncomeSaved,
        animate: !reducedMotion,
        duration: reducedMotion
            ? const Duration(milliseconds: 400)
            : const Duration(milliseconds: 1100),
      ),
    );
    if (!mounted) return;
    _amountController.clear();
    _noteController.clear();
    setState(() {
      _category = ExpenseCategory.food;
      _date = null;
      // The photo belongs to the expense that just saved, not to the next one.
      _receiptFileName = null;
    });
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        key: const PageStorageKey('register-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PixelTopBar(title: l10n.registerTitle),
              const SizedBox(height: 14),
              PixelSegmented<RegisterMode>(
                segments: [
                  PixelSegment(
                    value: RegisterMode.expense,
                    label: l10n.registerExpense,
                    icon: Icons.remove_circle_outline,
                  ),
                  PixelSegment(
                    value: RegisterMode.income,
                    label: l10n.registerIncome,
                    icon: Icons.add_circle_outline,
                  ),
                ],
                selected: _mode,
                onChanged: (value) => setState(() => _mode = value),
              ),
              const SizedBox(height: 22),
              Text(l10n.amount, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                keyboardType: amountKeyboardType(store.currency),
                inputFormatters: amountInputFormattersFor(store.currency),
                style: pixelText(size: 34, bold: true),
                decoration: InputDecoration(
                  hintText: '${store.currency.symbol}0',
                  // The hint has to sit on the same baseline as the 34px
                  // value it stands in for, not on the 14px default.
                  hintStyle: pixelText(
                    size: 34,
                    bold: true,
                    color: AppColors.muted,
                  ),
                  suffixText: store.currency.code,
                ),
                validator: (value) =>
                    parseAmount(store.currency, value ?? '') == null
                    ? l10n.registerAmountAboveZero
                    : null,
              ),
              const SizedBox(height: 22),
              if (_mode == RegisterMode.expense)
                _ExpenseFields(
                  category: _category,
                  paymentMethod: _paymentMethod,
                  onCategoryChanged: (value) =>
                      setState(() => _category = value),
                  onPaymentChanged: (value) =>
                      setState(() => _paymentMethod = value),
                )
              else
                _IncomeFields(
                  kind: _incomeKind,
                  allocation: _incomeAllocation,
                  destination: _paymentMethod,
                  onKindChanged: (value) => setState(() => _incomeKind = value),
                  onAllocationChanged: (value) =>
                      setState(() => _incomeAllocation = value),
                  onDestinationChanged: (value) =>
                      setState(() => _paymentMethod = value),
                ),
              const SizedBox(height: 22),
              Text(l10n.note, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: _mode == RegisterMode.expense
                      ? l10n.registerNoteExpenseExample
                      : l10n.registerNoteIncomeExample,
                ),
              ),
              // Expenses only. An income has no ticket to photograph, and a
              // camera button on that tab would just be noise.
              if (_mode == RegisterMode.expense) ...[
                const SizedBox(height: 18),
                ReceiptField(
                  fileName: _receiptFileName,
                  onChanged: (value) =>
                      setState(() => _receiptFileName = value),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                l10n.registerDate,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              PixelCard(
                elevation: PixelElevation.none,
                onTap: () => _pickDate(store),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppColors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        fullDate(
                          AppLocalizations.of(context),
                          _date ?? store.today,
                        ),
                        style: pixelText(size: 15, bold: true),
                      ),
                    ),
                    const Icon(Icons.expand_more),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.registerNoFutureMovements,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              PixelButton(
                label: _saving ? l10n.saving : l10n.save,
                icon: Icons.save,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseFields extends StatelessWidget {
  const _ExpenseFields({
    required this.category,
    required this.paymentMethod,
    required this.onCategoryChanged,
    required this.onPaymentChanged,
  });
  final ExpenseCategory category;
  final PaymentMethod paymentMethod;
  final ValueChanged<ExpenseCategory> onCategoryChanged;
  final ValueChanged<PaymentMethod> onPaymentChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        AppLocalizations.of(context).category,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: .9,
        children: ExpenseCategory.values.map((item) {
          final selected = item == category;
          return Semantics(
            button: true,
            selected: selected,
            label: item.label(AppLocalizations.of(context)),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onCategoryChanged(item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  // Selection is always teal. Tinting the cell with its own
                  // category colour made "selected" mean ten different things.
                  color: selected ? AppColors.tealSoft : AppColors.surface,
                  border: Border.all(
                    color: selected ? AppColors.tealInk : AppColors.ink,
                    width: 2.5,
                  ),
                ),
                // Painted over the child instead of thickening the border, so
                // selecting a cell does not shift its contents by a pixel.
                foregroundDecoration: selected
                    ? BoxDecoration(
                        border: Border.all(
                          color: AppColors.tealInk,
                          width: 2.5,
                        ),
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      categoryIcon(item),
                      color: categoryColor(item),
                      size: 27,
                    ),
                    const SizedBox(height: 7),
                    FittedBox(
                      child: Text(
                        item.label(AppLocalizations.of(context)),
                        style: pixelText(
                          size: 12,
                          bold: true,
                          color: selected ? AppColors.tealInk : AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 22),
      Text(
        AppLocalizations.of(context).registerPayment,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      _PaymentSelector(value: paymentMethod, onChanged: onPaymentChanged),
      const SizedBox(height: 12),
      PixelHint(text: AppLocalizations.of(context).registerPaymentHint),
    ],
  );
}

class _IncomeFields extends StatelessWidget {
  const _IncomeFields({
    required this.kind,
    required this.allocation,
    required this.destination,
    required this.onKindChanged,
    required this.onAllocationChanged,
    required this.onDestinationChanged,
  });
  final IncomeKind kind;
  final IncomeAllocation allocation;
  final PaymentMethod destination;
  final ValueChanged<IncomeKind> onKindChanged;
  final ValueChanged<IncomeAllocation> onAllocationChanged;
  final ValueChanged<PaymentMethod> onDestinationChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        AppLocalizations.of(context).registerIncomeKind,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      for (final option in const [IncomeKind.salary, IncomeKind.extra]) ...[
        PixelCard(
          elevation: PixelElevation.none,
          color: kind == option ? AppColors.tealSoft : AppColors.surface,
          borderColor: kind == option ? AppColors.teal : AppColors.ink,
          onTap: () => onKindChanged(option),
          child: Row(
            children: [
              Icon(
                option == IncomeKind.salary
                    ? Icons.account_balance_wallet
                    : Icons.arrow_upward,
                color: AppColors.teal,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.label(AppLocalizations.of(context)),
                  style: pixelText(size: 15, bold: true),
                ),
              ),
              Icon(
                kind == option
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 12),
      Text(
        AppLocalizations.of(context).registerWhatToDo,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      PixelSegmented<IncomeAllocation>(
        segments: [
          PixelSegment(
            value: IncomeAllocation.cycle,
            label: AppLocalizations.of(context).registerThisCycle,
          ),
          PixelSegment(
            value: IncomeAllocation.savings,
            label: AppLocalizations.of(context).registerSaveIt,
          ),
        ],
        selected: allocation,
        onChanged: onAllocationChanged,
      ),
      const SizedBox(height: 18),
      Text(
        AppLocalizations.of(context).registerReceivedIn,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      _PaymentSelector(
        value: destination,
        onChanged: onDestinationChanged,
        accountLabel: AppLocalizations.of(context).registerAccount,
      ),
    ],
  );
}

class _PaymentSelector extends StatelessWidget {
  const _PaymentSelector({
    required this.value,
    required this.onChanged,
    this.accountLabel,
  });
  final PaymentMethod value;
  final ValueChanged<PaymentMethod> onChanged;
  final String? accountLabel;
  @override
  Widget build(BuildContext context) => PixelSegmented<PaymentMethod>(
    segments: [
      PixelSegment(
        value: PaymentMethod.cash,
        label: PaymentMethod.cash.label(AppLocalizations.of(context)),
        icon: Icons.payments,
      ),
      PixelSegment(
        value: PaymentMethod.card,
        label:
            accountLabel ??
            PaymentMethod.card.label(AppLocalizations.of(context)),
        icon: Icons.account_balance,
      ),
    ],
    selected: value,
    onChanged: onChanged,
  );
}

/// The "saved" confirmation, which dismisses itself.
///
/// It owns its own lifetime so the caller can simply await it: nothing outside
/// has to reach in and pop the right route at the right moment.
class _SavedDialog extends StatefulWidget {
  const _SavedDialog({
    required this.motion,
    required this.message,
    required this.animate,
    required this.duration,
  });

  final CatMotion motion;
  final String message;
  final bool animate;
  final Duration duration;

  @override
  State<_SavedDialog> createState() => _SavedDialogState();
}

class _SavedDialogState extends State<_SavedDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    // Let it finish; it is about to close on its own either way.
    canPop: false,
    child: Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.ink, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: CatSprite(
                motion: widget.motion,
                width: 142,
                loop: false,
                animate: widget.animate,
                reserveMotionSpace: true,
              ),
            ),
            const SizedBox(height: 12),
            Text(widget.message, style: pixelText(size: 18, bold: true)),
          ],
        ),
      ),
    ),
  );
}
