import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/sobra_widget_sync.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/character_room.dart';
import '../widgets/gamification_ui.dart';
import 'budget_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';

enum AppTab {
  home(Icons.home_outlined, Icons.home),
  movements(Icons.list_alt_outlined, Icons.list_alt),
  register(Icons.add, Icons.add),
  budget(Icons.bar_chart_outlined, Icons.bar_chart),
  settings(Icons.settings_outlined, Icons.settings);

  const AppTab(this.icon, this.selectedIcon);

  final IconData icon;
  final IconData selectedIcon;

  String label(AppLocalizations l10n) => switch (this) {
    AppTab.home => l10n.tabHome,
    AppTab.movements => l10n.tabMovements,
    AppTab.register => l10n.tabRegister,
    AppTab.budget => l10n.tabBudget,
    AppTab.settings => l10n.tabSettings,
  };
}

/// Lets a tab move the shell to another tab.
///
/// Movimientos and Ajustes are destinations of their own now, so "Ver todos"
/// and the gear switch tabs instead of pushing a second copy on top.
class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.select,
    required this.current,
    required super.child,
  });

  final ValueChanged<AppTab> select;
  final AppTab current;

  static AppShellScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppShellScope>();
    assert(scope != null, 'AppShellScope is missing above this context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppShellScope oldWidget) =>
      current != oldWidget.current;
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _selected = AppTab.home;
  SobraStore? _store;
  bool _xpNoticeScheduled = false;

  @override
  void initState() {
    super.initState();
    SobraWidgetSync.destination.addListener(_onWidgetDestination);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onWidgetDestination());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextStore = SobraScope.of(context);
    if (!identical(_store, nextStore)) {
      _store?.removeListener(_onStoreChanged);
      _store = nextStore..addListener(_onStoreChanged);
    }
    // Inicio builds its list lazily, so the room is only created once the
    // user scrolls down to it — decoding there would show an empty card for
    // a frame. Warm it here instead, where nothing is waiting on it.
    unawaited(
      precacheImage(CharacterRoom.backgroundProvider(context), context),
    );
    _scheduleXpNotice();
  }

  @override
  void dispose() {
    SobraWidgetSync.destination.removeListener(_onWidgetDestination);
    _store?.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onWidgetDestination() {
    final destination = SobraWidgetSync.destination.value;
    if (!mounted || destination == null) return;
    final tab = switch (destination) {
      SobraWidgetDestination.home => AppTab.home,
      SobraWidgetDestination.register => AppTab.register,
    };
    if (_selected != tab) setState(() => _selected = tab);
    SobraWidgetSync.consumeDestination(destination);
  }

  void _onStoreChanged() => _scheduleXpNotice();

  void _scheduleXpNotice() {
    if (_xpNoticeScheduled || _store?.pendingXpNotice == null) return;
    _xpNoticeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _xpNoticeScheduled = false;
      if (!mounted) return;
      final notice = _store?.takePendingXpNotice();
      if (notice == null) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(xpSnackBar(notice));
    });
  }

  void _select(AppTab tab) => setState(() => _selected = tab);

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const TransactionsScreen(),
      RegisterScreen(onSaved: () => _select(AppTab.home)),
      const BudgetScreen(),
      const SettingsScreen(),
    ];

    return AppShellScope(
      select: _select,
      current: _selected,
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: AppColors.surface),
              child: Column(
                children: [
                  Expanded(
                    child: IndexedStack(
                      index: _selected.index,
                      children: screens,
                    ),
                  ),
                  PixelBottomNavigation(
                    selected: _selected,
                    onSelected: _select,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PixelBottomNavigation extends StatelessWidget {
  const PixelBottomNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AppTab selected;
  final ValueChanged<AppTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.ink, width: 3)),
        ),
        child: Row(
          children: [
            for (final tab in AppTab.values)
              tab == AppTab.register
                  ? _RegisterTile(
                      selected: selected == tab,
                      onTap: () => onSelected(tab),
                    )
                  : Expanded(
                      child: _NavItem(
                        tab: tab,
                        selected: selected == tab,
                        onTap: () => onSelected(tab),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.ink;
    return Semantics(
      selected: selected,
      button: true,
      label: tab.label(AppLocalizations.of(context)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ColoredBox(
          color: selected ? AppColors.teal : AppColors.surface,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? tab.selectedIcon : tab.icon,
                color: foreground,
                size: 24,
              ),
              const SizedBox(height: 3),
              Text(
                tab.label(AppLocalizations.of(context)),
                style: pixelText(size: 12, bold: true, color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The raised tile at the centre of the bar.
///
/// Registering an expense is the one thing the app exists for, so it gets a
/// shape of its own rather than a fifth equal slot.
class _RegisterTile extends StatelessWidget {
  const _RegisterTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: AppTab.register.label(AppLocalizations.of(context)),
      child: SizedBox(
        width: 76,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(9, 9, 9, 13),
          child: _PressTile(onTap: onTap, selected: selected),
        ),
      ),
    );
  }
}

class _PressTile extends StatefulWidget {
  const _PressTile({required this.onTap, required this.selected});

  final VoidCallback onTap;
  final bool selected;

  @override
  State<_PressTile> createState() => _PressTileState();
}

class _PressTileState extends State<_PressTile> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final down = _pressed || widget.selected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: Transform.translate(
        offset: down ? const Offset(0, 4) : Offset.zero,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.selected ? AppColors.tealInk : AppColors.teal,
            border: Border.all(color: AppColors.ink, width: 2.5),
            boxShadow: down
                ? null
                : const [BoxShadow(color: AppColors.ink, offset: Offset(0, 4))],
          ),
          child: const Center(
            child: Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
