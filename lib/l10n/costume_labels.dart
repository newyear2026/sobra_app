import '../models/character_costume.dart';
import 'generated/app_localizations.dart';

String costumeDisplayName(AppLocalizations l10n, String? id) {
  final costume = CharacterCostumes.byId(id);
  if (costume == null) return l10n.costumeDefault;
  return switch (costume.theme) {
    CostumeTheme.dracula => l10n.costumeDracula,
    CostumeTheme.frankenstein => l10n.costumeFrankenstein,
    CostumeTheme.werewolf => l10n.costumeWerewolf,
    CostumeTheme.pumpkin => l10n.costumePumpkin,
    CostumeTheme.mummy => l10n.costumeMummy,
    CostumeTheme.catrina => l10n.costumeCatrina,
    CostumeTheme.ghostPirate => l10n.costumeGhostPirate,
    CostumeTheme.swampMonster => l10n.costumeSwampMonster,
    CostumeTheme.moonWitch => l10n.costumeMoonWitch,
    CostumeTheme.calaveraMusician => l10n.costumeCalaveraMusician,
    CostumeTheme.scarecrow => l10n.costumeScarecrow,
    CostumeTheme.littleGhost => l10n.costumeLittleGhost,
  };
}
