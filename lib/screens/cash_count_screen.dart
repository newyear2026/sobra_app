import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/cash_reconciliation.dart';
import '../models/expense_entry.dart';
import '../models/income_entry.dart';
import '../models/xp_event.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/gamification_ui.dart';
import '../widgets/pixel_ui.dart';

class CashCountScreen extends StatefulWidget {
  const CashCountScreen({super.key});

  @override
  State<CashCountScreen> createState() => _CashCountScreenState();
}

class _CashCountScreenState extends State<CashCountScreen> {
  final _controller = TextEditingController();
  final _noteController = TextEditingController();
  CashResolution? _resolution;
  ExpenseCategory _category = ExpenseCategory.food;
  IncomeAllocation _incomeAllocation = IncomeAllocation.savings;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? get _actual => parseNonNegativeAmount(_controller.text);

  Future<void> _confirm(SobraStore store) async {
    final actual = _actual;
    if (actual == null || _saving) return;
    final difference = store.hasCashBaseline
        ? actual - store.expectedCashCentavos
        : 0;
    final resolution = difference == 0
        ? CashResolution.correction
        : _resolution;
    if (resolution == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).cashCountPickWhatHappened),
        ),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    XpNotice? xpNotice;
    final bool saved;
    try {
      saved = await guardStoreWrite(messenger, l10n, () async {
        await store.reconcileCashCount(
          actualCentavos: actual,
          resolution: resolution,
          category: _category,
          note: _noteController.text,
          incomeAllocation: _incomeAllocation,
        );
        xpNotice = store.takePendingXpNotice();
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    // The count screen stays put on a failure. Popping back to Inicio would
    // show the old estimate as though the recount had been accepted.
    if (!saved || !mounted) return;
    Navigator.pop(context);
    final notice = xpNotice;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        notice == null
            ? SnackBar(content: Text(l10n.cashCountSavedWithoutDuplicates))
            : xpSnackBar(notice),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    final currency = store.currency;
    final actual = _actual;
    final difference = actual == null || !store.hasCashBaseline
        ? null
        : actual - store.expectedCashCentavos;
    final isMissing = difference != null && difference < 0;
    final resultColor = isMissing ? AppColors.cashInk : AppColors.tealInk;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              children: [
                PixelTopBar(
                  title: l10n.cashCountTitle,
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 12),
                Text(
                  store.hasCashBaseline
                      ? l10n.cashCountPrompt
                      : l10n.cashCountNoneYet,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  onChanged: (_) => setState(() => _resolution = null),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: pixelText(size: 38, bold: true, color: AppColors.teal),
                  decoration: InputDecoration(
                    prefixText: currency.symbol,
                    hintText: '—',
                    suffixText: currency.code,
                  ),
                ),
                const SizedBox(height: 18),
                if (actual == null)
                  PixelCard(
                    elevation: PixelElevation.none,
                    color: AppColors.cashSoft,
                    borderColor: AppColors.cashInk,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.cashInk,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.cashCountResultPending,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.cashInk,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (!store.hasCashBaseline)
                  PixelCard(
                    elevation: PixelElevation.none,
                    color: AppColors.tealSoft,
                    borderColor: AppColors.tealInk,
                    child: Text(
                      l10n.cashCountBaselineHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.tealInk,
                        height: 1.45,
                      ),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _AmountCard(
                          label: l10n.cashCountExpected,
                          value: store.expectedCashCentavos,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AmountCard(
                          label: l10n.cashCountCounted,
                          value: actual,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  PixelCard(
                    elevation: PixelElevation.hero,
                    color: isMissing ? AppColors.cashSoft : AppColors.tealSoft,
                    borderColor: resultColor,
                    child: Text(
                      difference == 0
                          ? l10n.cashCountBalanced
                          : isMissing
                          ? l10n.cashCountShort(
                              formatMoney(currency, difference.abs()),
                            )
                          : l10n.cashCountExtra(
                              formatMoney(currency, difference!.abs()),
                            ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: resultColor,
                        fontSize: 23,
                        fontVariations: AppType.bold,
                      ),
                    ),
                  ),
                  if (difference != 0) ...[
                    const SizedBox(height: 22),
                    Text(
                      l10n.cashCountWhatHappened,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    for (final option
                        in isMissing
                            ? const [
                                CashResolution.expense,
                                CashResolution.transfer,
                                CashResolution.correction,
                                CashResolution.pending,
                              ]
                            : const [
                                CashResolution.income,
                                CashResolution.transfer,
                                CashResolution.correction,
                                CashResolution.pending,
                              ]) ...[
                      _ResolutionCard(
                        label: option.label(l10n),
                        helper: switch (option) {
                          CashResolution.expense => l10n.cashCountHelperExpense,
                          CashResolution.income => l10n.cashCountHelperIncome,
                          CashResolution.transfer =>
                            isMissing
                                ? l10n.cashCountHelperTransferOut
                                : l10n.cashCountHelperTransferIn,
                          CashResolution.correction =>
                            l10n.cashCountHelperCorrection,
                          CashResolution.pending => l10n.cashCountHelperPending,
                        },
                        icon: switch (option) {
                          CashResolution.expense => Icons.search,
                          CashResolution.income => Icons.arrow_upward,
                          CashResolution.transfer => Icons.account_balance,
                          CashResolution.correction => Icons.refresh,
                          CashResolution.pending => Icons.help_outline,
                        },
                        selected: _resolution == option,
                        onTap: () => setState(() => _resolution = option),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_resolution == CashResolution.expense) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ExpenseCategory>(
                        initialValue: _category,
                        borderRadius: BorderRadius.zero,
                        dropdownColor: AppColors.surface,
                        decoration: InputDecoration(labelText: l10n.category),
                        items: ExpenseCategory.values
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category.label(l10n)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _category = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText: l10n.note,
                          hintText: l10n.noteExample,
                        ),
                      ),
                      const SizedBox(height: 10),
                      PixelHint(
                        tone: PixelHintTone.teal,
                        text: l10n.cashCountSingleExpenseHint,
                      ),
                    ],
                    if (_resolution == CashResolution.income) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText: l10n.note,
                          hintText: l10n.cashCountNoteTipExample,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.cashCountWhatToDoWithMoney,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      PixelSegmented<IncomeAllocation>(
                        segments: [
                          PixelSegment(
                            value: IncomeAllocation.cycle,
                            label: l10n.registerThisCycle,
                          ),
                          PixelSegment(
                            value: IncomeAllocation.savings,
                            label: l10n.registerSaveIt,
                          ),
                        ],
                        selected: _incomeAllocation,
                        onChanged: (value) =>
                            setState(() => _incomeAllocation = value),
                      ),
                    ],
                  ],
                ],
                const SizedBox(height: 24),
                PixelButton(
                  label: _saving
                      ? l10n.saving
                      : !store.hasCashBaseline
                      ? l10n.cashCountSaveFirst
                      : l10n.cashCountSave,
                  onPressed: actual == null || _saving
                      ? null
                      : () => _confirm(store),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) {
    final currency = SobraScope.of(context).currency;
    return PixelCard(
      elevation: PixelElevation.none,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              formatMoney(currency, value),
              style: pixelText(size: 19, bold: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolutionCard extends StatelessWidget {
  const _ResolutionCard({
    required this.label,
    required this.helper,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String helper;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PixelCard(
    elevation: PixelElevation.none,
    color: selected ? AppColors.tealSoft : AppColors.surface,
    borderColor: selected ? AppColors.tealInk : AppColors.ink,
    onTap: onTap,
    child: Row(
      children: [
        Icon(icon, color: selected ? AppColors.tealInk : AppColors.ink),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: pixelText(
                  size: 15,
                  bold: true,
                  color: selected ? AppColors.tealInk : AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                helper,
                style: pixelText(
                  size: 12,
                  color: selected ? AppColors.tealInk : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        Icon(
          selected ? Icons.radio_button_checked : Icons.chevron_right,
          color: selected ? AppColors.tealInk : AppColors.ink,
        ),
      ],
    ),
  );
}
