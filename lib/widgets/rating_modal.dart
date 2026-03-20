import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/movie_block.dart';

class RatingModal extends StatefulWidget {
  final MovieBlock movie;
  final String? posterUrl;
  final String? synopsis;
  final int? runtimeMinutes;
  final ValueChanged<MovieBlock> onSave;

  const RatingModal({
    super.key,
    required this.movie,
    this.posterUrl,
    this.synopsis,
    this.runtimeMinutes,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required MovieBlock movie,
    String? posterUrl,
    String? synopsis,
    int? runtimeMinutes,
    required ValueChanged<MovieBlock> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => RatingModal(
        movie: movie,
        posterUrl: posterUrl,
        synopsis: synopsis,
        runtimeMinutes: runtimeMinutes,
        onSave: onSave,
      ),
    );
  }

  @override
  State<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.movie.userRating;
  }

  void _save() {
    final updatedMovie = widget.movie.copyWith(userRating: _rating);
    widget.onSave(updatedMovie);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final posterUrl = widget.posterUrl ?? widget.movie.posterUrl;
    final synopsis = widget.synopsis ?? widget.movie.synopsis;
    final runtime = widget.runtimeMinutes ?? widget.movie.runtimeMinutes;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (posterUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: posterUrl,
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 80,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 80,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.movie, size: 40),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.movie.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (runtime > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$runtime min',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (synopsis != null && synopsis.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                synopsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Your Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _StarRatingSelector(
              rating: _rating,
              onRatingChanged: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRatingSelector extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;

  const _StarRatingSelector({
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => onRatingChanged(index + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              index < rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 40,
            ),
          ),
        );
      }),
    );
  }
}
