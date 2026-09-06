import 'package:flutter/material.dart';

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
    _initialized = true;
  }

  PaySchedule _draft(DateTime effectiveAt) => switch (_type) {
    PayCycleType.semiMonthly => PaySchedule.semiMonthly(firstPayDay: _firstDay),
    PayCycleType.monthly => PaySchedule.monthly(monthlyPayDay: _monthlyDay),
    PayCycleType.weekly => PaySchedule.weekly(weeklyPayDay: _weeklyDay),
    PayCycleType.irregular => PaySchedule.irregular(
      planningHorizonDays: _horizon,
      irregularCycleStart: effectiveAt,
    ),
  };

  @override
  Widget build(BuildContext context) {
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
                  title: 'Tu ciclo',
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 18),
                Text(
                  'Ciclo actual',
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
                              'En curso',
                              style: pixelText(
                                size: 15,
                                bold: true,
                                color: AppColors.tealInk,
                              ),
                            ),
                            Text(
                              cycleDateRange(store.cycleStart, store.cycleEnd),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'No cambiará',
                        style: TextStyle(color: AppColors.teal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Nueva frecuencia',
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
                          child: Text(type.label),
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
                    label: 'Primer pago',
                    value: _firstDay,
                    max: 28,
                    onChanged: (value) => setState(() => _firstDay = value),
                  )
                else if (_type == PayCycleType.monthly)
                  _NumberDropdown(
                    label: 'Día de pago',
                    value: _monthlyDay,
                    max: 31,
                    onChanged: (value) => setState(() => _monthlyDay = value),
                  )
                else if (_type == PayCycleType.weekly)
                  DropdownButtonFormField<int>(
                    initialValue: _weeklyDay,
                    borderRadius: BorderRadius.zero,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(labelText: 'Día de pago'),
                    items: [
                      for (var index = 0; index < 7; index++)
                        DropdownMenuItem(
                          value: index + 1,
                          child: Text(
                            const [
                              'Lunes',
                              'Martes',
                              'Miércoles',
                              'Jueves',
                              'Viernes',
                              'Sábado',
                              'Domingo',
                            ][index],
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _weeklyDay = value);
                    },
                  )
                else
                  PixelSegmented<int>(
                    segments: const [
                      PixelSegment(value: 7, label: '7 días'),
                      PixelSegment(value: 14, label: '14 días'),
                      PixelSegment(value: 30, label: '30 días'),
                    ],
                    selected: _horizon,
                    onChanged: (value) => setState(() => _horizon = value),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Próximo ciclo',
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
                          cycleDateRange(effectiveAt, preview.end),
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
                      ? 'El cambio se aplicará al siguiente ciclo y después '
                            'se renovará cada $_horizon días.'
                      : 'El cambio se aplicará al siguiente ciclo.',
                ),
                const SizedBox(height: 24),
                PixelButton(
                  label: _saving ? 'Guardando…' : 'Guardar cambio',
                  onPressed: _saving
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _saving = true);
                          final saved = await guardStoreWrite(
                            messenger,
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
        DropdownMenuItem(value: day, child: Text('Día $day')),
    ],
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );
}
