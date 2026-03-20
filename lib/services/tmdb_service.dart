import 'dart:convert';
import 'package:http/http.dart' as http;

class TmdbService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  String? _apiKey;

  String? get apiKey => _apiKey;
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  void setApiKey(String? key) {
    _apiKey = key;
  }

  String? getFullPosterUrl(String? posterPath) {
    if (posterPath == null || posterPath.isEmpty) return null;
    if (posterPath.startsWith('http')) return posterPath;
    return '$_imageBaseUrl$posterPath';
  }

  Future<List<TmdbSearchResult>> searchMovies(String query) async {
    if (!isConfigured || query.trim().isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/search/movie?api_key=$_apiKey&query=${Uri.encodeComponent(query)}',
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('TMDB API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];

      return results
          .map((r) => TmdbSearchResult.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<TmdbMovieDetails> getMovieDetails(int tmdbId) async {
    if (!isConfigured) {
      throw Exception('TMDB API key not configured');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/$tmdbId?api_key=$_apiKey'),
      );

      if (response.statusCode != 200) {
        throw Exception('TMDB API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return TmdbMovieDetails.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> testApiKey(String key) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/configuration?api_key=$key'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class TmdbSearchResult {
  final int id;
  final String title;
  final String? posterPath;
  final String? releaseDate;
  final double? voteAverage;
  final String? overview;

  TmdbSearchResult({
    required this.id,
    required this.title,
    this.posterPath,
    this.releaseDate,
    this.voteAverage,
    this.overview,
  });

  factory TmdbSearchResult.fromJson(Map<String, dynamic> json) {
    return TmdbSearchResult(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Unknown',
      posterPath: json['poster_path'] as String?,
      releaseDate: json['release_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      overview: json['overview'] as String?,
    );
  }

  String? getFullPosterUrl(TmdbService service) {
    return service.getFullPosterUrl(posterPath);
  }

  String get year {
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    return releaseDate!.substring(0, 4);
  }
}

class TmdbMovieDetails {
  final int id;
  final String title;
  final int runtime;
  final String? posterPath;
  final String? overview;
  final String? releaseDate;
  final double? voteAverage;
  final String? tagline;

  TmdbMovieDetails({
    required this.id,
    required this.title,
    required this.runtime,
    this.posterPath,
    this.overview,
    this.releaseDate,
    this.voteAverage,
    this.tagline,
  });

  factory TmdbMovieDetails.fromJson(Map<String, dynamic> json) {
    return TmdbMovieDetails(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Unknown',
      runtime: (json['runtime'] as int?) ?? 0,
      posterPath: json['poster_path'] as String?,
      overview: json['overview'] as String?,
      releaseDate: json['release_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      tagline: json['tagline'] as String?,
    );
  }

  String? getFullPosterUrl(TmdbService service) {
    return service.getFullPosterUrl(posterPath);
  }

  String get year {
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    return releaseDate!.substring(0, 4);
  }
}
