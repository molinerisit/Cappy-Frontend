class CultureNode {
  final String id;
  final String countryId;
  final String title;
  final String description;
  final int xp;
  final bool isLocked;

  CultureNode({
    required this.id,
    required this.countryId,
    required this.title,
    required this.description,
    required this.xp,
    required this.isLocked,
  });

  factory CultureNode.fromJson(Map<String, dynamic> json) {
    return CultureNode(
      id: json['id'],
      countryId: json['countryId'],
      title: json['title'],
      description: json['description'],
      xp: json['xp'],
      isLocked: json['isLocked'],
    );
  }
}
