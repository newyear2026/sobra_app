/// The currencies Sobra can label money in.
///
/// This is the unit the user reads, not a rate: switching relabels the figures
/// already saved and never converts them. Sobra tracks what somebody counted
/// in their own pocket, and there is no honest exchange rate to apply to a
/// cash count from three weeks ago.
///
/// Seven of these share `$`, so the code beside those figures is doing real
/// work — `$1,200` is seven different amounts of money, and two of them are
/// not within an order of magnitude of each other. The real, the pound, the
/// sol, the euro, the yen and the won carry their own sign, and still print
/// their code so a figure always names the unit.
///
/// A sign is only worth having if the font can draw it. Pixelify Sans ships
/// no ₩, so `tool/patch_pixelify_won.py` puts one there; `font_coverage_test`
/// fails if a currency on this list ever loses its glyph.
///
/// Ordered and grouped by where they are spent rather than by when they were
/// added: the picker reads [region] and lists them in this order, and the
/// pesos are worth reading next to each other. Nothing is stored by position —
/// the code is what gets saved — so this list can be reordered freely.
enum Currency {
  mxn('MXN', r'$', CurrencyRegion.americas),
  usd('USD', r'$', CurrencyRegion.americas),
  cad('CAD', r'$', CurrencyRegion.americas),
  cop('COP', r'$', CurrencyRegion.americas, decimalComma: true),
  ars('ARS', r'$', CurrencyRegion.americas, decimalComma: true),
  clp(
    'CLP',
    r'$',
    CurrencyRegion.americas,
    decimalDigits: 0,
    decimalComma: true,
  ),
  pen('PEN', 'S/', CurrencyRegion.americas),
  brl('BRL', r'R$', CurrencyRegion.americas, decimalComma: true),
  eur('EUR', '€', CurrencyRegion.europe, decimalComma: true),
  gbp('GBP', '£', CurrencyRegion.europe),
  jpy('JPY', '¥', CurrencyRegion.asiaPacific, decimalDigits: 0),
  krw('KRW', '₩', CurrencyRegion.asiaPacific, decimalDigits: 0),
  aud('AUD', r'$', CurrencyRegion.asiaPacific);

  const Currency(
    this.code,
    this.symbol,
    this.region, {
    this.decimalDigits = 2,
    this.decimalComma = false,
  });

  /// The ISO code shown next to an amount, and what gets saved.
  final String code;

  /// The symbol before the digits.
  final String symbol;

  /// Which heading the picker files this one under. Presentation only.
  final CurrencyRegion region;

  /// How many digits this currency writes behind the decimal point.
  ///
  /// Zero for the yen, the won and the Chilean peso, which have no
  /// subdivision anybody spends: ¥100 is a hundred yen, not one. This governs
  /// what gets printed and what an amount field will accept — never what gets
  /// stored. See [minorUnitsPerUnit].
  ///
  /// Two rather than zero for the Colombian and Argentine pesos, whose
  /// centavos are gone from circulation but not from the standard. Costing
  /// them nothing: a figure with no hundredths prints none either way, so
  /// they read as whole pesos in practice while a relabelled amount keeps
  /// what it arrived with.
  final int decimalDigits;

  /// Whether this money is written 1.234,56 rather than 1,234.56.
  ///
  /// Follows the country that spends it, not the language on screen: a
  /// Colombian reading Sobra in English still expects $15.000, and $15,000
  /// reads to them as fifteen pesos. The euro goes with the larger part of the
  /// eurozone; Ireland and Malta write it the other way. A currency with no
  /// decimals still cares, because its grouping mark is the one that differs.
  ///
  /// Like [decimalDigits], a display rule only — nothing saved changes.
  final bool decimalComma;

  /// The mark every three digits, counting from the right.
  String get groupSeparator => decimalComma ? '.' : ',';

  /// The mark between the whole units and the hundredths.
  String get decimalSeparator => decimalComma ? ',' : '.';

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

/// The headings the currency picker groups its rows under.
///
/// Thirteen rows in one column is a list nobody reads to the end; under three
/// headings it is three short ones, and somebody hunting for their own money
/// knows which to look in. Nothing is stored by region — it decides where a
/// row is drawn and nothing else — so a currency can be moved between them
/// without touching a single saved figure.
enum CurrencyRegion { americas, europe, asiaPacific }
