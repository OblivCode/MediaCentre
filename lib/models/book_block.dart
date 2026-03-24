import 'media_block.dart';

class BookBlock extends MediaBlock {
  final String? author;
  final int pageCount;
  final int currentPage;
  final String? isbn;
  final String? coverUrl;
  final String? synopsis;
  final String? openLibraryId;

  BookBlock({
    required super.id,
    required super.title,
    this.author,
    this.pageCount = 0,
    this.currentPage = 0,
    this.isbn,
    this.coverUrl,
    this.synopsis,
    this.openLibraryId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'book',
        'id': id,
        'title': title,
        'author': author,
        'pageCount': pageCount,
        'currentPage': currentPage,
        'isbn': isbn,
        'coverUrl': coverUrl,
        'synopsis': synopsis,
        'openLibraryId': openLibraryId,
      };

  factory BookBlock.fromJson(Map<String, dynamic> json) {
    return BookBlock(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      pageCount: json['pageCount'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 0,
      isbn: json['isbn'] as String?,
      coverUrl: json['coverUrl'] as String?,
      synopsis: json['synopsis'] as String?,
      openLibraryId: json['openLibraryId'] as String?,
    );
  }

  BookBlock copyWith({
    String? id,
    String? title,
    String? author,
    int? pageCount,
    int? currentPage,
    String? isbn,
    String? coverUrl,
    String? synopsis,
    String? openLibraryId,
  }) {
    return BookBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      pageCount: pageCount ?? this.pageCount,
      currentPage: currentPage ?? this.currentPage,
      isbn: isbn ?? this.isbn,
      coverUrl: coverUrl ?? this.coverUrl,
      synopsis: synopsis ?? this.synopsis,
      openLibraryId: openLibraryId ?? this.openLibraryId,
    );
  }
}
