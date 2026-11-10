/// The least time between two native impressions in the same slot.
///
/// Three minutes, down from five on 2026-11-10: sessions in a budget app
/// are short, so a five-minute gap rarely let one slot serve twice in a
/// visit to the app, while three still keeps quick tab flipping from
/// swapping the card in and out.
const nativeAdGap = Duration(minutes: 3);

/// Each place a native ad can appear. Every slot keeps its own
/// [nativeAdGap], so an ad in one never holds back the others.
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
