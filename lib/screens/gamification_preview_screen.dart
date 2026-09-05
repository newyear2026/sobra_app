import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/gamification_ui.dart';
import '../widgets/pixel_ui.dart';

/// A design-only gallery for the XP and mission surfaces.
///
/// It deliberately owns no state and writes nothing. The settlement engine can
/// later replace these fixtures with view data without changing the widgets.
class GamificationPreviewScreen extends StatelessWidget {
  const GamificationPreviewScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            children: [
              PixelTopBar(
                title: 'Vista previa XP',
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: 18),
              const PixelHint(
                tone: PixelHintTone.cash,
                icon: Icons.design_services_outlined,
                text:
                    'Solo es la capa visual. Todavía no entrega XP, no cierra '
                    'ciclos y no guarda progreso.',
              ),
              const SizedBox(height: 22),
              _PreviewLink(
                icon: Icons.home_outlined,
                tint: AppColors.tealSoft,
                title: 'Inicio con nivel',
                description: 'Franja de nivel y resumen de misiones.',
                onTap: () => _open(context, const _HomeXpPreview()),
              ),
              _PreviewLink(
                icon: Icons.auto_awesome_outlined,
                tint: AppColors.violetSoft,
                title: 'Misiones',
                description: 'Tres semanales y una ligada al ciclo.',
                onTap: () => _open(context, const _MissionsPreview()),
              ),
              _PreviewLink(
                icon: Icons.emoji_events_outlined,
                tint: AppColors.cashSoft,
                title: 'Cierre de ciclo',
                description: 'Resumen del dinero y desglose de XP.',
                onTap: () => _open(context, const _CycleClosurePreview()),
              ),
              _PreviewLink(
                icon: Icons.insights_outlined,
                tint: AppColors.blueSoft,
                title: 'Progreso',
                description: 'Nivel, hábitos recientes y desbloqueos.',
                onTap: () => _open(context, const _ProgressPreview()),
              ),
              const SizedBox(height: 8),
              Text(
                'La subida de nivel se abre desde “Cierre de ciclo”.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PreviewLink extends StatelessWidget {
  const _PreviewLink({
    required this.icon,
    required this.tint,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: PixelCard(
      elevation: PixelElevation.none,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint,
              border: Border.all(color: AppColors.ink, width: 2.5),
            ),
            child: Icon(icon, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: pixelText(size: 15, bold: true)),
                const SizedBox(height: 3),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

class _PreviewScaffold extends StatelessWidget {
  const _PreviewScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            children: [
              PixelTopBar(title: title, onBack: () => Navigator.pop(context)),
              const SizedBox(height: 18),
              ...children,
            ],
          ),
        ),
      ),
    ),
  );
}

class _HomeXpPreview extends StatelessWidget {
  const _HomeXpPreview();

  @override
  Widget build(BuildContext context) => _PreviewScaffold(
    title: 'Inicio · XP',
    children: [
      Text('Hoy te queda', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 4),
      Text(
        r'$422 MXN',
        style: Theme.of(
          context,
        ).textTheme.displayLarge?.copyWith(color: AppColors.teal),
      ),
      const SizedBox(height: 14),
      LevelStrip(
        level: 4,
        title: 'Michi guardián',
        subtitle: 'Meta del mes · 390 XP',
        currentXp: 155,
        targetXp: 390,
        trailingLabel: '19 días',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const _ProgressPreview()),
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: Text(
              'Avance del mes',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Text('30 ago–29 sept', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      const SizedBox(height: 8),
      const SegmentedProgress(value: .33),
      const SizedBox(height: 6),
      Row(
        children: [
          Text(
            r'Presupuesto $12,000',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Text(r'Gastado $3,980', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      const SizedBox(height: 18),
      PixelCard(
        elevation: PixelElevation.none,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const _MissionsPreview()),
        ),
        child: const Column(
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_outlined, color: AppColors.tealInk),
                SizedBox(width: 9),
                Expanded(child: Text('Misiones de la semana')),
                PixelTag(
                  label: '1 / 3',
                  color: AppColors.tealSoft,
                  ink: AppColors.tealInk,
                ),
              ],
            ),
            SizedBox(height: 10),
            SegmentedProgress(value: 1 / 3),
            SizedBox(height: 6),
            Row(
              children: [
                Text('Se renuevan el lunes'),
                Spacer(),
                Text('+70 XP posibles'),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const PixelCard(
        elevation: PixelElevation.none,
        color: AppColors.cashSoft,
        borderColor: AppColors.cashInk,
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: AppColors.cashInk,
              size: 31,
            ),
            SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Efectivo estimado'),
                  Text('\$2,180', style: TextStyle(fontSize: 21)),
                ],
              ),
            ),
            PixelTag(label: 'domingo'),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const PixelHint(
        tone: PixelHintTone.teal,
        icon: Icons.check,
        text: 'Hoy vas bajo tu límite. Si cierras así, +5 XP.',
      ),
      const SizedBox(height: 12),
      const PixelHint(
        tone: PixelHintTone.neutral,
        icon: Icons.close,
        text:
            'Registrar un gasto no da XP. Se premia el resultado, no la '
            'cantidad de toques.',
      ),
    ],
  );
}

class _MissionsPreview extends StatelessWidget {
  const _MissionsPreview();

  @override
  Widget build(BuildContext context) => _PreviewScaffold(
    title: 'Misiones',
    children: const [
      _SectionTitle(label: 'De la semana', tag: 'Se renuevan el lunes'),
      MissionCard(
        title: 'Cuenta tu efectivo del domingo',
        xp: 25,
        progress: 1,
        leadingLabel: 'Listo · domingo 14',
        trailingLabel: 'Completada',
        icon: Icons.payments_outlined,
        completed: true,
      ),
      SizedBox(height: 10),
      MissionCard(
        title: '5 días bajo tu límite diario',
        xp: 25,
        progress: .6,
        leadingLabel: '3 de 5 días',
        trailingLabel: 'Faltan 2',
        icon: Icons.calendar_month_outlined,
        tint: AppColors.violetSoft,
        iconColor: AppColors.violet,
      ),
      SizedBox(height: 10),
      MissionCard(
        title: 'Mantén Comida bajo su límite',
        xp: 20,
        progress: .71,
        leadingLabel: '\$1,420 de \$2,000',
        trailingLabel: 'Vas bien',
        icon: Icons.restaurant_outlined,
        tint: AppColors.dangerSoft,
        iconColor: AppColors.dangerInk,
      ),
      SizedBox(height: 20),
      _SectionTitle(label: 'De tu ciclo', tag: 'Cierra el 29 sept'),
      MissionCard(
        title: 'Cierra el mes en verde',
        xp: 200,
        progress: .33,
        leadingLabel: '\$3,980 de \$12,000',
        trailingLabel: '19 días',
        icon: Icons.star_outline,
      ),
      SizedBox(height: 14),
      PixelHint(
        tone: PixelHintTone.neutral,
        icon: Icons.close,
        text:
            'Ninguna misión te pide gastar ni registrar más. Todas se '
            'cumplen gastando menos o igual.',
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.tag});

  final String label;
  final String tag;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        PixelTag(label: tag),
      ],
    ),
  );
}

class _CycleClosurePreview extends StatelessWidget {
  const _CycleClosurePreview();

  @override
  Widget build(BuildContext context) => _PreviewScaffold(
    title: 'Mes cerrado',
    children: [
      Text(
        '30 ago–29 sept',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
      Text(
        'Te sobraron',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      Text(
        r'$1,340 MXN',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.displayLarge?.copyWith(color: AppColors.teal),
      ),
      const SizedBox(height: 12),
      const PixelCard(
        elevation: PixelElevation.none,
        color: AppColors.beige,
        padding: EdgeInsets.fromLTRB(12, 14, 12, 0),
        child: Center(
          child: CatSprite(
            motion: CatMotion.celebrate,
            width: 155,
            animate: false,
          ),
        ),
      ),
      const SizedBox(height: 18),
      Text('Lo que ganaste', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      const XpRewardRow(
        label: 'Cerraste el mes en verde',
        xp: 200,
        icon: Icons.check,
        tint: AppColors.tealSoft,
        iconColor: AppColors.tealInk,
      ),
      const Divider(),
      const XpRewardRow(
        label: '4 conteos de efectivo',
        xp: 100,
        icon: Icons.payments_outlined,
        tint: AppColors.cashSoft,
        iconColor: AppColors.cashInk,
      ),
      const Divider(),
      const XpRewardRow(
        label: '18 días bajo tu límite',
        xp: 90,
        icon: Icons.calendar_month_outlined,
        tint: AppColors.violetSoft,
        iconColor: AppColors.violet,
      ),
      const SizedBox(height: 10),
      const PixelCard(
        elevation: PixelElevation.none,
        color: AppColors.tealSoft,
        child: Row(
          children: [
            Expanded(child: Text('Total del ciclo')),
            Text('+390 XP', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const PixelHint(
        text:
            'Un mes vale más que una quincena porque dura más. El objetivo '
            'se normaliza por los días del ciclo.',
      ),
      const SizedBox(height: 22),
      PixelButton(
        label: 'Reclamar 390 XP',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const _LevelUpPreview()),
        ),
      ),
    ],
  );
}

class _LevelUpPreview extends StatelessWidget {
  const _LevelUpPreview();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.ink,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              children: [
                Text(
                  'SUBISTE DE NIVEL',
                  style: pixelText(
                    size: 14,
                    bold: true,
                    color: const Color(0xFF7FD8CE),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '4',
                  style: pixelText(
                    size: 68,
                    bold: true,
                    color: const Color(0xFF7FD8CE),
                  ),
                ),
                Text(
                  'Michi guardián',
                  style: pixelText(size: 29, bold: true, color: Colors.white),
                ),
                const SizedBox(height: 6),
                const CatSprite(
                  motion: CatMotion.celebrate,
                  width: 165,
                  animate: false,
                ),
                const SizedBox(height: 14),
                const _UnlockCard(
                  icon: Icons.lock_open,
                  eyebrow: 'Nuevo accesorio',
                  label: 'Gorro de invierno',
                  dark: true,
                ),
                const SizedBox(height: 10),
                const _UnlockCard(
                  icon: Icons.auto_awesome,
                  eyebrow: 'Nueva animación',
                  label: 'Michi festeja',
                  dark: true,
                ),
                const SizedBox(height: 14),
                const SegmentedProgress(value: .06),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '45 / 700 XP',
                      style: pixelText(
                        size: 12,
                        color: const Color(0xFFB5BEDD),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Nivel 5',
                      style: pixelText(
                        size: 12,
                        color: const Color(0xFFB5BEDD),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                PixelButton(
                  label: 'Continuar',
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 8),
                Text(
                  'Puedes equiparlo después, en Progreso.',
                  style: pixelText(size: 12, color: const Color(0xFFB5BEDD)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ProgressPreview extends StatelessWidget {
  const _ProgressPreview();

  @override
  Widget build(BuildContext context) => _PreviewScaffold(
    title: 'Progreso',
    children: [
      const LevelStrip(
        level: 4,
        title: 'Michi guardián',
        subtitle: '895 XP totales',
        currentXp: 45,
        targetXp: 700,
        trailingLabel: 'Faltan 655 XP',
      ),
      const SizedBox(height: 20),
      Text('Ciclos en verde', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      const PixelCard(
        elevation: PixelElevation.none,
        child: Row(
          children: [
            CatSprite(motion: CatMotion.idle, width: 48, animate: false),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '6',
                    style: TextStyle(fontSize: 28, color: AppColors.teal),
                  ),
                  Text('de 7 ciclos registrados'),
                ],
              ),
            ),
            PixelTag(label: '+100 XP\nc/u', color: AppColors.tealSoft),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Text(
        'Conteos de efectivo',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 9),
      const _WeekGrid(
        values: [true, true, false, true, true, false, true, true],
      ),
      const SizedBox(height: 7),
      Row(
        children: [
          Text(
            '6 de las últimas 8 semanas',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Text(
            '+150 XP',
            style: pixelText(size: 12, bold: true, color: AppColors.tealInk),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Text(
        'Lo que has desbloqueado',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 9),
      const _UnlockCard(
        icon: Icons.circle_outlined,
        eyebrow: 'Nivel 2',
        label: 'Collar dorado',
      ),
      const SizedBox(height: 8),
      const _UnlockCard(
        icon: Icons.savings_outlined,
        eyebrow: 'Nivel 3',
        label: 'Alcancía del michi',
      ),
      const SizedBox(height: 8),
      const _UnlockCard(
        icon: Icons.checkroom_outlined,
        eyebrow: 'Nivel 4 · NUEVO',
        label: 'Gorro de invierno',
        highlighted: true,
      ),
      const SizedBox(height: 8),
      const Opacity(
        opacity: .55,
        child: _UnlockCard(
          icon: Icons.dark_mode_outlined,
          eyebrow: 'Nivel 5',
          label: 'Tema “noche”',
        ),
      ),
      const SizedBox(height: 18),
      const PixelHint(
        text: 'Saltarte una semana no borra nada. Se cuenta lo que sí hiciste.',
      ),
    ],
  );
}

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({required this.values});

  final List<bool> values;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (index, value) in values.indexed) ...[
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: value ? AppColors.teal : AppColors.surface,
                border: Border.all(color: AppColors.ink, width: 2.5),
              ),
            ),
          ),
        ),
        if (index != values.length - 1) const SizedBox(width: 5),
      ],
    ],
  );
}

class _UnlockCard extends StatelessWidget {
  const _UnlockCard({
    required this.icon,
    required this.eyebrow,
    required this.label,
    this.highlighted = false,
    this.dark = false,
  });

  final IconData icon;
  final String eyebrow;
  final String label;
  final bool highlighted;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : AppColors.ink;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.ink
            : highlighted
            ? AppColors.tealSoft
            : AppColors.paperLight,
        border: Border.all(
          color: dark ? const Color(0xFF7FD8CE) : AppColors.ink,
          width: 2.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: dark ? const Color(0xFF7FD8CE) : AppColors.tealInk),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: pixelText(
                    size: 12,
                    color: dark ? const Color(0xFFB5BEDD) : AppColors.muted,
                  ),
                ),
                Text(
                  label,
                  style: pixelText(size: 14, bold: true, color: foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
