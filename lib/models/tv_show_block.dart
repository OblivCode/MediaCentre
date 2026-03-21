import 'models.dart';

class TvShowBlock extends CollectionBlock {
  final String? network;
  final String? status;
  final String? posterUrl;
  final String? synopsis;
  final int? tmdbId;

  TvShowBlock({
    required super.id,
    required super.title,
    super.children,
    this.network,
    this.status,
    this.posterUrl,
    this.synopsis,
    this.tmdbId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tv_show',
        'id': id,
        'title': title,
        'children': children.map((c) => c.toJson()).toList(),
        'network': network,
        'status': status,
        'posterUrl': posterUrl,
        'synopsis': synopsis,
        'tmdbId': tmdbId,
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
      network: json['network'] as String?,
      status: json['status'] as String?,
      posterUrl: json['posterUrl'] as String?,
      synopsis: json['synopsis'] as String?,
      tmdbId: json['tmdbId'] as int?,
    );
  }

  @override
  TvShowBlock copyWith({
    String? id,
    String? title,
    List<MediaBlock>? children,
    String? network,
    String? status,
    String? posterUrl,
    String? synopsis,
    int? tmdbId,
  }) {
    return TvShowBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      children: children ?? this.children,
      network: network ?? this.network,
      status: status ?? this.status,
      posterUrl: posterUrl ?? this.posterUrl,
      synopsis: synopsis ?? this.synopsis,
      tmdbId: tmdbId ?? this.tmdbId,
    );
  }
}
