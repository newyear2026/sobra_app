import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pay_schedule.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/pixel_ui.dart';
import 'cycle_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SobraScope.of(context);

    return SafeArea(
      bottom: false,
      child: ListView(
        key: const PageStorageKey('settings-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          const PixelTopBar(title: 'Ajustes'),
          const SizedBox(height: 24),
          _SettingsRow(
            icon: Icons.attach_money,
            iconColor: AppColors.teal,
            label: 'Moneda',
            value: 'MXN',
            onTap: () => _fixedSetting(context),
          ),
          _SettingsRow(
            icon: Icons.calendar_month,
            iconColor: AppColors.violet,
            label: 'Ciclo de presupuesto',
            value:
                store.pendingPaySchedule?.type.label ??
                store.paySchedule.type.label,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CycleSettingsScreen(),
              ),
            ),
          ),
          _SettingsRow(
            icon: Icons.event_available,
            iconColor: AppColors.blue,
            label: 'Día de conteo',
            value: 'Domingo',
            onTap: () => _fixedSetting(context),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PixelCard(
              elevation: PixelElevation.none,
              child: Row(
                children: [
                  _IconTile(
                    icon: Icons.motion_photos_off,
                    color: AppColors.cash,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reducir movimiento',
                          style: pixelText(size: 15, bold: true),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Se activa solo si tu teléfono ya lo pide.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PixelSwitch(
                    value: store.reducedMotion,
                    onChanged: store.setReducedMotion,
                    semanticLabel: 'Reducir movimiento',
                  ),
                ],
              ),
            ),
          ),
          _SettingsRow(
            icon: Icons.cloud_upload,
            iconColor: AppColors.teal,
            label: 'Respaldo de datos',
            value: 'Copiar',
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: store.exportJson()));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Respaldo copiado al portapapeles.'),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            'Tus datos se guardan en este dispositivo. No se necesita una cuenta para usar Sobra.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _fixedSetting(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Esta opción queda fija en la versión 1.')),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PixelCard(
        elevation: PixelElevation.none,
        onTap: onTap,
        child: Row(
          children: [
            _IconTile(icon: icon, color: iconColor),
            const SizedBox(width: 13),
            Expanded(
              child: Text(label, style: pixelText(size: 15, bold: true)),
            ),
            Text(
              value,
              style: pixelText(size: 14, bold: true, color: AppColors.muted),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: Icon(icon, color: color),
    );
  }
}
