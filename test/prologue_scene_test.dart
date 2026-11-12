import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/state/sobra_store.dart';
import 'package:sobra_app/widgets/prologue_scene.dart';

void main() {
  Future<SobraStore> store({required bool reducedMotion}) async {
    SharedPreferences.setMockInitialValues({});
    final result = await SobraStore.load();
    await result.setReducedMotion(reducedMotion);
    return result;
  }

  Widget scene(SobraStore store) => SobraScope(
    store: store,
    child: const MaterialApp(
      home: Scaffold(body: PrologueScene(height: 180, raining: true)),
    ),
  );

  testWidgets('rain drifts while motion is allowed', (tester) async {
    await tester.pumpWidget(scene(await store(reducedMotion: false)));
    await tester.pump();

    final first = tester.widget<CustomPaint>(find.byKey(PrologueScene.rainKey));
    // ignore: avoid_dynamic_calls
    final firstPhase = (first.painter as dynamic).phase;
    await tester.pump(const Duration(milliseconds: 180));
    final second = tester.widget<CustomPaint>(
      find.byKey(PrologueScene.rainKey),
    );
    // ignore: avoid_dynamic_calls
    final secondPhase = (second.painter as dynamic).phase;

    expect(secondPhase, isNot(firstPhase));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('rain stays still when reduced motion is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(scene(await store(reducedMotion: true)));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 300));
    final paint = tester.widget<CustomPaint>(find.byKey(PrologueScene.rainKey));
    // ignore: avoid_dynamic_calls
    expect((paint.painter as dynamic).phase, 0);
  });

  testWidgets('arrival walks in and then holds the story pose', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PrologueArrival(
          animate: true,
          moving: Text('moving'),
          arrived: Text('arrived'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('moving'), findsOneWidget);
    expect(find.text('arrived'), findsNothing);

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('moving'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('moving'), findsNothing);
    expect(find.text('arrived'), findsOneWidget);
  });

  testWidgets('arrival skips travel when motion is reduced', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PrologueArrival(
          animate: false,
          moving: Text('moving'),
          arrived: Text('arrived'),
        ),
      ),
    );

    expect(find.text('moving'), findsNothing);
    expect(find.text('arrived'), findsOneWidget);
  });
}
