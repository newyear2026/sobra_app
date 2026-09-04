import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_ui.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  bool _working = false;

  Future<void> _run(Future<bool> Function() action) async {
    if (_working) return;
    setState(() => _working = true);
    final success = await action();
    if (!mounted) return;
    setState(() => _working = false);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos recuperar los datos todavía.'),
        ),
      );
    }
  }

  Future<void> _startFresh(SobraStore store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Empezar de nuevo?'),
        content: const Text(
          'Conservaremos una copia del archivo original antes de crear datos nuevos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Empezar de nuevo'),
          ),
        ],
      ),
    );
    if (confirmed != true || _working) return;
    setState(() => _working = true);
    await store.startFreshAfterCorruption();
    if (mounted) setState(() => _working = false);
  }

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 30),
                const Icon(Icons.storage, size: 58, color: AppColors.cashInk),
                const SizedBox(height: 20),
                Text(
                  'No pudimos leer tus datos',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'El archivo original sigue guardado. '
                  'No lo reemplazamos ni borramos.',
                  textAlign: TextAlign.center,
                  style: pixelText(
                    size: 15,
                    color: AppColors.inkSoft,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                PixelCard(
                  elevation: PixelElevation.none,
                  color: AppColors.cashSoft,
                  borderColor: AppColors.cashInk,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: AppColors.cashInk,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Puedes reintentar, usar el respaldo o exportar el '
                          'archivo para conservarlo.',
                          style: pixelText(
                            size: 13,
                            bold: true,
                            color: AppColors.cashInk,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                PixelButton(
                  label: _working ? 'Reintentando…' : 'Reintentar',
                  onPressed: _working ? null : () => _run(store.retryRestore),
                ),
                const SizedBox(height: 14),
                PixelButton(
                  label: 'Usar respaldo',
                  onPressed: _working || !store.hasRecoverableBackup
                      ? null
                      : () => _run(store.restoreBackup),
                  color: AppColors.blue,
                ),
                const SizedBox(height: 10),
                PixelButton(
                  label: 'Exportar archivo',
                  icon: Icons.copy,
                  variant: PixelButtonVariant.secondary,
                  onPressed: _working || store.exportCorruptedJson == null
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(text: store.exportCorruptedJson!),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Archivo original copiado.'),
                            ),
                          );
                        },
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _working ? null : () => _startFresh(store),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.dangerInk,
                  ),
                  child: const Text('Empezar de nuevo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
