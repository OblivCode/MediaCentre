import 'models.dart';

class SeasonBlock extends CollectionBlock {
  final int seasonNumber;
  final String? posterUrl;
  final int userRating;

  SeasonBlock({
    required super.id,
    required super.title,
    super.children,
    this.seasonNumber = 0,
    this.posterUrl,
    this.userRating = 0,
  });

  double get averageEpisodeRating {
    final episodes = children.whereType<EpisodeBlock>().toList();
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
        'children': children.map((c) => c.toJson()).toList(),
        'seasonNumber': seasonNumber,
        'posterUrl': posterUrl,
        'userRating': userRating,
      };

  factory SeasonBlock.fromJson(Map<String, dynamic> json) {
    final childrenList = json['children'] as List<dynamic>? ?? [];
    final children = childrenList
        .map((c) => mediaBlockFromJson(c as Map<String, dynamic>))
        .toList();

    return SeasonBlock(
      id: json['id'] as String,
      title: json['title'] as String,
      children: children,
      seasonNumber: json['seasonNumber'] as int? ?? 0,
      posterUrl: json['posterUrl'] as String?,
      userRating: json['userRating'] as int? ?? 0,
    );
  }

  @override
  SeasonBlock copyWith({
    String? id,
    String? title,
    List<MediaBlock>? children,
    int? seasonNumber,
    String? posterUrl,
    int? userRating,
  }) {
    return SeasonBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      children: children ?? this.children,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      posterUrl: posterUrl ?? this.posterUrl,
      userRating: userRating ?? this.userRating,
    );
  }
}
