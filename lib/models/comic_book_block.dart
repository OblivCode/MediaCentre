import 'media_block.dart';

class ComicBookBlock extends MediaBlock {
  final String? author;
  final int chapterCount;
  final int currentChapter;
  final int? anilistId;
  final String? coverUrl;
  final String? synopsis;

  ComicBookBlock({
    required super.id,
    required super.title,
    this.author,
    this.chapterCount = 0,
    this.currentChapter = 0,
    this.anilistId,
    this.coverUrl,
    this.synopsis,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'comic_book',
        'id': id,
        'title': title,
        'author': author,
        'chapterCount': chapterCount,
        'currentChapter': currentChapter,
        'anilistId': anilistId,
        'coverUrl': coverUrl,
        'synopsis': synopsis,
      };

  factory ComicBookBlock.fromJson(Map<String, dynamic> json) {
    return ComicBookBlock(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      chapterCount: json['chapterCount'] as int? ?? 0,
      currentChapter: json['currentChapter'] as int? ?? 0,
      anilistId: json['anilistId'] as int?,
      coverUrl: json['coverUrl'] as String?,
      synopsis: json['synopsis'] as String?,
    );
  }

  ComicBookBlock copyWith({
    String? id,
    String? title,
    String? author,
    int? chapterCount,
    int? currentChapter,
    int? anilistId,
    String? coverUrl,
    String? synopsis,
  }) {
    return ComicBookBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      chapterCount: chapterCount ?? this.chapterCount,
      currentChapter: currentChapter ?? this.currentChapter,
      anilistId: anilistId ?? this.anilistId,
      coverUrl: coverUrl ?? this.coverUrl,
      synopsis: synopsis ?? this.synopsis,
    );
  }
}
