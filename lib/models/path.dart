class Path {
  final String id;
  final String name;
  final String type;
  final String icon;
  final String description;

  const Path({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.description,
  });

  factory Path.fromJson(Map<String, dynamic> json) {
    return Path(
      id: json["_id"]?.toString() ?? json["id"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      type: json["type"]?.toString() ?? "",
      icon: json["icon"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
    );
  }
}
