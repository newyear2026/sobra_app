import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/room_time_of_day.dart';
import '../state/sobra_store.dart';

/// Builds with the room's current time of day, and again whenever it changes.
///
/// The phase is read from the store's clock, so tests pin it the way they pin
/// everything else. It is re-read when the app comes back to the foreground
/// and at each phase boundary while it stays open, so a room left on screen
/// through the evening still turns to night.
class RoomTimeOfDayBuilder extends StatefulWidget {
  const RoomTimeOfDayBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, RoomTimeOfDay phase) builder;

  @override
  State<RoomTimeOfDayBuilder> createState() => _RoomTimeOfDayBuilderState();
}

class _RoomTimeOfDayBuilderState extends State<RoomTimeOfDayBuilder>
    with WidgetsBindingObserver {
  Timer? _boundary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _boundary?.cancel();
    super.dispose();
  }

  void _scheduleBoundary(DateTime now) {
    _boundary?.cancel();
    _boundary = Timer(RoomTimeOfDay.nextChangeAfter(now).difference(now), () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = SobraScope.of(context).currentMoment;
    _scheduleBoundary(now);
    return widget.builder(context, RoomTimeOfDay.fromLocal(now));
  }
}
