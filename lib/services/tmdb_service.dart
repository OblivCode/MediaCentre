import 'dart:convert';
import 'package:http/http.dart' as http;

class _CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  _CacheEntry(this.data, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class TmdbService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  static const Duration _cacheDuration = Duration(hours: 24);

  String? _apiKey;

  final Map<String, _CacheEntry<dynamic>> _cache = {};

  String? get apiKey => _apiKey;
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  void setApiKey(String? key) {
    _apiKey = key;
    _cache.clear();
  }

  T? _getFromCache<T>(String key) {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      return entry.data as T;
    }
    _cache.remove(key);
    return null;
  }

  void _addToCache<T>(String key, T data) {
    _cache[key] = _CacheEntry(data, DateTime.now().add(_cacheDuration));
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

    final cacheKey = 'movie_$tmdbId';
    final cached = _getFromCache<TmdbMovieDetails>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/movie/$tmdbId?api_key=$_apiKey'),
      );

      if (response.statusCode != 200) {
        throw Exception('TMDB API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final details = TmdbMovieDetails.fromJson(data);
      _addToCache(cacheKey, details);
      return details;
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

  Future<List<TmdbTvSearchResult>> searchTvShows(String query) async {
    if (!isConfigured || query.trim().isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/search/tv?api_key=$_apiKey&query=${Uri.encodeComponent(query)}',
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('TMDB API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];

      return results
          .map((r) => TmdbTvSearchResult.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<TmdbTvDetails> getTvShowDetails(int tmdbId) async {
    if (!isConfigured) {
      throw Exception('TMDB API key not configured');
    }

    final cacheKey = 'tv_$tmdbId';
    final cached = _getFromCache<TmdbTvDetails>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tv/$tmdbId?api_key=$_apiKey'),
      );

      if (response.statusCode != 200) {
        throw Exception('TMDB API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final details = TmdbTvDetails.fromJson(data);
      _addToCache(cacheKey, details);
      return details;
    } catch (e) {
      rethrow;
    }
  }

  Future<TmdbSeasonDetails> getSeasonDetails(int tvId, int seasonNumber) async {
    if (!isConfigured) {
      throw Exception('TMDB API key not configured');
    }

    final cacheKey = 'tv_${tvId}_season_$seasonNumber';
    final cached = _getFromCache<TmdbSeasonDetails>(cacheKey);
    if (cached != null) return cached;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tv/$tvId/season/$seasonNumber?api_key=$_apiKey'),
      );

      if (response.statusCode != 200) {
        throw Exception('TMDB API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final details = TmdbSeasonDetails.fromJson(data);
      _addToCache(cacheKey, details);
      return details;
    } catch (e) {
      rethrow;
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

class TmdbTvSearchResult {
  final int id;
  final String name;
  final String? posterPath;
  final String? firstAirDate;
  final double? voteAverage;
  final String? overview;

  TmdbTvSearchResult({
    required this.id,
    required this.name,
    this.posterPath,
    this.firstAirDate,
    this.voteAverage,
    this.overview,
  });

  factory TmdbTvSearchResult.fromJson(Map<String, dynamic> json) {
    return TmdbTvSearchResult(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      posterPath: json['poster_path'] as String?,
      firstAirDate: json['first_air_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      overview: json['overview'] as String?,
    );
  }

  String? getFullPosterUrl(TmdbService service) {
    return service.getFullPosterUrl(posterPath);
  }

  String get year {
    if (firstAirDate == null || firstAirDate!.isEmpty) return '';
    return firstAirDate!.substring(0, 4);
  }
}

class TmdbTvDetails {
  final int id;
  final String name;
  final String? posterPath;
  final String? overview;
  final String? firstAirDate;
  final double? voteAverage;
  final String? status;
  final List<String> networks;
  final List<TmdbSeasonInfo> seasons;

  TmdbTvDetails({
    required this.id,
    required this.name,
    this.posterPath,
    this.overview,
    this.firstAirDate,
    this.voteAverage,
    this.status,
    this.networks = const [],
    this.seasons = const [],
  });

  factory TmdbTvDetails.fromJson(Map<String, dynamic> json) {
    final networkList = json['networks'] as List<dynamic>? ?? [];
    final networks =
        networkList.map((n) => n['name'] as String? ?? '').toList();

    final seasonList = json['seasons'] as List<dynamic>? ?? [];
    final seasons = seasonList
        .map((s) => TmdbSeasonInfo.fromJson(s as Map<String, dynamic>))
        .where((s) => s.seasonNumber > 0)
        .toList();

    return TmdbTvDetails(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      posterPath: json['poster_path'] as String?,
      overview: json['overview'] as String?,
      firstAirDate: json['first_air_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      status: json['status'] as String?,
      networks: networks,
      seasons: seasons,
    );
  }

  String? getFullPosterUrl(TmdbService service) {
    return service.getFullPosterUrl(posterPath);
  }

  String? get primaryNetwork => networks.isNotEmpty ? networks.first : null;
}

class TmdbSeasonInfo {
  final int id;
  final int seasonNumber;
  final String name;
  final String? posterPath;
  final int episodeCount;
  final String? overview;

  TmdbSeasonInfo({
    required this.id,
    required this.seasonNumber,
    required this.name,
    this.posterPath,
    this.episodeCount = 0,
    this.overview,
  });

  factory TmdbSeasonInfo.fromJson(Map<String, dynamic> json) {
    return TmdbSeasonInfo(
      id: json['id'] as int,
      seasonNumber: json['season_number'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      posterPath: json['poster_path'] as String?,
      episodeCount: json['episode_count'] as int? ?? 0,
      overview: json['overview'] as String?,
    );
  }

  String? getFullPosterUrl(TmdbService service) {
    return service.getFullPosterUrl(posterPath);
  }
}

class TmdbSeasonDetails {
  final int id;
  final int seasonNumber;
  final String name;
  final String? posterPath;
  final String? overview;
  final List<TmdbEpisodeInfo> episodes;

  TmdbSeasonDetails({
    required this.id,
    required this.seasonNumber,
    required this.name,
    this.posterPath,
    this.overview,
    this.episodes = const [],
  });

  factory TmdbSeasonDetails.fromJson(Map<String, dynamic> json) {
    final episodeList = json['episodes'] as List<dynamic>? ?? [];
    final episodes = episodeList
        .map((e) => TmdbEpisodeInfo.fromJson(e as Map<String, dynamic>))
        .toList();

    return TmdbSeasonDetails(
      id: json['id'] as int,
      seasonNumber: json['season_number'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      posterPath: json['poster_path'] as String?,
      overview: json['overview'] as String?,
      episodes: episodes,
    );
  }

  String? getFullPosterUrl(TmdbService service) {
    return service.getFullPosterUrl(posterPath);
  }
}

class TmdbEpisodeInfo {
  final int id;
  final int episodeNumber;
  final String name;
  final String? overview;
  final int? runtime;
  final double? voteAverage;

  TmdbEpisodeInfo({
    required this.id,
    required this.episodeNumber,
    required this.name,
    this.overview,
    this.runtime,
    this.voteAverage,
  });

  factory TmdbEpisodeInfo.fromJson(Map<String, dynamic> json) {
    return TmdbEpisodeInfo(
      id: json['id'] as int,
      episodeNumber: json['episode_number'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      overview: json['overview'] as String?,
      runtime: json['runtime'] as int?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
    );
  }
}
