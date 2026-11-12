import '../models/room_design.dart';

/// Local, cosmetic launch gift. Update this date when the release is final.
abstract final class LaunchGiftCampaign {
  // Starts with the build that introduces the gift. Update with release date.
  static final DateTime startsOn = DateTime(2026, 9, 29);
  static final DateTime lastEligibleDay = DateTime(2026, 11, 15);

  static const itemIds = <String>{
    RoomDecorAssets.launchSofaId,
    RoomDecorAssets.launchTvId,
  };

  static bool eligible(DateTime firstStartedAt) {
    final day = DateTime(
      firstStartedAt.year,
      firstStartedAt.month,
      firstStartedAt.day,
    );
    return !day.isAfter(lastEligibleDay);
  }

  static bool active(DateTime today) => !today.isBefore(startsOn);
}
