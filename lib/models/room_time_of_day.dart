/// Approximate local clock phases. A time zone alone does not tell us the
/// observer's latitude, so these are deliberately not claimed as solar times.
enum RoomTimeOfDay {
  dawn,
  day,
  sunset,
  night;

  static RoomTimeOfDay fromLocal(DateTime now) {
    final minutes = now.hour * 60 + now.minute;
    if (minutes >= 5 * 60 + 30 && minutes < 8 * 60) return dawn;
    if (minutes >= 8 * 60 && minutes < 17 * 60 + 30) return day;
    if (minutes >= 17 * 60 + 30 && minutes < 20 * 60) return sunset;
    return night;
  }

  /// The first moment after [now] at which [fromLocal] answers differently.
  static DateTime nextChangeAfter(DateTime now) {
    for (var day = 0; day < 2; day++) {
      for (final minutes in const [
        5 * 60 + 30,
        8 * 60,
        17 * 60 + 30,
        20 * 60,
      ]) {
        // Built from fields, not added as a duration, so a daylight-saving
        // night still lands on the wall-clock time.
        final boundary = DateTime(
          now.year,
          now.month,
          now.day + day,
          minutes ~/ 60,
          minutes % 60,
        );
        if (boundary.isAfter(now)) return boundary;
      }
    }
    throw StateError('unreachable: a phase starts every day');
  }
}
