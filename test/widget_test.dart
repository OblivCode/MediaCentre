import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_centre/main.dart';

void main() {
  testWidgets('App loads and shows empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const MediaCentreApp());
    await tester.pumpAndSettle();

    expect(find.text('MediaCentre'), findsOneWidget);
    expect(find.text('No movies yet.\nTap + to add one.'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
