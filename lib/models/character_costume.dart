/// Costumes are appearances of an existing companion, never catalog characters.
enum CostumeTheme {
  dracula,
  frankenstein,
  werewolf,
  pumpkin,
  mummy,
  catrina,
  ghostPirate,
  swampMonster,
  moonWitch,
  calaveraMusician,
  scarecrow,
  littleGhost,
}

class CharacterCostume {
  const CharacterCostume(this.characterId, this.theme);

  final String characterId;
  final CostumeTheme theme;

  String get id => 'autumn-2026-$characterId';
  String get asset =>
      'assets/costumes/autumn_2026/motion_v2/$characterId/idle-8.webp';

  /// Every role has its own sequential, individually drawn animation atlas.
  /// Idle/warning have eight frames; the other roles have twelve.
  String motionAsset(String role) =>
      'assets/costumes/autumn_2026/motion_v2/$characterId/'
      '$role-${role == 'idle' || role == 'warning' ? 8 : 12}.webp';
}

abstract final class CharacterCostumes {
  static const campaignId = 'autumn-2026';
  static DateTime get startsAt => DateTime(2026, 10, 23);
  static DateTime get endsAt => DateTime(2026, 11, 4);
  static DateTime get lastClaimDay => DateTime(2026, 11, 3);

  // Availability is the device's local calendar, like the rest of the offline
  // app. Only acquisition ends; an already received costume never expires.
  static bool canClaimOn(DateTime moment) {
    final day = DateTime(moment.year, moment.month, moment.day);
    return !day.isBefore(startsAt) && day.isBefore(endsAt);
  }

  static const all = <CharacterCostume>[
    CharacterCostume('michi', CostumeTheme.dracula),
    CharacterCostume('poodle', CostumeTheme.frankenstein),
    CharacterCostume('schnauzer', CostumeTheme.werewolf),
    CharacterCostume('guinea-pig', CostumeTheme.pumpkin),
    CharacterCostume('capybara', CostumeTheme.mummy),
    CharacterCostume('alpaca', CostumeTheme.catrina),
    CharacterCostume('raccoon', CostumeTheme.ghostPirate),
    CharacterCostume('platypus', CostumeTheme.swampMonster),
    CharacterCostume('rabbit', CostumeTheme.moonWitch),
    CharacterCostume('penguin', CostumeTheme.calaveraMusician),
    CharacterCostume('quokka', CostumeTheme.scarecrow),
    CharacterCostume('maltese', CostumeTheme.littleGhost),
  ];

  static CharacterCostume? byId(String? id) =>
      all.where((costume) => costume.id == id).firstOrNull;

  static Iterable<CharacterCostume> forCharacter(String id) =>
      all.where((costume) => costume.characterId == id);
}
