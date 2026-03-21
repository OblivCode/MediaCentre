import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/collection_block.dart';
import '../models/media_block.dart';
import '../models/movie_block.dart';
import '../models/tv_show_block.dart';
import '../models/season_block.dart';
import '../services/volume_manager.dart';
import '../widgets/add_media_menu.dart';
import '../widgets/collection_card.dart';
import '../widgets/rating_modal.dart';
import 'add_media_screen.dart';
import 'create_collection_screen.dart';
import 'settings_screen.dart';

class LibraryScreen extends StatelessWidget {
  final CollectionBlock? collection;

  const LibraryScreen({super.key, this.collection});

  CollectionBlock _getCurrentLibrary(VolumeManager manager) =>
      collection ?? manager.library;

  @override
  Widget build(BuildContext context) {
    return Consumer<VolumeManager>(
      builder: (context, manager, child) {
        final currentLibrary = _getCurrentLibrary(manager);
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(collection?.title ?? 'MediaCentre'),
                if (manager.activeVolume != null && collection == null)
                  Text(
                    manager.activeVolume!.providerName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              if (collection == null)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
            ],
          ),
          body: _buildBody(context, manager, currentLibrary),
          floatingActionButton: FloatingActionButton(
            onPressed: manager.isLoading
                ? null
                : () => _showAddMenu(context, manager, currentLibrary),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    VolumeManager manager,
    CollectionBlock currentLibrary,
  ) {
    if (manager.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (manager.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                manager.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => manager.loadLibrary(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (currentLibrary.children.isEmpty) {
      return Center(
        child: Text(
          collection == null
              ? 'No movies yet.\nTap + to add one.'
              : 'This collection is empty.\nTap + to add items.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: currentLibrary.children.length,
      itemBuilder: (context, index) {
        final media = currentLibrary.children[index];
        if (media is MovieBlock) {
          return _MovieCard(
            movie: media,
            onDelete: () => manager.deleteMedia(media.id),
            onEdit: (updated) => manager.updateMedia(updated),
            onMoveToCollection: (targetId) =>
                manager.moveMediaToCollection(media.id, targetId),
            collections: manager.getAllCollections(),
          );
        }
        if (media is TvShowBlock) {
          return _TvShowCard(
            tvShow: media,
            onNavigate: () => _navigateToCollection(context, media),
            onEdit: (updated) => manager.updateMedia(updated),
            onDelete: () => manager.deleteMedia(media.id),
            onMoveToCollection: (targetId) =>
                manager.moveMediaToCollection(media.id, targetId),
            collections: manager.getAllCollections(),
          );
        }
        if (media is SeasonBlock) {
          return _SeasonCard(
            season: media,
            onNavigate: () => _navigateToCollection(context, media),
            onEdit: (updated) => manager.updateMedia(updated),
            onDelete: () => manager.deleteMedia(media.id),
            onMoveToCollection: (targetId) =>
                manager.moveMediaToCollection(media.id, targetId),
            collections: manager.getAllCollections(),
          );
        }
        if (media is CollectionBlock) {
          return CollectionCard(
            collection: media,
            onTap: () => _navigateToCollection(context, media),
            onDelete: () => manager.deleteMedia(media.id),
          );
        }
        return ListTile(
          title: Text(media.title),
          subtitle: const Text('Unknown type'),
        );
      },
    );
  }

  void _navigateToCollection(BuildContext context, CollectionBlock col) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LibraryScreen(collection: col)),
    );
  }

  void _showAddMenu(
    BuildContext context,
    VolumeManager manager,
    CollectionBlock currentLibrary,
  ) async {
    final choice = await AddMediaMenu.show(context);
    if (choice == null || !context.mounted) return;

    switch (choice) {
      case AddMediaType.movie:
        final result = await Navigator.push<MediaBlock>(
          context,
          MaterialPageRoute(
              builder: (context) => const AddMediaScreen(initialTab: 0)),
        );
        if (result != null && result is MovieBlock) {
          try {
            await manager.addMovie(result);
          } on DuplicateMediaException catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.message)),
              );
            }
          }
        }
      case AddMediaType.tvShow:
        final result = await Navigator.push<MediaBlock>(
          context,
          MaterialPageRoute(
              builder: (context) => const AddMediaScreen(initialTab: 1)),
        );
        if (result != null && result is TvShowBlock) {
          try {
            await manager.addTvShow(result);
          } on DuplicateMediaException catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.message)),
              );
            }
          }
        }
      case AddMediaType.collection:
        final result = await Navigator.push<CollectionBlock>(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateCollectionScreen(),
          ),
        );
        if (result != null) {
          manager.addCollection(result);
        }
    }
  }
}

class _MovieCard extends StatelessWidget {
  final MovieBlock movie;
  final VoidCallback onDelete;
  final ValueChanged<MediaBlock> onEdit;
  final ValueChanged<String>? onMoveToCollection;
  final List<CollectionBlock> collections;

  const _MovieCard({
    required this.movie,
    required this.onDelete,
    required this.onEdit,
    this.onMoveToCollection,
    this.collections = const [],
  });

  Future<void> _showEditModal(BuildContext context) async {
    final result = await RatingModal.show(
      context: context,
      media: movie,
      posterUrl: movie.posterUrl,
      synopsis: movie.synopsis,
      runtimeMinutes: movie.runtimeMinutes,
      collections: collections,
    );

    if (result != null) {
      onEdit(result.media);
      if (result.moveToCollectionId != null && onMoveToCollection != null) {
        onMoveToCollection!(result.moveToCollectionId!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(movie.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: () => _showEditModal(context),
          onLongPress: () {
            HapticFeedback.mediumImpact();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: movie.posterUrl != null
                      ? CachedNetworkImage(
                          imageUrl: movie.posterUrl!,
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
                            child: const Icon(Icons.movie, size: 32),
                          ),
                        )
                      : Container(
                          width: 70,
                          height: 105,
                          color: Colors.grey[300],
                          child: const Icon(Icons.movie, size: 32),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (movie.runtimeMinutes > 0)
                        Text(
                          '${movie.runtimeMinutes} min',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 8),
                      _StarRating(rating: movie.userRating),
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
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final int rating;

  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }
}

class _TvShowCard extends StatelessWidget {
  final TvShowBlock tvShow;
  final VoidCallback onNavigate;
  final ValueChanged<MediaBlock> onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String>? onMoveToCollection;
  final List<CollectionBlock> collections;

  const _TvShowCard({
    required this.tvShow,
    required this.onNavigate,
    required this.onEdit,
    required this.onDelete,
    this.onMoveToCollection,
    this.collections = const [],
  });

  Future<void> _showEditModal(BuildContext context) async {
    final result = await RatingModal.show(
      context: context,
      media: tvShow,
      posterUrl: tvShow.posterUrl,
      synopsis: tvShow.synopsis,
      collections: collections,
    );

    if (result != null) {
      onEdit(result.media);
      if (result.moveToCollectionId != null && onMoveToCollection != null) {
        onMoveToCollection!(result.moveToCollectionId!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(tvShow.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: () => _showEditModal(context),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            onNavigate();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: tvShow.posterUrl != null
                      ? CachedNetworkImage(
                          imageUrl: tvShow.posterUrl!,
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
                            child: const Icon(Icons.tv, size: 32),
                          ),
                        )
                      : Container(
                          width: 70,
                          height: 105,
                          color: Colors.grey[300],
                          child: const Icon(Icons.tv, size: 32),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tvShow.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (tvShow.network != null)
                        Text(
                          tvShow.network!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (tvShow.userRating > 0) ...[
                            _StarRating(rating: tvShow.userRating),
                            const SizedBox(width: 8),
                          ],
                          if (tvShow.status != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tvShow.status == 'Ended'
                                    ? Colors.grey[300]
                                    : Colors.green[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tvShow.status!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tvShow.status == 'Ended'
                                      ? Colors.grey[700]
                                      : Colors.green[800],
                                ),
                              ),
                            ),
                        ],
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
      ),
    );
  }
}

class _SeasonCard extends StatelessWidget {
  final SeasonBlock season;
  final VoidCallback onNavigate;
  final ValueChanged<MediaBlock> onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String>? onMoveToCollection;
  final List<CollectionBlock> collections;

  const _SeasonCard({
    required this.season,
    required this.onNavigate,
    required this.onEdit,
    required this.onDelete,
    this.onMoveToCollection,
    this.collections = const [],
  });

  Future<void> _showEditModal(BuildContext context) async {
    final result = await RatingModal.show(
      context: context,
      media: season,
      posterUrl: season.posterUrl,
      collections: collections,
    );

    if (result != null) {
      onEdit(result.media);
      if (result.moveToCollectionId != null && onMoveToCollection != null) {
        onMoveToCollection!(result.moveToCollectionId!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(season.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: () => _showEditModal(context),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            onNavigate();
          },
          borderRadius: BorderRadius.circular(12),
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
                        'Season ${season.seasonNumber}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (season.userRating > 0)
                        _StarRating(rating: season.userRating),
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
      ),
    );
  }
}
