import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_shop/theme/app_theme.dart';
import 'package:red_shop/utils/formatters.dart';
import 'package:red_shop/widgets/shop_widgets.dart';

void main() {
  test('formatCurrency adds separators and decimals', () {
    expect(formatCurrency(1234.5), 'ETB 1,234.50');
    expect(formatCurrency(-75), '-ETB 75.00');
  });

  testWidgets('DashboardStatCard fits a mobile dashboard tile', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 148,
              height: 196,
              child: DashboardStatCard(
                title: 'Money in',
                value: 'ETB 7,000.00',
                subtitle: '2 sales done',
                icon: Icons.payments_outlined,
                color: AppTheme.success,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('ActionShortcutCard fits a mobile action tile', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 148,
              height: 188,
              child: ActionShortcutCard(
                icon: Icons.local_shipping_outlined,
                title: 'Restocking',
                subtitle: 'Record new stock',
                hint: 'Tap to open',
                color: AppTheme.warning,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(ActionShortcutCard));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('HeroMetricBadge is tappable for detail shortcuts', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: HeroMetricBadge(
              icon: Icons.trending_up_outlined,
              label: 'Net profit',
              value: 'ETB 5,000.00',
              hint: 'Tap to open',
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(HeroMetricBadge));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
