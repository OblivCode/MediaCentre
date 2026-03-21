import 'models.dart';

class SeasonBlock extends MediaBlock {
  final int seasonNumber;
  final String? posterUrl;
  final int userRating;
  final List<EpisodeBlock> episodes;

  SeasonBlock({
    required super.id,
    required super.title,
    this.seasonNumber = 0,
    this.posterUrl,
    this.userRating = 0,
    this.episodes = const [],
  });

  double get averageEpisodeRating {
    if (episodes.isEmpty) return 0;
    final ratedEpisodes = episodes.where((e) => e.userRating > 0).toList();
    if (ratedEpisodes.isEmpty) return 0;
    return ratedEpisodes.map((e) => e.userRating).reduce((a, b) => a + b) /
        ratedEpisodes.length;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'season',
        'id': id,
        'title': title,
        'seasonNumber': seasonNumber,
        'posterUrl': posterUrl,
        'userRating': userRating,
        'episodes': episodes.map((e) => e.toJson()).toList(),
      };

  factory SeasonBlock.fromJson(Map<String, dynamic> json) {
    final episodesList = json['episodes'] as List<dynamic>? ?? [];
    final episodes = episodesList
        .map((e) => EpisodeBlock.fromJson(e as Map<String, dynamic>))
        .toList();

    return SeasonBlock(
      id: json['id'] as String,
      title: json['title'] as String,
      seasonNumber: json['seasonNumber'] as int? ?? 0,
      posterUrl: json['posterUrl'] as String?,
      userRating: json['userRating'] as int? ?? 0,
      episodes: episodes,
    );
  }

  SeasonBlock copyWith({
    String? id,
    String? title,
    int? seasonNumber,
    String? posterUrl,
    int? userRating,
    List<EpisodeBlock>? episodes,
  }) {
    return SeasonBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      posterUrl: posterUrl ?? this.posterUrl,
      userRating: userRating ?? this.userRating,
      episodes: episodes ?? this.episodes,
    );
  }
}
