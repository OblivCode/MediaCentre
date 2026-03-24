import 'models.dart';

class TvShowBlock extends MediaBlock {
  final String? posterUrl;
  final String? synopsis;
  final int? tmdbId;
  final String? network;
  final String? status;
  final int userRating;
  final List<SeasonBlock> seasons;

  TvShowBlock({
    required super.id,
    required super.title,
    super.dateAdded,
    this.posterUrl,
    this.synopsis,
    this.tmdbId,
    this.network,
    this.status,
    this.userRating = 0,
    this.seasons = const [],
  });

  double get averageEpisodeRating {
    final ratings = <int>[];
    for (final season in seasons) {
      final seasonRating = season.averageEpisodeRating;
      if (seasonRating > 0) ratings.add(seasonRating.round());
    }
    if (ratings.isEmpty) return 0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tv_show',
        'id': id,
        'title': title,
        'dateAdded': dateAdded.toIso8601String(),
        'posterUrl': posterUrl,
        'synopsis': synopsis,
        'tmdbId': tmdbId,
        'network': network,
        'status': status,
        'userRating': userRating,
        'seasons': seasons.map((s) => s.toJson()).toList(),
      };

  factory TvShowBlock.fromJson(Map<String, dynamic> json) {
    final seasonsList = json['seasons'] as List<dynamic>? ?? [];
    final seasons = seasonsList
        .map((s) => SeasonBlock.fromJson(s as Map<String, dynamic>))
        .toList();

    return TvShowBlock(
      id: json['id'] as String,
      title: json['title'] as String,
      dateAdded: DateTime.tryParse(json['dateAdded'] as String? ?? '') ??
          DateTime.now(),
      posterUrl: json['posterUrl'] as String?,
      synopsis: json['synopsis'] as String?,
      tmdbId: json['tmdbId'] as int?,
      network: json['network'] as String?,
      status: json['status'] as String?,
      userRating: json['userRating'] as int? ?? 0,
      seasons: seasons,
    );
  }

  TvShowBlock copyWith({
    String? id,
    String? title,
    DateTime? dateAdded,
    String? posterUrl,
    String? synopsis,
    int? tmdbId,
    String? network,
    String? status,
    int? userRating,
    List<SeasonBlock>? seasons,
  }) {
    return TvShowBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      dateAdded: dateAdded ?? this.dateAdded,
      posterUrl: posterUrl ?? this.posterUrl,
      synopsis: synopsis ?? this.synopsis,
      tmdbId: tmdbId ?? this.tmdbId,
      network: network ?? this.network,
      status: status ?? this.status,
      userRating: userRating ?? this.userRating,
      seasons: seasons ?? this.seasons,
    );
  }
}
