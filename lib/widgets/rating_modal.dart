import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/collection_block.dart';
import '../models/media_block.dart';
import '../models/movie_block.dart';
import '../models/tv_show_block.dart';
import '../models/season_block.dart';

class RatingModalResult {
  final MediaBlock media;
  final String? moveToCollectionId;

  RatingModalResult({required this.media, this.moveToCollectionId});
}

class RatingModal extends StatefulWidget {
  final MediaBlock media;
  final String? posterUrl;
  final String? synopsis;
  final int? runtimeMinutes;
  final List<CollectionBlock> collections;

  const RatingModal({
    super.key,
    required this.media,
    this.posterUrl,
    this.synopsis,
    this.runtimeMinutes,
    this.collections = const [],
  });

  static Future<RatingModalResult?> show({
    required BuildContext context,
    required MediaBlock media,
    String? posterUrl,
    String? synopsis,
    int? runtimeMinutes,
    List<CollectionBlock> collections = const [],
  }) {
    return showModalBottomSheet<RatingModalResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => RatingModal(
        media: media,
        posterUrl: posterUrl,
        synopsis: synopsis,
        runtimeMinutes: runtimeMinutes,
        collections: collections,
      ),
    );
  }

  @override
  State<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> {
  late int _rating;
  String? _selectedCollectionId;

  @override
  void initState() {
    super.initState();
    _rating = _getCurrentRating();
  }

  int _getCurrentRating() {
    if (widget.media is MovieBlock) {
      return (widget.media as MovieBlock).userRating;
    } else if (widget.media is TvShowBlock) {
      return (widget.media as TvShowBlock).userRating;
    } else if (widget.media is SeasonBlock) {
      return (widget.media as SeasonBlock).userRating;
    }
    return 0;
  }

  void _save() {
    final updatedMedia = _updateMediaWithRating();
    Navigator.pop(
      context,
      RatingModalResult(
        media: updatedMedia,
        moveToCollectionId: _selectedCollectionId,
      ),
    );
  }

  MediaBlock _updateMediaWithRating() {
    if (widget.media is MovieBlock) {
      return (widget.media as MovieBlock).copyWith(userRating: _rating);
    } else if (widget.media is TvShowBlock) {
      return (widget.media as TvShowBlock).copyWith(userRating: _rating);
    } else if (widget.media is SeasonBlock) {
      return (widget.media as SeasonBlock).copyWith(userRating: _rating);
    }
    return widget.media;
  }

  @override
  Widget build(BuildContext context) {
    final posterUrl = _getPosterUrl();
    final synopsis = _getSynopsis();
    final runtime = _getRuntime();
    final subtitle = _getSubtitle();

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
                        child: Icon(_getIcon(), size: 40),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.media.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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
            if (_shouldShowAverageRating()) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Average Episode Rating: ${_getAverageRating().toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
            if (widget.collections.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Move to Collection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCollectionId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Leave here',
                ),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Leave here')),
                  ...widget.collections.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.title)),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCollectionId = value;
                  });
                },
              ),
            ],
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

  String? _getPosterUrl() {
    if (widget.posterUrl != null) return widget.posterUrl;
    if (widget.media is MovieBlock) {
      return (widget.media as MovieBlock).posterUrl;
    } else if (widget.media is TvShowBlock) {
      return (widget.media as TvShowBlock).posterUrl;
    } else if (widget.media is SeasonBlock) {
      return (widget.media as SeasonBlock).posterUrl;
    }
    return null;
  }

  String? _getSynopsis() {
    if (widget.synopsis != null) return widget.synopsis;
    if (widget.media is MovieBlock) {
      return (widget.media as MovieBlock).synopsis;
    } else if (widget.media is TvShowBlock) {
      return (widget.media as TvShowBlock).synopsis;
    }
    return null;
  }

  int _getRuntime() {
    if (widget.runtimeMinutes != null) return widget.runtimeMinutes!;
    if (widget.media is MovieBlock) {
      return (widget.media as MovieBlock).runtimeMinutes;
    }
    return 0;
  }

  String? _getSubtitle() {
    if (widget.media is TvShowBlock) {
      final tv = widget.media as TvShowBlock;
      return tv.network;
    } else if (widget.media is SeasonBlock) {
      final season = widget.media as SeasonBlock;
      return 'Season ${season.seasonNumber}';
    }
    return null;
  }

  IconData _getIcon() {
    if (widget.media is TvShowBlock || widget.media is SeasonBlock) {
      return Icons.tv;
    }
    return Icons.movie;
  }

  bool _shouldShowAverageRating() {
    if (widget.media is TvShowBlock) {
      return (widget.media as TvShowBlock).averageEpisodeRating > 0;
    } else if (widget.media is SeasonBlock) {
      return (widget.media as SeasonBlock).averageEpisodeRating > 0;
    }
    return false;
  }

  double _getAverageRating() {
    if (widget.media is TvShowBlock) {
      return (widget.media as TvShowBlock).averageEpisodeRating;
    } else if (widget.media is SeasonBlock) {
      return (widget.media as SeasonBlock).averageEpisodeRating;
    }
    return 0;
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
