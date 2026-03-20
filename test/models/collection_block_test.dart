import 'package:flutter_test/flutter_test.dart';
import 'package:media_centre/models/collection_block.dart';
import 'package:media_centre/models/movie_block.dart';

void main() {
  group('CollectionBlock', () {
    test('creates with required parameters', () {
      final collection =
          CollectionBlock(id: 'test-id', title: 'Test Collection');

      expect(collection.id, 'test-id');
      expect(collection.title, 'Test Collection');
      expect(collection.children, isEmpty);
    });

    test('creates with children', () {
      final movie = MovieBlock(id: 'movie-1', title: 'Movie');
      final collection = CollectionBlock(
        id: 'test-id',
        title: 'Test Collection',
        children: [movie],
      );

      expect(collection.children.length, 1);
      expect(collection.children.first.id, 'movie-1');
    });

    test('toJson and fromJson round trip', () {
      final movie = MovieBlock(
        id: 'movie-1',
        title: 'Movie',
        runtimeMinutes: 120,
        userRating: 4,
      );
      final original = CollectionBlock(
        id: 'test-id',
        title: 'Test Collection',
        children: [movie],
      );

      final json = original.toJson();
      final restored = CollectionBlock.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.children.length, 1);
      expect((restored.children.first as MovieBlock).userRating, 4);
    });

    test('fromJson handles empty children', () {
      final json = {'id': 'test-id', 'title': 'Test Collection'};

      final collection = CollectionBlock.fromJson(json);

      expect(collection.children, isEmpty);
    });

    test('toJson includes type field', () {
      final collection =
          CollectionBlock(id: 'test-id', title: 'Test Collection');

      expect(collection.toJson()['type'], 'collection');
    });

    test('copyWith preserves unchanged values', () {
      final original = CollectionBlock(
        id: 'test-id',
        title: 'Test Collection',
        children: [],
      );

      final copied = original.copyWith(title: 'New Title');

      expect(copied.id, 'test-id');
      expect(copied.title, 'New Title');
      expect(copied.children, isEmpty);
    });

    test('addChild returns new collection with added child', () {
      final collection =
          CollectionBlock(id: 'test-id', title: 'Test Collection');
      final movie = MovieBlock(id: 'movie-1', title: 'Movie');

      final updated = collection.addChild(movie);

      expect(collection.children, isEmpty);
      expect(updated.children.length, 1);
      expect(updated.children.first.id, 'movie-1');
    });

    test('removeChild returns new collection without child', () {
      final movie1 = MovieBlock(id: 'movie-1', title: 'Movie 1');
      final movie2 = MovieBlock(id: 'movie-2', title: 'Movie 2');
      final collection = CollectionBlock(
        id: 'test-id',
        title: 'Test Collection',
        children: [movie1, movie2],
      );

      final updated = collection.removeChild('movie-1');

      expect(collection.children.length, 2);
      expect(updated.children.length, 1);
      expect(updated.children.first.id, 'movie-2');
    });

    test('removeChild with non-existent id returns same children', () {
      final movie = MovieBlock(id: 'movie-1', title: 'Movie');
      final collection = CollectionBlock(
        id: 'test-id',
        title: 'Test Collection',
        children: [movie],
      );

      final updated = collection.removeChild('non-existent');

      expect(updated.children.length, 1);
    });

    test('supports nested collections', () {
      final movie = MovieBlock(id: 'movie-1', title: 'Movie');
      final innerCollection = CollectionBlock(
        id: 'inner',
        title: 'Inner',
        children: [movie],
      );
      final outerCollection = CollectionBlock(
        id: 'outer',
        title: 'Outer',
        children: [innerCollection],
      );

      final json = outerCollection.toJson();
      final restored = CollectionBlock.fromJson(json);

      expect(restored.children.length, 1);
      final inner = restored.children.first as CollectionBlock;
      expect(inner.children.length, 1);
      expect(inner.children.first.id, 'movie-1');
    });
  });
}
