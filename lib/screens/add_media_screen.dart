import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/movie_block.dart';

class AddMediaScreen extends StatefulWidget {
  const AddMediaScreen({super.key});

  @override
  State<AddMediaScreen> createState() => _AddMediaScreenState();
}

class _AddMediaScreenState extends State<AddMediaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _runtimeController = TextEditingController();
  int _rating = 3;

  void _saveMovie() {
    if (_formKey.currentState!.validate()) {
      final movie = MovieBlock(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        runtimeMinutes: int.tryParse(_runtimeController.text) ?? 0,
        userRating: _rating,
      );

      Navigator.pop(context, movie);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _runtimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Movie'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _saveMovie,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _runtimeController,
                decoration: const InputDecoration(
                  labelText: 'Runtime (minutes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter runtime';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number < 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              const Text(
                'Rating',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _StarRatingSelector(
                rating: _rating,
                onRatingChanged: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
            ],
          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 4),
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
