import 'package:flutter/material.dart';

import '../screens/library_domain.dart';

enum AddMediaType { movie, tvShow, book, comicBook, collection }

class AddMediaMenu {
  static Future<AddMediaType?> show(
    BuildContext context, {
    LibraryDomain domain = LibraryDomain.watch,
  }) {
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
            if (domain == LibraryDomain.watch) ...[
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
            ] else if (domain == LibraryDomain.read) ...[
              ListTile(
                leading: const Icon(Icons.menu_book),
                title: const Text('Add Book'),
                onTap: () => Navigator.pop(context, AddMediaType.book),
              ),
              ListTile(
                leading: const Icon(Icons.style),
                title: const Text('Add Comic Book'),
                onTap: () => Navigator.pop(context, AddMediaType.comicBook),
              ),
            ] else if (domain == LibraryDomain.collections) ...[
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Create Collection'),
                onTap: () => Navigator.pop(context, AddMediaType.collection),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
