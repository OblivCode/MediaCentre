import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:media_centre/screens/library_screen.dart';
import 'package:media_centre/services/volume_manager.dart';
import 'package:media_centre/services/volume_provider.dart';
import 'package:media_centre/models/collection_block.dart';
import 'package:media_centre/models/movie_block.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockVolumeManager extends Mock implements VolumeManager {}

class MockVolumeProvider extends Mock implements VolumeProvider {}

class FakeMovieBlock extends Fake implements MovieBlock {}

void main() {
  late MockVolumeManager mockManager;

  setUpAll(() {
    registerFallbackValue(FakeMovieBlock());
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    mockManager = MockVolumeManager();
  });

  Widget createTestWidget() {
    return ChangeNotifierProvider<VolumeManager>.value(
      value: mockManager,
      child: const MaterialApp(home: LibraryScreen()),
    );
  }

  group('LibraryScreen', () {
    testWidgets('shows empty state when library is empty', (tester) async {
      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.activeVolume).thenReturn(null);
      when(() => mockManager.library)
          .thenReturn(CollectionBlock(id: 'root', title: 'My Library'));
      when(() => mockManager.loadLibrary()).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No movies yet.\nTap + to add one.'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      when(() => mockManager.isLoading).thenReturn(true);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.activeVolume).thenReturn(null);
      when(() => mockManager.library)
          .thenReturn(CollectionBlock(id: 'root', title: 'My Library'));

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state when error is set', (tester) async {
      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.error).thenReturn('Test error message');
      when(() => mockManager.activeVolume).thenReturn(null);
      when(() => mockManager.library)
          .thenReturn(CollectionBlock(id: 'root', title: 'My Library'));
      when(() => mockManager.loadLibrary()).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Test error message'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows movies in list', (tester) async {
      final movies = [
        MovieBlock(
            id: '1', title: 'Movie 1', runtimeMinutes: 120, userRating: 4),
        MovieBlock(
            id: '2', title: 'Movie 2', runtimeMinutes: 90, userRating: 3),
      ];
      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.activeVolume).thenReturn(null);
      when(() => mockManager.library).thenReturn(
          CollectionBlock(id: 'root', title: 'My Library', children: movies));
      when(() => mockManager.deleteMovie(any())).thenAnswer((_) async => true);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Movie 1'), findsOneWidget);
      expect(find.text('Movie 2'), findsOneWidget);
      expect(find.text('120 min'), findsOneWidget);
      expect(find.text('90 min'), findsOneWidget);
    });

    testWidgets('deleteMovie is called when swiping to dismiss',
        (tester) async {
      final movie = MovieBlock(id: '1', title: 'Test Movie');
      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.activeVolume).thenReturn(null);
      when(() => mockManager.library).thenReturn(
          CollectionBlock(id: 'root', title: 'My Library', children: [movie]));
      when(() => mockManager.deleteMovie('1')).thenAnswer((_) async => true);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      verify(() => mockManager.deleteMovie('1')).called(1);
    });

    testWidgets('shows active volume name in app bar', (tester) async {
      final mockVolume = MockVolumeProvider();
      when(() => mockVolume.providerName).thenReturn('Test Volume');

      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.activeVolume).thenReturn(mockVolume);
      when(() => mockManager.library)
          .thenReturn(CollectionBlock(id: 'root', title: 'My Library'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Test Volume'), findsOneWidget);
    });

    testWidgets('settings button navigates to settings screen', (tester) async {
      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.activeVolume).thenReturn(null);
      when(() => mockManager.library)
          .thenReturn(CollectionBlock(id: 'root', title: 'My Library'));
      when(() => mockManager.availableVolumes).thenReturn([]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
