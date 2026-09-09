import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/pay_schedule.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/pixel_ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _budgetController = TextEditingController(text: '6000');
  final _cashController = TextEditingController();
  PayCycleType _type = PayCycleType.semiMonthly;
  int _firstPayDay = 15;
  int _monthlyPayDay = 30;
  int _weeklyPayDay = DateTime.friday;
  int _planningHorizon = 7;

  /// The day the user says they were last paid, which anchors a fortnight.
  DateTime? _lastPayday;
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _budgetController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  PaySchedule _schedule(DateTime today) => switch (_type) {
    PayCycleType.semiMonthly => PaySchedule.semiMonthly(
      firstPayDay: _firstPayDay,
    ),
    PayCycleType.biweekly => PaySchedule.biweekly(anchor: _lastPayday ?? today),
    PayCycleType.monthly => PaySchedule.monthly(monthlyPayDay: _monthlyPayDay),
    PayCycleType.weekly => PaySchedule.weekly(weeklyPayDay: _weeklyPayDay),
    PayCycleType.irregular => PaySchedule.irregular(
      planningHorizonDays: _planningHorizon,
      irregularCycleStart: today,
    ),
  };

  Future<void> _goTo(int page) async {
    FocusScope.of(context).unfocus();
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// A fortnight is the one cycle that cannot be guessed from a day number,
  /// so it is the one page that can refuse to move on.
  Future<void> _continueFromSchedule() async {
    if (_type == PayCycleType.biweekly && _lastPayday == null) {
      _showError(AppLocalizations.of(context).onboardingBiweeklyNeedsDate);
      return;
    }
    await _goTo(3);
  }

  Future<void> _continueFromBudget() async {
    if (parseAmount(_budgetController.text) == null) {
      _showError(AppLocalizations.of(context).onboardingBudgetAboveZero);
      return;
    }
    await _goTo(4);
  }

  Future<void> _prepareSummary({required bool skipCash}) async {
    if (_saving) return;
    final budget = parseAmount(_budgetController.text);
    if (budget == null) {
      _showError(AppLocalizations.of(context).onboardingBudgetAboveZero);
      await _goTo(3);
      return;
    }
    final cash = skipCash ? null : parseNonNegativeAmount(_cashController.text);
    if (!skipCash && cash == null) {
      _showError(AppLocalizations.of(context).onboardingCashOrSkip);
      return;
    }
    setState(() => _saving = true);
    final store = SobraScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final saved = await guardStoreWrite(
      messenger,
      AppLocalizations.of(context),
      () => store.configureOnboarding(
        budgetCentavos: budget,
        schedule: _schedule(store.today),
        cashCentavos: cash,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    // The summary page reads its figures back out of the store, so it would
    // present numbers that were never written down.
    if (!saved) return;
    await _goTo(5);
  }

  /// Marks onboarding finished, which is what swaps the whole app over to the
  /// shell. A failure here has to be visible: the user taps "Listo" and would
  /// otherwise be left staring at the summary with nothing happening.
  Future<void> _finish(SobraStore store) => guardStoreWrite(
    ScaffoldMessenger.of(context),
    AppLocalizations.of(context),
    store.completeOnboarding,
  );

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    final schedule = _schedule(store.today);
    final preview = schedule.boundsFor(store.today);
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.surface),
            child: SafeArea(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomePage(
                    reducedMotion: reducedMotionOf(context),
                    onContinue: () => _goTo(1),
                  ),
                  _PayCyclePage(
                    type: _type,
                    onChanged: (type) => setState(() => _type = type),
                    onBack: () => _goTo(0),
                    onContinue: () => _goTo(2),
                  ),
                  _ScheduleDetailsPage(
                    type: _type,
                    firstPayDay: _firstPayDay,
                    monthlyPayDay: _monthlyPayDay,
                    weeklyPayDay: _weeklyPayDay,
                    planningHorizon: _planningHorizon,
                    lastPayday: _lastPayday ?? store.today,
                    preview: preview,
                    onFirstPayDayChanged: (value) =>
                        setState(() => _firstPayDay = value),
                    onLastPaydayChanged: (value) =>
                        setState(() => _lastPayday = value),
                    onMonthlyPayDayChanged: (value) =>
                        setState(() => _monthlyPayDay = value),
                    onWeeklyPayDayChanged: (value) =>
                        setState(() => _weeklyPayDay = value),
                    onPlanningHorizonChanged: (value) =>
                        setState(() => _planningHorizon = value),
                    onBack: () => _goTo(1),
                    onContinue: _continueFromSchedule,
                  ),
                  _BudgetSetupPage(
                    controller: _budgetController,
                    preview: preview,
                    onBack: () => _goTo(2),
                    onContinue: _continueFromBudget,
                  ),
                  _CashSetupPage(
                    controller: _cashController,
                    saving: _saving,
                    onBack: () => _goTo(3),
                    onContinue: () => _prepareSummary(skipCash: false),
                    onSkip: () => _prepareSummary(skipCash: true),
                  ),
                  _ReadyPage(
                    budgetCentavos: store.totalBudgetCentavos,
                    todayCentavos: store.todayRemainingCentavos,
                    bounds: store.cycleBounds,
                    reducedMotion: reducedMotionOf(context),
                    onFinish: () => _finish(store),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.reducedMotion, required this.onContinue});
  final bool reducedMotion;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => _OnboardingFrame(
    bottom: PixelButton(
      label: AppLocalizations.of(context).onboardingStart,
      onPressed: onContinue,
    ),
    child: Column(
      children: [
        const Spacer(),
        Text(
          AppLocalizations.of(context).appName,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontSize: 50),
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context).onboardingTagline,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 27),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context).onboardingPromise,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        PixelCard(
          elevation: PixelElevation.none,
          color: AppColors.beige,
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 0),
          child: Center(
            child: CatSprite(
              motion: CatMotion.idle,
              width: 190,
              animate: !reducedMotion,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 17, color: AppColors.teal),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                AppLocalizations.of(context).onboardingNoAccount,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkSoft),
              ),
            ),
          ],
        ),
        const Spacer(),
      ],
    ),
  );
}

class _PayCyclePage extends StatelessWidget {
  const _PayCyclePage({
    required this.type,
    required this.onChanged,
    required this.onBack,
    required this.onContinue,
  });
  final PayCycleType type;
  final ValueChanged<PayCycleType> onChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => _OnboardingFrame(
    bottom: PixelButton(
      label: AppLocalizations.of(context).continueLabel,
      onPressed: onContinue,
    ),
    child: Column(
      children: [
        _ProgressHeader(step: 1, onBack: onBack),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context).onboardingHowPaid,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 29),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).onboardingHowPaidHint,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.inkSoft),
        ),
        const SizedBox(height: 24),
        for (final option in PayCycleType.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ChoiceCard(
              label: option.label(AppLocalizations.of(context)),
              helper: switch (option) {
                PayCycleType.semiMonthly => AppLocalizations.of(
                  context,
                ).onboardingCycleHelperSemiMonthly,
                PayCycleType.biweekly => AppLocalizations.of(
                  context,
                ).onboardingCycleHelperBiweekly,
                PayCycleType.monthly => AppLocalizations.of(
                  context,
                ).onboardingCycleHelperMonthly,
                PayCycleType.weekly => AppLocalizations.of(
                  context,
                ).onboardingCycleHelperWeekly,
                PayCycleType.irregular => AppLocalizations.of(
                  context,
                ).onboardingCycleHelperIrregular,
              },
              selected: type == option,
              icon: switch (option) {
                PayCycleType.semiMonthly => Icons.today,
                PayCycleType.biweekly => Icons.repeat,
                PayCycleType.monthly => Icons.calendar_month,
                PayCycleType.weekly => Icons.date_range,
                PayCycleType.irregular => Icons.help_outline,
              },
              onTap: () => onChanged(option),
            ),
          ),
      ],
    ),
  );
}

class _ScheduleDetailsPage extends StatelessWidget {
  const _ScheduleDetailsPage({
    required this.type,
    required this.firstPayDay,
    required this.monthlyPayDay,
    required this.weeklyPayDay,
    required this.planningHorizon,
    required this.lastPayday,
    required this.preview,
    required this.onFirstPayDayChanged,
    required this.onLastPaydayChanged,
    required this.onMonthlyPayDayChanged,
    required this.onWeeklyPayDayChanged,
    required this.onPlanningHorizonChanged,
    required this.onBack,
    required this.onContinue,
  });
  final PayCycleType type;
  final int firstPayDay;
  final int monthlyPayDay;
  final int weeklyPayDay;
  final int planningHorizon;
  final DateTime lastPayday;
  final CycleBounds preview;
  final ValueChanged<int> onFirstPayDayChanged;
  final ValueChanged<DateTime> onLastPaydayChanged;
  final ValueChanged<int> onMonthlyPayDayChanged;
  final ValueChanged<int> onWeeklyPayDayChanged;
  final ValueChanged<int> onPlanningHorizonChanged;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => _OnboardingFrame(
    bottom: PixelButton(
      label: AppLocalizations.of(context).continueLabel,
      onPressed: onContinue,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressHeader(step: 2, onBack: onBack),
        const SizedBox(height: 24),
        Text(
          switch (type) {
            PayCycleType.irregular => AppLocalizations.of(
              context,
            ).onboardingPlanWithoutFixedDate,
            PayCycleType.biweekly => AppLocalizations.of(
              context,
            ).onboardingWhenLastPaid,
            _ => AppLocalizations.of(context).onboardingWhichDayPaid,
          },
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 24),
        if (type == PayCycleType.semiMonthly) ...[
          _DayDropdown(
            label: AppLocalizations.of(context).cycleFirstPay,
            value: firstPayDay,
            max: 28,
            onChanged: onFirstPayDayChanged,
          ),
          const SizedBox(height: 12),
          PixelCard(
            elevation: PixelElevation.none,
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: AppColors.teal),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).onboardingSecondPayEndOfMonth,
                    style: const TextStyle(fontVariations: AppType.bold),
                  ),
                ),
              ],
            ),
          ),
        ] else if (type == PayCycleType.biweekly)
          PaydayField(
            label: AppLocalizations.of(context).cycleLastPayday,
            value: lastPayday,
            onChanged: onLastPaydayChanged,
          )
        else if (type == PayCycleType.monthly)
          _DayDropdown(
            label: AppLocalizations.of(context).cyclePayDay,
            value: monthlyPayDay,
            max: 31,
            onChanged: onMonthlyPayDayChanged,
          )
        else if (type == PayCycleType.weekly)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final day in const [1, 2, 3, 4, 5, 6, 7])
                _SmallChoice(
                  label: weekdayShortName(AppLocalizations.of(context), day),
                  selected: weeklyPayDay == day,
                  onTap: () => onWeeklyPayDayChanged(day),
                ),
            ],
          )
        else ...[
          Text(
            AppLocalizations.of(context).onboardingHowManyDays,
            textAlign: TextAlign.center,
            style: const TextStyle(fontVariations: AppType.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final days in const [7, 14, 30]) ...[
                Expanded(
                  child: _SmallChoice(
                    label: AppLocalizations.of(context).daysCount(days),
                    selected: planningHorizon == days,
                    onTap: () => onPlanningHorizonChanged(days),
                  ),
                ),
                if (days != 30) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
        const SizedBox(height: 26),
        Text(
          AppLocalizations.of(context).onboardingCyclePreview,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        PixelCard(
          elevation: PixelElevation.none,
          color: AppColors.tealSoft,
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.teal),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cycleDateRange(
                    AppLocalizations.of(context),
                    preview.start,
                    preview.end,
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontVariations: AppType.bold,
                  ),
                ),
              ),
              Text(
                AppLocalizations.of(context).daysCount(preview.lengthInDays),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          type == PayCycleType.irregular
              ? AppLocalizations.of(
                  context,
                ).onboardingRepeatsEvery(planningHorizon)
              : AppLocalizations.of(context).onboardingShortMonthsNote,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.inkSoft),
        ),
      ],
    ),
  );
}

class _BudgetSetupPage extends StatelessWidget {
  const _BudgetSetupPage({
    required this.controller,
    required this.preview,
    required this.onBack,
    required this.onContinue,
  });
  final TextEditingController controller;
  final CycleBounds preview;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => _OnboardingFrame(
    bottom: PixelButton(
      label: AppLocalizations.of(context).continueLabel,
      onPressed: onContinue,
    ),
    child: Column(
      children: [
        _ProgressHeader(step: 3, onBack: onBack),
        const Spacer(),
        Text(
          AppLocalizations.of(context).onboardingBudgetQuestion,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.teal,
            fontSize: 39,
            fontVariations: AppType.bold,
          ),
          decoration: InputDecoration(
            prefixText: SobraScope.of(context).currency.symbol,
            suffixText: SobraScope.of(context).currency.code,
          ),
        ),
        const SizedBox(height: 20),
        PixelCard(
          elevation: PixelElevation.none,
          child: Row(
            children: [
              const Icon(Icons.date_range, color: AppColors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cycleDateRange(
                    AppLocalizations.of(context),
                    preview.start,
                    preview.end,
                  ),
                  style: const TextStyle(fontVariations: AppType.bold),
                ),
              ),
              Text(
                AppLocalizations.of(context).daysCount(preview.lengthInDays),
              ),
            ],
          ),
        ),
        const Spacer(flex: 2),
      ],
    ),
  );
}

class _CashSetupPage extends StatelessWidget {
  const _CashSetupPage({
    required this.controller,
    required this.saving,
    required this.onBack,
    required this.onContinue,
    required this.onSkip,
  });
  final TextEditingController controller;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => _OnboardingFrame(
    bottom: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelButton(
          label: saving
              ? AppLocalizations.of(context).saving
              : AppLocalizations.of(context).continueLabel,
          onPressed: saving ? null : onContinue,
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: saving ? null : onSkip,
          child: Text(AppLocalizations.of(context).onboardingNotNow),
        ),
      ],
    ),
    child: Column(
      children: [
        _ProgressHeader(step: 4, onBack: onBack),
        const Spacer(),
        Text(
          AppLocalizations.of(context).onboardingCashQuestion,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 29),
        ),
        const SizedBox(height: 10),
        Text(
          AppLocalizations.of(context).onboardingCashOptional,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: pixelText(size: 39, bold: true, color: AppColors.teal),
          decoration: InputDecoration(
            prefixText: SobraScope.of(context).currency.symbol,
            hintText: '—',
            suffixText: SobraScope.of(context).currency.code,
          ),
        ),
        const SizedBox(height: 30),
        PixelCard(
          elevation: PixelElevation.none,
          color: AppColors.cashSoft,
          borderColor: AppColors.cashInk,
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 38,
                color: AppColors.cashInk,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).onboardingCashIsBaseline,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.cashInk,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 2),
      ],
    ),
  );
}

class _ReadyPage extends StatelessWidget {
  const _ReadyPage({
    required this.budgetCentavos,
    required this.todayCentavos,
    required this.bounds,
    required this.reducedMotion,
    required this.onFinish,
  });
  final int budgetCentavos;
  final int todayCentavos;
  final CycleBounds bounds;
  final bool reducedMotion;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) => _OnboardingFrame(
    bottom: PixelButton(
      label: AppLocalizations.of(context).onboardingGoHome,
      onPressed: onFinish,
    ),
    child: Column(
      children: [
        const Spacer(),
        Text(
          AppLocalizations.of(context).onboardingPlanReady,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 31),
        ),
        const SizedBox(height: 10),
        Text(
          AppLocalizations.of(context).onboardingCanSpendToday,
          style: const TextStyle(fontSize: 18, fontVariations: AppType.bold),
        ),
        const SizedBox(height: 8),
        FittedBox(
          child: Text(
            formatMoney(SobraScope.of(context).currency, todayCentavos),
            style: const TextStyle(
              color: AppColors.teal,
              fontSize: 47,
              fontVariations: AppType.bold,
            ),
          ),
        ),
        const SizedBox(height: 18),
        PixelCard(
          elevation: PixelElevation.none,
          child: Column(
            children: [
              _SummaryRow(
                label: AppLocalizations.of(context).xpDetailCycle,
                value: cycleDateRange(
                  AppLocalizations.of(context),
                  bounds.start,
                  bounds.end,
                ),
              ),
              const Divider(),
              _SummaryRow(
                label: AppLocalizations.of(context).budget,
                value: formatMoney(
                  SobraScope.of(context).currency,
                  budgetCentavos,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PixelCard(
          elevation: PixelElevation.none,
          color: AppColors.beige,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Center(
            child: CatSprite(
              motion: CatMotion.celebrate,
              width: 176,
              loop: false,
              animate: !reducedMotion,
            ),
          ),
        ),
        const Spacer(),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontVariations: AppType.bold),
        ),
      ),
      Text(value, style: const TextStyle(fontVariations: AppType.bold)),
    ],
  );
}

class _DayDropdown extends StatelessWidget {
  const _DayDropdown({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
    initialValue: value,
    borderRadius: BorderRadius.zero,
    dropdownColor: AppColors.surface,
    decoration: InputDecoration(labelText: label),
    items: [
      for (var day = 1; day <= max; day++)
        DropdownMenuItem(
          value: day,
          child: Text(AppLocalizations.of(context).dayOfMonth(day)),
        ),
    ],
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.helper,
    required this.selected,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final String helper;
  final bool selected;
  final IconData icon;
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
                  size: 16,
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
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? AppColors.tealInk : AppColors.ink,
        ),
      ],
    ),
  );
}

class _SmallChoice extends StatelessWidget {
  const _SmallChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : AppColors.surface,
          border: Border.all(color: AppColors.ink, width: 2.5),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: pixelText(
            size: 14,
            bold: true,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    ),
  );
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step, this.onBack});
  final int step;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: Stack(
      alignment: Alignment.center,
      children: [
        if (onBack != null)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
          ),
        Text(
          AppLocalizations.of(context).onboardingStepOf(step, 4),
          style: pixelText(size: 16, bold: true),
        ),
      ],
    ),
  );
}

class _OnboardingFrame extends StatelessWidget {
  const _OnboardingFrame({required this.child, required this.bottom});
  final Widget child;
  final Widget bottom;
  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.fromLTRB(20, 12, 20, 18);
    return LayoutBuilder(
      builder: (context, constraints) {
        final minimumHeight = (constraints.maxHeight - padding.vertical).clamp(
          0.0,
          double.infinity,
        );
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minimumHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Expanded(child: child),
                  const SizedBox(height: 16),
                  bottom,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
