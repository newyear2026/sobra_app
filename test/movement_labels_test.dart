import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobra_app/l10n/generated/app_localizations.dart';
import 'package:sobra_app/l10n/labels.dart';
import 'package:sobra_app/main.dart';
import 'package:sobra_app/models/cash_reconciliation.dart';
import 'package:sobra_app/models/expense_entry.dart';
import 'package:sobra_app/models/income_entry.dart';
import 'package:sobra_app/models/money_movement.dart';
import 'package:sobra_app/models/pay_schedule.dart';
import 'package:sobra_app/services/sobra_widget_sync.dart';
import 'package:sobra_app/state/sobra_store.dart';

import 'support/localizations.dart';

/// What a movement row says is built in the view now, so these tests read the
/// words the same way a screen does instead of asking the store for them.
final l10n = lookupAppLocalizations(const Locale('es'));

MoneyMovement _expenseMovement(ExpenseEntry entry) => MoneyMovement(
  id: entry.id,
  amountCentavos: -entry.amountCentavos,
  occurredAt: entry.occurredAt,
  type: MovementType.expense,
  expense: entry,
  isPending: entry.isPendingCashAdjustment,
);

void main() {
  final moment = DateTime(2026, 9, 5, 12);

  ExpenseEntry expense({
    String note = '',
    ExpenseCategory category = ExpenseCategory.food,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    bool pending = false,
  }) => ExpenseEntry(
    id: 'expense-1',
    amountCentavos: 12000,
    category: category,
    note: note,
    occurredAt: moment,
    paymentMethod: paymentMethod,
    isPendingCashAdjustment: pending,
  );

  group('an expense headline', () {
    test('falls back to its category when the user wrote no note', () {
      expect(expenseTitle(l10n, expense()), 'Comida');
    });

    test('keeps a note the user did write', () {
      expect(
        expenseTitle(l10n, expense(note: 'Taquería El Faro')),
        'Taquería El Faro',
      );
    });

    // Rows saved before the app localized its text carry the old Spanish
    // default in the note itself. They must keep reading as they always did.
    test('keeps a note left behind by an older version of the app', () {
      expect(expenseTitle(l10n, expense(note: 'Comida')), 'Comida');
    });

    test('names an unidentified cash difference by what it is', () {
      expect(
        expenseTitle(l10n, expense(pending: true)),
        'Diferencia por identificar',
      );
    });
  });

  group('a movement subtitle', () {
    test('pairs an expense category with how it was paid', () {
      expect(
        movementSubtitle(l10n, _expenseMovement(expense())),
        'Comida · Efectivo',
      );
      expect(
        movementSubtitle(
          l10n,
          _expenseMovement(
            expense(
              category: ExpenseCategory.transport,
              paymentMethod: PaymentMethod.card,
            ),
          ),
        ),
        'Transporte · Tarjeta',
      );
    });

    test('marks a pending cash expense as pending instead of by category', () {
      expect(
        movementSubtitle(l10n, _expenseMovement(expense(pending: true))),
        'Pendiente · Efectivo',
      );
    });

    test('pairs an income kind with where it went', () {
      final income = IncomeEntry(
        id: 'income-1',
        amountCentavos: 25000,
        kind: IncomeKind.extra,
        note: '',
        occurredAt: moment,
        destination: PaymentMethod.card,
        allocation: IncomeAllocation.savings,
      );
      final movement = MoneyMovement(
        id: income.id,
        amountCentavos: income.amountCentavos,
        occurredAt: moment,
        type: MovementType.income,
        income: income,
      );
      expect(incomeTitle(l10n, income), 'Ingreso extra');
      expect(movementSubtitle(l10n, movement), 'Ingreso extra · Ahorro');
    });

    test('says where a standalone adjustment came from', () {
      final reconciliation = CashReconciliationEntry(
        id: 'cash-1',
        expectedBeforeCentavos: 200000,
        actualCentavos: 198000,
        occurredAt: moment,
        resolution: CashResolution.correction,
      );
      final movement = MoneyMovement(
        id: reconciliation.id,
        amountCentavos: reconciliation.differenceCentavos,
        occurredAt: moment,
        type: MovementType.adjustment,
        reconciliation: reconciliation,
      );
      expect(movementTitle(l10n, movement), 'Corrección del conteo');
      expect(movementSubtitle(l10n, movement), 'Conteo de efectivo');
    });
  });

  group('the store', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<SobraStore> seeded() async {
      final store = await SobraStore.load(now: () => moment);
      await store.configureOnboarding(
        budgetCentavos: 600000,
        schedule: PaySchedule.irregular(
          planningHorizonDays: 15,
          irregularCycleStart: DateTime(2026, 9, 1),
        ),
      );
      await store.completeOnboarding();
      return store;
    }

    // The point of the refactor: no Spanish reaches saved data any more, so
    // the same row can be read back in another language later.
    test('saves an empty note rather than a translated default', () async {
      final store = await seeded();
      await store.addExpense(
        amountCentavos: 12000,
        category: ExpenseCategory.food,
        note: '   ',
        occurredAt: moment,
        paymentMethod: PaymentMethod.cash,
      );
      await store.addIncome(
        amountCentavos: 25000,
        kind: IncomeKind.extra,
        note: '',
        occurredAt: moment,
        destination: PaymentMethod.card,
        allocation: IncomeAllocation.cycle,
      );

      expect(store.transactions.single.note, '');
      expect(store.incomes.single.note, '');
      expect(expenseTitle(l10n, store.transactions.single), 'Comida');
      expect(incomeTitle(l10n, store.incomes.single), 'Ingreso extra');
    });

    test('labels the home widget payload the way the app does', () async {
      final store = await seeded();
      await store.addExpense(
        amountCentavos: 12000,
        category: ExpenseCategory.food,
        note: '',
        occurredAt: moment,
        paymentMethod: PaymentMethod.cash,
      );

      final payload = SobraWidgetSnapshot.fromStore(
        store,
        (movement) => movementTitle(l10n, movement),
      ).toPlatformMap();

      expect(payload['movement1Title'], 'Comida');
    });

    // The home widget is the one surface that cannot look up its own words.
    // This is the seam that carries them to it, end to end.
    testWidgets('the running app hands the sync its labeller', (tester) async {
      useSpanishDevice(tester);
      final store = await seeded();
      await store.addExpense(
        amountCentavos: 12000,
        category: ExpenseCategory.food,
        note: '',
        occurredAt: moment,
        paymentMethod: PaymentMethod.cash,
      );

      const channel = MethodChannel('com.sobra.app/widgets');
      final updates = <Map<Object?, Object?>>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'updateWidgets') {
          updates.add(call.arguments as Map<Object?, Object?>);
        }
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      await SobraWidgetSync.initialize(store);
      expect(
        updates.last['movement1Title'],
        '',
        reason: 'nothing can name a movement before the app is built',
      );

      // Inicio animates forever, so settle would never return; one frame is
      // all the app root needs to install the labeller.
      await tester.pumpWidget(SobraApp(store: store));
      await tester.pump();

      expect(updates.last['movement1Title'], 'Comida');
    });
  });
}
