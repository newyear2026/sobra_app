/// The currencies Sobra can label money in.
///
/// This is the unit the user reads, not a rate: switching relabels the figures
/// already saved and never converts them. Sobra tracks what somebody counted
/// in their own pocket, and there is no honest exchange rate to apply to a
/// cash count from three weeks ago.
///
/// Six of these share `$`, so the code beside those figures is doing real
/// work — `$1,200` is six different amounts of money, and two of them are not
/// within an order of magnitude of each other. The pound, the sol, the euro
/// and the yen carry their own sign, and still print their code so a figure
/// always names the unit.
///
/// Grouped by where they are spent rather than added as they arrived: the
/// picker lists them in this order, and the pesos are worth reading next to
/// each other. Nothing is stored by position — the code is what gets saved —
/// so this list can be reordered freely.
enum Currency {
  // The Americas.
  mxn('MXN', r'$'),
  usd('USD', r'$'),
  cad('CAD', r'$'),
  cop('COP', r'$'),
  ars('ARS', r'$'),
  clp('CLP', r'$', decimalDigits: 0),
  pen('PEN', 'S/'),
  // Europe.
  eur('EUR', '€'),
  gbp('GBP', '£'),
  // Asia.
  jpy('JPY', '¥', decimalDigits: 0);

  const Currency(this.code, this.symbol, {this.decimalDigits = 2});

  /// The ISO code shown next to an amount, and what gets saved.
  final String code;

  /// The symbol before the digits.
  final String symbol;

  /// How many digits this currency writes behind the decimal point.
  ///
  /// Zero for the yen and the Chilean peso, which have no subdivision anybody
  /// spends: ¥100 is a hundred yen, not one. This governs what gets printed
  /// and what an amount field will accept — never what gets stored. See
  /// [minorUnitsPerUnit].
  ///
  /// Two rather than zero for the Colombian and Argentine pesos, whose
  /// centavos are gone from circulation but not from the standard. Costing
  /// them nothing: a figure with no hundredths prints none either way, so
  /// they read as whole pesos in practice while a relabelled amount keeps
  /// what it arrived with.
  final int decimalDigits;

  /// What one whole unit is stored as, for every currency on this list.
  ///
  /// Amounts are a plain integer of hundredths and the helpers named
  /// `…Centavos` are that integer, so this being the same number everywhere is
  /// what lets a saved row mean one thing regardless of the label in force
  /// when it was written, and what lets switching the label leave the ledger
  /// untouched. A yen is stored as 100 of these and no screen ever says so.
  ///
  /// Making this per-currency is the tempting shape and the wrong one: it
  /// would rewrite the meaning of every row already saved — off by a factor of
  /// a hundred, with no error anywhere — and every backup ever exported. A
  /// currency with no subdivision costs [decimalDigits] instead, which is a
  /// display rule and rewrites nothing.
  static const minorUnitsPerUnit = 100;

  /// Falls back to Mexican pesos, which is what saved data written before
  /// this setting existed means.
  static Currency fromCode(String? code) => values.firstWhere(
    (value) => value.code == code,
    orElse: () => Currency.mxn,
  );
}
