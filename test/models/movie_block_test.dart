import 'package:flutter_test/flutter_test.dart';
import 'package:media_centre/models/movie_block.dart';

void main() {
  group('MovieBlock', () {
    test('creates with required parameters', () {
      final movie = MovieBlock(id: 'test-id', title: 'Test Movie');

      expect(movie.id, 'test-id');
      expect(movie.title, 'Test Movie');
      expect(movie.runtimeMinutes, 0);
      expect(movie.userRating, 0);
    });

    test('creates with all parameters', () {
      final movie = MovieBlock(
        id: 'test-id',
        title: 'Test Movie',
        runtimeMinutes: 120,
        userRating: 4,
      );

      expect(movie.runtimeMinutes, 120);
      expect(movie.userRating, 4);
    });

    test('toJson and fromJson round trip', () {
      final original = MovieBlock(
        id: 'test-id',
        title: 'Test Movie',
        runtimeMinutes: 120,
        userRating: 4,
      );

      final json = original.toJson();
      final restored = MovieBlock.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.runtimeMinutes, original.runtimeMinutes);
      expect(restored.userRating, original.userRating);
    });

    test('fromJson handles missing optional fields', () {
      final json = {'id': 'test-id', 'title': 'Test Movie'};

      final movie = MovieBlock.fromJson(json);

      expect(movie.runtimeMinutes, 0);
      expect(movie.userRating, 0);
    });

    test('toJson includes type field', () {
      final movie = MovieBlock(id: 'test-id', title: 'Test Movie');

      expect(movie.toJson()['type'], 'movie');
    });

    test('copyWith preserves unchanged values', () {
      final original = MovieBlock(
        id: 'test-id',
        title: 'Test Movie',
        runtimeMinutes: 120,
        userRating: 4,
      );

      final copied = original.copyWith(title: 'New Title');

      expect(copied.id, 'test-id');
      expect(copied.title, 'New Title');
      expect(copied.runtimeMinutes, 120);
      expect(copied.userRating, 4);
    });

    test('copyWith updates all values', () {
      final original = MovieBlock(
        id: 'test-id',
        title: 'Test Movie',
        runtimeMinutes: 120,
        userRating: 4,
      );

      final copied = original.copyWith(
        id: 'new-id',
        title: 'New Title',
        runtimeMinutes: 90,
        userRating: 5,
      );

      expect(copied.id, 'new-id');
      expect(copied.title, 'New Title');
      expect(copied.runtimeMinutes, 90);
      expect(copied.userRating, 5);
    });
  });
}
