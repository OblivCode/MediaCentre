import 'package:flutter/material.dart';

import '../models/audio_blocks.dart';

class ListeningModalResult {
  final AlbumBlock media;

  ListeningModalResult({required this.media});
}

class ListeningModal extends StatefulWidget {
  final AlbumBlock media;

  const ListeningModal({super.key, required this.media});

  static Future<ListeningModalResult?> show({
    required BuildContext context,
    required AlbumBlock media,
  }) {
    return showModalBottomSheet<ListeningModalResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ListeningModal(media: media),
    );
  }

  @override
  State<ListeningModal> createState() => _ListeningModalState();
}

class _ListeningModalState extends State<ListeningModal> {
  late int _rating;
  late int _listenCount;
  late final TextEditingController _listenCountController;

  @override
  void initState() {
    super.initState();
    _rating = widget.media.userRating;
    _listenCount = widget.media.listenCount;
    _listenCountController =
        TextEditingController(text: _listenCount.toString());
  }

  @override
  void dispose() {
    _listenCountController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(
      context,
      ListeningModalResult(
        media: widget.media.copyWith(
          userRating: _rating,
          listenCount: _listenCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          const Text('Your Rating', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          _StarRatingSelector(
            rating: _rating,
            onRatingChanged: (rating) => setState(() => _rating = rating),
          ),
          const SizedBox(height: 20),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Listen Count',
              border: OutlineInputBorder(),
            ),
            controller: _listenCountController,
            onChanged: (value) {
              _listenCount = int.tryParse(value.trim()) ?? _listenCount;
            },
          ),
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
