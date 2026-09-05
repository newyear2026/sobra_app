import 'package:flutter/material.dart';

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

  int? get _actual => parseNonNegativePesos(_controller.text);

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
        const SnackBar(content: Text('Elige qué pasó con la diferencia.')),
      );
      return;
    }
    setState(() => _saving = true);
    XpNotice? xpNotice;
    try {
      await store.reconcileCashCount(
        actualCentavos: actual,
        resolution: resolution,
        category: _category,
        note: _noteController.text,
        incomeAllocation: _incomeAllocation,
      );
      xpNotice = store.takePendingXpNotice();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        xpNotice == null
            ? const SnackBar(
                content: Text('Conteo guardado sin duplicar movimientos.'),
              )
            : xpSnackBar(xpNotice),
      );
  }

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
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
                  title: 'Conteo de efectivo',
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 12),
                Text(
                  store.hasCashBaseline
                      ? 'Cuenta solo el efectivo que tienes ahora.'
                      : 'Sin conteo todavía',
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
                  decoration: const InputDecoration(
                    prefixText: '\$',
                    hintText: '—',
                    suffixText: 'MXN',
                  ),
                ),
                const SizedBox(height: 18),
                if (actual == null)
                  const PixelCard(
                    elevation: PixelElevation.none,
                    color: AppColors.cashSoft,
                    borderColor: AppColors.cashInk,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.cashInk),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'El resultado aparecerá después de escribir '
                            'el conteo.',
                            style: TextStyle(
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
                  const PixelCard(
                    elevation: PixelElevation.none,
                    color: AppColors.tealSoft,
                    borderColor: AppColors.tealInk,
                    child: Text(
                      'Este será tu punto de partida. '
                      'No se registrará como ingreso.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                          label: 'Esperábamos',
                          value: store.expectedCashCentavos,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AmountCard(label: 'Contaste', value: actual),
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
                          ? 'Todo cuadra'
                          : isMissing
                          ? 'Faltan ${formatMoney(difference.abs())}'
                          : 'Hay ${formatMoney(difference!.abs())} de más',
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
                      '¿Qué pasó?',
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
                        label: option.label,
                        helper: switch (option) {
                          CashResolution.expense =>
                            'Fue un gasto que no habías registrado.',
                          CashResolution.income =>
                            'Fue dinero nuevo que recibiste.',
                          CashResolution.transfer =>
                            isMissing
                                ? 'Lo depositaste o lo moviste a otra cuenta.'
                                : 'Lo retiraste o lo moviste desde otra cuenta.',
                          CashResolution.correction =>
                            'El conteo anterior estaba equivocado.',
                          CashResolution.pending => 'Decídelo después.',
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
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                        ),
                        items: ExpenseCategory.values
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category.label),
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
                        decoration: const InputDecoration(
                          labelText: 'Nota',
                          hintText: 'Ej. Tacos',
                        ),
                      ),
                      const SizedBox(height: 10),
                      const PixelHint(
                        tone: PixelHintTone.teal,
                        text:
                            'Esto crea un solo gasto. No tendrás que '
                            'registrarlo otra vez.',
                      ),
                    ],
                    if (_resolution == CashResolution.income) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Nota',
                          hintText: 'Ej. Propina',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '¿Qué hacemos con este dinero?',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      PixelSegmented<IncomeAllocation>(
                        segments: const [
                          PixelSegment(
                            value: IncomeAllocation.cycle,
                            label: 'Este ciclo',
                          ),
                          PixelSegment(
                            value: IncomeAllocation.savings,
                            label: 'Guardarlo',
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
                      ? 'Guardando…'
                      : !store.hasCashBaseline
                      ? 'Guardar primer conteo'
                      : 'Guardar conteo',
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
  Widget build(BuildContext context) => PixelCard(
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
            formatMoney(value),
            style: pixelText(size: 19, bold: true),
          ),
        ),
      ],
    ),
  );
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
