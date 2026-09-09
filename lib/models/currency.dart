/// The currencies Sobra can label money in.
///
/// This is the unit the user reads, not a rate: switching relabels the figures
/// already saved and never converts them. Sobra tracks what somebody counted
/// in their own pocket, and there is no honest exchange rate to apply to a
/// cash count from three weeks ago.
///
/// All three prefix the same `$`, so the code beside the figure is doing real
/// work here rather than decorating it — `$1,200` is three very different
/// amounts of money across this list.
enum Currency {
  mxn('MXN'),
  usd('USD'),
  cad('CAD');

  const Currency(this.code);

  /// The ISO code shown next to an amount, and what gets saved.
  final String code;

  /// The symbol before the digits. The same for all three today; it is a field
  /// rather than a constant because that is a fact about these currencies, not
  /// about currencies.
  String get symbol => r'$';

  /// Every currency on this list splits into 100.
  ///
  /// This is load-bearing, not a coincidence: amounts are stored as a plain
  /// integer of minor units, and helpers named `…Centavos` are that integer.
  /// A currency with no subdivision (the won, the yen) or a different one
  /// would silently misread every row already saved — off by a factor of a
  /// hundred, with no error anywhere. Adding one is a storage migration
  /// first and a new entry here second.
  static const minorUnitsPerUnit = 100;

  /// Falls back to Mexican pesos, which is what saved data written before
  /// this setting existed means.
  static Currency fromCode(String? code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => Currency.mxn,
  );
}
