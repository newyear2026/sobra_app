import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/receipt_store.dart';
import '../theme/app_theme.dart';
import 'pixel_ui.dart';

/// Attaches one photo to an expense, or shows the one already attached.
///
/// The parent owns the name; this only picks files and reports back. Removing
/// reports null and deliberately leaves the file alone — the sheet it sits in
/// can still be dismissed without saving, and deleting here would take a photo
/// that is still on a saved expense. The launch sweep collects it instead.
class ReceiptField extends StatefulWidget {
  const ReceiptField({
    super.key,
    required this.fileName,
    required this.onChanged,
  });

  final String? fileName;
  final ValueChanged<String?> onChanged;

  @override
  State<ReceiptField> createState() => _ReceiptFieldState();
}

class _ReceiptFieldState extends State<ReceiptField> {
  bool _picking = false;

  Future<void> _pick(ReceiptSource source) async {
    if (_picking) return;
    final store = ReceiptScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _picking = true);
    try {
      final name = await store.capture(source);
      // Null is the user backing out of the picker. Nothing to report and
      // nothing to change; treating it as a failure would nag on every
      // cancelled camera.
      if (name != null) widget.onChanged(name);
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.receiptFailed)));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Nothing to offer on a build with nowhere to put a file. Showing a camera
    // button that silently does nothing is worse than showing no camera.
    if (!ReceiptScope.of(context).isSupported) return const SizedBox.shrink();
    final name = widget.fileName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.receiptTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (name == null)
          _EmptyReceipt(picking: _picking, onPick: _pick)
        else
          _AttachedReceipt(
            fileName: name,
            picking: _picking,
            onPick: _pick,
            onRemove: () => widget.onChanged(null),
          ),
      ],
    );
  }
}

class _EmptyReceipt extends StatelessWidget {
  const _EmptyReceipt({required this.picking, required this.onPick});

  final bool picking;
  final ValueChanged<ReceiptSource> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PixelCard(
      elevation: PixelElevation.none,
      color: AppColors.paperLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.receiptHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PixelButton(
                  label: l10n.receiptCamera,
                  icon: Icons.photo_camera_outlined,
                  variant: PixelButtonVariant.secondary,
                  onPressed: picking
                      ? null
                      : () => onPick(ReceiptSource.camera),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PixelButton(
                  label: l10n.receiptGallery,
                  icon: Icons.photo_library_outlined,
                  variant: PixelButtonVariant.secondary,
                  onPressed: picking
                      ? null
                      : () => onPick(ReceiptSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachedReceipt extends StatelessWidget {
  const _AttachedReceipt({
    required this.fileName,
    required this.picking,
    required this.onPick,
    required this.onRemove,
  });

  final String fileName;
  final bool picking;
  final ValueChanged<ReceiptSource> onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PixelCard(
      elevation: PixelElevation.none,
      color: AppColors.paperLight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReceiptThumbnail(
            fileName: fileName,
            size: 72,
            onTap: () => openReceiptViewer(context, fileName),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.receiptAttached,
                  style: pixelText(size: 14, bold: true),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: PixelButton(
                        label: l10n.receiptChange,
                        variant: PixelButtonVariant.secondary,
                        onPressed: picking
                            ? null
                            : () => onPick(ReceiptSource.gallery),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PixelButton(
                        label: l10n.receiptRemove,
                        variant: PixelButtonVariant.danger,
                        onPressed: picking ? null : onRemove,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A square crop of a stored receipt, or a marker that the file is gone.
class ReceiptThumbnail extends StatelessWidget {
  const ReceiptThumbnail({
    super.key,
    required this.fileName,
    this.size = 42,
    this.onTap,
  });

  final String fileName;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final file = ReceiptScope.of(context).fileFor(fileName);
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.beige,
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: file == null
            // The ledger row survives a photo the phone no longer has: an app
            // container can be cleared, and a restored backup brings the
            // entries without the images.
            ? Icon(
                Icons.image_not_supported_outlined,
                size: size * .5,
                color: AppColors.muted,
              )
            : Image.file(
                file,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
      ),
    );
    return Semantics(
      button: onTap != null,
      label: file == null ? l10n.receiptMissing : l10n.receiptView,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// Opens the photo full screen.
Future<void> openReceiptViewer(BuildContext context, String fileName) {
  final store = ReceiptScope.of(context);
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ReceiptScope(
        // The route is a sibling of the screen that opened it, so it cannot
        // inherit the scope through the tree.
        store: store,
        child: _ReceiptViewer(fileName: fileName),
      ),
    ),
  );
}

class _ReceiptViewer extends StatelessWidget {
  const _ReceiptViewer({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final file = ReceiptScope.of(context).fileFor(fileName);
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.receiptTitle,
                      style: pixelText(
                        size: 18,
                        bold: true,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: l10n.receiptClose,
                  ),
                ],
              ),
            ),
            Expanded(
              child: file == null
                  ? Center(
                      child: Text(
                        l10n.receiptMissing,
                        textAlign: TextAlign.center,
                        style: pixelText(size: 14, color: Colors.white),
                      ),
                    )
                  : InteractiveViewer(
                      maxScale: 5,
                      child: Center(child: Image.file(file)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
