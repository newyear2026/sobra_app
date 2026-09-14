import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/daily_mission.dart';
import '../models/xp_event.dart';
import '../models/pay_schedule.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/prologue_scene.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _budgetController = TextEditingController(text: '6000');
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
    await _goTo(5);
  }

  /// Confirms the companion and moves on.
  ///
  /// Only Michi is drawable today, so this is a confirmation rather than a
  /// fork — but it is written through the store so the second pack is art
  /// alone when it lands.
  Future<void> _chooseCharacter(SobraStore store) async {
    await store.chooseCharacter(CharacterCatalog.michi.id);
    await _goTo(3);
  }

  Future<void> _continueFromBudget() async {
    if (parseAmount(_budgetController.text) == null) {
      _showError(AppLocalizations.of(context).onboardingBudgetAboveZero);
      return;
    }
    await _prepareSummary(skipBudget: false);
  }

  /// Writes the answers and moves to the last page.
  ///
  /// The cash count is not asked here any more. Counting it inside onboarding
  /// wrote the same baseline the cash screen writes but earned none of its XP,
  /// because the award is gated on onboarding being finished — so the first
  /// count is worth more once the user is home.
  Future<void> _prepareSummary({required bool skipBudget}) async {
    if (_saving) return;
    final budget = skipBudget ? null : parseAmount(_budgetController.text);
    if (!skipBudget && budget == null) {
      _showError(AppLocalizations.of(context).onboardingBudgetAboveZero);
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
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    // The summary page reads its figures back out of the store, so it would
    // present numbers that were never written down.
    if (!saved) return;
    await _goTo(6);
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
                  _TitlePage(onContinue: () => _goTo(1)),
                  _MeetingPage(
                    reducedMotion: reducedMotionOf(context),
                    onBack: () => _goTo(0),
                    onContinue: () => _goTo(2),
                  ),
                  _CharacterPickPage(
                    reducedMotion: reducedMotionOf(context),
                    onBack: () => _goTo(1),
                    onContinue: () => _chooseCharacter(store),
                  ),
                  _PayCyclePage(
                    type: _type,
                    onChanged: (type) => setState(() => _type = type),
                    onBack: () => _goTo(2),
                    onContinue: () => _goTo(4),
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
                    onBack: () => _goTo(3),
                    onContinue: _continueFromSchedule,
                  ),
                  _BudgetSetupPage(
                    controller: _budgetController,
                    preview: preview,
                    saving: _saving,
                    onBack: () => _goTo(4),
                    onContinue: _continueFromBudget,
                    onSkip: () => _prepareSummary(skipBudget: true),
                  ),
                  _ReadyPage(
                    budgetCentavos: store.hasBudget
                        ? store.totalBudgetCentavos
                        : null,
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

/// Wet, cold, and not yet anybody's.
Widget _rained(Widget child) => ColorFiltered(
  colorFilter: const ColorFilter.mode(Color(0x553A5484), BlendMode.srcATop),
  child: child,
);

/// The character whose art has not been drawn yet.
///
/// A flat silhouette rather than a guess at what it will look like: the shape
/// promises a second animal without inventing one.
Widget _silhouette(Widget child) => Opacity(
  opacity: 0.24,
  child: ColorFiltered(
    colorFilter: const ColorFilter.mode(AppColors.ink, BlendMode.srcIn),
    child: child,
  ),
);

/// A line of the prologue's prose.
class _Prose extends StatelessWidget {
  const _Prose(this.text, {this.centered = false});
  final String text;
  final bool centered;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: pixelText(size: 14, bold: true, height: 1.7),
    ),
  );
}

/// One of the prologue's answers, in the player's own voice.
class _StoryChoice extends StatelessWidget {
  const _StoryChoice({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: PixelCard(
      onTap: onTap,
      child: Row(
        children: [
          Text(
            '\u25c8 ',
            style: pixelText(size: 15, bold: true, color: AppColors.teal),
          ),
          Expanded(child: Text(label, style: pixelText(size: 15, bold: true))),
        ],
      ),
    ),
  );
}

/// What the companion says, with its name on it.
///
/// The character asks the setup questions from here on, so the questions keep
/// a speaker instead of turning back into form labels.
class _Says extends StatelessWidget {
  const _Says(this.lines);
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final name = CharacterCatalog.resolve(
      SobraScope.of(context).characterId,
    ).displayName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          PixelCard(
            color: i == 0 ? AppColors.cashSoft : AppColors.paperLight,
            borderColor: AppColors.cashInk,
            elevation: PixelElevation.none,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (i == 0) ...[
                  Text(
                    name,
                    style: pixelText(
                      size: 11,
                      bold: true,
                      color: AppColors.cashInk,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  lines[i],
                  style: pixelText(size: 14, bold: true, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TitlePage extends StatelessWidget {
  const _TitlePage({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _OnboardingFrame(
      bottom: PixelButton(label: l10n.prologueGoLook, onPressed: onContinue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.appName,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontSize: 44),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingTagline,
            textAlign: TextAlign.center,
            style: pixelText(size: 17, bold: true, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 14),
          // Nobody is in the room yet. The sound at the door is the hook, and
          // showing who made it here would spend it a page early.
          const PrologueScene(height: 170, raining: true),
          const SizedBox(height: 12),
          _Prose(l10n.prologueRainNoEnd),
          _Prose(l10n.prologueRentPaid),
          _Prose(l10n.prologueSoundAtDoor),
          // No reassurance about accounts here any more. The screen before
          // this one is where that belongs now: it says what is stored and
          // offers "start without an account" as a button the user presses.
          // Repeating "no account needed" one page later told somebody who
          // had just chosen to connect one the opposite of what they did.
          const Spacer(),
        ],
      ),
    );
  }
}

class _MeetingPage extends StatelessWidget {
  const _MeetingPage({
    required this.reducedMotion,
    required this.onBack,
    required this.onContinue,
  });
  final bool reducedMotion;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget arriving({required bool silhouette, required double delay}) {
      Widget pose(CatMotion motion, {required bool animate}) => CatSprite(
        motion: motion,
        width: 96,
        animate: animate,
        loop: motion == CatMotion.walk ? true : false,
      );

      final moving = _rained(pose(CatMotion.walk, animate: !reducedMotion));
      final arrived = _rained(pose(CatMotion.concern, animate: !reducedMotion));
      return PrologueArrival(
        animate: !reducedMotion,
        delayFraction: delay,
        moving: silhouette ? _silhouette(moving) : moving,
        arrived: silhouette ? _silhouette(arrived) : arrived,
      );
    }

    return _OnboardingFrame(
      bottom: const SizedBox.shrink(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 46,
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onContinue,
                  child: Text(l10n.prologueSkip),
                ),
              ],
            ),
          ),
          PrologueScene(
            height: 176,
            raining: true,
            actors: [
              arriving(silhouette: false, delay: 0),
              arriving(silhouette: true, delay: 0.16),
            ],
          ),
          const SizedBox(height: 14),
          _Prose(l10n.prologueWetTracks),
          PixelCard(
            color: AppColors.cashSoft,
            borderColor: AppColors.cashInk,
            child: Text(
              l10n.prologueShelter,
              textAlign: TextAlign.center,
              style: pixelText(size: 19, bold: true),
            ),
          ),
          const SizedBox(height: 14),
          _Prose(l10n.prologueItSpoke, centered: true),
          const SizedBox(height: 2),
          // Both answers reach the same next page. The choice is a tone, not
          // a branch: a prologue that forked here would owe the player two of
          // everything after it.
          _StoryChoice(label: l10n.prologueReplySurprised, onTap: onContinue),
          _StoryChoice(label: l10n.prologueReplyTowel, onTap: onContinue),
          const Spacer(),
        ],
      ),
    );
  }
}

class _CharacterPickPage extends StatelessWidget {
  const _CharacterPickPage({
    required this.reducedMotion,
    required this.onBack,
    required this.onContinue,
  });
  final bool reducedMotion;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resting = CatSprite(
      motion: CatMotion.idle,
      width: 92,
      animate: !reducedMotion,
    );
    return _OnboardingFrame(
      bottom: PixelButton(
        label: l10n.prologueLiveTogether,
        onPressed: onContinue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 46,
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
          ),
          PrologueScene(height: 164, actors: [resting, _silhouette(resting)]),
          const SizedBox(height: 14),
          _Prose(l10n.prologueDriedOff),
          Text(
            l10n.prologueWhoSits,
            textAlign: TextAlign.center,
            style: pixelText(size: 13, bold: true, color: AppColors.teal),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PickCard(
                  name: CharacterCatalog.michi.displayName,
                  trait: l10n.prologueMichiTrait,
                  selected: true,
                  child: CatSprite(
                    motion: CatMotion.idle,
                    width: 86,
                    animate: !reducedMotion,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickCard(
                  name: l10n.prologueLockedName,
                  trait: l10n.prologueLockedTrait,
                  selected: false,
                  locked: l10n.prologueLockedSoon,
                  child: _silhouette(
                    CatSprite(
                      motion: CatMotion.walk,
                      width: 86,
                      animate: false,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PixelCard(
            color: AppColors.cashSoft,
            borderColor: AppColors.cashInk,
            elevation: PixelElevation.none,
            child: Text(
              l10n.prologueGreeting(CharacterCatalog.michi.displayName),
              style: pixelText(size: 14, bold: true),
            ),
          ),
          const SizedBox(height: 10),
          PixelHint(tone: PixelHintTone.neutral, text: l10n.prologueOtherStays),
          const Spacer(),
        ],
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  const _PickCard({
    required this.name,
    required this.trait,
    required this.selected,
    required this.child,
    this.locked,
  });
  final String name;
  final String trait;
  final bool selected;
  final Widget child;
  final String? locked;

  @override
  Widget build(BuildContext context) => PixelCard(
    color: selected ? AppColors.tealSoft : AppColors.surface,
    borderColor: selected ? AppColors.tealInk : AppColors.ink,
    padding: const EdgeInsets.fromLTRB(9, 9, 9, 10),
    child: Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.beige,
            border: Border.all(color: AppColors.ink, width: 2.5),
          ),
          child: SizedBox(
            height: 104,
            width: double.infinity,
            child: Align(alignment: Alignment.bottomCenter, child: child),
          ),
        ),
        const SizedBox(height: 8),
        Text(name, style: pixelText(size: 15, bold: true)),
        const SizedBox(height: 3),
        Text(
          trait,
          textAlign: TextAlign.center,
          style: pixelText(
            size: 11,
            color: selected ? AppColors.tealInk : AppColors.inkSoft,
          ),
        ),
        if (locked != null) ...[
          const SizedBox(height: 7),
          Text(
            locked!,
            style: pixelText(size: 11, bold: true, color: AppColors.muted),
          ),
        ],
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
        const SizedBox(height: 10),
        Center(
          child: CatSprite(
            motion: CatMotion.calculate,
            width: 96,
            animate: !reducedMotionOf(context),
          ),
        ),
        const SizedBox(height: 10),
        // The role that had never been used in onboarding, and the one beat
        // where the character is visibly doing the counting it offered.
        _Says([
          AppLocalizations.of(context).prologueEarnKeep,
          AppLocalizations.of(context).prologueAskSchedule,
        ]),
        const SizedBox(height: 18),
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
        const SizedBox(height: 10),
        _Says([
          switch (type) {
            PayCycleType.irregular => AppLocalizations.of(
              context,
            ).onboardingPlanWithoutFixedDate,
            PayCycleType.biweekly => AppLocalizations.of(
              context,
            ).onboardingWhenLastPaid,
            _ => AppLocalizations.of(context).prologueAskPayday,
          },
        ]),
        const SizedBox(height: 18),
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
    required this.saving,
    required this.onContinue,
    required this.onSkip,
  });
  final TextEditingController controller;
  final CycleBounds preview;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => _OnboardingFrame(
    // The cash question already offers "not now"; this one used to be the
    // single page onboarding could not get past. Somebody who does not know
    // their number yet is not stuck with a wrong one.
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
        _ProgressHeader(step: 3, onBack: onBack),
        const SizedBox(height: 10),
        Center(
          child: CatSprite(
            motion: CatMotion.saving,
            width: 96,
            animate: !reducedMotionOf(context),
          ),
        ),
        const SizedBox(height: 10),
        _Says([
          AppLocalizations.of(context).prologueAskBudget(preview.lengthInDays),
        ]),
        const SizedBox(height: 18),
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
        const SizedBox(height: 12),
        // Said before the skip is taken, not after: permission is only worth
        // something while the choice is still open.
        PixelHint(
          tone: PixelHintTone.neutral,
          text: AppLocalizations.of(context).prologueSkipIsFine,
        ),
        const Spacer(),
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

  /// Null when the budget question was answered with "not yet".
  final int? budgetCentavos;
  final int todayCentavos;
  final CycleBounds bounds;
  final bool reducedMotion;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    final name = CharacterCatalog.resolve(store.characterId).displayName;
    return _OnboardingFrame(
      bottom: PixelButton(label: l10n.onboardingGoHome, onPressed: onFinish),
      scrollContent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          PrologueScene(
            height: 172,
            actors: [
              PrologueArrival(
                animate: !reducedMotion,
                distance: 96,
                duration: const Duration(milliseconds: 2400),
                moving: CatSprite(
                  motion: CatMotion.walk,
                  width: 104,
                  animate: !reducedMotion,
                ),
                arrived: CatSprite(
                  motion: reducedMotion ? CatMotion.idle : CatMotion.celebrate,
                  width: 104,
                  loop: false,
                  animate: !reducedMotion,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // The weather opened the prologue and closes it, so no line has to
          // announce that the story is over.
          _Prose(l10n.onboardingSettledIn(name), centered: true),
          _LevelBadge(name: name),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingCanSpendToday,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontVariations: AppType.bold),
          ),
          const SizedBox(height: 6),
          if (budgetCentavos == null) ...[
            // The same placeholder Inicio shows, so the two screens agree
            // about what is missing.
            const Text(
              emDash,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.line,
                fontSize: 44,
                fontVariations: AppType.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.onboardingBudgetLater,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ] else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatMoney(store.currency, todayCentavos),
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 44,
                  fontVariations: AppType.bold,
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text(
            l10n.onboardingFirstQuests,
            style: pixelText(size: 12, bold: true, color: AppColors.teal),
          ),
          const SizedBox(height: 8),
          for (final kind in DailyMissionKind.values)
            _QuestRow(label: kind.title(l10n), xp: kind.xp),
          const SizedBox(height: 4),
          // The biggest single reward in the app, and it is deliberately not
          // collectable here: the award is gated on onboarding being over.
          _WaitingAtHome(l10n: l10n),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = XpProgress.fromTotal(0);
    return PixelCard(
      color: AppColors.tealSoft,
      borderColor: AppColors.tealInk,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.teal,
              border: Border.all(color: AppColors.ink, width: 2.5),
            ),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: Text(
                  '${progress.level}',
                  style: pixelText(size: 17, bold: true, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  xpLevelTitle(l10n, progress.level),
                  style: pixelText(size: 14, bold: true),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.xpOfTarget(
                    progress.currentLevelXp,
                    progress.targetLevelXp,
                  ),
                  style: pixelText(size: 12, color: AppColors.tealInk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({required this.label, required this.xp});
  final String label;
  final int xp;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: PixelCard(
      elevation: PixelElevation.none,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.ink, width: 2.5),
            ),
            child: const SizedBox(width: 18, height: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: pixelText(size: 13, bold: true))),
          Text(
            AppLocalizations.of(context).xpAmount(xp),
            style: pixelText(size: 13, bold: true, color: AppColors.teal),
          ),
        ],
      ),
    ),
  );
}

class _WaitingAtHome extends StatelessWidget {
  const _WaitingAtHome({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => PixelCard(
    elevation: PixelElevation.none,
    color: AppColors.cashSoft,
    borderColor: AppColors.cashInk,
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.onboardingWaitingAtHome,
                style: pixelText(
                  size: 11,
                  bold: true,
                  color: AppColors.cashInk,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.cashCountTitle,
                style: pixelText(
                  size: 13,
                  bold: true,
                  color: AppColors.cashInk,
                ),
              ),
            ],
          ),
        ),
        Text(
          l10n.xpAmount(25),
          style: pixelText(size: 15, bold: true, color: AppColors.cashInk),
        ),
      ],
    ),
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

/// How many questions onboarding still asks after the prologue.
const _settingSteps = 3;

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
          AppLocalizations.of(context).onboardingStepOf(step, _settingSteps),
          style: pixelText(size: 16, bold: true),
        ),
      ],
    ),
  );
}

class _OnboardingFrame extends StatelessWidget {
  const _OnboardingFrame({
    required this.child,
    required this.bottom,
    this.scrollContent = false,
  });
  final Widget child;
  final Widget bottom;
  final bool scrollContent;
  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.fromLTRB(20, 12, 20, 18);
    if (scrollContent) {
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: SingleChildScrollView(child: child)),
            const SizedBox(height: 16),
            bottom,
          ],
        ),
      );
    }
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
