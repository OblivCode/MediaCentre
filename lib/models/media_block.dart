abstract class MediaBlock {
  final String id;
  final String title;
  final DateTime dateAdded;

  MediaBlock({required this.id, required this.title, DateTime? dateAdded})
      : dateAdded = dateAdded ?? DateTime.now();

  Map<String, dynamic> toJson();
}
