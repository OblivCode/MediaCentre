import 'package:flutter_test/flutter_test.dart';
import 'package:media_centre/models/comic_book_block.dart';

void main() {
  group('ComicBookBlock', () {
    test('creates with required parameters', () {
      final comic = ComicBookBlock(id: 'test-id', title: 'Test Comic');

      expect(comic.id, 'test-id');
      expect(comic.title, 'Test Comic');
      expect(comic.chapterCount, 0);
      expect(comic.currentChapter, 0);
    });

    test('toJson and fromJson round trip', () {
      final original = ComicBookBlock(
        id: 'comic-id',
        title: 'Test Comic',
        author: 'Test Author',
        chapterCount: 100,
        currentChapter: 10,
      );

      final json = original.toJson();
      final restored = ComicBookBlock.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.author, original.author);
      expect(restored.chapterCount, original.chapterCount);
      expect(restored.currentChapter, original.currentChapter);
    });

    test('fromJson handles missing optional fields', () {
      final json = {'id': 'test-id', 'title': 'Test Comic'};

      final comic = ComicBookBlock.fromJson(json);

      expect(comic.author, isNull);
      expect(comic.chapterCount, 0);
      expect(comic.currentChapter, 0);
    });

    test('copyWith updates selected fields', () {
      final original = ComicBookBlock(
        id: 'comic-id',
        title: 'Test Comic',
        author: 'Test Author',
        chapterCount: 100,
        currentChapter: 10,
      );

      final copied = original.copyWith(title: 'New Title', currentChapter: 20);

      expect(copied.id, 'comic-id');
      expect(copied.title, 'New Title');
      expect(copied.author, 'Test Author');
      expect(copied.chapterCount, 100);
      expect(copied.currentChapter, 20);
    });
  });
}
