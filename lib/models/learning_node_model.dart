class LearningNodeModel {
  final String id;
  final String pathId;
  final String title;
  final String? description;
  final String type; // 'recipe' | 'skill' | 'quiz'
  final int difficulty; // 1=easy, 2=medium, 3=hard
  final int xpReward;
  final int order;
  final List<dynamic> steps;
  final List<Map<String, dynamic>>? ingredients;
  final int? prepTime;
  final int? cookTime;
  final int? servings;
  final bool isPremium;
  final List<String> requiredNodes;
  final String? status; // 'locked' | 'unlocked' | 'completed'

  const LearningNodeModel({
    required this.id,
    required this.pathId,
    required this.title,
    this.description,
    required this.type,
    required this.difficulty,
    required this.xpReward,
    required this.order,
    required this.steps,
    this.ingredients,
    this.prepTime,
    this.cookTime,
    this.servings,
    required this.isPremium,
    required this.requiredNodes,
    this.status,
  });

  factory LearningNodeModel.fromJson(Map<String, dynamic> json) {
    return LearningNodeModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      pathId: json['pathId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      type: json['type']?.toString() ?? 'recipe',
      difficulty: (json['difficulty'] is int) ? json['difficulty'] : 2,
      xpReward: json['xpReward'] ?? 0,
      order: json['order'] ?? 0,
      steps: json['steps'] ?? [],
      ingredients: (json['ingredients'] as List?)
          ?.map((i) => i as Map<String, dynamic>)
          .toList(),
      prepTime: json['prepTime'],
      cookTime: json['cookTime'],
      servings: json['servings'],
      isPremium: json['isPremium'] ?? false,
      requiredNodes:
          (json['requiredNodes'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      status: json['status']?.toString(),
    );
  }

  bool get isLocked => status == 'locked';
  bool get isUnlocked => status == 'unlocked';
  bool get isCompleted => status == 'completed';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pathId': pathId,
      'title': title,
      'description': description,
      'type': type,
      'difficulty': difficulty,
      'xpReward': xpReward,
      'order': order,
      'steps': steps,
      'ingredients': ingredients,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'isPremium': isPremium,
      'requiredNodes': requiredNodes,
      'status': status,
    };
  }
}
