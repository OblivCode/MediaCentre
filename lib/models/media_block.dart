abstract class MediaBlock {
  final String id;
  final String title;

  MediaBlock({required this.id, required this.title});

  Map<String, dynamic> toJson();
}
