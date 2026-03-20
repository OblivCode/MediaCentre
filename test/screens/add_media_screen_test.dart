import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_centre/screens/add_media_screen.dart';
import 'package:media_centre/models/movie_block.dart';

void main() {
  group('AddMediaScreen', () {
    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AddMediaScreen(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('displays form fields', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Runtime (minutes)'), findsOneWidget);
      expect(find.text('Rating'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows error when title is empty', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a title'), findsOneWidget);
    });

    testWidgets('shows error when runtime is empty', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Test Movie');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter runtime'), findsOneWidget);
    });

    testWidgets('shows error when runtime is invalid', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Test Movie');
      await tester.enterText(find.byType(TextFormField).last, 'invalid');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid number'), findsOneWidget);
    });

    testWidgets('shows error when runtime is negative', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Test Movie');
      await tester.enterText(find.byType(TextFormField).last, '-5');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid number'), findsOneWidget);
    });

    testWidgets('returns MovieBlock when form is valid', (tester) async {
      MovieBlock? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await Navigator.push<MovieBlock>(
                    context,
                    MaterialPageRoute(builder: (_) => const AddMediaScreen()),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Test Movie');
      await tester.enterText(find.byType(TextFormField).last, '120');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.title, 'Test Movie');
      expect(result!.runtimeMinutes, 120);
    });

    testWidgets('star rating can be changed', (tester) async {
      await pumpScreen(tester);

      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.star_border).last);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsNWidgets(5));
    });

    testWidgets('default rating is 3 stars', (tester) async {
      await pumpScreen(tester);

      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });

    testWidgets('app bar shows correct title', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Add Movie'), findsOneWidget);
    });
  });
}
