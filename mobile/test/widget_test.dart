import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/shared/widgets/guardian_button.dart';
import 'package:mobile/shared/widgets/guardian_badge.dart';
import 'package:mobile/shared/widgets/risk_donut_chart.dart';
import 'package:mobile/shared/models/dashboard_stats_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Shared Widgets Tests', () {
    testWidgets('GuardianButton renders label and triggers tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuardianButton(
              label: 'Scan Now',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Scan Now'), findsOneWidget);
      await tester.tap(find.text('Scan Now'));
      expect(tapped, isTrue);
    });

    testWidgets('GuardianBadge renders severity badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GuardianBadge.severity('CRITICAL'),
                GuardianBadge.status('RUNNING'),
                GuardianBadge.service('EC2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('RUNNING'), findsOneWidget);
      expect(find.text('EC2'), findsOneWidget);
    });

    testWidgets('RiskDonutChart renders overview', (tester) async {
      final overview = RiskOverview(
        critical: 2,
        high: 3,
        medium: 1,
        low: 0,
        totalAlerts: 6,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RiskDonutChart(riskOverview: overview),
            ),
          ),
        ),
      );

      expect(find.text('Risk Overview'), findsOneWidget);
      expect(find.text('Total Alerts'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });
  });
}
