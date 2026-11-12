import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/costume_labels.dart';
import '../l10n/generated/app_localizations.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import 'cat_sprite.dart';
import 'pixel_ui.dart';

/// Null cancels; an empty id means the original appearance. The caller stages
/// the choice with room edits, so closing this sheet never writes to disk.
Future<String?> showCharacterCostumePicker(
  BuildContext context, {
  required String characterId,
  required String? selectedCostumeId,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppColors.paperLight,
  shape: const RoundedRectangleBorder(
    side: BorderSide(color: AppColors.ink, width: 3),
  ),
  builder: (_) => _CostumeSheet(
    characterId: characterId,
    selectedCostumeId: selectedCostumeId,
  ),
);

class _CostumeSheet extends StatefulWidget {
  const _CostumeSheet({required this.characterId, this.selectedCostumeId});

  final String characterId;
  final String? selectedCostumeId;

  @override
  State<_CostumeSheet> createState() => _CostumeSheetState();
}

class _CostumeSheetState extends State<_CostumeSheet> {
  late String? _selected = widget.selectedCostumeId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SobraScope.of(context);
    final outfits = <String?>[
      null,
      ...store.ownedCostumesFor(widget.characterId).map((outfit) => outfit.id),
    ];
    final selected = outfits.contains(_selected) ? _selected : null;
    final name = CharacterCatalog.require(widget.characterId).displayName;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .8,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.costumeSheetTitle(name),
                      style: pixelText(size: 20, bold: true),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                l10n.costumeCanReturn,
                style: pixelText(size: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final id in outfits)
                            SizedBox(
                              width: width,
                              child: _OutfitTile(
                                characterId: widget.characterId,
                                costumeId: id,
                                selected: selected == id,
                                imageWidth: math.min(width - 20, 88),
                                onTap: () => setState(() => _selected = id),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PixelButton(
                key: const ValueKey('apply-costume'),
                maxLines: 2,
                label: l10n.costumeApply,
                onPressed: () => Navigator.pop(
                  context,
                  outfits.contains(_selected) ? (_selected ?? '') : '',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutfitTile extends StatelessWidget {
  const _OutfitTile({
    required this.characterId,
    required this.costumeId,
    required this.selected,
    required this.imageWidth,
    required this.onTap,
  });

  final String characterId;
  final String? costumeId;
  final bool selected;
  final double imageWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = costumeDisplayName(l10n, costumeId);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        key: ValueKey('costume-option-${costumeId ?? 'base'}'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected ? AppColors.tealSoft : AppColors.surface,
            border: Border.all(
              color: selected ? AppColors.teal : AppColors.line,
              width: selected ? 3 : 2,
            ),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Center(
                    child: CharacterSprite(
                      characterId: characterId,
                      costumeId: costumeId,
                      role: CharacterMotionRole.idle,
                      width: imageWidth,
                      animate: false,
                      semanticLabel: label,
                    ),
                  ),
                  if (selected)
                    const ColoredBox(
                      color: AppColors.teal,
                      child: Icon(Icons.check, color: Colors.white, size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: pixelText(size: 14, bold: true),
              ),
              const SizedBox(height: 6),
              Text(
                costumeId == null ? '' : l10n.costumePermanent,
                textAlign: TextAlign.center,
                style: pixelText(
                  size: 12,
                  color: costumeId == null
                      ? AppColors.muted
                      : AppColors.cashInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
