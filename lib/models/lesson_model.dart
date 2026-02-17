class LessonModel {
  final String id;
  final String title;
  final String description;
  final int order;
  final bool locked;
  final bool completed;
  final int xpReward;
  final List<dynamic> ingredients;
  final List<String> steps;
  final Map<String, dynamic>? nutrition;
  final List<String> tips;
  final bool isPremium;

  const LessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.locked,
    required this.completed,
    required this.xpReward,
    required this.ingredients,
    required this.steps,
    required this.nutrition,
    required this.tips,
    required this.isPremium,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    final status = json["status"]?.toString() ?? "locked";
    return LessonModel(
      id: json["id"]?.toString() ?? json["_id"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      order: (json["order"] as num?)?.toInt() ?? 0,
      locked: status == "locked",
      completed: status == "completed",
      xpReward: (json["xpReward"] as num?)?.toInt() ?? 0,
      ingredients: (json["ingredients"] as List?) ?? const [],
      steps: ((json["steps"] as List?) ?? const [])
          .map((step) => step.toString())
          .toList(),
      nutrition: json["nutrition"] as Map<String, dynamic>?,
      tips: ((json["tips"] as List?) ?? const [])
          .map((tip) => tip.toString())
          .toList(),
      isPremium: json["isPremium"] == true,
    );
  }
}
