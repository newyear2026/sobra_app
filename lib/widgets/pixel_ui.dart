import 'package:flutter/material.dart';

import '../models/expense_entry.dart';
import '../theme/app_theme.dart';

/// U+2212. The typographic minus, so a negative amount lines up with the
/// digits around it. ASCII `-` is a hyphen and renders narrower.
const minusSign = '−';

String formatMoney(int centavos, {bool currency = true}) {
  final negative = centavos < 0;
  final absolute = centavos.abs();
  final pesos = absolute ~/ 100;
  final decimals = absolute % 100;
  final whole = pesos.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  final decimalPart = decimals == 0
      ? ''
      : '.${decimals.toString().padLeft(2, '0')}';
  return '${negative ? minusSign : ''}\$$whole$decimalPart'
      '${currency ? ' MXN' : ''}';
}

String _normalizeAmount(String input) => input
    .replaceAll(minusSign, '-')
    .replaceAll(RegExp(r'[^0-9,.-]'), '')
    .replaceAll(',', '.');

int? parsePesos(String input) {
  final value = double.tryParse(_normalizeAmount(input));
  if (value == null || value <= 0) return null;
  return (value * 100).round();
}

int? parseNonNegativePesos(String input) {
  final value = double.tryParse(_normalizeAmount(input));
  if (value == null || value < 0) return null;
  return (value * 100).round();
}

String shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

String shortTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';

/// The one set of month abbreviations. Anything that shortens a date reads
/// from here, so the same month never appears two ways in one list.
const monthAbbreviations = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String shortCycleDate(DateTime date) =>
    '${date.day} ${monthAbbreviations[date.month - 1]}';

String cycleDateRange(DateTime start, DateTime end) =>
    '${shortCycleDate(start)}–${shortCycleDate(end)}';

/// Depth steps.
///
/// A press consumes exactly one step: the surface travels down onto its own
/// shadow and the shadow disappears. That is how this design says "pressed" —
/// there is no ripple anywhere in the app.
abstract final class PixelDepth {
  static const shadowColor = Color(0x28202848);
  static const card = Offset(4, 4);
  static const hero = Offset(7, 7);
  static const button = Offset(0, 5);
}

enum PixelElevation {
  /// Sits flat on the page — list rows, secondary cards.
  none,

  /// The default card.
  card,

  /// One card per screen at most: the thing the screen is about.
  hero;

  Offset? get offset => switch (this) {
    PixelElevation.none => null,
    PixelElevation.card => PixelDepth.card,
    PixelElevation.hero => PixelDepth.hero,
  };
}

/// Wraps [builder] with pressed-state tracking and shifts it down by [travel]
/// while held, so a tap reads as the surface settling onto its shadow.
class _PressDown extends StatefulWidget {
  const _PressDown({
    required this.onTap,
    required this.travel,
    required this.builder,
  });

  final VoidCallback? onTap;
  final Offset travel;
  final Widget Function(BuildContext context, bool pressed) builder;

  @override
  State<_PressDown> createState() => _PressDownState();
}

class _PressDownState extends State<_PressDown> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final pressed = enabled && _pressed;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      child: Transform.translate(
        offset: pressed ? widget.travel : Offset.zero,
        child: widget.builder(context, pressed),
      ),
    );
  }
}

class PixelCard extends StatelessWidget {
  const PixelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = AppColors.surface,
    this.borderColor = AppColors.ink,
    this.onTap,
    this.elevation = PixelElevation.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;
  final PixelElevation elevation;

  @override
  Widget build(BuildContext context) {
    Widget surface({required bool pressed}) {
      final offset = elevation.offset;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor, width: 2.5),
          boxShadow: offset == null || pressed
              ? null
              : [BoxShadow(color: PixelDepth.shadowColor, offset: offset)],
        ),
        child: Padding(padding: padding, child: child),
      );
    }

    if (onTap == null) return surface(pressed: false);
    return _PressDown(
      onTap: onTap,
      travel: elevation.offset ?? const Offset(0, 2),
      builder: (context, pressed) => surface(pressed: pressed),
    );
  }
}

enum PixelButtonVariant {
  /// The one action the screen wants.
  primary,

  /// Everything alongside it — cancel, back, "do it later".
  secondary,

  /// Destructive.
  danger;

  Color get background => switch (this) {
    PixelButtonVariant.primary => AppColors.teal,
    PixelButtonVariant.secondary => AppColors.surface,
    PixelButtonVariant.danger => AppColors.danger,
  };

  Color get foreground => switch (this) {
    PixelButtonVariant.secondary => AppColors.ink,
    _ => Colors.white,
  };
}

class PixelButton extends StatelessWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = PixelButtonVariant.primary,
    this.color,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PixelButtonVariant variant;

  /// Overrides the variant's fill. Use only for the few buttons that carry a
  /// category or channel colour of their own.
  final Color? color;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final background = enabled ? (color ?? variant.background) : AppColors.line;
    final foreground = enabled ? variant.foreground : AppColors.muted;

    final button = _PressDown(
      onTap: onPressed,
      travel: PixelDepth.button,
      builder: (context, pressed) => DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: AppColors.ink, width: 2.5),
          boxShadow: pressed || !enabled
              ? null
              : const [
                  BoxShadow(color: AppColors.ink, offset: PixelDepth.button),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: foreground),
                const SizedBox(width: 9),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: pixelText(size: 16, bold: true, color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(
        width: expand ? double.infinity : null,
        // Reserve the shadow so the next widget does not sit under it.
        child: Padding(
          padding: EdgeInsets.only(bottom: PixelDepth.button.dy),
          child: button,
        ),
      ),
    );
  }
}

/// A segmented control in the pixel language.
///
/// Replaces Material's [SegmentedButton], whose stadium shape and tonal fills
/// are the loudest Material default in the app.
class PixelSegmented<T> extends StatelessWidget {
  const PixelSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<PixelSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    // Container, not DecoratedBox: the segments paint their own fills, and a
    // DecoratedBox draws its border behind the child, so those fills would
    // cover it. Container insets the child by the border width instead.
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ink, width: 2.5),
        color: AppColors.surface,
      ),
      child: Row(
        children: [
          for (final (index, segment) in segments.indexed)
            Expanded(
              child: Semantics(
                button: true,
                selected: segment.value == selected,
                label: segment.label,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(segment.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: segment.value == selected
                          ? AppColors.tealSoft
                          : AppColors.surface,
                      border: index == 0
                          ? null
                          : const Border(
                              left: BorderSide(
                                color: AppColors.ink,
                                width: 2.5,
                              ),
                            ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (segment.icon != null) ...[
                          Icon(
                            segment.value == selected
                                ? (segment.selectedIcon ?? segment.icon)
                                : segment.icon,
                            size: 19,
                            color: segment.value == selected
                                ? AppColors.tealInk
                                : AppColors.ink,
                          ),
                          const SizedBox(width: 7),
                        ],
                        Flexible(
                          child: Text(
                            segment.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: pixelText(
                              size: 14,
                              bold: true,
                              color: segment.value == selected
                                  ? AppColors.tealInk
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PixelSegment<T> {
  const PixelSegment({
    required this.value,
    required this.label,
    this.icon,
    this.selectedIcon,
  });

  final T value;
  final String label;
  final IconData? icon;
  final IconData? selectedIcon;
}

enum PixelHintTone {
  neutral,
  teal,
  cash,
  danger;

  Color get background => switch (this) {
    PixelHintTone.neutral => AppColors.paperLight,
    PixelHintTone.teal => AppColors.tealSoft,
    PixelHintTone.cash => AppColors.cashSoft,
    PixelHintTone.danger => AppColors.dangerSoft,
  };

  Color get ink => switch (this) {
    PixelHintTone.neutral => AppColors.inkSoft,
    PixelHintTone.teal => AppColors.tealInk,
    PixelHintTone.cash => AppColors.cashInk,
    PixelHintTone.danger => AppColors.dangerInk,
  };

  Color get border => switch (this) {
    PixelHintTone.neutral => AppColors.ink,
    _ => ink,
  };
}

/// An inline explanation that stays on screen.
///
/// Most of what the app has to say is a standing condition, not an event —
/// a SnackBar shows it for four seconds and then the answer is gone.
class PixelHint extends StatelessWidget {
  const PixelHint({
    super.key,
    required this.text,
    this.tone = PixelHintTone.neutral,
    this.icon = Icons.info_outline,
  });

  final String text;
  final PixelHintTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: tone.background,
        border: Border.all(color: tone.border, width: 2.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: tone.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: pixelText(size: 13, color: tone.ink, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// A square toggle.
///
/// Material's [Switch] is a stadium and its shape is not themeable, so it was
/// the last rounded object left in a design with no rounded objects.
class PixelSwitch extends StatelessWidget {
  const PixelSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    const height = 30.0;
    const width = 56.0;
    const knob = height - 9;
    final enabled = onChanged != null;

    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: !enabled
                ? AppColors.line
                : value
                ? AppColors.teal
                : AppColors.surface,
            border: Border.all(color: AppColors.ink, width: 2.5),
          ),
          child: Align(
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: knob,
              height: knob,
              decoration: BoxDecoration(
                color: value ? AppColors.surface : AppColors.line,
                border: Border.all(color: AppColors.ink, width: 2.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What a list says before it has anything in it.
class PixelEmptyState extends StatelessWidget {
  const PixelEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
  });

  final String title;
  final String? message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _DashedBorderPainter(),
      child: Container(
        width: double.infinity,
        color: AppColors.paperLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 30, color: AppColors.muted),
              const SizedBox(height: 10),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: pixelText(size: 14, bold: true),
            ),
            if (message != null) ...[
              const SizedBox(height: 5),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: pixelText(
                  size: 12,
                  color: AppColors.muted,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false;
    const dash = 7.0;
    const gap = 5.0;

    void run(Offset from, Offset to) {
      final total = (to - from).distance;
      final step = (to - from) / total;
      var travelled = 0.0;
      while (travelled < total) {
        final end = (travelled + dash).clamp(0.0, total);
        canvas.drawLine(from + step * travelled, from + step * end, paint);
        travelled = end + gap;
      }
    }

    final topLeft = Offset.zero;
    final topRight = Offset(size.width, 0);
    final bottomRight = Offset(size.width, size.height);
    final bottomLeft = Offset(0, size.height);
    run(topLeft, topRight);
    run(topRight, bottomRight);
    run(bottomRight, bottomLeft);
    run(bottomLeft, topLeft);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}

class PixelTopBar extends StatelessWidget {
  const PixelTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // A pushed screen centres a smaller title between its back arrow and its
    // trailing slot; a root tab keeps the large left-aligned wordmark.
    final pushed = onBack != null;
    return Row(
      children: [
        if (pushed)
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 28),
            color: AppColors.ink,
            tooltip: 'Volver',
          ),
        Expanded(
          child: Text(
            title,
            textAlign: pushed ? TextAlign.center : TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: pixelText(size: pushed ? 20 : 28, bold: true),
          ),
        ),
        if (trailing != null)
          trailing!
        else if (pushed)
          const SizedBox(width: 48),
      ],
    );
  }
}

class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({
    super.key,
    required this.value,
    this.danger = false,
  });

  final double value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    const segments = 12;
    final filled = (value.clamp(0, 1) * segments).ceil();
    return Semantics(
      label: 'Progreso ${(value * 100).round()} por ciento',
      child: Container(
        height: 20,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.ink, width: 2.5),
        ),
        child: Row(
          children: List.generate(segments, (index) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == segments - 1 ? 0 : 2),
                color: index < filled
                    ? (danger ? AppColors.danger : AppColors.teal)
                    : AppColors.line,
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Progress through a multi-step flow.
class PixelSteps extends StatelessWidget {
  const PixelSteps({super.key, required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Paso ${current + 1} de $total',
      child: Row(
        children: [
          for (var index = 0; index < total; index++) ...[
            if (index > 0) const SizedBox(width: 5),
            Expanded(
              child: Container(
                height: 5,
                color: index <= current ? AppColors.teal : AppColors.line,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

IconData categoryIcon(ExpenseCategory category) => switch (category) {
  ExpenseCategory.food => Icons.ramen_dining,
  ExpenseCategory.transport => Icons.directions_bus,
  ExpenseCategory.shopping => Icons.shopping_bag,
  ExpenseCategory.home => Icons.home,
  ExpenseCategory.services => Icons.receipt_long,
  ExpenseCategory.health => Icons.medical_services,
  ExpenseCategory.education => Icons.school,
  ExpenseCategory.entertainment => Icons.sports_esports,
  ExpenseCategory.pets => Icons.pets,
  ExpenseCategory.other => Icons.more_horiz,
};

Color categoryColor(ExpenseCategory category) => switch (category) {
  ExpenseCategory.food => AppColors.danger,
  ExpenseCategory.transport => AppColors.blue,
  ExpenseCategory.shopping => AppColors.violet,
  ExpenseCategory.home => AppColors.teal,
  ExpenseCategory.services => AppColors.cash,
  ExpenseCategory.health => AppColors.rose,
  ExpenseCategory.education => AppColors.indigo,
  ExpenseCategory.entertainment => AppColors.plum,
  ExpenseCategory.pets => AppColors.green,
  ExpenseCategory.other => AppColors.slate,
};

/// The tint behind a category's icon.
///
/// Fixed values rather than `categoryColor.withValues(alpha: .13)`: the ten
/// accents differ enough in saturation that a single alpha gives ten tints of
/// visibly different strength.
Color categorySoftColor(ExpenseCategory category) => switch (category) {
  ExpenseCategory.food => AppColors.dangerSoft,
  ExpenseCategory.transport => AppColors.blueSoft,
  ExpenseCategory.shopping => AppColors.violetSoft,
  ExpenseCategory.home => AppColors.tealSoft,
  ExpenseCategory.services => AppColors.cashSoft,
  ExpenseCategory.health => const Color(0xFFF7DFE6),
  ExpenseCategory.education => const Color(0xFFE0E4F3),
  ExpenseCategory.entertainment => const Color(0xFFEEDFEC),
  ExpenseCategory.pets => const Color(0xFFDEEADF),
  ExpenseCategory.other => const Color(0xFFE3E5EA),
};

class CategoryIconBox extends StatelessWidget {
  const CategoryIconBox({super.key, required this.category, this.size = 42});

  final ExpenseCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: categorySoftColor(category),
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: Icon(
        categoryIcon(category),
        color: categoryColor(category),
        size: size * .55,
      ),
    );
  }
}
