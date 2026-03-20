import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/volume_manager.dart';
import 'add_media_screen.dart';
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
            onPressed: manager.isLoading
                ? null
                : () => _navigateToAddMedia(context, manager),
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
      itemCount: manager.library.children.length,
      itemBuilder: (context, index) {
        final media = manager.library.children[index];
        if (media is MovieBlock) {
          return _MovieCard(
            movie: media,
            onDelete: () => manager.deleteMovie(media.id),
          );
        }
        return ListTile(
          title: Text(media.title),
          subtitle: const Text('Collection'),
        );
      },
    );
  }

  void _navigateToAddMedia(BuildContext context, VolumeManager manager) async {
    final result = await Navigator.push<MovieBlock>(
      context,
      MaterialPageRoute(builder: (context) => const AddMediaScreen()),
    );

    if (result != null) {
      manager.addMovie(result);
    }
  }
}

class _MovieCard extends StatelessWidget {
  final MovieBlock movie;
  final VoidCallback onDelete;

  const _MovieCard({required this.movie, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Dismissible(
        key: Key(movie.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Colors.red,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      movie.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StarRating(rating: movie.userRating),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${movie.runtimeMinutes} min',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
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
