import 'package:flutter_test/flutter_test.dart';
import 'package:media_centre/models/models.dart';

void main() {
  group('mediaBlockFromJson', () {
    test('creates MovieBlock for movie type', () {
      final json = {
        'type': 'movie',
        'id': 'test-id',
        'title': 'Test Movie',
        'runtimeMinutes': 120,
        'userRating': 4,
      };

      final block = mediaBlockFromJson(json);

      expect(block, isA<MovieBlock>());
      expect(block.id, 'test-id');
      expect(block.title, 'Test Movie');
      expect((block as MovieBlock).runtimeMinutes, 120);
    });

    test('creates CollectionBlock for collection type', () {
      final json = {
        'type': 'collection',
        'id': 'test-id',
        'title': 'Test Collection',
        'children': [],
      };

      final block = mediaBlockFromJson(json);

      expect(block, isA<CollectionBlock>());
      expect(block.id, 'test-id');
      expect(block.title, 'Test Collection');
    });

    test('throws ArgumentError for unknown type', () {
      final json = {'type': 'unknown', 'id': 'test-id', 'title': 'Test'};

      expect(() => mediaBlockFromJson(json), throwsArgumentError);
    });

    test('throws ArgumentError for missing type', () {
      final json = {'id': 'test-id', 'title': 'Test'};

      expect(() => mediaBlockFromJson(json), throwsA(isA<TypeError>()));
    });

    test('deserializes nested collections', () {
      final json = {
        'type': 'collection',
        'id': 'outer',
        'title': 'Outer',
        'children': [
          {
            'type': 'movie',
            'id': 'movie-1',
            'title': 'Movie',
          },
          {
            'type': 'collection',
            'id': 'inner',
            'title': 'Inner',
            'children': [],
          },
        ],
      };

      final block = mediaBlockFromJson(json) as CollectionBlock;

      expect(block.children.length, 2);
      expect(block.children[0], isA<MovieBlock>());
      expect(block.children[1], isA<CollectionBlock>());
    });

    test('preserves dateAdded for album blocks', () {
      final json = {
        'type': 'album',
        'id': 'album-1',
        'title': 'Album',
        'artist': 'Artist',
        'dateAdded': '2024-01-02T03:04:05.000Z',
      };

      final block = mediaBlockFromJson(json) as AlbumBlock;

      expect(
          block.dateAdded.toUtc(), DateTime.parse(json['dateAdded'] as String));
    });
  });
}
