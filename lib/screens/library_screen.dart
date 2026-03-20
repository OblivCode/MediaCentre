import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import 'add_media_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final StorageService _storageService = StorageService();
  CollectionBlock _library = CollectionBlock(id: 'root', title: 'My Library');
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    final library = await _storageService.loadLibrary();
    setState(() {
      _library = library;
      _isLoading = false;
    });
  }

  Future<void> _addMovie(MovieBlock movie) async {
    final updatedLibrary = _library.addChild(movie);
    await _storageService.saveLibrary(updatedLibrary);
    setState(() {
      _library = updatedLibrary;
    });
  }

  Future<void> _deleteMovie(String id) async {
    final updatedLibrary = _library.removeChild(id);
    await _storageService.saveLibrary(updatedLibrary);
    setState(() {
      _library = updatedLibrary;
    });
  }

  void _navigateToAddMedia() async {
    final result = await Navigator.push<MovieBlock>(
      context,
      MaterialPageRoute(builder: (context) => const AddMediaScreen()),
    );

    if (result != null) {
      _addMovie(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediaCentre'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _library.children.isEmpty
              ? const Center(
                  child: Text(
                    'No movies yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _library.children.length,
                  itemBuilder: (context, index) {
                    final media = _library.children[index];
                    if (media is MovieBlock) {
                      return _MovieCard(
                        movie: media,
                        onDelete: () => _deleteMovie(media.id),
                      );
                    }
                    return ListTile(
                      title: Text(media.title),
                      subtitle: const Text('Collection'),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddMedia,
        child: const Icon(Icons.add),
      ),
    );
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
