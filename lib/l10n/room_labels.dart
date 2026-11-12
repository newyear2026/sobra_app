import '../models/room_design.dart';
import 'generated/app_localizations.dart';

String roomThemeDisplayName(AppLocalizations l10n, String roomId) =>
    switch (roomId) {
      RoomThemes.casaJardinId => l10n.roomThemeCasaJardin,
      RoomThemes.casaDePlayaId => l10n.roomThemeCasaDePlaya,
      RoomThemes.casaTorreId => l10n.roomThemeCasaTorre,
      RoomThemes.casaMontanaId => l10n.roomThemeCasaMontana,
      RoomThemes.casaInvernaderoId => l10n.roomThemeCasaInvernadero,
      _ => l10n.roomThemeCasaClara,
    };
