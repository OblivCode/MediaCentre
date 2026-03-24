import 'dart:convert';

import 'package:http/http.dart' as http;

class AniListSearchResult {
  final int id;
  final String title;
  final String? author;
  final int? chapterCount;
  final String? coverImage;
  final String? description;

  AniListSearchResult({
    required this.id,
    required this.title,
    this.author,
    this.chapterCount,
    this.coverImage,
    this.description,
  });
}

class AniListService {
  Future<List<AniListSearchResult>> searchComics(String query) async {
    if (query.trim().isEmpty) return [];

    const gql = r'''
      query ($search: String) {
        Page(page: 1, perPage: 20) {
          media(type: MANGA, search: $search) {
            id
            title {
              romaji
              english
            }
            chapters
            description(asHtml: false)
            coverImage {
              large
            }
            authors {
              nodes {
                name {
                  full
                }
              }
            }
          }
        }
      }
    ''';

    final response = await http.post(
      Uri.parse('https://graphql.anilist.co'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': gql,
        'variables': {'search': query},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('AniList API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final media = (((data['data'] as Map<String, dynamic>)['Page']
            as Map<String, dynamic>)['media'] as List<dynamic>? ??
        []);

    return media.map((item) {
      final json = item as Map<String, dynamic>;
      final title = json['title'] as Map<String, dynamic>;
      final authors = (json['authors'] as Map<String, dynamic>?)?['nodes']
              as List<dynamic>? ??
          [];

      return AniListSearchResult(
        id: json['id'] as int,
        title: (title['english'] as String?) ??
            (title['romaji'] as String? ?? 'Unknown'),
        chapterCount: json['chapters'] as int?,
        coverImage:
            (json['coverImage'] as Map<String, dynamic>?)?['large'] as String?,
        description: json['description'] as String?,
        author: authors.isNotEmpty
            ? (((authors.first as Map<String, dynamic>)['name']
                as Map<String, dynamic>)['full'] as String?)
            : null,
      );
    }).toList();
  }
}
