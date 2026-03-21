import 'package:flutter/material.dart';

enum AddMediaType { movie, tvShow, collection }

class AddMediaMenu {
  static Future<AddMediaType?> show(BuildContext context) {
    return showModalBottomSheet<AddMediaType>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.movie),
              title: const Text('Add Movie'),
              onTap: () => Navigator.pop(context, AddMediaType.movie),
            ),
            ListTile(
              leading: const Icon(Icons.tv),
              title: const Text('Add TV Show'),
              onTap: () => Navigator.pop(context, AddMediaType.tvShow),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Create Collection'),
              onTap: () => Navigator.pop(context, AddMediaType.collection),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
