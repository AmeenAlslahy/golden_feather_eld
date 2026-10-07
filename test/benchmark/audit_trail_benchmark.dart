// ignore_for_file: avoid_print, prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Standalone benchmark for AuditTrailPage list rendering
void main() {
  group('AuditTrailPage rendering benchmark', () {
    Widget buildTestApp(int itemCount) {
      return MaterialApp(
        home: Scaffold(
          body: ListView.separated(
            itemCount: itemCount,
            itemBuilder: (context, index) => ListTile(
              title: Text('Action $index'),
              subtitle: Text('Time: 12:00 PM'),
              trailing: Text('Driver $index'),
            ),
            separatorBuilder: (context, index) => const Divider(),
          ),
        ),
      );
    }

    testWidgets('Benchmark 1000 records', (tester) async {
      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(buildTestApp(1000));
      await tester.pumpAndSettle();
      stopwatch.stop();
      print('AuditTrailPage with 1000 records took: ${stopwatch.elapsedMilliseconds} ms');
    });

    testWidgets('Benchmark 5000 records', (tester) async {
      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(buildTestApp(5000));
      await tester.pumpAndSettle();
      stopwatch.stop();
      print('AuditTrailPage with 5000 records took: ${stopwatch.elapsedMilliseconds} ms');
    });
  });
}
