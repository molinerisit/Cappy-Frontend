class PathGroup {
  final String id;
  final String title;
  final int order;

  const PathGroup({required this.id, required this.title, required this.order});

  factory PathGroup.fromJson(Map<String, dynamic> json) {
    return PathGroup(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      order: json['order'] as int? ?? 0,
    );
  }
}
