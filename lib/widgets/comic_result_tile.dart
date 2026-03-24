import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/anilist_service.dart';

class ComicResultTile extends StatelessWidget {
  final AniListSearchResult result;
  final VoidCallback onTap;

  const ComicResultTile({super.key, required this.result, required this.onTap});

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
                child: result.coverImage != null
                    ? CachedNetworkImage(
                        imageUrl: result.coverImage!,
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
                          child: const Icon(Icons.style, size: 30),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 90,
                        color: Colors.grey[300],
                        child: const Icon(Icons.style, size: 30),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        )),
                    if (result.author != null) ...[
                      const SizedBox(height: 4),
                      Text(result.author!),
                    ],
                    if (result.chapterCount != null) ...[
                      const SizedBox(height: 4),
                      Text('${result.chapterCount} chapters'),
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
