/// Why a store write did not go through, in a form the view can word.
///
/// The store used to raise its refusals as Spanish sentences and the screen
/// showed `error.message` verbatim, which made the exception type part of the
/// user interface. It carries the reason now; `l10n/labels.dart` turns that
/// into the line the user reads.
///
/// Programmer errors — an amount that should never have reached the store —
/// stay as plain [ArgumentError]s. They are bugs, not messages.
enum StoreFailure {
  /// The new total is at or below the income already booked to this cycle.
  budgetBelowCycleIncome,

  /// A movement dated after today.
  futureMovement,

  /// A backup could not be written back over the live data.
  restoreFailed,

  /// The unreadable original could not be kept alongside the fresh start.
  originalNotKept,

  /// The backup copy itself could not be saved.
  backupNotSaved,

  /// The ordinary save at the end of a mutation did not land.
  saveFailed,
}

class SobraStoreException implements Exception {
  const SobraStoreException(this.failure);

  final StoreFailure failure;

  @override
  String toString() => 'SobraStoreException(${failure.name})';
}
