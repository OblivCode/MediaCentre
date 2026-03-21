import 'models.dart';

class TvShowBlock extends CollectionBlock {
  final String? posterUrl;
  final String? synopsis;
  final int? tmdbId;
  final String? network;
  final String? status;
  final int userRating;

  TvShowBlock({
    required super.id,
    required super.title,
    super.children,
    this.posterUrl,
    this.synopsis,
    this.tmdbId,
    this.network,
    this.status,
    this.userRating = 0,
  });

  double get averageEpisodeRating {
    final ratings = <int>[];
    for (final child in children) {
      if (child is SeasonBlock) {
        final seasonRating = child.averageEpisodeRating;
        if (seasonRating > 0) ratings.add(seasonRating.round());
      }
    }
    if (ratings.isEmpty) return 0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tv_show',
        'id': id,
        'title': title,
        'children': children.map((c) => c.toJson()).toList(),
        'posterUrl': posterUrl,
        'synopsis': synopsis,
        'tmdbId': tmdbId,
        'network': network,
        'status': status,
        'userRating': userRating,
      };

  factory TvShowBlock.fromJson(Map<String, dynamic> json) {
    final childrenList = json['children'] as List<dynamic>? ?? [];
    final children = childrenList
        .map((c) => mediaBlockFromJson(c as Map<String, dynamic>))
        .toList();

    return TvShowBlock(
      id: json['id'] as String,
      title: json['title'] as String,
      children: children,
      posterUrl: json['posterUrl'] as String?,
      synopsis: json['synopsis'] as String?,
      tmdbId: json['tmdbId'] as int?,
      network: json['network'] as String?,
      status: json['status'] as String?,
      userRating: json['userRating'] as int? ?? 0,
    );
  }

  @override
  TvShowBlock copyWith({
    String? id,
    String? title,
    List<MediaBlock>? children,
    String? posterUrl,
    String? synopsis,
    int? tmdbId,
    String? network,
    String? status,
    int? userRating,
  }) {
    return TvShowBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      children: children ?? this.children,
      posterUrl: posterUrl ?? this.posterUrl,
      synopsis: synopsis ?? this.synopsis,
      tmdbId: tmdbId ?? this.tmdbId,
      network: network ?? this.network,
      status: status ?? this.status,
      userRating: userRating ?? this.userRating,
    );
  }
}
