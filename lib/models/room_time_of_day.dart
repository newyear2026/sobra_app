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
}
