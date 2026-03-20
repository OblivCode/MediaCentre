import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:media_centre/services/volume_manager.dart';
import 'package:media_centre/services/volume_provider.dart';
import 'package:media_centre/models/collection_block.dart';
import 'package:media_centre/models/movie_block.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockVolumeProvider extends Mock implements VolumeProvider {}

void main() {
  late VolumeManager manager;
  late MockVolumeProvider mockVolume;

  setUpAll(() {
    registerFallbackValue(CollectionBlock(id: 'fallback', title: 'Fallback'));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    manager = VolumeManager();
    mockVolume = MockVolumeProvider();

    when(() => mockVolume.providerId).thenReturn('test-volume');
    when(() => mockVolume.providerName).thenReturn('Test Volume');
    when(() => mockVolume.requiresAuth).thenReturn(false);
    when(() => mockVolume.isAuthenticated).thenReturn(true);
    when(() => mockVolume.loadLibrary())
        .thenAnswer((_) async => CollectionBlock(
              id: 'root',
              title: 'Test Library',
              children: [],
            ));
    when(() => mockVolume.saveLibrary(any())).thenAnswer((_) async => true);
  });

  group('VolumeManager', () {
    test('initial state has available volumes', () {
      expect(manager.availableVolumes.length, greaterThan(0));
    });

    test('initial isLoading is false', () {
      expect(manager.isLoading, false);
    });

    test('initial error is null', () {
      expect(manager.error, null);
    });

    test('setVolume loads library and sets active volume', () async {
      await manager.setVolume(mockVolume);

      expect(manager.activeVolume, mockVolume);
      expect(manager.library.id, 'root');
      verify(() => mockVolume.loadLibrary()).called(1);
    });

    test('setVolume handles authentication when required', () async {
      final authVolume = MockVolumeProvider();
      when(() => authVolume.providerId).thenReturn('auth-volume');
      when(() => authVolume.providerName).thenReturn('Auth Volume');
      when(() => authVolume.requiresAuth).thenReturn(true);
      when(() => authVolume.isAuthenticated).thenReturn(false);
      when(() => authVolume.authenticate()).thenAnswer((_) async => true);
      when(() => authVolume.loadLibrary())
          .thenAnswer((_) async => CollectionBlock(
                id: 'auth-root',
                title: 'Auth Library',
              ));

      await manager.setVolume(authVolume);

      verify(() => authVolume.authenticate()).called(1);
      verify(() => authVolume.loadLibrary()).called(1);
    });

    test('setVolume sets error when authentication fails', () async {
      final authVolume = MockVolumeProvider();
      when(() => authVolume.providerId).thenReturn('auth-volume');
      when(() => authVolume.providerName).thenReturn('Auth Volume');
      when(() => authVolume.requiresAuth).thenReturn(true);
      when(() => authVolume.isAuthenticated).thenReturn(false);
      when(() => authVolume.authenticate()).thenAnswer((_) async => false);

      await manager.setVolume(authVolume);

      expect(manager.error, 'Authentication failed');
      verifyNever(() => authVolume.loadLibrary());
    });

    test('addMovie updates library and saves', () async {
      await manager.setVolume(mockVolume);
      final movie = MovieBlock(id: '1', title: 'Test Movie');

      final result = await manager.addMovie(movie);

      expect(result, true);
      expect(manager.library.children.length, 1);
      verify(() => mockVolume.saveLibrary(any())).called(1);
    });

    test('addMovie returns false when no active volume', () async {
      final movie = MovieBlock(id: '1', title: 'Test Movie');

      final result = await manager.addMovie(movie);

      expect(result, false);
    });

    test('addMovie sets error when save fails', () async {
      when(() => mockVolume.saveLibrary(any())).thenAnswer((_) async => false);
      await manager.setVolume(mockVolume);
      final movie = MovieBlock(id: '1', title: 'Test Movie');

      await manager.addMovie(movie);

      expect(manager.error, 'Failed to save movie');
    });

    test('deleteMovie removes from library and saves', () async {
      final movie = MovieBlock(id: '1', title: 'Test Movie');
      final library =
          CollectionBlock(id: 'root', title: 'Library', children: [movie]);
      when(() => mockVolume.loadLibrary()).thenAnswer((_) async => library);

      await manager.setVolume(mockVolume);
      expect(manager.library.children.length, 1);

      final result = await manager.deleteMovie('1');

      expect(result, true);
      expect(manager.library.children.length, 0);
      verify(() => mockVolume.saveLibrary(any())).called(1);
    });

    test('deleteMovie returns false when no active volume', () async {
      final result = await manager.deleteMovie('nonexistent');

      expect(result, false);
    });

    test('loadLibrary reloads from active volume', () async {
      final movie = MovieBlock(id: 'new', title: 'New Movie');
      when(() => mockVolume.loadLibrary())
          .thenAnswer((_) async => CollectionBlock(
                id: 'root',
                title: 'Updated',
                children: [movie],
              ));

      await manager.setVolume(mockVolume);
      await manager.loadLibrary();

      expect(manager.library.children.length, 1);
    });

    test('loadLibrary does nothing when no active volume', () async {
      await manager.loadLibrary();

      expect(manager.library.id, 'root');
    });

    test('clearError removes error', () async {
      final authVolume = MockVolumeProvider();
      when(() => authVolume.providerId).thenReturn('auth-volume');
      when(() => authVolume.providerName).thenReturn('Auth Volume');
      when(() => authVolume.requiresAuth).thenReturn(true);
      when(() => authVolume.isAuthenticated).thenReturn(false);
      when(() => authVolume.authenticate()).thenAnswer((_) async => false);

      await manager.setVolume(authVolume);
      expect(manager.error, isNotNull);

      manager.clearError();

      expect(manager.error, null);
    });
  });
}
