import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/expense_entry.dart';
import '../services/app_telemetry.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/starter_friend.dart';
import 'collection_screen.dart';

/// Where a first-expense prompt was answered from. Sent with
/// [TelemetryEvent.firstExpense].
enum FirstExpenseOrigin { onboarding, homeCard }

/// How a first-expense prompt ended. Sent with [TelemetryEvent.firstExpense].
enum FirstExpenseResult { saved, skipped, snoozed }

/// Opens the guided first expense, and resolves once it is closed.
Future<void> showFirstExpenseGuide(
  BuildContext context, {
  required FirstExpenseOrigin origin,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => FirstExpenseScreen(origin: origin)),
);

/// The first expense, asked one question at a time.
///
/// Half the people who finish onboarding never record anything, and the
/// register tab — every field at once, under a tab bar — is where they stop.
/// This asks for the amount alone, then what it was for, then shows what that
/// one record already did: today's figure moved, and the day counts towards
/// the starter waiting at the door.
///
/// The save goes through [SobraStore.addExpense] exactly as the register tab's
/// does, so XP, missions and recorded days treat it as any other expense.
class FirstExpenseScreen extends StatefulWidget {
  const FirstExpenseScreen({super.key, required this.origin});

  final FirstExpenseOrigin origin;

  @override
  State<FirstExpenseScreen> createState() => _FirstExpenseScreenState();
}

enum _Step { amount, details, done }

/// The categories offered here. The register tab keeps the full grid; a first
/// record only needs the few most people reach for, with "other" for the rest.
const _quickCategories = [
  ExpenseCategory.food,
  ExpenseCategory.transport,
  ExpenseCategory.shopping,
  ExpenseCategory.other,
];

class _FirstExpenseScreenState extends State<FirstExpenseScreen> {
  final _amountController = TextEditingController();
  final _amountFocus = FocusNode();
  _Step _step = _Step.amount;
  ExpenseCategory _category = ExpenseCategory.food;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  int? _amountCentavos;
  ExpenseEntry? _saved;
  bool _saving = false;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final amount = parseAmount(
      SobraScope.of(context).currency,
      _amountController.text,
    );
    if (amount != _amountCentavos) setState(() => _amountCentavos = amount);
  }

  void _report(FirstExpenseResult result) {
    if (_reported) return;
    _reported = true;
    unawaited(
      AppTelemetry.instance.event(TelemetryEvent.firstExpense, {
        'origin': widget.origin,
        'result': result,
      }),
    );
  }

  void _skip() {
    _report(FirstExpenseResult.skipped);
    Navigator.of(context).pop();
  }

  void _toDetails() {
    if (_amountCentavos == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _step = _Step.details);
  }

  void _toAmount() {
    setState(() => _step = _Step.amount);
    _amountFocus.requestFocus();
  }

  Future<void> _save() async {
    final amount = _amountCentavos;
    if (_saving || amount == null) return;
    final store = SobraScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    ExpenseEntry? entry;
    final bool saved;
    try {
      saved = await guardStoreWrite(messenger, l10n, () async {
        entry = await store.addExpense(
          amountCentavos: amount,
          category: _category,
          note: '',
          occurredAt: store.currentMoment,
          paymentMethod: _paymentMethod,
        );
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!saved) return;
    unawaited(AppTelemetry.instance.event(TelemetryEvent.expenseRecorded));
    _report(FirstExpenseResult.saved);
    if (!mounted) return;
    setState(() {
      _saved = entry;
      _step = _Step.done;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back from the details goes back to the amount; back from the amount
      // is the same answer as "Aún no he gastado".
      canPop: _step == _Step.done,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        switch (_step) {
          case _Step.details:
            _toAmount();
          case _Step.amount:
            _skip();
          case _Step.done:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: AppColors.surface),
              child: SafeArea(
                child: switch (_step) {
                  _Step.amount => _AmountStep(
                    controller: _amountController,
                    focusNode: _amountFocus,
                    canContinue: _amountCentavos != null,
                    onContinue: _toDetails,
                    onSkip: _skip,
                  ),
                  _Step.details => _DetailsStep(
                    amountCentavos: _amountCentavos!,
                    category: _category,
                    paymentMethod: _paymentMethod,
                    saving: _saving,
                    onEditAmount: _toAmount,
                    onCategoryChanged: (value) =>
                        setState(() => _category = value),
                    onPaymentChanged: (value) =>
                        setState(() => _paymentMethod = value),
                    onSave: _save,
                  ),
                  _Step.done => _DoneStep(
                    entry: _saved,
                    onGoHome: () => Navigator.of(context).pop(),
                  ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountStep extends StatelessWidget {
  const _AmountStep({
    required this.controller,
    required this.focusNode,
    required this.canContinue,
    required this.onContinue,
    required this.onSkip,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canContinue;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    return _StepFrame(
      header: const _StepHeader(step: 1),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PixelButton(
            label: l10n.continueLabel,
            onPressed: canContinue ? onContinue : null,
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: onSkip,
            child: Text(
              l10n.firstExpenseNotYet,
              style: pixelText(
                size: 14,
                bold: true,
                color: AppColors.tealInk,
              ).copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CharacterSays(
            role: CharacterMotionRole.idle,
            title: l10n.firstExpenseAmountQuestion,
            body: l10n.firstExpenseAmountHint,
          ),
          const SizedBox(height: 22),
          TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: amountKeyboardType(store.currency),
            inputFormatters: amountInputFormattersFor(store.currency),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => onContinue(),
            style: pixelText(size: 34, bold: true),
            decoration: InputDecoration(
              hintText: '${store.currency.symbol}0',
              hintStyle: pixelText(
                size: 34,
                bold: true,
                color: AppColors.muted,
              ),
              suffixText: store.currency.code,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.firstExpenseAmountLater,
            textAlign: TextAlign.center,
            style: pixelText(size: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.amountCentavos,
    required this.category,
    required this.paymentMethod,
    required this.saving,
    required this.onEditAmount,
    required this.onCategoryChanged,
    required this.onPaymentChanged,
    required this.onSave,
  });

  final int amountCentavos;
  final ExpenseCategory category;
  final PaymentMethod paymentMethod;
  final bool saving;
  final VoidCallback onEditAmount;
  final ValueChanged<ExpenseCategory> onCategoryChanged;
  final ValueChanged<PaymentMethod> onPaymentChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    return _StepFrame(
      header: _StepHeader(step: 2, onBack: onEditAmount),
      bottom: PixelButton(
        label: saving ? l10n.saving : l10n.firstExpenseSave,
        onPressed: saving ? null : onSave,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PixelCard(
            elevation: PixelElevation.none,
            color: AppColors.tealSoft,
            borderColor: AppColors.tealInk,
            onTap: onEditAmount,
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatMoney(store.currency, amountCentavos),
                      style: pixelText(
                        size: 26,
                        bold: true,
                        color: AppColors.tealInk,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.edit,
                  style: pixelText(
                    size: 13,
                    bold: true,
                    color: AppColors.tealInk,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CharacterSays(
            role: CharacterMotionRole.positive,
            title: l10n.firstExpenseWhatQuestion,
          ),
          const SizedBox(height: 18),
          Text(l10n.category, style: pixelText(size: 14, bold: true)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final item in _quickCategories) ...[
                if (item != _quickCategories.first) const SizedBox(width: 8),
                Expanded(
                  child: _CategoryChoice(
                    category: item,
                    selected: item == category,
                    onTap: () => onCategoryChanged(item),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Text(
            l10n.firstExpensePaymentQuestion,
            style: pixelText(size: 14, bold: true),
          ),
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
            selected: paymentMethod,
            onChanged: onPaymentChanged,
          ),
        ],
      ),
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.entry, required this.onGoHome});

  /// Null only if the save reported success without handing an entry back.
  final ExpenseEntry? entry;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    final saved = entry;
    final waiting = store.waitingStarter;
    return _StepFrame(
      header: const _StepHeader(step: null),
      bottom: PixelButton(label: l10n.onboardingGoHome, onPressed: onGoHome),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CharacterSays(
            role: CharacterMotionRole.success,
            title: l10n.firstExpenseDoneTitle,
            body: l10n.firstExpenseDoneBody,
          ),
          if (saved != null) ...[
            const SizedBox(height: 18),
            Text(
              l10n.firstExpenseRecordTitle,
              textAlign: TextAlign.center,
              style: pixelText(size: 16, bold: true),
            ),
            const SizedBox(height: 8),
            PixelCard(
              elevation: PixelElevation.none,
              color: AppColors.tealSoft,
              borderColor: AppColors.tealInk,
              child: Row(
                children: [
                  CategoryIconBox(category: saved.category, size: 38),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          saved.category.label(l10n),
                          style: pixelText(size: 14, bold: true),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.movementSubtitle(
                            saved.paymentMethod.label(l10n),
                            l10n.today,
                          ),
                          style: pixelText(size: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatMoney(
                      store.currency,
                      saved.amountCentavos,
                      showCode: false,
                    ),
                    style: pixelText(
                      size: 16,
                      bold: true,
                      color: AppColors.tealInk,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Without a budget there is no figure for the record to move, and
          // Inicio's own card already asks for one.
          if (store.hasBudget) ...[
            const SizedBox(height: 18),
            Text(
              l10n.homeTodayLeft,
              textAlign: TextAlign.center,
              style: pixelText(size: 14, bold: true),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatMoney(store.currency, store.todayRemainingCentavos),
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 40,
                  fontVariations: AppType.bold,
                ),
              ),
            ),
          ],
          // The record that just saved is the first of the days that bring
          // the other starter over, so this is where that is worth saying.
          if (waiting != null) ...[
            const SizedBox(height: 16),
            Text(
              l10n.firstExpenseStarterNote(
                CharacterCatalog.resolve(waiting.id).displayName,
              ),
              textAlign: TextAlign.center,
              style: pixelText(size: 13, bold: true, height: 1.45),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.ink, width: 2.5),
              ),
              child: StarterWaitingRow(
                characterId: waiting.id,
                recordedDays: store.recordedDayCount,
                recordedToday: store.recordedToday,
                adProgress: store.rewardedAdProgressFor(waiting.id),
                adTarget: waiting.rewardedAdTarget!,
                onCallWithAds: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CollectionScreen(
                      origin: CollectionOrigin.firstExpense,
                      initialEntryId: waiting.id,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The companion and what it asks, side by side.
class _CharacterSays extends StatelessWidget {
  const _CharacterSays({required this.role, required this.title, this.body});

  final CharacterMotionRole role;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    final text = body;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CharacterSprite(
          characterId: CharacterCatalog.resolve(store.characterId).id,
          role: role,
          width: 104,
          animate: !reducedMotionOf(context),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PixelCard(
            elevation: PixelElevation.none,
            color: AppColors.cashSoft,
            borderColor: AppColors.cashInk,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: pixelText(size: 17, bold: true)),
                if (text != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    text,
                    style: pixelText(
                      size: 13,
                      color: AppColors.cashInk,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ExpenseCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: category.label(l10n),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            // Teal for selected, as in the register tab's grid.
            color: selected ? AppColors.tealSoft : AppColors.surface,
            border: Border.all(
              color: selected ? AppColors.tealInk : AppColors.ink,
              width: 2.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                categoryIcon(category),
                color: categoryColor(category),
                size: 27,
              ),
              const SizedBox(height: 6),
              FittedBox(
                child: Text(
                  category.label(l10n),
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
  }
}

/// Two steps and a finish, so the progress is a short track rather than the
/// onboarding's "x de y" header.
class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, this.onBack});

  /// 1 or 2, or null once the expense is saved.
  final int? step;
  final VoidCallback? onBack;

  static const _total = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = step;
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (onBack != null)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Track(filled: current ?? _total, done: current == null),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    current == null
                        ? l10n.firstExpenseDoneStep
                        : l10n.firstExpenseStepOf(current, _total),
                    style: pixelText(size: 13, bold: true),
                  ),
                  if (current == null) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check, size: 16, color: AppColors.teal),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.filled, required this.done});

  final int filled;
  final bool done;

  @override
  Widget build(BuildContext context) {
    Widget dot(bool on) => Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: on ? AppColors.teal : AppColors.surface,
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: done && on
          ? const Icon(Icons.check, size: 10, color: Colors.white)
          : null,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot(filled >= 1),
        Container(width: 54, height: 3, color: AppColors.ink),
        dot(filled >= 2),
      ],
    );
  }
}

class _StepFrame extends StatelessWidget {
  const _StepFrame({
    required this.header,
    required this.child,
    required this.bottom,
  });

  final Widget header;
  final Widget child;
  final Widget bottom;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 10),
        Expanded(child: SingleChildScrollView(child: child)),
        const SizedBox(height: 14),
        bottom,
      ],
    ),
  );
}
