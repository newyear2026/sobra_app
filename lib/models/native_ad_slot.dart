/// Each place a native ad can appear. Every slot keeps its own five-minute
/// gap, so an ad in one never holds back the others.
///
/// The names are persisted as keys of `nativeAdImpressionsAt`; renaming one
/// forgets that slot's last impression.
enum NativeAdSlot {
  /// Movimientos, under the third row.
  ledger,

  /// Presupuesto, under the last category.
  budget,

  /// The exit confirmation dialog.
  exit,
}
