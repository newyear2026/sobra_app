import '../models/catalog_entry.dart';
import 'generated/app_localizations.dart';

/// Localized display name for provisional catalog slots.
///
/// Michi already has a final proper name. Numbered entries stay generic until
/// the character and room-item lineup is approved.
String catalogEntryDisplayName(AppLocalizations l10n, CatalogEntry entry) {
  if (entry.id == 'michi') return entry.name;
  final number = int.tryParse(entry.id.split('-').last) ?? 0;
  return entry.kind == CatalogKind.character
      ? l10n.collectionCharacterPlaceholder(number)
      : l10n.collectionItemPlaceholder(number);
}
