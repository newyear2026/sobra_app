import 'dart:async';

import 'package:flutter/material.dart';

import '../data/catalog_preview_data.dart';
import '../l10n/catalog_labels.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/room_labels.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/room_scene.dart';
import 'room_decorate_screen.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  bool _reacting = false;
  Timer? _reactionTimer;

  @override
  void dispose() {
    _reactionTimer?.cancel();
    super.dispose();
  }

  void _react() {
    if (_reacting) return;
    _reactionTimer?.cancel();
    setState(() => _reacting = true);
    // A still poster has no animation completion callback.
    if (reducedMotionOf(context)) {
      _reactionTimer = Timer(
        const Duration(milliseconds: 1400),
        _finishReaction,
      );
    }
  }

  void _finishReaction() {
    if (mounted && _reacting) setState(() => _reacting = false);
  }

  void _openDecorator() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RoomDecorateScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    final character = CatalogPreviewData.characters.firstWhere(
      (entry) => entry.id == store.characterId,
      orElse: () => CatalogPreviewData.characters.first,
    );
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                  child: PixelTopBar(
                    title: l10n.roomTitle,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: Semantics(
                    label: roomThemeDisplayName(l10n, store.equippedRoomId),
                    child: RoomScene(
                      variant: RoomSceneVariant.immersive,
                      roomId: store.equippedRoomId,
                      placements: store.roomDecorationsFor(),
                      message: _reacting
                          ? l10n.roomCatReaction
                          : l10n.homeGoingWell,
                      onCatTap: _react,
                      reacting: _reacting,
                      onReactionComplete: _finishReaction,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.tealSoft,
                    border: Border.all(color: AppColors.ink, width: 2.5),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 46,
                        height: 52,
                        child: CatSprite(
                          motion: CatMotion.idle,
                          width: 46,
                          animate: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              catalogEntryDisplayName(l10n, character),
                              style: pixelText(size: 16, bold: true),
                            ),
                            Text(
                              roomThemeDisplayName(l10n, store.equippedRoomId),
                              style: pixelText(
                                size: 12,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PixelButton(
                        label: l10n.roomDecorate,
                        icon: Icons.brush,
                        expand: false,
                        onPressed: _openDecorator,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
