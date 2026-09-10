import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/currency.dart';
import '../models/pay_schedule.dart';
import '../state/sobra_store.dart';
import '../models/expense_entry.dart';
import '../theme/app_theme.dart';

/// U+2212. The typographic minus, so a negative amount lines up with the
/// digits around it. ASCII `-` is a hyphen and renders narrower.
const minusSign = '−';

/// Writes an amount of minor units the way Sobra shows money.
///
/// Both languages Sobra ships — Mexican Spanish and American English — group
/// with commas and separate decimals with a dot, so the separators are fixed
/// here rather than read from the locale. A locale that groups the other way
/// around would have to make them a setting of their own.
///
/// [showCode] drops the currency code for figures that sit beside another one
/// already carrying it, such as the two halves of a category limit.
String formatMoney(Currency currency, int minorUnits, {bool showCode = true}) {
  final negative = minorUnits < 0;
  final absolute = minorUnits.abs();
  final units = absolute ~/ Currency.minorUnitsPerUnit;
  final decimals = absolute % Currency.minorUnitsPerUnit;
  final whole = units.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  final decimalPart = decimals == 0
      ? ''
      : '.${decimals.toString().padLeft(2, '0')}';
  return '${negative ? minusSign : ''}${currency.symbol}$whole$decimalPart'
      '${showCode ? ' ${currency.code}' : ''}';
}

String? _normalizeAmount(String input) {
  var value = input
      .replaceAll(minusSign, '-')
      .replaceAll(RegExp(r'[^0-9,.-]'), '');
  if (value.isEmpty || value == '-' || value.indexOf('-') > 0) return null;
  if ('-'.allMatches(value).length > 1) return null;

  final sign = value.startsWith('-') ? '-' : '';
  if (sign.isNotEmpty) value = value.substring(1);
  if (value.isEmpty || !RegExp(r'\d').hasMatch(value)) return null;

  final commaCount = ','.allMatches(value).length;
  final dotCount = '.'.allMatches(value).length;
  String integerPart;
  String fractionPart = '';

  if (commaCount > 0 && dotCount > 0) {
    // Accept both 1,234.56 (MX) and 1.234,56. The last separator is the
    // decimal separator; the other occurrences are grouping separators.
    final decimalIndex = value.lastIndexOf(',') > value.lastIndexOf('.')
        ? value.lastIndexOf(',')
        : value.lastIndexOf('.');
    integerPart = value
        .substring(0, decimalIndex)
        .replaceAll(RegExp(r'[,.]'), '');
    fractionPart = value.substring(decimalIndex + 1);
  } else if (commaCount > 0) {
    final parts = value.split(',');
    final looksGrouped =
        parts.length > 1 &&
        parts.first.isNotEmpty &&
        parts.first.length <= 3 &&
        parts.skip(1).every((part) => part.length == 3);
    if (looksGrouped) {
      integerPart = parts.join();
    } else if (parts.length == 2 && parts.last.length <= 2) {
      // Decimal comma is accepted for pasted values, while 1,200 remains one
      // thousand two hundred rather than silently becoming 1.20.
      integerPart = parts.first;
      fractionPart = parts.last;
    } else {
      return null;
    }
  } else if (dotCount > 0) {
    if (dotCount != 1) return null;
    final decimalIndex = value.indexOf('.');
    integerPart = value.substring(0, decimalIndex);
    fractionPart = value.substring(decimalIndex + 1);
  } else {
    integerPart = value;
  }

  if (integerPart.isEmpty) integerPart = '0';
  if (!RegExp(r'^\d+$').hasMatch(integerPart) ||
      (fractionPart.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fractionPart))) {
    return null;
  }
  return '$sign$integerPart${fractionPart.isEmpty ? '' : '.$fractionPart'}';
}

int? parseAmount(String input) {
  final normalized = _normalizeAmount(input);
  final value = normalized == null ? null : double.tryParse(normalized);
  if (value == null || !value.isFinite || value <= 0) return null;
  return (value * 100).round();
}

int? parseNonNegativeAmount(String input) {
  final normalized = _normalizeAmount(input);
  final value = normalized == null ? null : double.tryParse(normalized);
  if (value == null || !value.isFinite || value < 0) return null;
  return (value * 100).round();
}

/// Runs a store write and shows why it failed if it throws.
///
/// Every mutation on the store ends in a save that raises rather than
/// returning false, so without this the one thing the user cares about —
/// whether their money got written down — fails as an unhandled async error
/// behind a screen that looks like it worked. Returns whether the write
/// landed, so a caller can hold back its own success message.
///
/// Takes the messenger rather than a [BuildContext] on purpose: a write that
/// closes its own screen, or a Deshacer tapped after the row is gone, has no
/// context left to read one from by the time the answer arrives.
Future<bool> guardStoreWrite(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  Future<void> Function() write,
) async {
  try {
    await write();
    return true;
  } on Object catch (error) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(describeStoreFailure(l10n, error))),
      );
    return false;
  }
}

String shortTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';

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
            tooltip: AppLocalizations.of(context).back,
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
      label: AppLocalizations.of(
        context,
      ).progressPercent((value * 100).round()),
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
      label: AppLocalizations.of(context).stepOf(current + 1, total),
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

/// The one date field in the app: a fortnight is anchored on a real day.
///
/// Only the past is offerable — "when were you last paid" has no answer in
/// the future, and an anchor ahead of today would put the current cycle in a
/// window that has not started.
class PaydayField extends StatelessWidget {
  const PaydayField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = SobraScope.of(context).today;
    return PixelCard(
      elevation: PixelElevation.none,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(today.year - 1),
          lastDate: today,
        );
        if (picked != null) onChanged(dateOnly(picked));
      },
      child: Row(
        children: [
          const Icon(Icons.event, color: AppColors.violet),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  fullDate(l10n, value),
                  style: pixelText(size: 15, bold: true),
                ),
              ],
            ),
          ),
          Text(l10n.pickDate, style: pixelText(size: 12, bold: true)),
        ],
      ),
    );
  }
}

/// Which category owns each block of [CategoryRing], or null for a block that
/// has not been spent yet.
///
/// Rounding up matches [SegmentedProgress]: any spending at all claims a
/// block, because a ring reading empty next to a non-zero figure is worse than
/// one block of overstatement. Blocks are handed out largest-remainder, so the
/// coloured run is always exactly as long as the filled run — a category can
/// lose its block to rounding, but the ring can never gain or drop one.
///
/// Over budget every block is filled; the figure beside the ring is what says
/// by how much, because the ring has no room left to say it.
@visibleForTesting
List<ExpenseCategory?> categoryRingSegments({
  required Map<ExpenseCategory, int> spentByCategory,
  required int budgetCentavos,
  int segments = 12,
}) {
  final result = List<ExpenseCategory?>.filled(segments, null);
  final spent = spentByCategory.values.fold(0, (sum, value) => sum + value);
  if (budgetCentavos <= 0 || spent <= 0) return result;

  final filled = math.min(segments, (spent / budgetCentavos * segments).ceil());

  final ranked = spentByCategory.entries.where((e) => e.value > 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final exact = {
    for (final entry in ranked) entry.key: entry.value / spent * filled,
  };
  final blocks = {
    for (final entry in exact.entries) entry.key: entry.value.floor(),
  };
  var spare = filled - blocks.values.fold(0, (sum, value) => sum + value);
  final byRemainder = [
    ...exact.keys,
  ]..sort((a, b) => (exact[b]! - blocks[b]!).compareTo(exact[a]! - blocks[a]!));
  for (final category in byRemainder) {
    if (spare <= 0) break;
    blocks[category] = blocks[category]! + 1;
    spare--;
  }

  var index = 0;
  for (final entry in ranked) {
    for (var n = 0; n < blocks[entry.key]!; n++) {
      if (index < filled) result[index++] = entry.key;
    }
  }
  return result;
}

/// The cycle's budget as one ring: how much is gone, and what it went on.
///
/// The blocks carry the same colours the category icons do, so the ring reads
/// without a legend — somebody who knows the red bowl is Comida already knows
/// the red block is too.
class CategoryRing extends StatelessWidget {
  const CategoryRing({
    super.key,
    required this.spentByCategory,
    required this.budgetCentavos,
    this.diameter = 104,
  });

  final Map<ExpenseCategory, int> spentByCategory;
  final int budgetCentavos;
  final double diameter;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: diameter,
    height: diameter,
    child: CustomPaint(
      painter: _CategoryRingPainter(
        categoryRingSegments(
          spentByCategory: spentByCategory,
          budgetCentavos: budgetCentavos,
        ),
      ),
    ),
  );
}

class _CategoryRingPainter extends CustomPainter {
  const _CategoryRingPainter(this.segments);

  final List<ExpenseCategory?> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final outerR = size.shortestSide / 2 - 2;
    final innerR = outerR * 0.6;
    final outer = Rect.fromCircle(center: centre, radius: outerR);
    final inner = Rect.fromCircle(center: centre, radius: innerR);

    const gap = 0.09;
    final step = 2 * math.pi / segments.length;
    final sweep = step - gap;
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.miter
      ..color = AppColors.ink;

    for (var i = 0; i < segments.length; i++) {
      // Start at twelve o'clock so the biggest category reads first.
      final start = -math.pi / 2 + i * step + gap / 2;
      final path = Path()
        ..arcTo(outer, start, sweep, true)
        ..arcTo(inner, start + sweep, -sweep, false)
        ..close();
      final category = segments[i];
      canvas
        ..drawPath(
          path,
          Paint()
            ..color = category == null
                ? AppColors.beige
                : categoryColor(category),
        )
        ..drawPath(path, border);
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryRingPainter oldDelegate) =>
      !listEquals(oldDelegate.segments, segments);
}

/// One day of a cycle, as the daily chart needs it.
@immutable
class DailySpend {
  const DailySpend({
    required this.day,
    required this.centavos,
    required this.isFuture,
    required this.isToday,
  });

  final DateTime day;
  final int centavos;

  /// A day the cycle has not reached. Drawn differently from a day that came
  /// and went without a peso: "nothing yet" and "nothing at all" are answers
  /// to different questions, and a chart that draws them the same is lying to
  /// whichever one the reader had in mind.
  final bool isFuture;
  final bool isToday;

  @override
  bool operator ==(Object other) =>
      other is DailySpend &&
      other.day == day &&
      other.centavos == centavos &&
      other.isFuture == isFuture &&
      other.isToday == isToday;

  @override
  int get hashCode => Object.hash(day, centavos, isFuture, isToday);
}

/// Every day of [bounds], with what was spent on it.
///
/// Days with nothing on them are kept rather than dropped: the gaps are the
/// point of the chart, and a bar per day only lines up with the calendar if
/// the quiet days hold their place.
List<DailySpend> dailySpend({
  required CycleBounds bounds,
  required Iterable<ExpenseEntry> entries,
  required DateTime today,
}) {
  final start = dateOnly(bounds.start);
  final now = dateOnly(today);
  final totals = List<int>.filled(bounds.lengthInDays, 0);
  for (final entry in entries) {
    final index = dateOnly(entry.occurredAt).difference(start).inDays;
    if (index >= 0 && index < totals.length) {
      totals[index] += entry.amountCentavos;
    }
  }
  return [
    for (var i = 0; i < totals.length; i++)
      DailySpend(
        day: DateTime(start.year, start.month, start.day + i),
        centavos: totals[i],
        isFuture: DateTime(start.year, start.month, start.day + i).isAfter(now),
        isToday: DateTime(start.year, start.month, start.day + i) == now,
      ),
  ];
}

/// A block per day of the cycle, against the day's share of the budget.
///
/// Blocks rather than a line, because every other quantity in this app is
/// drawn as blocks — and because a cycle is a couple of dozen days at most,
/// which is few enough to show one by one.
class DailySpendChart extends StatelessWidget {
  const DailySpendChart({
    super.key,
    required this.days,
    required this.dailyLimitCentavos,
  });

  final List<DailySpend> days;
  final int dailyLimitCentavos;

  static const _barsHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final peak = [
      dailyLimitCentavos,
      ...days.map((day) => day.centavos),
    ].reduce(math.max);
    final limitTop = peak <= 0
        ? _barsHeight
        : _barsHeight * (1 - dailyLimitCentavos / peak);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _barsHeight,
          child: Stack(
            children: [
              // What one day is worth, so a red block reads as "over this"
              // rather than merely "bigger than the others".
              if (dailyLimitCentavos > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  top: limitTop,
                  child: Container(height: 1.5, color: AppColors.muted),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < days.length; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      child: _Bar(
                        day: days[i],
                        peak: peak,
                        limit: dailyLimitCentavos,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // The today marker sits under the bars, on the same grid, so it points
        // at a column instead of floating near one.
        Row(
          children: [
            for (var i = 0; i < days.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 4,
                  color: days[i].isToday ? AppColors.ink : Colors.transparent,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.day, required this.peak, required this.limit});

  final DailySpend day;
  final int peak;
  final int limit;

  @override
  Widget build(BuildContext context) {
    if (day.centavos <= 0) {
      // A stub either way, but a paler one for a day that has not happened.
      return Container(
        height: 3,
        color: day.isFuture ? AppColors.beige : AppColors.muted,
      );
    }
    final height = peak <= 0
        ? 0.0
        : math.max(6.0, DailySpendChart._barsHeight * day.centavos / peak);
    final over = limit > 0 && day.centavos > limit;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: over ? AppColors.danger : AppColors.teal,
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
    );
  }
}
