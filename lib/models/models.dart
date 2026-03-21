export 'media_block.dart';
export 'movie_block.dart';
export 'collection_block.dart';
export 'tv_show_block.dart';

import 'media_block.dart';
import 'movie_block.dart';
import 'collection_block.dart';
import 'tv_show_block.dart';

MediaBlock mediaBlockFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String;
  switch (type) {
    case 'movie':
      return MovieBlock.fromJson(json);
    case 'collection':
      return CollectionBlock.fromJson(json);
    case 'tv_show':
      return TvShowBlock.fromJson(json);
    default:
      throw ArgumentError('Unknown media type: $type');
  }
}
