import 'package:flutter/material.dart';

import '../models/book_block.dart';
import '../models/comic_book_block.dart';
import '../models/media_block.dart';

class ReadingModalResult {
  final MediaBlock media;

  ReadingModalResult({required this.media});
}

class ReadingModal extends StatefulWidget {
  final MediaBlock media;

  const ReadingModal({super.key, required this.media});

  static Future<ReadingModalResult?> show({
    required BuildContext context,
    required MediaBlock media,
  }) {
    return showModalBottomSheet<ReadingModalResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ReadingModal(media: media),
    );
  }

  @override
  State<ReadingModal> createState() => _ReadingModalState();
}

class _ReadingModalState extends State<ReadingModal> {
  late final TextEditingController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController =
        TextEditingController(text: _currentProgress.toString());
  }

  int get _currentProgress {
    if (widget.media is BookBlock) {
      return (widget.media as BookBlock).currentPage;
    }
    if (widget.media is ComicBookBlock) {
      return (widget.media as ComicBookBlock).currentChapter;
    }
    return 0;
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _save() {
    final value =
        int.tryParse(_progressController.text.trim()) ?? _currentProgress;
    if (widget.media is BookBlock) {
      Navigator.pop(
        context,
        ReadingModalResult(
          media: (widget.media as BookBlock).copyWith(currentPage: value),
        ),
      );
    } else if (widget.media is ComicBookBlock) {
      Navigator.pop(
        context,
        ReadingModalResult(
          media:
              (widget.media as ComicBookBlock).copyWith(currentChapter: value),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final label =
        widget.media is BookBlock ? 'Current Page' : 'Current Chapter';
    final maxValue = widget.media is BookBlock
        ? (widget.media as BookBlock).pageCount
        : (widget.media as ComicBookBlock).chapterCount;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.media.title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _progressController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: label, border: const OutlineInputBorder()),
          ),
          if (maxValue > 0) ...[
            const SizedBox(height: 12),
            Text('Max: $maxValue'),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
