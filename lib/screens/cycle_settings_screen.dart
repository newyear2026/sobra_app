import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/pay_schedule.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_ui.dart';

class CycleSettingsScreen extends StatefulWidget {
  const CycleSettingsScreen({super.key});

  @override
  State<CycleSettingsScreen> createState() => _CycleSettingsScreenState();
}

class _CycleSettingsScreenState extends State<CycleSettingsScreen> {
  bool _initialized = false;
  late PayCycleType _type;
  int _firstDay = 15;
  int _monthlyDay = 30;
  int _weeklyDay = DateTime.friday;
  int _horizon = 7;

  /// A fortnight needs a real calendar date, not a day number: it is the day
  /// the user was last paid, and every fourteenth day from it opens a cycle.
  DateTime? _lastPayday;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final schedule =
        SobraScope.of(context).pendingPaySchedule ??
        SobraScope.of(context).paySchedule;
    _type = schedule.type;
    _firstDay = schedule.firstPayDay;
    _monthlyDay = schedule.monthlyPayDay;
    _weeklyDay = schedule.weeklyPayDay;
    _horizon = schedule.planningHorizonDays;
    _lastPayday = schedule.biweeklyAnchor;
    _initialized = true;
  }

  PaySchedule _draft(DateTime effectiveAt) => switch (_type) {
    PayCycleType.semiMonthly => PaySchedule.semiMonthly(firstPayDay: _firstDay),
    PayCycleType.biweekly => PaySchedule.biweekly(
      anchor: _lastPayday ?? effectiveAt,
    ),
    PayCycleType.monthly => PaySchedule.monthly(monthlyPayDay: _monthlyDay),
    PayCycleType.weekly => PaySchedule.weekly(weeklyPayDay: _weeklyDay),
    PayCycleType.irregular => PaySchedule.irregular(
      planningHorizonDays: _horizon,
      irregularCycleStart: effectiveAt,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    final effectiveAt = store.cycleEnd.add(const Duration(days: 1));
    final draft = _draft(effectiveAt);
    final preview = draft.boundsFor(effectiveAt);
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
                  title: l10n.cycleTitle,
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.cycleCurrent,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                PixelCard(
                  elevation: PixelElevation.none,
                  color: AppColors.tealSoft,
                  borderColor: AppColors.tealInk,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_available,
                        color: AppColors.tealInk,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.cycleInProgress,
                              style: pixelText(
                                size: 15,
                                bold: true,
                                color: AppColors.tealInk,
                              ),
                            ),
                            Text(
                              cycleDateRange(
                                l10n,
                                store.cycleStart,
                                store.cycleEnd,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        l10n.cycleUnchanged,
                        style: const TextStyle(color: AppColors.teal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.cycleNewFrequency,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<PayCycleType>(
                  initialValue: _type,
                  borderRadius: BorderRadius.zero,
                  dropdownColor: AppColors.surface,
                  items: PayCycleType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label(l10n)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _type = value);
                  },
                ),
                const SizedBox(height: 14),
                if (_type == PayCycleType.semiMonthly)
                  _NumberDropdown(
                    label: l10n.cycleFirstPay,
                    value: _firstDay,
                    max: 28,
                    onChanged: (value) => setState(() => _firstDay = value),
                  )
                else if (_type == PayCycleType.biweekly)
                  PaydayField(
                    label: l10n.cycleLastPayday,
                    value: _lastPayday ?? store.today,
                    onChanged: (value) => setState(() => _lastPayday = value),
                  )
                else if (_type == PayCycleType.monthly)
                  _NumberDropdown(
                    label: l10n.cyclePayDay,
                    value: _monthlyDay,
                    max: 31,
                    onChanged: (value) => setState(() => _monthlyDay = value),
                  )
                else if (_type == PayCycleType.weekly)
                  DropdownButtonFormField<int>(
                    initialValue: _weeklyDay,
                    borderRadius: BorderRadius.zero,
                    dropdownColor: AppColors.surface,
                    decoration: InputDecoration(labelText: l10n.cyclePayDay),
                    items: [
                      for (var index = 0; index < 7; index++)
                        DropdownMenuItem(
                          value: index + 1,
                          child: Text(weekdayName(l10n, index + 1)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _weeklyDay = value);
                    },
                  )
                else
                  PixelSegmented<int>(
                    segments: [
                      for (final days in const [7, 14, 30])
                        PixelSegment(value: days, label: l10n.daysCount(days)),
                    ],
                    selected: _horizon,
                    onChanged: (value) => setState(() => _horizon = value),
                  ),
                const SizedBox(height: 24),
                Text(
                  l10n.cycleNext,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                PixelCard(
                  elevation: PixelElevation.none,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppColors.violet),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cycleDateRange(l10n, effectiveAt, preview.end),
                          style: pixelText(size: 17, bold: true),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PixelHint(
                  tone: PixelHintTone.cash,
                  text: _type == PayCycleType.irregular
                      ? l10n.cycleChangeAppliesRepeating(_horizon)
                      : l10n.cycleChangeApplies,
                ),
                const SizedBox(height: 24),
                PixelButton(
                  label: _saving ? l10n.saving : l10n.cycleSaveChange,
                  onPressed: _saving
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _saving = true);
                          final saved = await guardStoreWrite(
                            messenger,
                            l10n,
                            () => store.queuePayScheduleChange(draft),
                          );
                          if (!context.mounted) return;
                          setState(() => _saving = false);
                          // Staying here on a failure keeps the choice on
                          // screen, so Guardar can simply be tapped again.
                          if (saved) Navigator.pop(context);
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberDropdown extends StatelessWidget {
  const _NumberDropdown({
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
