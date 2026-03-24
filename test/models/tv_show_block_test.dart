import 'package:flutter_test/flutter_test.dart';
import 'package:media_centre/models/models.dart';

void main() {
  group('TvShowBlock', () {
    test('averageEpisodeRating returns 0 when there are no seasons', () {
      final show = TvShowBlock(
        id: '1',
        title: 'Test Show',
        seasons: [],
      );

      expect(show.averageEpisodeRating, 0);
    });

    test('averageEpisodeRating calculates correct average across seasons', () {
      final season1 = SeasonBlock(
        id: 's1',
        title: 'Season 1',
        seasonNumber: 1,
        episodes: [
          EpisodeBlock(
              id: 'e1', title: 'Ep 1', episodeNumber: 1, userRating: 8),
          EpisodeBlock(
              id: 'e2', title: 'Ep 2', episodeNumber: 2, userRating: 6),
        ],
      );

      final season2 = SeasonBlock(
        id: 's2',
        title: 'Season 2',
        seasonNumber: 2,
        episodes: [
          EpisodeBlock(
              id: 'e3', title: 'Ep 1', episodeNumber: 1, userRating: 10),
        ],
      );

      final show = TvShowBlock(
        id: '1',
        title: 'Test Show',
        seasons: [season1, season2],
      );

      // s1 average = 7
      // s2 average = 10
      // show average = (7 + 10) / 2 = 8.5
      expect(show.averageEpisodeRating, 8.5);
    });

    test('toJson and fromJson round trip', () {
      final original = TvShowBlock(
          id: 'tv-1',
          title: 'Breaking Bad',
          network: 'HBO',
          userRating: 5,
          seasons: [
            SeasonBlock(
              id: 's1',
              title: 'Season 1',
              seasonNumber: 1,
              episodes: [],
            )
          ]);

      final json = original.toJson();
      final restored = TvShowBlock.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.network, original.network);
      expect(restored.userRating, original.userRating);
      expect(restored.seasons.length, 1);
      expect(restored.seasons[0].id, 's1');
    });
  });
}
