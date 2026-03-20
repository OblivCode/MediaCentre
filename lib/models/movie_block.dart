import 'media_block.dart';

class MovieBlock extends MediaBlock {
  final int runtimeMinutes;
  final int userRating;

  MovieBlock({
    required super.id,
    required super.title,
    this.runtimeMinutes = 0,
    this.userRating = 0,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'movie',
        'id': id,
        'title': title,
        'runtimeMinutes': runtimeMinutes,
        'userRating': userRating,
      };

  factory MovieBlock.fromJson(Map<String, dynamic> json) {
    return MovieBlock(
      id: json['id'] as String,
      title: json['title'] as String,
      runtimeMinutes: json['runtimeMinutes'] as int? ?? 0,
      userRating: json['userRating'] as int? ?? 0,
    );
  }

  MovieBlock copyWith({
    String? id,
    String? title,
    int? runtimeMinutes,
    int? userRating,
  }) {
    return MovieBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      userRating: userRating ?? this.userRating,
    );
  }
}
