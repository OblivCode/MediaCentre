import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/lastfm_service.dart';

class AlbumResultTile extends StatelessWidget {
  final LastFmSearchResult result;
  final VoidCallback onTap;

  const AlbumResultTile({super.key, required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: result.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: result.imageUrl!,
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 60,
                          height: 90,
                          color: Colors.grey[300],
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 60,
                          height: 90,
                          color: Colors.grey[300],
                          child: const Icon(Icons.album, size: 30),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 90,
                        color: Colors.grey[300],
                        child: const Icon(Icons.album, size: 30),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (result.artist != null) ...[
                      const SizedBox(height: 4),
                      Text(result.artist!),
                    ],
                    if (result.trackCount != null) ...[
                      const SizedBox(height: 4),
                      Text('${result.trackCount} tracks'),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
