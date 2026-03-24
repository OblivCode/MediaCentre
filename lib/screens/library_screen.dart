import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/collection_block.dart';
import '../models/book_block.dart';
import '../models/comic_book_block.dart';
import '../models/media_block.dart';
import '../models/movie_block.dart';
import '../models/tv_show_block.dart';
import '../services/volume_manager.dart';
import '../widgets/add_media_menu.dart';
import '../widgets/reading_modal.dart';
import '../widgets/collection_card.dart';
import '../widgets/rating_modal.dart';
import 'library_domain.dart';
import 'add_media_screen.dart';
import 'create_collection_screen.dart';
import 'settings_screen.dart';
import 'tv_show_detail_screen.dart';

enum _CardAction { edit, move, delete }

class LibraryScreen extends StatelessWidget {
  final CollectionBlock? collection;
  final LibraryDomain domain;

  const LibraryScreen(
      {super.key, this.collection, this.domain = LibraryDomain.watch});

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

    final items =
        collection == null ? _rootItems(manager) : currentLibrary.children;

    if (items.isEmpty) {
      return Center(
        child: Text(
          collection == null
              ? _emptyStateText()
              : 'This collection is empty.\nTap + to add items.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final media = items[index];
        if (media is MovieBlock) {
          return _MovieCard(
            movie: media,
            onDelete: () => manager.deleteMedia(media.id),
            onEdit: (updated) => manager.updateMedia(updated),
            onMoveToCollection: (targetId) =>
                manager.moveMediaToCollection(media.id, targetId),
            collections: manager.rootCollections,
          );
        }
        if (media is TvShowBlock) {
          return _TvShowCard(
            tvShow: media,
            onNavigate: () => _navigateToTvShow(context, media),
            onEdit: (updated) => manager.updateMedia(updated),
            onDelete: () => manager.deleteMedia(media.id),
            onMoveToCollection: (targetId) =>
                manager.moveMediaToCollection(media.id, targetId),
            collections: manager.rootCollections,
          );
        }
        if (media is CollectionBlock) {
          return CollectionCard(
            collection: media,
            onTap: () => _navigateToCollection(context, media),
            onDelete: () => manager.deleteMedia(media.id),
          );
        }
        if (media is BookBlock || media is ComicBookBlock) {
          return _ReadingCard(
            media: media,
            onEdit: (updated) => manager.updateMedia(updated),
          );
        }
        return ListTile(
          title: Text(media.title),
          subtitle: const Text('Unknown type'),
        );
      },
    );
  }

  List<MediaBlock> _rootItems(VolumeManager manager) {
    switch (domain) {
      case LibraryDomain.watch:
        return manager.watchableMedia;
      case LibraryDomain.read:
        return manager.readableMedia;
      case LibraryDomain.listen:
        return manager.listableMedia;
      case LibraryDomain.collections:
        return manager.rootCollections;
    }
  }

  String _emptyStateText() {
    switch (domain) {
      case LibraryDomain.watch:
        return 'No movies yet.\nTap + to add one.';
      case LibraryDomain.read:
        return 'No reading items yet.\nTap + to add one.';
      case LibraryDomain.listen:
        return 'No listening items yet.\nTap + to add one.';
      case LibraryDomain.collections:
        return 'No collections yet.\nTap + to add one.';
    }
  }

  void _navigateToCollection(BuildContext context, CollectionBlock col) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LibraryScreen(collection: col)),
    );
  }

  void _navigateToTvShow(BuildContext context, TvShowBlock tvShow) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TvShowDetailScreen(tvShow: tvShow)),
    );
  }

  void _showAddMenu(
    BuildContext context,
    VolumeManager manager,
    CollectionBlock currentLibrary,
  ) async {
    final choice = await AddMediaMenu.show(context, domain: domain);
    if (choice == null || !context.mounted) return;

    if (choice == AddMediaType.movie) {
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
    } else if (choice == AddMediaType.tvShow) {
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
    } else if (choice == AddMediaType.book) {
      final result = await Navigator.push<MediaBlock>(
        context,
        MaterialPageRoute(
          builder: (context) => const AddMediaScreen(initialTab: 2),
        ),
      );
      if (result != null && result is BookBlock) {
        await manager.addBook(result);
      }
    } else if (choice == AddMediaType.comicBook) {
      final result = await Navigator.push<MediaBlock>(
        context,
        MaterialPageRoute(
          builder: (context) => const AddMediaScreen(initialTab: 3),
        ),
      );
      if (result != null && result is ComicBookBlock) {
        await manager.addComicBook(result);
      }
    } else if (choice == AddMediaType.collection) {
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

class _ReadingCard extends StatelessWidget {
  final MediaBlock media;
  final ValueChanged<MediaBlock> onEdit;

  const _ReadingCard({required this.media, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final progress = media is BookBlock
        ? (media as BookBlock).currentPage
        : (media as ComicBookBlock).currentChapter;
    final maxValue = media is BookBlock
        ? (media as BookBlock).pageCount
        : (media as ComicBookBlock).chapterCount;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: () async {
          final result =
              await ReadingModal.show(context: context, media: media);
          if (result != null) onEdit(result.media);
        },
        title: Text(media.title),
        subtitle: Text(
          maxValue > 0 ? '$progress / $maxValue' : '$progress',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
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

  Future<void> _showMoveDialog(BuildContext context) async {
    if (onMoveToCollection == null || collections.isEmpty) return;

    String? selectedId;
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Move to Collection'),
              content: DropdownButtonFormField<String?>(
                initialValue: selectedId,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Leave here'),
                  ),
                  ...collections.map(
                    (collection) => DropdownMenuItem<String?>(
                      value: collection.id,
                      child: Text(collection.title),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => selectedId = value),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, selectedId),
                  child: const Text('Move'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!context.mounted) return;
    if (result != null) {
      onMoveToCollection!(result);
    }
  }

  Future<void> _showContextMenu(
      BuildContext context, Offset globalPosition) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final choice = await showMenu<_CardAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        overlay.size.width - globalPosition.dx,
        overlay.size.height - globalPosition.dy,
      ),
      items: [
        const PopupMenuItem(
          value: _CardAction.edit,
          child: Text('Edit Rating'),
        ),
        if (onMoveToCollection != null && collections.isNotEmpty)
          const PopupMenuItem(
            value: _CardAction.move,
            child: Text('Move to Collection'),
          ),
        const PopupMenuItem(
          value: _CardAction.delete,
          child: Text('Delete'),
        ),
      ],
    );

    if (!context.mounted) return;
    if (choice == _CardAction.edit) {
      await _showEditModal(context);
    } else if (choice == _CardAction.move) {
      await _showMoveDialog(context);
    } else if (choice == _CardAction.delete) {
      onDelete();
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
        child: GestureDetector(
          onTap: () => _showEditModal(context),
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

  Future<void> _showMoveDialog(BuildContext context) async {
    if (onMoveToCollection == null || collections.isEmpty) return;

    String? selectedId;
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Move to Collection'),
              content: DropdownButtonFormField<String?>(
                initialValue: selectedId,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Leave here'),
                  ),
                  ...collections.map(
                    (collection) => DropdownMenuItem<String?>(
                      value: collection.id,
                      child: Text(collection.title),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => selectedId = value),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, selectedId),
                  child: const Text('Move'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!context.mounted) return;
    if (result != null) {
      onMoveToCollection!(result);
    }
  }

  Future<void> _showContextMenu(
      BuildContext context, Offset globalPosition) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final choice = await showMenu<_CardAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        overlay.size.width - globalPosition.dx,
        overlay.size.height - globalPosition.dy,
      ),
      items: [
        const PopupMenuItem(
          value: _CardAction.edit,
          child: Text('Edit Rating'),
        ),
        if (onMoveToCollection != null && collections.isNotEmpty)
          const PopupMenuItem(
            value: _CardAction.move,
            child: Text('Move to Collection'),
          ),
        const PopupMenuItem(
          value: _CardAction.delete,
          child: Text('Delete'),
        ),
      ],
    );

    if (!context.mounted) return;
    if (choice == _CardAction.edit) {
      await _showEditModal(context);
    } else if (choice == _CardAction.move) {
      await _showMoveDialog(context);
    } else if (choice == _CardAction.delete) {
      onDelete();
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
