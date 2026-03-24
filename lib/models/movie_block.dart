import 'media_block.dart';

class MovieBlock extends MediaBlock {
  final int runtimeMinutes;
  final int userRating;
  final String? posterUrl;
  final String? synopsis;
  final int? tmdbId;

  MovieBlock({
    required super.id,
    required super.title,
    super.dateAdded,
    this.runtimeMinutes = 0,
    this.userRating = 0,
    this.posterUrl,
    this.synopsis,
    this.tmdbId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'movie',
        'id': id,
        'title': title,
        'dateAdded': dateAdded.toIso8601String(),
        'runtimeMinutes': runtimeMinutes,
        'userRating': userRating,
        'posterUrl': posterUrl,
        'synopsis': synopsis,
        'tmdbId': tmdbId,
      };

  factory MovieBlock.fromJson(Map<String, dynamic> json) {
    return MovieBlock(
      id: json['id'] as String,
      title: json['title'] as String,
      dateAdded: DateTime.tryParse(json['dateAdded'] as String? ?? '') ??
          DateTime.now(),
      runtimeMinutes: json['runtimeMinutes'] as int? ?? 0,
      userRating: json['userRating'] as int? ?? 0,
      posterUrl: json['posterUrl'] as String?,
      synopsis: json['synopsis'] as String?,
      tmdbId: json['tmdbId'] as int?,
    );
  }

  MovieBlock copyWith({
    String? id,
    String? title,
    DateTime? dateAdded,
    int? runtimeMinutes,
    int? userRating,
    String? posterUrl,
    String? synopsis,
    int? tmdbId,
  }) {
    return MovieBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      dateAdded: dateAdded ?? this.dateAdded,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      userRating: userRating ?? this.userRating,
      posterUrl: posterUrl ?? this.posterUrl,
      synopsis: synopsis ?? this.synopsis,
      tmdbId: tmdbId ?? this.tmdbId,
    );
  }
}
