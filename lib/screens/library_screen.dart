import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/volume_manager.dart';
import '../widgets/add_media_menu.dart';
import '../widgets/rating_modal.dart';
import 'add_media_screen.dart';
import 'create_collection_screen.dart';
import 'settings_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VolumeManager>(
      builder: (context, manager, child) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MediaCentre'),
                if (manager.activeVolume != null)
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
          body: _buildBody(context, manager),
          floatingActionButton: FloatingActionButton(
            onPressed:
                manager.isLoading ? null : () => _showAddMenu(context, manager),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, VolumeManager manager) {
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

    if (manager.library.children.isEmpty) {
      return const Center(
        child: Text(
          'No movies yet.\nTap + to add one.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: manager.library.children.length,
      itemBuilder: (context, index) {
        final media = manager.library.children[index];
        if (media is MovieBlock) {
          return _MovieCard(
            movie: media,
            onDelete: () => manager.deleteMovie(media.id),
            onEdit: (updated) => manager.updateMovie(updated),
          );
        }
        return ListTile(
          title: Text(media.title),
          subtitle: const Text('Collection'),
        );
      },
    );
  }

  void _showAddMenu(BuildContext context, VolumeManager manager) async {
    final choice = await AddMediaMenu.show(context);
    if (choice == null || !context.mounted) return;

    switch (choice) {
      case AddMediaType.movie:
        final result = await Navigator.push<MovieBlock>(
          context,
          MaterialPageRoute(builder: (context) => const AddMediaScreen()),
        );
        if (result != null) {
          manager.addMovie(result);
        }
      case AddMediaType.tvShow:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TV Show support coming soon!')),
        );
      case AddMediaType.collection:
        final result = await Navigator.push<CollectionBlock>(
          context,
          MaterialPageRoute(
              builder: (context) => const CreateCollectionScreen()),
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
  final ValueChanged<MovieBlock> onEdit;

  const _MovieCard({
    required this.movie,
    required this.onDelete,
    required this.onEdit,
  });

  Future<void> _showEditModal(BuildContext context) async {
    final updatedMovie = await RatingModal.show(
      context: context,
      movie: movie,
      posterUrl: movie.posterUrl,
      synopsis: movie.synopsis,
      runtimeMinutes: movie.runtimeMinutes,
    );

    if (updatedMovie != null) {
      onEdit(updatedMovie);
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
