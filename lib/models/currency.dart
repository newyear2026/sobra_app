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

  /// The money a new user starts with, from the phone's country.
  ///
  /// Only a starting point, chosen once when there is no ledger yet: the
  /// picker in Ajustes changes it, and nothing saved ever follows the phone
  /// afterwards. A country whose money is not on this list, or a phone that
  /// names no country, starts in Mexican pesos as every install did before.
  static Currency forCountry(String? countryCode) =>
      _byCountry[countryCode?.toUpperCase()] ?? Currency.mxn;

  /// What onboarding fills the budget field with, in whole units.
  ///
  /// Roughly what MX\$6,000 is in each, rounded to a figure somebody might
  /// write: a starting point to overwrite, never anybody's real budget. One
  /// number for every currency made \$6,000 a peso budget and ₩6,000 the
  /// price of a coffee.
  int get suggestedBudgetUnits => switch (this) {
    Currency.mxn => 6000,
    Currency.usd => 300,
    Currency.cad => 450,
    Currency.cop => 1300000,
    Currency.ars => 400000,
    Currency.clp => 300000,
    Currency.pen => 1200,
    Currency.brl => 1800,
    Currency.eur => 300,
    Currency.gbp => 250,
    Currency.jpy => 50000,
    Currency.krw => 450000,
    Currency.aud => 500,
  };

  static const _byCountry = <String, Currency>{
    'MX': Currency.mxn,
    // The dollar, and the countries that spend it as their own.
    'US': Currency.usd, 'PR': Currency.usd, 'EC': Currency.usd,
    'SV': Currency.usd, 'PA': Currency.usd,
    'CA': Currency.cad,
    'CO': Currency.cop,
    'AR': Currency.ars,
    'CL': Currency.clp,
    'PE': Currency.pen,
    'BR': Currency.brl,
    // The euro area as of 2026, Bulgaria included, and the small states
    // that use the euro by agreement.
    'AT': Currency.eur, 'BE': Currency.eur, 'BG': Currency.eur,
    'HR': Currency.eur, 'CY': Currency.eur, 'EE': Currency.eur,
    'FI': Currency.eur, 'FR': Currency.eur, 'DE': Currency.eur,
    'GR': Currency.eur, 'IE': Currency.eur, 'IT': Currency.eur,
    'LV': Currency.eur, 'LT': Currency.eur, 'LU': Currency.eur,
    'MT': Currency.eur, 'NL': Currency.eur, 'PT': Currency.eur,
    'SK': Currency.eur, 'SI': Currency.eur, 'ES': Currency.eur,
    'AD': Currency.eur, 'MC': Currency.eur, 'SM': Currency.eur,
    'VA': Currency.eur,
    'GB': Currency.gbp,
    'JP': Currency.jpy,
    'KR': Currency.krw,
    'AU': Currency.aud,
  };
}

/// The headings the currency picker groups its rows under.
///
/// Thirteen rows in one column is a list nobody reads to the end; under three
/// headings it is three short ones, and somebody hunting for their own money
/// knows which to look in. Nothing is stored by region — it decides where a
/// row is drawn and nothing else — so a currency can be moved between them
/// without touching a single saved figure.
enum CurrencyRegion { americas, europe, asiaPacific }
