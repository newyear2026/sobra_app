import 'dart:async';

import 'package:flutter/material.dart';

import '../data/catalog_preview_data.dart';
import '../l10n/catalog_labels.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/room_design.dart';
import '../models/xp_event.dart';
import '../services/app_review_service.dart';
import '../services/app_update_service.dart';
import '../services/app_version_service.dart';
import '../services/native_ad_service.dart';
import '../services/release_announcement_service.dart';
import '../services/sobra_widget_sync.dart';
import '../state/sobra_store.dart';
import '../theme/app_theme.dart';
import '../widgets/gamification_ui.dart';
import '../widgets/launch_gift_dialog.dart';
import '../widgets/pixel_ui.dart';
import '../widgets/release_announcement.dart';
import '../widgets/update_prompt.dart';
import 'budget_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'room_decorate_screen.dart';
import 'settings_screen.dart';
import 'settlement_screen.dart';
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
  AppUpdates? _updates;
  ReleaseAnnouncements? _announcements;
  bool _xpNoticeScheduled = false;
  bool _launchGiftScheduled = false;
  bool _launchGiftPresenting = false;
  bool _updatePromptScheduled = false;
  bool _announcementScheduled = false;
  String? _runningVersion;
  Future<void>? _versionReady;
  RegisterMode _registerMode = RegisterMode.expense;
  int _registerSession = 0;

  @override
  void initState() {
    super.initState();
    SobraWidgetSync.destination.addListener(_onWidgetDestination);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onWidgetDestination());
    _versionReady = _loadRunningVersion();
  }

  /// Only for the dialog's "your version" row, so a failure to read it is a
  /// row that does not appear rather than a prompt that does not.
  Future<void> _loadRunningVersion() async {
    final version = await loadAppVersion();
    if (!mounted || version == null) return;
    setState(() => _runningVersion = version.version);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextStore = SobraScope.of(context);
    if (!identical(_store, nextStore)) {
      _store?.removeListener(_onStoreChanged);
      _store = nextStore..addListener(_onStoreChanged);
    }
    final nextUpdates = AppUpdateScope.maybeOf(context);
    if (!identical(_updates, nextUpdates)) {
      _updates?.removeListener(_onUpdatesChanged);
      _updates = nextUpdates?..addListener(_onUpdatesChanged);
      // Here rather than in [initState]: the scope is only reachable once
      // dependencies resolve, and asking twice costs nothing — the service
      // drops a second check on the same day.
      unawaited(nextUpdates?.refresh() ?? Future<void>.value());
    }
    final nextAnnouncements = ReleaseAnnouncementScope.maybeOf(context);
    if (!identical(_announcements, nextAnnouncements)) {
      _announcements?.removeListener(_onAnnouncementsChanged);
      _announcements = nextAnnouncements?..addListener(_onAnnouncementsChanged);
      unawaited(nextAnnouncements?.start() ?? Future<void>.value());
    }
    // The room is now above the fold, so its fixed layer and included decor
    // are warmed before Inicio asks for them.
    unawaited(
      Future.wait([
        precacheImage(
          AssetImage(RoomThemes.byId(nextStore.equippedRoomId).previewAsset),
          context,
        ),
        precacheImage(const AssetImage(RoomDecorAssets.rug), context),
        precacheImage(const AssetImage(RoomDecorAssets.tablePlant), context),
      ]),
    );
    _scheduleXpNotice();
    _scheduleLaunchGiftNotice();
  }

  @override
  void dispose() {
    SobraWidgetSync.destination.removeListener(_onWidgetDestination);
    _store?.removeListener(_onStoreChanged);
    _updates?.removeListener(_onUpdatesChanged);
    _announcements?.removeListener(_onAnnouncementsChanged);
    super.dispose();
  }

  void _onWidgetDestination() {
    final destination = SobraWidgetSync.destination.value;
    if (!mounted || destination == null) return;
    switch (destination) {
      case SobraWidgetDestination.home:
        _changeSelection(AppTab.home);
      case SobraWidgetDestination.budget:
        _changeSelection(AppTab.budget);
      case SobraWidgetDestination.register:
      case SobraWidgetDestination.registerExpense:
        _noteTabTransition(AppTab.register);
        setState(() {
          _selected = AppTab.register;
          _registerMode = RegisterMode.expense;
          _registerSession++;
        });
      case SobraWidgetDestination.registerIncome:
        _noteTabTransition(AppTab.register);
        setState(() {
          _selected = AppTab.register;
          _registerMode = RegisterMode.income;
          _registerSession++;
        });
    }
    SobraWidgetSync.consumeDestination(destination);
  }

  void _onStoreChanged() {
    _scheduleXpNotice();
    _scheduleLaunchGiftNotice();
  }

  void _onUpdatesChanged() {
    setState(() {});
    _scheduleUpdatePrompt();
  }

  void _onAnnouncementsChanged() {
    if (!mounted) return;
    setState(() {});
    _scheduleAnnouncement();
    _scheduleLaunchGiftNotice();
  }

  /// Says what the update they already installed changed.
  ///
  /// Ahead of the update prompt in the queue below, because it is about the
  /// build in their hand rather than one that can wait for tomorrow.
  void _scheduleAnnouncement() {
    final announcements = _announcements;
    if (_announcementScheduled ||
        announcements == null ||
        !announcements.shouldAnnounce ||
        (_store?.launchGiftNoticePending ?? false) ||
        _store?.pendingXpNotice != null) {
      return;
    }
    _announcementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _announcementScheduled = false;
      if (!mounted || !announcements.shouldAnnounce) return;
      await showReleaseAnnouncement(context, announcements: announcements);
      if (mounted) _scheduleUpdatePrompt();
    });
  }

  /// Offers the update once the frame is done and nothing louder is queued.
  ///
  /// Last in the queue of things that may interrupt a launch, behind a
  /// level-up and behind the release card. Both of those are about something
  /// that already happened; the update will still be there tomorrow, and
  /// stacking dialogs buries whichever goes first.
  void _scheduleUpdatePrompt() {
    final updates = _updates;
    if (_updatePromptScheduled ||
        updates == null ||
        !updates.shouldPrompt ||
        _store?.pendingXpNotice != null ||
        (_store?.launchGiftNoticePending ?? false) ||
        (_announcements?.shouldAnnounce ?? false)) {
      return;
    }
    _updatePromptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _updatePromptScheduled = false;
      // The version row is worth a moment's wait. Play's round trip is far
      // slower than reading the package info, so this normally costs nothing
      // — but without it the row appears or not depending on which future
      // won, and a dialog that is one line taller on some launches than on
      // others looks like a bug to the person reading it.
      await _versionReady;
      if (!mounted || !updates.shouldPrompt) return;
      await showUpdatePrompt(
        context,
        updates: updates,
        currentVersion: _runningVersion,
      );
    });
  }

  Future<void> _openStoreFromBanner() async {
    final updates = _updates;
    if (updates == null) return;
    final messenger = ScaffoldMessenger.of(context);
    if (await updates.openStore()) return;
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).updateStoreFailed)),
      );
  }

  void _scheduleXpNotice() {
    if (_xpNoticeScheduled || _store?.pendingXpNotice == null) return;
    _xpNoticeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _xpNoticeScheduled = false;
      if (!mounted) return;
      unawaited(_presentXpNotice().whenComplete(_scheduleLaunchGiftNotice));
    });
  }

  void _scheduleLaunchGiftNotice() {
    if (_launchGiftScheduled ||
        _launchGiftPresenting ||
        !(_store?.launchGiftNoticePending ?? false) ||
        _store?.pendingXpNotice != null) {
      return;
    }
    _launchGiftScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _launchGiftScheduled = false;
      if (mounted) unawaited(_presentLaunchGift());
    });
  }

  Future<void> _presentLaunchGift() async {
    final store = _store;
    if (_launchGiftPresenting || store == null || !mounted) return;
    _launchGiftPresenting = true;
    try {
      if (!store.launchGiftNoticePending) return;
      final placeNow = await showLaunchGiftDialog(context);
      if (!mounted) return;
      await store.takeLaunchGiftNotice();
      if (placeNow) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const RoomDecorateScreen()),
        );
      }
    } on Object {
      // If saving the seen state fails, it remains pending for the next open.
    } finally {
      _launchGiftPresenting = false;
      if (mounted) {
        _scheduleAnnouncement();
        _scheduleUpdatePrompt();
      }
    }
  }

  Future<void> _presentXpNotice() async {
    final notice = _store?.takePendingXpNotice();
    if (notice == null || !mounted) return;
    final newLevel = notice.newLevel;
    if (newLevel != null) {
      // A level-up is rare enough to interrupt for; everyday XP is not.
      final previousLevel = notice.previousLevel ?? newLevel - 1;
      final l10n = AppLocalizations.of(context);
      final unlockedItemNames =
          CatalogPreviewData.levelItemsUnlockedBetween(
                previousLevel: previousLevel,
                currentLevel: newLevel,
              )
              .map((entry) => catalogEntryDisplayName(l10n, entry))
              .toList(growable: false);
      await showLevelUpCelebration(
        context,
        newLevel,
        newlyUnlockedItemNames: unlockedItemNames,
      );
      if (!mounted) return;
    }
    if (notice.kind == XpNoticeKind.cyclesClosed) {
      // The celebration of a closed cycle is a screen, not a snack bar.
      // Ads are not played here; the card only opens the collection.
      final record = _store?.cycleRecords.firstOrNull;
      final reviews = AppReviewScope.maybeOf(context);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SettlementScreen(notice: notice, record: record),
        ),
      );
      // After the screen, not on it: Play's sheet over the result would cover
      // the very number that made this a good moment to ask.
      if (mounted) await reviews?.afterSettlement(record);
      return;
    }
    if (newLevel != null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(xpSnackBar(context, notice));
  }

  void _select(AppTab tab) {
    // Re-tapping the selected tab is not another visit. This distinction is
    // what makes "one native impression per transactions visit" deterministic.
    if (tab == _selected) return;
    _changeSelection(tab);
    if (tab == AppTab.budget) {
      unawaited(_store?.noteBudgetReviewed() ?? Future<void>.value());
    }
  }

  void _changeSelection(AppTab tab) {
    if (tab == _selected) return;
    _noteTabTransition(tab);
    setState(() => _selected = tab);
  }

  void _noteTabTransition(AppTab next) {
    final nativeAds = NativeAdScope.maybeOf(context);
    if (_selected == AppTab.movements && next != AppTab.movements) {
      nativeAds?.endVisit();
    }
    if (_selected != AppTab.movements && next == AppTab.movements) {
      nativeAds?.startVisit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(active: _selected == AppTab.home),
      const TransactionsScreen(),
      RegisterScreen(
        key: ValueKey('register-$_registerSession'),
        onSaved: () => _select(AppTab.home),
        initialMode: _registerMode,
        focusAmountOnOpen: _registerSession > 0,
      ),
      BudgetScreen(active: _selected == AppTab.budget),
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
                  // Inicio only. The line is a small interruption on the
                  // screen the app opens on, and would be a running one if it
                  // sat above every tab.
                  if (_selected == AppTab.home &&
                      (_updates?.showBanner ?? false))
                    UpdateBanner(
                      onUpdate: () => unawaited(_openStoreFromBanner()),
                      onDismiss: () => _updates?.hideBanner(),
                    ),
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
        height: kPixelBottomBarHeight,
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
