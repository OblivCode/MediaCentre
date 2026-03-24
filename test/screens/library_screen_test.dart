import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:media_centre/models/collection_block.dart';
import 'package:media_centre/models/audio_blocks.dart';
import 'package:media_centre/models/movie_block.dart';
import 'package:media_centre/screens/library_domain.dart';
import 'package:media_centre/screens/library_screen.dart';
import 'package:media_centre/services/tmdb_service.dart';
import 'package:media_centre/services/volume_manager.dart';
import 'package:media_centre/services/volume_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockVolumeManager extends Mock implements VolumeManager {}

class MockVolumeProvider extends Mock implements VolumeProvider {}

class FakeMovieBlock extends Fake implements MovieBlock {}

class FakeAlbumBlock extends Fake implements AlbumBlock {}

void main() {
  late MockVolumeManager mockManager;

  setUpAll(() {
    registerFallbackValue(FakeMovieBlock());
    registerFallbackValue(FakeAlbumBlock());
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    mockManager = MockVolumeManager();
  });

  Widget createTestWidget() {
    return Provider<TmdbService>.value(
      value: TmdbService(),
      child: ChangeNotifierProvider<VolumeManager>.value(
        value: mockManager,
        child: const MaterialApp(home: LibraryScreen()),
      ),
    );
  }

  group('LibraryScreen', () {
    testWidgets('shows empty state when library is empty', (tester) async {
      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.activeVolume).thenReturn(null);
      when(() => mockManager.library)
          .thenReturn(CollectionBlock(id: 'root', title: 'My Library'));
      when(() => mockManager.watchableMedia).thenReturn([]);
      when(() => mockManager.readableMedia).thenReturn([]);
      when(() => mockManager.listableMedia).thenReturn([]);
      when(() => mockManager.rootCollections).thenReturn([]);
      when(() => mockManager.loadLibrary()).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No movies yet.\nTap + to add one.'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows album cards in listen domain', (tester) async {
      final albums = [
        AlbumBlock(
          id: '1',
          title: 'Album 1',
          artist: 'Artist 1',
          trackCount: 10,
          listenCount: 2,
          userRating: 4,
        ),
      ];
      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.activeVolume).thenReturn(null);
      when(() => mockManager.library).thenReturn(
        CollectionBlock(id: 'root', title: 'My Library', children: albums),
      );
      when(() => mockManager.watchableMedia).thenReturn([]);
      when(() => mockManager.readableMedia).thenReturn([]);
      when(() => mockManager.listableMedia).thenReturn(albums);
      when(() => mockManager.rootCollections).thenReturn([]);
      when(() => mockManager.loadLibrary()).thenAnswer((_) async {});
      when(() => mockManager.updateAlbum(any())).thenAnswer((_) async => true);

      await tester.pumpWidget(
        Provider<TmdbService>.value(
          value: TmdbService(),
          child: ChangeNotifierProvider<VolumeManager>.value(
            value: mockManager,
            child: const MaterialApp(
              home: LibraryScreen(domain: LibraryDomain.listen),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Album 1'), findsOneWidget);
      expect(find.text('Artist 1 • 10 tracks • 2 listens'), findsOneWidget);
    });

    testWidgets('sorts items by title when requested', (tester) async {
      final oldItem = MovieBlock(
        id: '1',
        title: 'Zulu',
        dateAdded: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );
      final newItem = MovieBlock(
        id: '2',
        title: 'Alpha',
        dateAdded: DateTime.parse('2024-02-01T00:00:00.000Z'),
      );
      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.activeVolume).thenReturn(null);
      when(() => mockManager.library).thenReturn(
        CollectionBlock(
            id: 'root', title: 'My Library', children: [oldItem, newItem]),
      );
      when(() => mockManager.watchableMedia).thenReturn([oldItem, newItem]);
      when(() => mockManager.readableMedia).thenReturn([]);
      when(() => mockManager.listableMedia).thenReturn([]);
      when(() => mockManager.rootCollections).thenReturn([]);

      await tester.pumpWidget(
        Provider<TmdbService>.value(
          value: TmdbService(),
          child: ChangeNotifierProvider<VolumeManager>.value(
            value: mockManager,
            child: const MaterialApp(
              home: LibraryScreen(
                sort: LibrarySort.title,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final alphaDy = tester.getTopLeft(find.text('Alpha')).dy;
      final zuluDy = tester.getTopLeft(find.text('Zulu')).dy;
      expect(alphaDy, lessThan(zuluDy));
    });

    testWidgets('pull to refresh reloads library', (tester) async {
      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.activeVolume).thenReturn(null);
      when(() => mockManager.library)
          .thenReturn(CollectionBlock(id: 'root', title: 'My Library'));
      when(() => mockManager.watchableMedia).thenReturn([]);
      when(() => mockManager.readableMedia).thenReturn([]);
      when(() => mockManager.listableMedia).thenReturn([]);
      when(() => mockManager.rootCollections).thenReturn([]);
      when(() => mockManager.loadLibrary()).thenAnswer((_) async {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      verify(() => mockManager.loadLibrary()).called(greaterThan(0));
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      when(() => mockManager.isLoading).thenReturn(true);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.activeVolume).thenReturn(null);
      when(() => mockManager.library)
          .thenReturn(CollectionBlock(id: 'root', title: 'My Library'));
      when(() => mockManager.watchableMedia).thenReturn([]);
      when(() => mockManager.readableMedia).thenReturn([]);
      when(() => mockManager.listableMedia).thenReturn([]);
      when(() => mockManager.rootCollections).thenReturn([]);

      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state when error is set', (tester) async {
      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.error).thenReturn('Test error message');
      when(() => mockManager.activeVolume).thenReturn(null);
      when(() => mockManager.library)
          .thenReturn(CollectionBlock(id: 'root', title: 'My Library'));
      when(() => mockManager.watchableMedia).thenReturn([]);
      when(() => mockManager.readableMedia).thenReturn([]);
      when(() => mockManager.listableMedia).thenReturn([]);
      when(() => mockManager.rootCollections).thenReturn([]);
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
        CollectionBlock(id: 'root', title: 'My Library', children: movies),
      );
      when(() => mockManager.watchableMedia).thenReturn(movies);
      when(() => mockManager.readableMedia).thenReturn([]);
      when(() => mockManager.listableMedia).thenReturn([]);
      when(() => mockManager.rootCollections).thenReturn([]);
      when(() => mockManager.deleteMovie(any())).thenAnswer((_) async => true);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Movie 1'), findsOneWidget);
      expect(find.text('Movie 2'), findsOneWidget);
      expect(find.text('120 min'), findsOneWidget);
      expect(find.text('90 min'), findsOneWidget);
    });

    testWidgets('shows active volume name in app bar', (tester) async {
      final mockVolume = MockVolumeProvider();
      when(() => mockVolume.providerName).thenReturn('Test Volume');

      when(() => mockManager.isLoading).thenReturn(false);
      when(() => mockManager.error).thenReturn(null);
      when(() => mockManager.activeVolume).thenReturn(mockVolume);
      when(() => mockManager.library)
          .thenReturn(CollectionBlock(id: 'root', title: 'My Library'));
      when(() => mockManager.watchableMedia).thenReturn([]);
      when(() => mockManager.readableMedia).thenReturn([]);
      when(() => mockManager.listableMedia).thenReturn([]);
      when(() => mockManager.rootCollections).thenReturn([]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Test Volume'), findsOneWidget);
    });
  });
}
