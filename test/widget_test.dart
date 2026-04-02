// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_planner/app.dart';

void main() {
  testWidgets('App launches and shows bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StudentPlannerApp());
    await tester.pumpAndSettle();

    // เช็คว่า Bottom Navigation แสดงครบ 5 tabs
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Grades'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
  });
}
