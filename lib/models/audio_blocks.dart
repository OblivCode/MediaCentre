import 'media_block.dart';

class AlbumBlock extends MediaBlock {
  final String? artist;
  final int trackCount;
  final bool listened;
  final String? coverUrl;
  final String? lastFmMbid;

  AlbumBlock({
    required super.id,
    required super.title,
    this.artist,
    this.trackCount = 0,
    this.listened = false,
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
        'listened': listened,
        'coverUrl': coverUrl,
        'lastFmMbid': lastFmMbid,
      };

  factory AlbumBlock.fromJson(Map<String, dynamic> json) {
    return AlbumBlock(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String?,
      trackCount: json['trackCount'] as int? ?? 0,
      listened: json['listened'] as bool? ?? false,
      coverUrl: json['coverUrl'] as String?,
      lastFmMbid: json['lastFmMbid'] as String?,
    );
  }

  AlbumBlock copyWith({
    String? id,
    String? title,
    String? artist,
    int? trackCount,
    bool? listened,
    String? coverUrl,
    String? lastFmMbid,
  }) {
    return AlbumBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      trackCount: trackCount ?? this.trackCount,
      listened: listened ?? this.listened,
      coverUrl: coverUrl ?? this.coverUrl,
      lastFmMbid: lastFmMbid ?? this.lastFmMbid,
    );
  }
}
