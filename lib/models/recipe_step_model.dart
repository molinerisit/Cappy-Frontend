class RecipeStep {
  final String id;
  final String recipeId;
  final String title;
  final String description;
  final String? image;
  final bool hasTimer;
  final int? timerDurationSeconds;

  RecipeStep({
    required this.id,
    required this.recipeId,
    required this.title,
    required this.description,
    this.image,
    this.hasTimer = false,
    this.timerDurationSeconds,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      id: json['id'],
      recipeId: json['recipeId'],
      title: json['title'],
      description: json['description'],
      image: json['image'],
      hasTimer: json['hasTimer'] ?? false,
      timerDurationSeconds: json['timerDurationSeconds'],
    );
  }
}
