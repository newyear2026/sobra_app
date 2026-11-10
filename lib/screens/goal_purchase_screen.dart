import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/expense_entry.dart';
import '../models/savings_goal.dart';
import '../services/goal_product_import.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/goal_product_thumbnail.dart';
import '../widgets/pixel_ui.dart';
import 'goal_product_browser_screen.dart';
import 'savings_goal_screen.dart' show GoalProductLoader;

/// A recorded purchase, returned to the goal screen that opened this one.
///
/// The goal screen decides where to go next, because it is the route that
/// has to leave the stack: the goal it edits no longer exists.
class GoalPurchaseResult {
  const GoalPurchaseResult({this.nextGoalStartingCentavos});

  /// Set when the user chose to start a new goal with the money left over.
  final int? nextGoalStartingCentavos;
}

/// Records buying the thing the active goal saved for.
///
/// The expense stays out of today's money and the cycle budget, and the goal
/// moves to the history (see [SobraStore.recordSavingsGoalPurchase]). Only
/// saved money can be spent here; the store refuses anything above it.
class GoalPurchaseScreen extends StatefulWidget {
  const GoalPurchaseScreen({super.key, required this.goal, this.readPrice});

  final SavingsGoal goal;

  /// Reads the product page again. Tests pass a fake; the app opens the
  /// same in-app browser the goal was created with.
  final GoalProductLoader? readPrice;

  @override
  State<GoalPurchaseScreen> createState() => _GoalPurchaseScreenState();
}

class _GoalPurchaseScreenState extends State<GoalPurchaseScreen> {
  final _amount = TextEditingController();
  PaymentMethod _payment = PaymentMethod.card;
  bool _initialized = false;
  bool _saving = false;
  bool _reading = false;
  String? _error;
  String? _priceNote;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final store = SobraScope.of(context);
    final saved = store.savingsGoalProgressCentavos;
    // The list price when it fits; otherwise everything saved, which the
    // user lowers to what the till actually said.
    final suggested = widget.goal.targetCentavos <= saved
        ? widget.goal.targetCentavos
        : saved;
    _amount.text = amountFieldText(store.currency, suggested);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _readPrice() async {
    final url = safeGoalUrl(widget.goal.productUrl);
    if (url == null || _reading || _saving) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();
    setState(() => _reading = true);
    try {
      final result = await (widget.readPrice ?? openGoalProductBrowser)(
        context,
        url.toString(),
      );
      if (!mounted || result == null) return;
      final currency = SobraScope.of(context).currency;
      final price = result.priceCentavos;
      setState(() {
        _error = null;
        if (price == null) {
          _priceNote = l10n.goalPurchasePriceMissing;
        } else if (result.currencyCode != currency.code) {
          // Never relabel a price in another currency as the user's money.
          _priceNote = l10n.goalCurrencyMismatch(result.currencyCode ?? '?');
        } else {
          _amount.text = amountFieldText(currency, price);
          _priceNote = l10n.goalPurchasePriceRead(
            formatMoney(currency, price, showCode: false),
          );
        }
      });
    } on Object {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.goalBrowserLoadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  Future<void> _confirm({required bool startNext}) async {
    if (_saving || _reading) return;
    final store = SobraScope.of(context);
    final l10n = AppLocalizations.of(context);
    final saved = store.savingsGoalProgressCentavos;
    final amount = parseAmount(store.currency, _amount.text);
    if (amount == null || amount <= 0 || amount > saved) {
      setState(
        () => _error = l10n.goalPurchaseTooMuch(
          formatMoney(store.currency, saved, showCode: false),
        ),
      );
      return;
    }
    final left = saved - amount;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final recorded = await guardStoreWrite(
      messenger,
      l10n,
      () => store.recordSavingsGoalPurchase(
        goalId: widget.goal.id,
        amountCentavos: amount,
        paymentMethod: _payment,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!recorded) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.goalPurchaseRecorded(widget.goal.name))),
      );
    navigator.pop(
      GoalPurchaseResult(
        nextGoalStartingCentavos: startNext && left > 0 ? left : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    final currency = store.currency;
    String money(int value) => formatMoney(currency, value, showCode: false);
    final goal = widget.goal;
    final saved = store.savingsGoalProgressCentavos;
    final typed = parseAmount(currency, _amount.text) ?? 0;
    final left = saved - typed;
    final busy = _saving || _reading;
    final canReadPrice = safeGoalUrl(goal.productUrl) != null;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PixelTopBar(
                  title: l10n.goalPurchaseTitle,
                  onBack: () {
                    if (!_saving) Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (goal.kind == SavingsGoalKind.product) ...[
                      GoalProductThumbnail(url: goal.imageUrl, size: 56),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: pixelText(
                              size: 18,
                              bold: true,
                              color: AppColors.tealInk,
                            ),
                          ),
                          if (goal.merchantName case final merchant?) ...[
                            const SizedBox(height: 2),
                            Text(
                              merchant,
                              style: pixelText(
                                size: 13,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  key: const ValueKey('goal-purchase-amount'),
                  controller: _amount,
                  enabled: !busy,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [AmountInputFormatter(currency)],
                  decoration: InputDecoration(
                    labelText: l10n.goalPurchaseAmount,
                    prefixText: currency.symbol,
                    suffixText: currency.code,
                    helperText: l10n.goalPurchaseAmountHelper(money(saved)),
                    helperMaxLines: 2,
                  ),
                  onChanged: (_) => setState(() => _error = null),
                ),
                if (canReadPrice) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const ValueKey('goal-purchase-read-price'),
                      onPressed: busy ? null : _readPrice,
                      icon: _reading
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 18),
                      label: Text(l10n.goalPurchaseRefreshPrice),
                    ),
                  ),
                ],
                if (_priceNote case final note?)
                  Text(
                    note,
                    key: const ValueKey('goal-purchase-price-note'),
                    style: pixelText(size: 13, color: AppColors.muted),
                  ),
                const SizedBox(height: 18),
                Text(
                  l10n.registerPayment,
                  style: Theme.of(context).textTheme.titleMedium,
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
                  selected: _payment,
                  onChanged: (value) {
                    if (!busy) setState(() => _payment = value);
                  },
                ),
                const SizedBox(height: 8),
                PixelHint(text: l10n.registerPaymentHint),
                const SizedBox(height: 20),
                _SummaryRow(
                  label: l10n.goalPurchaseSaved,
                  amount: money(saved),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: l10n.goalPurchaseAmount,
                  amount: '-${money(typed)}',
                ),
                const Divider(height: 22),
                _SummaryRow(
                  key: const ValueKey('goal-purchase-left'),
                  label: l10n.goalPurchaseLeft,
                  amount: money(left < 0 ? 0 : left),
                  emphasize: true,
                ),
                const SizedBox(height: 16),
                PixelCard(
                  elevation: PixelElevation.none,
                  color: AppColors.tealSoft,
                  borderColor: AppColors.tealInk,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: AppColors.tealInk,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.goalPurchaseOutsideBudget,
                          style: pixelText(
                            size: 13,
                            color: AppColors.tealInk,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error case final error?) ...[
                  const SizedBox(height: 14),
                  Text(
                    error,
                    key: const ValueKey('goal-purchase-error'),
                    style: pixelText(size: 13, color: AppColors.dangerInk),
                  ),
                ],
                const SizedBox(height: 20),
                PixelButton(
                  key: const ValueKey('goal-purchase-confirm'),
                  label: l10n.goalPurchaseConfirm,
                  maxLines: 2,
                  onPressed: busy ? null : () => _confirm(startNext: false),
                ),
                if (left > 0 && typed > 0) ...[
                  const SizedBox(height: 12),
                  PixelButton(
                    key: const ValueKey('goal-purchase-confirm-next'),
                    label: l10n.goalPurchaseConfirmNext,
                    variant: PixelButtonVariant.secondary,
                    maxLines: 2,
                    onPressed: busy ? null : () => _confirm(startNext: true),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    super.key,
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  final String label;
  final String amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: pixelText(size: 14, bold: true))),
      const SizedBox(width: 12),
      Text(
        amount,
        style: pixelText(
          size: 16,
          bold: true,
          color: emphasize ? AppColors.tealInk : AppColors.ink,
        ),
      ),
    ],
  );
}
