class PathModel {
  final String id;
  final String name;
  final String type;
  final String icon;
  final String description;

  const PathModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.description,
  });

  factory PathModel.fromJson(Map<String, dynamic> json) {
    return PathModel(
      id: json["_id"]?.toString() ?? json["id"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      type: json["type"]?.toString() ?? "",
      icon: json["icon"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
    );
  }
}
