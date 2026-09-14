import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/currency.dart';
import '../models/pay_schedule.dart';
import '../state/sobra_store.dart';
import '../models/expense_entry.dart';
import '../models/income_entry.dart';
import '../theme/app_theme.dart';

/// U+2212. The typographic minus, so a negative amount lines up with the
/// digits around it. ASCII `-` is a hyphen and renders narrower.
const minusSign = '−';

/// Stands where a figure would go when there is none to show.
///
/// Not a zero: zero is a measurement, and this is the absence of one.
const emDash = '—';

/// Height of the five-tab bar, not counting the device's bottom safe inset.
///
/// XP toasts have to sit above this or they cover the + tile.
const kPixelBottomBarHeight = 72.0;

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
  final whole = _groupDigits(
    (absolute ~/ Currency.minorUnitsPerUnit).toString(),
  );
  final decimals = absolute % Currency.minorUnitsPerUnit;
  final decimalPart = decimals == 0
      ? ''
      : '.${decimals.toString().padLeft(2, '0')}';
  return '${negative ? minusSign : ''}${currency.symbol}$whole$decimalPart'
      '${showCode ? ' ${currency.code}' : ''}';
}

/// Writes [minorUnits] the way an amount field holds it.
///
/// The digits [formatMoney] would print, without the symbol or the code: a
/// field carries those in its prefix and suffix, and [AmountInputFormatter]
/// strips them out of the text anyway. Use it wherever a field opens on an
/// existing figure, so what it shows first is already the shape typing
/// produces — and so a field opened on $1,200.50 and saved untouched does not
/// hand back $1,201.
String amountFieldText(int minorUnits) {
  final absolute = minorUnits.abs();
  final whole = _groupDigits(
    (absolute ~/ Currency.minorUnitsPerUnit).toString(),
  );
  final decimals = absolute % Currency.minorUnitsPerUnit;
  return decimals == 0
      ? whole
      : '$whole.${decimals.toString().padLeft(2, '0')}';
}

/// Puts a comma every three digits, counting from the right.
String _groupDigits(String digits) =>
    digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');

/// The most digits an amount may carry ahead of the decimal point.
///
/// Twelve is past any figure a household budget holds, and it keeps the
/// centavos — and every sum built on them — clear of the far end of int64,
/// where a pasted string of twenty digits used to land as 92,233,720,368,547.
const _maxAmountDigits = 12;

/// Keeps an amount field in the shape [formatMoney] prints.
///
/// Without it a field took whatever the keyboard sent and left the reading to
/// [parseAmount], which drops what it cannot understand: `9,,,,`, `9abc` and
/// `$9` all registered as nine pesos, and `1e3` as thirteen. Here the grouping
/// commas are placed rather than typed, so a separator the user enters can
/// only mean the decimal point and there is only ever one of it. What the
/// field shows is what gets registered.
class AmountInputFormatter extends TextInputFormatter {
  const AmountInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    final insertedAt = _insertedAt(oldValue.text, text);
    if (insertedAt >= 0 && text[insertedAt] == ',') {
      // A keyboard that offers a comma where the point should be is offering
      // the decimal key, not a grouping separator: those this formatter
      // places itself.
      text = text.replaceRange(insertedAt, insertedAt + 1, '.');
    }
    // Nothing but digits and separators reaches the field, so a pasted
    // "$1,200.50 MXN" keeps its figure and loses the rest of itself.
    final cleaned = text.replaceAll(RegExp(r'[^0-9.,]'), '');
    if (cleaned.isEmpty) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // A figure that arrived whole is read the generous way [parseAmount]
    // reads it. One being typed is read against what the field already holds,
    // where every comma is this formatter's own grouping and the first point
    // is the decimal one — so a fifth digit typed onto 1,234 makes 12,345
    // rather than being taken for the decimals of one peso.
    final point = (text.length - oldValue.text.length).abs() > 1
        ? _wholeDecimalIndex(cleaned)
        : cleaned.indexOf('.');

    final ahead = point < 0 ? cleaned : cleaned.substring(0, point);
    final integerDigits = ahead.replaceAll(RegExp(r'[.,]'), '');
    // A thirteenth digit is refused rather than dropped: keeping twelve of a
    // pasted figure would register a number nobody typed.
    if (integerDigits.length > _maxAmountDigits) return oldValue;

    final trimmed = integerDigits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final rest = point < 0
        ? ''
        : cleaned.substring(point + 1).replaceAll(RegExp(r'[^0-9]'), '');
    final fraction = rest.substring(0, math.min(rest.length, 2));
    final whole = _groupDigits(trimmed.isEmpty ? '0' : trimmed);
    final formatted = point < 0 ? whole : '$whole.$fraction';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _caretFor(
          oldValue,
          newValue,
          text,
          formatted,
          insertedAt,
          integerDigits,
          trimmed,
        ),
      ),
    );
  }

  /// Where to leave the caret once [formatted] has replaced what was typed.
  int _caretFor(
    TextEditingValue oldValue,
    TextEditingValue newValue,
    String text,
    String formatted,
    int insertedAt,
    String integerDigits,
    String trimmed,
  ) {
    // The decimal key puts the caret past the point it just made, so the next
    // digit typed is a centavo.
    if (insertedAt >= 0 &&
        text[insertedAt] == '.' &&
        !oldValue.text.contains('.')) {
      return formatted.indexOf('.') + 1;
    }
    final caret = newValue.selection.end < 0
        ? text.length
        : newValue.selection.end;
    // The zero standing in front of a bare decimal point was not typed
    // either, so it too belongs behind the caret.
    final synthesized = trimmed.isEmpty ? 1 : 0;
    return _caretAfterDigits(
      formatted,
      _digitsBefore(text, caret) +
          synthesized -
          (integerDigits.length - trimmed.length),
    );
  }

  /// Where the decimal point falls in a figure that arrived whole, or -1.
  ///
  /// The reading [parseAmount] gives a pasted string: with both separators
  /// present the last one takes the decimals, a lone point always does, and a
  /// lone comma only when what it separates cannot be groups of three.
  int _wholeDecimalIndex(String cleaned) {
    final dot = cleaned.lastIndexOf('.');
    final comma = cleaned.lastIndexOf(',');
    if (dot >= 0) return comma > dot ? comma : dot;
    if (comma < 0) return -1;
    final parts = cleaned.split(',');
    final grouped =
        parts.first.isNotEmpty &&
        parts.first.length <= 3 &&
        parts.skip(1).every((part) => part.length == 3);
    return grouped ? -1 : comma;
  }

  /// Where [newText] gained its one new character over [oldText], or -1 when
  /// the change was anything else — a deletion, a paste, a field filled in.
  int _insertedAt(String oldText, String newText) {
    if (newText.length != oldText.length + 1) return -1;
    var i = 0;
    while (i < oldText.length &&
        oldText.codeUnitAt(i) == newText.codeUnitAt(i)) {
      i++;
    }
    return oldText.substring(i) == newText.substring(i + 1) ? i : -1;
  }

  /// How many digits of [text] sit left of [offset].
  ///
  /// The caret is held by its place among the digits rather than by its
  /// index, which shifts every time a grouping comma appears or leaves.
  int _digitsBefore(String text, int offset) {
    if (offset <= 0) return 0;
    final head = text.substring(0, math.min(offset, text.length));
    return RegExp(r'\d').allMatches(head).length;
  }

  /// Where the caret sits in [text] once [digits] of it are behind it.
  int _caretAfterDigits(String text, int digits) {
    if (digits <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < text.length; i++) {
      if (!_isDigit(text.codeUnitAt(i))) continue;
      if (++seen < digits) continue;
      // Whatever trails the last digit is the decimal point just typed — a
      // grouping comma cannot end the text — so the caret goes behind it.
      return RegExp(r'\d').hasMatch(text.substring(i + 1))
          ? i + 1
          : text.length;
    }
    return text.length;
  }

  bool _isDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39;
}

/// What every amount field runs its input through. See [AmountInputFormatter].
const amountInputFormatters = <TextInputFormatter>[AmountInputFormatter()];

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

/// Reads [input] as a figure of money, or null when it does not read as one.
///
/// Counts the centavos out of the digits rather than multiplying a double by
/// a hundred, which is how 0.001 used to come back as an amount of nothing.
int? _parseMinorUnits(String input) {
  final normalized = _normalizeAmount(input);
  if (normalized == null) return null;
  final negative = normalized.startsWith('-');
  final body = negative ? normalized.substring(1) : normalized;
  final point = body.indexOf('.');
  final integerPart = point < 0 ? body : body.substring(0, point);
  final fractionPart = point < 0 ? '' : body.substring(point + 1);
  // Finer than a centavo is not a sum of money, and rounding it quietly is
  // how 9.999 became ten pesos. Too many digits ahead of the point is not one
  // either: it overflows before anyone reads it.
  if (fractionPart.length > 2 || integerPart.length > _maxAmountDigits) {
    return null;
  }
  final units = int.tryParse(integerPart);
  if (units == null) return null;
  final minorUnits =
      units * Currency.minorUnitsPerUnit +
      int.parse(fractionPart.padRight(2, '0'));
  return negative ? -minorUnits : minorUnits;
}

int? parseAmount(String input) {
  final value = _parseMinorUnits(input);
  return value == null || value <= 0 ? null : value;
}

int? parseNonNegativeAmount(String input) {
  final value = _parseMinorUnits(input);
  return value == null || value < 0 ? null : value;
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
}) => dailyTotals(
  bounds: bounds,
  today: today,
  amounts: [
    for (final entry in entries) (entry.occurredAt, entry.amountCentavos),
  ],
);

/// Every day of [bounds], with what came in on it.
List<DailySpend> dailyIncome({
  required CycleBounds bounds,
  required Iterable<IncomeEntry> entries,
  required DateTime today,
}) => dailyTotals(
  bounds: bounds,
  today: today,
  amounts: [
    for (final entry in entries) (entry.occurredAt, entry.amountCentavos),
  ],
);

List<DailySpend> dailyTotals({
  required CycleBounds bounds,
  required DateTime today,
  required Iterable<(DateTime occurredAt, int amountCentavos)> amounts,
}) {
  final start = dateOnly(bounds.start);
  final now = dateOnly(today);
  final totals = List<int>.filled(bounds.lengthInDays, 0);
  for (final amount in amounts) {
    final index = dateOnly(amount.$1).difference(start).inDays;
    if (index >= 0 && index < totals.length) {
      totals[index] += amount.$2;
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
