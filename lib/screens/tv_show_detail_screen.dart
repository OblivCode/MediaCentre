import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/tv_show_block.dart';
import '../models/season_block.dart';
import '../models/episode_block.dart';
import '../models/media_block.dart';
import '../services/volume_manager.dart';
import '../services/tmdb_service.dart';
import '../widgets/rating_modal.dart';

class TvShowDetailScreen extends StatelessWidget {
  final TvShowBlock tvShow;

  const TvShowDetailScreen({super.key, required this.tvShow});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tvShow.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (tvShow.seasons.isEmpty) {
      return Center(
        child: Text(
          'No seasons available',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tvShow.seasons.length,
      itemBuilder: (context, index) {
        final season = tvShow.seasons[index];
        return _SeasonCard(
          season: season,
          onNavigate: () => _navigateToSeason(context, season),
          onEdit: (updated) =>
              context.read<VolumeManager>().updateMedia(updated),
        );
      },
    );
  }

  void _navigateToSeason(BuildContext context, SeasonBlock season) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeasonDetailScreen(tvShow: tvShow, season: season),
      ),
    );
  }
}

class SeasonDetailScreen extends StatefulWidget {
  final TvShowBlock tvShow;
  final SeasonBlock season;

  const SeasonDetailScreen(
      {super.key, required this.tvShow, required this.season});

  @override
  State<SeasonDetailScreen> createState() => _SeasonDetailScreenState();
}

class _SeasonDetailScreenState extends State<SeasonDetailScreen> {
  late SeasonBlock _season;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _season = widget.season;
    _loadSeasonDetailsIfNeeded();
  }

  Future<void> _loadSeasonDetailsIfNeeded() async {
    if (_season.episodes.isNotEmpty) return;
    if (widget.tvShow.tmdbId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tmdbService = context.read<TmdbService>();
      final details = await tmdbService.getSeasonDetails(
        widget.tvShow.tmdbId!,
        _season.seasonNumber,
      );
      final episodes = details.episodes
          .map(
            (episode) => EpisodeBlock(
              id: 'season_${_season.id}_episode_${episode.id}',
              title: episode.name,
              episodeNumber: episode.episodeNumber,
              runtimeMinutes: episode.runtime ?? 0,
              userRating: 0,
            ),
          )
          .toList();

      final updatedSeason = _season.copyWith(
        title: details.name,
        posterUrl: details.getFullPosterUrl(tmdbService),
        episodes: episodes,
      );

      final updatedSeasons = widget.tvShow.seasons.map((season) {
        if (season.id == updatedSeason.id) return updatedSeason;
        return season;
      }).toList();
      final updatedTvShow = widget.tvShow.copyWith(seasons: updatedSeasons);

      if (!mounted) return;
      setState(() {
        _season = updatedSeason;
        _isLoading = false;
      });
      await context.read<VolumeManager>().updateMedia(updatedTvShow);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_season.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_season.episodes.isEmpty) {
      return Center(
        child: Text(
          'No episodes available',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _season.episodes.length,
      itemBuilder: (context, index) {
        final episode = _season.episodes[index];
        return _EpisodeCard(
          episode: episode,
          onEdit: (updated) =>
              context.read<VolumeManager>().updateMedia(updated),
        );
      },
    );
  }
}

class _SeasonCard extends StatelessWidget {
  final SeasonBlock season;
  final VoidCallback onNavigate;
  final ValueChanged<MediaBlock> onEdit;

  const _SeasonCard({
    required this.season,
    required this.onNavigate,
    required this.onEdit,
  });

  Future<void> _showEditModal(BuildContext context) async {
    final result = await RatingModal.show(
      context: context,
      media: season,
      posterUrl: season.posterUrl,
    );

    if (result != null) {
      onEdit(result.media);
    }
  }

  Future<void> _showContextMenu(
      BuildContext context, Offset globalPosition) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final choice = await showMenu<_SeasonAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        overlay.size.width - globalPosition.dx,
        overlay.size.height - globalPosition.dy,
      ),
      items: const [
        PopupMenuItem(value: _SeasonAction.edit, child: Text('Edit Rating')),
        PopupMenuItem(value: _SeasonAction.open, child: Text('Open Season')),
      ],
    );

    if (!context.mounted) return;
    if (choice == _SeasonAction.edit) {
      await _showEditModal(context);
    } else if (choice == _SeasonAction.open) {
      onNavigate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => _showEditModal(context),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          onNavigate();
        },
        onSecondaryTapDown: (details) => _showContextMenu(
          context,
          details.globalPosition,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: season.posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: season.posterUrl!,
                        width: 70,
                        height: 105,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 70,
                          height: 105,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 70,
                          height: 105,
                          color: Colors.grey[300],
                          child: const Icon(Icons.video_library, size: 32),
                        ),
                      )
                    : Container(
                        width: 70,
                        height: 105,
                        color: Colors.grey[300],
                        child: const Icon(Icons.video_library, size: 32),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      season.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${season.episodes.length} episodes',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (season.userRating > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < season.userRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SeasonAction { edit, open }

class _EpisodeCard extends StatelessWidget {
  final EpisodeBlock episode;
  final ValueChanged<MediaBlock> onEdit;

  const _EpisodeCard({
    required this.episode,
    required this.onEdit,
  });

  Future<void> _showEditModal(BuildContext context) async {
    final result = await RatingModal.show(
      context: context,
      media: episode,
    );

    if (result != null) {
      onEdit(result.media);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showEditModal(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'E${episode.episodeNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (episode.runtimeMinutes > 0)
                      Text(
                        '${episode.runtimeMinutes} min',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (episode.userRating > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < episode.userRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
