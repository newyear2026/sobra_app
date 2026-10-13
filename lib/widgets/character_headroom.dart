import 'cat_sprite.dart';

/// The highest painted row, in source pixels, across every frame of each
/// character's motion sheets — sparkles and other effects included.
///
/// Room scenes lift the speech bubble clear of it: the bubble's base height
/// fits the shorter characters, while larger room scales and high jumps
/// (Miru's celebration, Lana's ears) rose into it. Measured from the sheets;
/// `test/character_headroom_test.dart` re-measures them, so regenerate this
/// map whenever a sheet changes.
const characterTopRows = <String, Map<CharacterMotionRole, int>>{
  'michi': {
    CharacterMotionRole.idle: 71,
    CharacterMotionRole.activity: 55,
    CharacterMotionRole.processing: 44,
    CharacterMotionRole.positive: 72,
    CharacterMotionRole.success: 48,
    CharacterMotionRole.warning: 44,
  },
  'poodle': {
    CharacterMotionRole.idle: 16,
    CharacterMotionRole.activity: 39,
    CharacterMotionRole.processing: 16,
    CharacterMotionRole.positive: 16,
    CharacterMotionRole.success: 16,
    CharacterMotionRole.warning: 16,
  },
  'schnauzer': {
    CharacterMotionRole.idle: 24,
    CharacterMotionRole.activity: 34,
    CharacterMotionRole.processing: 29,
    CharacterMotionRole.positive: 26,
    CharacterMotionRole.success: 16,
    CharacterMotionRole.warning: 24,
  },
  'guinea-pig': {
    CharacterMotionRole.idle: 43,
    CharacterMotionRole.activity: 59,
    CharacterMotionRole.processing: 44,
    CharacterMotionRole.positive: 49,
    CharacterMotionRole.success: 16,
    CharacterMotionRole.warning: 45,
  },
  'capybara': {
    CharacterMotionRole.idle: 44,
    CharacterMotionRole.activity: 52,
    CharacterMotionRole.processing: 44,
    CharacterMotionRole.positive: 46,
    CharacterMotionRole.success: 22,
    CharacterMotionRole.warning: 44,
  },
  'alpaca': {
    CharacterMotionRole.idle: 44,
    CharacterMotionRole.activity: 52,
    CharacterMotionRole.processing: 24,
    CharacterMotionRole.positive: 44,
    CharacterMotionRole.success: 20,
    CharacterMotionRole.warning: 44,
  },
  'platypus': {
    CharacterMotionRole.idle: 105,
    CharacterMotionRole.activity: 114,
    CharacterMotionRole.processing: 100,
    CharacterMotionRole.positive: 153,
    CharacterMotionRole.success: 32,
    CharacterMotionRole.warning: 128,
  },
  'rabbit': {
    CharacterMotionRole.idle: 84,
    CharacterMotionRole.activity: 52,
    CharacterMotionRole.processing: 84,
    CharacterMotionRole.positive: 84,
    CharacterMotionRole.success: 57,
    CharacterMotionRole.warning: 84,
  },
  'raccoon': {
    CharacterMotionRole.idle: 44,
    CharacterMotionRole.activity: 96,
    CharacterMotionRole.processing: 44,
    CharacterMotionRole.positive: 57,
    CharacterMotionRole.success: 29,
    CharacterMotionRole.warning: 44,
  },
  'quokka': {
    CharacterMotionRole.idle: 44,
    CharacterMotionRole.activity: 36,
    CharacterMotionRole.processing: 44,
    CharacterMotionRole.positive: 61,
    CharacterMotionRole.success: 16,
    CharacterMotionRole.warning: 44,
  },
  'maltese': {
    CharacterMotionRole.idle: 41,
    CharacterMotionRole.activity: 42,
    CharacterMotionRole.processing: 42,
    CharacterMotionRole.positive: 40,
    CharacterMotionRole.success: 16,
    CharacterMotionRole.warning: 33,
  },
};
