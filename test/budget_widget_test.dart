import 'package:expensetracker/models/budget_model.dart';
import 'package:expensetracker/models/category_model.dart';
import 'package:expensetracker/providers/budget_provider.dart';
import 'package:expensetracker/providers/category_provider.dart';
import 'package:expensetracker/views/budgets/budgets_screen.dart';
import 'package:expensetracker/views/budgets/widgets/budgets_content.dart';
import 'package:expensetracker/views/budgets/widgets/add_budget_amount_field.dart';
import 'package:expensetracker/views/budgets/widgets/add_budget_category_selector.dart';
import 'package:expensetracker/views/budgets/widgets/add_budget_sheet.dart';
import 'package:expensetracker/views/budgets/widgets/budget_tile_menu.dart';
import 'package:expensetracker/views/budgets/widgets/budgets_month_selector.dart';
import 'package:expensetracker/views/budgets/budgets_ui_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'BudgetsScreen renders month selector and content without crashing',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: BudgetsScreen())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BudgetsMonthSelector), findsOneWidget);
    },
  );

  testWidgets('empty state actions stack without a render overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final month = DateTime(2026, 9);
    final previousMonth = DateTime(2026, 8);
    const previousBudget = BudgetProgress(
      budget: BudgetModel(
        id: 'previous-budget',
        categoryId: 'bills',
        amount: 180,
        monthYear: '2026-08',
      ),
      spent: 80,
      category: CategoryModel(
        id: 'bills',
        name: 'Bills',
        type: 'expense',
        icon: 'receipt',
        color: '#3B82F6',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          monthBudgetProgressProvider(
            previousMonth,
          ).overrideWith((ref) async => [previousBudget]),
          monthBudgetProgressProvider(
            month,
          ).overrideWith((ref) async => <BudgetProgress>[]),
        ],
        child: MaterialApp(
          home: Scaffold(body: BudgetsEmptyState(month: month)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Budget'), findsOneWidget);
    expect(find.text('Copy Last Month'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('budget edit dialog remains laid out when keyboard is open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 360);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    const progress = BudgetProgress(
      budget: BudgetModel(
        id: 'budget-1',
        categoryId: 'food',
        amount: 250,
        monthYear: '2026-09',
      ),
      spent: 80,
      category: CategoryModel(
        id: 'food',
        name: 'Food',
        type: 'expense',
        icon: 'restaurant',
        color: '#EF4444',
      ),
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: BudgetTileMenu(progress: progress)),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit budget for Food'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField), '300');
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Save'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('add budget sheet remains usable when keyboard opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddBudgetSheet(),
                  ),
                  child: const Text('Open budget sheet'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open budget sheet'));
    await tester.pumpAndSettle();
    expect(find.byType(AddBudgetAmountField), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.viewInsets = const FakeViewPadding(bottom: 340);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(AddBudgetAmountField), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final amountFieldRect = tester.getRect(find.byType(AddBudgetAmountField));
    final saveButtonRect = tester.getRect(find.text('Save'));
    expect(amountFieldRect.bottom, lessThanOrEqualTo(saveButtonRect.top));
    expect(
      saveButtonRect.bottom,
      lessThanOrEqualTo(tester.view.physicalSize.height - 340),
    );
  });

  testWidgets('category with an existing budget cannot be selected again', (
    tester,
  ) async {
    final month = DateTime(2026, 9);
    const existingCategory = CategoryModel(
      id: 'bills',
      name: 'Bills',
      type: 'expense',
      icon: 'receipt',
      color: '#3B82F6',
    );
    const availableCategory = CategoryModel(
      id: 'food',
      name: 'Food',
      type: 'expense',
      icon: 'restaurant',
      color: '#EF4444',
    );
    const existingBudget = BudgetProgress(
      budget: BudgetModel(
        id: 'budget-bills',
        categoryId: 'bills',
        amount: 120,
        monthYear: '2026-09',
      ),
      spent: 20,
      category: existingCategory,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedBudgetMonthProvider.overrideWithValue(month),
          expenseCategoriesProvider.overrideWith(
            (ref) async => [existingCategory, availableCategory],
          ),
          monthBudgetProgressProvider(
            month,
          ).overrideWith((ref) async => [existingBudget]),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AddBudgetCategorySelector(),
                _SelectedBudgetCategory(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bills'));
    await tester.pump();
    expect(find.text('Already set'), findsOneWidget);
    expect(find.text('none'), findsOneWidget);

    await tester.tap(find.text('Food'));
    await tester.pump();
    expect(find.text('food'), findsOneWidget);
  });
}

class _SelectedBudgetCategory extends ConsumerWidget {
  const _SelectedBudgetCategory();

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      Text(ref.watch(addBudgetCategoryProvider) ?? 'none');
}
