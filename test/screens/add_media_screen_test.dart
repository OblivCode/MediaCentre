import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_centre/screens/add_media_screen.dart';

void main() {
  testWidgets('AddMediaScreen shows search UI', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AddMediaScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Add Media'), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text('TV Shows'), findsOneWidget);
    expect(find.text('Search for a movie to add'), findsOneWidget);
  });
}
