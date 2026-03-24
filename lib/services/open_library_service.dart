import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenLibrarySearchResult {
  final String key;
  final String title;
  final String? authorName;
  final int? pageCount;
  final String? isbn;
  final int? coverId;
  final String? firstPublishYear;

  OpenLibrarySearchResult({
    required this.key,
    required this.title,
    this.authorName,
    this.pageCount,
    this.isbn,
    this.coverId,
    this.firstPublishYear,
  });

  factory OpenLibrarySearchResult.fromJson(Map<String, dynamic> json) {
    final authorNames = json['author_name'] as List<dynamic>? ?? [];
    final isbnList = json['isbn'] as List<dynamic>? ?? [];

    return OpenLibrarySearchResult(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown',
      authorName: authorNames.isNotEmpty ? authorNames.first as String : null,
      pageCount: json['number_of_pages_median'] as int?,
      isbn: isbnList.isNotEmpty ? isbnList.first as String : null,
      coverId: json['cover_i'] as int?,
      firstPublishYear: json['first_publish_year']?.toString(),
    );
  }

  String? get coverUrl => coverId == null
      ? null
      : 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
}

class OpenLibraryService {
  Future<List<OpenLibrarySearchResult>> searchBooks(String query) async {
    if (query.trim().isEmpty) return [];

    final response = await http.get(
      Uri.parse(
          'https://openlibrary.org/search.json?q=${Uri.encodeComponent(query)}'),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenLibrary API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final docs = data['docs'] as List<dynamic>? ?? [];
    return docs
        .map((doc) =>
            OpenLibrarySearchResult.fromJson(doc as Map<String, dynamic>))
        .toList();
  }
}
