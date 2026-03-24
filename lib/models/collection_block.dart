import 'models.dart';

class CollectionBlock extends MediaBlock {
  final List<MediaBlock> children;

  CollectionBlock({
    required super.id,
    required super.title,
    List<MediaBlock>? children,
  }) : children = children ?? [];

  @override
  Map<String, dynamic> toJson() => {
        'type': 'collection',
        'id': id,
        'title': title,
        'children': children.map((c) => c.toJson()).toList(),
      };

  factory CollectionBlock.fromJson(Map<String, dynamic> json) {
    final childrenList = json['children'] as List<dynamic>? ?? [];
    final children = childrenList
        .map((c) => mediaBlockFromJson(c as Map<String, dynamic>))
        .toList();

    return CollectionBlock(
      id: json['id'] as String,
      title: json['title'] as String,
      children: children,
    );
  }

  CollectionBlock copyWith({
    String? id,
    String? title,
    List<MediaBlock>? children,
  }) {
    return CollectionBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      children: children ?? this.children,
    );
  }

  CollectionBlock addChild(MediaBlock child) {
    return copyWith(children: [...children, child]);
  }

  CollectionBlock removeChild(String id) {
    return copyWith(children: children.where((c) => c.id != id).toList());
  }

  CollectionBlock replaceChild(MediaBlock updated) {
    return copyWith(
      children: children.map((child) {
        if (child.id == updated.id) return updated;
        if (child is CollectionBlock) return child.replaceChild(updated);
        return child;
      }).toList(),
    );
  }
}
