import 'dart:convert';

import 'package:http/http.dart' as http;

class LastFmSearchResult {
  final String title;
  final String? artist;
  final int? trackCount;
  final String? imageUrl;
  final String? mbid;

  LastFmSearchResult({
    required this.title,
    this.artist,
    this.trackCount,
    this.imageUrl,
    this.mbid,
  });

  factory LastFmSearchResult.fromJson(Map<String, dynamic> json) {
    final images = json['image'] as List<dynamic>? ?? [];
    String? imageUrl;
    for (final image in images.reversed) {
      final candidate = image as Map<String, dynamic>;
      final url = candidate['#text'] as String?;
      if (url != null && url.isNotEmpty) {
        imageUrl = url;
        break;
      }
    }

    return LastFmSearchResult(
      title: json['name'] as String? ?? 'Unknown',
      artist: json['artist'] as String?,
      trackCount: (json['trackCount'] as num?)?.toInt() ??
          (json['track_count'] as num?)?.toInt(),
      imageUrl: imageUrl,
      mbid: json['mbid'] as String?,
    );
  }
}

class LastFmService {
  static const String _baseUrl = 'https://ws.audioscrobbler.com/2.0/';

  String? apiKey;

  void setApiKey(String? key) {
    apiKey = key;
  }

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  Future<List<LastFmSearchResult>> searchAlbums(String query,
      {int page = 1}) async {
    if (!isConfigured || query.trim().isEmpty) return [];

    final response = await http.get(
      Uri.parse(
        '$_baseUrl?method=album.search&album=${Uri.encodeComponent(query)}&api_key=$apiKey&format=json&page=$page',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Last.fm API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (((data['results'] as Map<String, dynamic>)['albummatches']
            as Map<String, dynamic>)['album'] as List<dynamic>? ??
        []);

    return results
        .map(
            (item) => LastFmSearchResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
