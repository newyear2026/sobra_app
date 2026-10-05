import 'package:flutter_test/flutter_test.dart';
import 'package:sobra_app/services/app_telemetry.dart';

void main() {
  test(
    'reports the error type and stack without financial exception text',
    () async {
      String? receivedType;
      StackTrace? receivedStack;
      bool? receivedFatal;
      final telemetry = AppTelemetry(
        sendError: (type, stack, fatal) async {
          receivedType = type;
          receivedStack = stack;
          receivedFatal = fatal;
        },
      );
      final stack = StackTrace.current;
      await telemetry.reportError(
        FormatException('Private receipt and amount: 1234.56'),
        stack,
        fatal: true,
      );
      expect(receivedType, 'FormatException');
      expect(receivedStack, same(stack));
      expect(receivedFatal, isTrue);
    },
  );

  test(
    'failed SDK calls do not turn a successful app action into an error',
    () async {
      final telemetry = AppTelemetry(
        sendEvent: (_, _) => Future.error(StateError('SDK unavailable')),
        sendError: (_, _, _) => throw StateError('SDK unavailable'),
      );
      await expectLater(
        telemetry.event(TelemetryEvent.expenseRecorded),
        completes,
      );
      await expectLater(telemetry.screen(TelemetryScreen.budget), completes);
      await expectLater(
        telemetry.reportError(Exception('original'), StackTrace.current),
        completes,
      );
    },
  );

  test(
    'unconfigured platforms and widget tests need no Firebase instance',
    () async {
      final telemetry = AppTelemetry();
      await telemetry.screen(TelemetryScreen.home);
      await telemetry.event(TelemetryEvent.onboardingCompleted);
      await telemetry.reportError(Exception('offline'), StackTrace.current);
    },
  );
}
