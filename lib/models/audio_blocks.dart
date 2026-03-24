import 'media_block.dart';

class AlbumBlock extends MediaBlock {
  final String? artist;
  final int trackCount;
  final int userRating;
  final int listenCount;
  final String? coverUrl;
  final String? lastFmMbid;

  AlbumBlock({
    required super.id,
    required super.title,
    super.dateAdded,
    this.artist,
    this.trackCount = 0,
    this.userRating = 0,
    this.listenCount = 0,
    this.coverUrl,
    this.lastFmMbid,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'album',
        'id': id,
        'title': title,
        'artist': artist,
        'trackCount': trackCount,
        'userRating': userRating,
        'listenCount': listenCount,
        'dateAdded': dateAdded.toIso8601String(),
        'coverUrl': coverUrl,
        'lastFmMbid': lastFmMbid,
      };

  factory AlbumBlock.fromJson(Map<String, dynamic> json) {
    return AlbumBlock(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      trackCount: json['trackCount'] as int? ?? 0,
      userRating: json['userRating'] as int? ?? 0,
      listenCount: json['listenCount'] as int? ?? 0,
      dateAdded: DateTime.tryParse(json['dateAdded'] as String? ?? '') ??
          DateTime.now(),
      coverUrl: json['coverUrl'] as String?,
      lastFmMbid: json['lastFmMbid'] as String?,
    );
  }

  AlbumBlock copyWith({
    String? id,
    String? title,
    String? artist,
    int? trackCount,
    int? userRating,
    int? listenCount,
    String? coverUrl,
    String? lastFmMbid,
    DateTime? dateAdded,
  }) {
    return AlbumBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      trackCount: trackCount ?? this.trackCount,
      userRating: userRating ?? this.userRating,
      listenCount: listenCount ?? this.listenCount,
      dateAdded: dateAdded ?? this.dateAdded,
      coverUrl: coverUrl ?? this.coverUrl,
      lastFmMbid: lastFmMbid ?? this.lastFmMbid,
    );
  }
}
