import 'models.dart';

class EpisodeBlock extends MediaBlock {
  final int episodeNumber;
  final int runtimeMinutes;
  final int userRating;

  EpisodeBlock({
    required super.id,
    required super.title,
    this.episodeNumber = 0,
    this.runtimeMinutes = 0,
    this.userRating = 0,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'episode',
        'id': id,
        'title': title,
        'episodeNumber': episodeNumber,
        'runtimeMinutes': runtimeMinutes,
        'userRating': userRating,
      };

  factory EpisodeBlock.fromJson(Map<String, dynamic> json) {
    return EpisodeBlock(
      id: json['id'] as String,
      title: json['title'] as String,
      episodeNumber: json['episode_number'] as int,
      runtimeMinutes: json['runtime_minutes'] as int? ?? 0,
      userRating: json['user_rating'] as int? ?? 0,
    );
  }

  EpisodeBlock copyWith({
    String? id,
    String? title,
    int? episodeNumber,
    int? runtimeMinutes,
    int? userRating,
  }) {
    return EpisodeBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      userRating: userRating ?? this.userRating,
    );
  }
}
