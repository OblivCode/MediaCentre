export 'media_block.dart';
export 'movie_block.dart';
export 'book_block.dart';
export 'comic_book_block.dart';
export 'collection_block.dart';
export 'tv_show_block.dart';
export 'season_block.dart';
export 'episode_block.dart';

import 'media_block.dart';
import 'movie_block.dart';
import 'book_block.dart';
import 'comic_book_block.dart';
import 'collection_block.dart';
import 'tv_show_block.dart';
import 'season_block.dart';
import 'episode_block.dart';

MediaBlock mediaBlockFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String;
  switch (type) {
    case 'movie':
      return MovieBlock.fromJson(json);
    case 'book':
      return BookBlock.fromJson(json);
    case 'comic_book':
      return ComicBookBlock.fromJson(json);
    case 'collection':
      return CollectionBlock.fromJson(json);
    case 'tv_show':
      return TvShowBlock.fromJson(json);
    case 'season':
      return SeasonBlock.fromJson(json);
    case 'episode':
      return EpisodeBlock.fromJson(json);
    default:
      throw ArgumentError('Unknown media type: $type');
  }
}
