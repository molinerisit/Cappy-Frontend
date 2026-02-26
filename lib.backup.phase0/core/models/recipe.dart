class RecipeStep {
  final String instruction;
  final String? image;
  final String? animation;
  final Map<String, dynamic>? validationLogic;
  final String? feedback;
  final int duration;

  RecipeStep({
    required this.instruction,
    this.image,
    this.animation,
    this.validationLogic,
    this.feedback,
    required this.duration,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      instruction: json['instruction'] ?? '',
      image: json['image'],
      animation: json['animation'],
      validationLogic: json['validationLogic'],
      feedback: json['feedback'],
      duration: json['duration'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instruction': instruction,
      'image': image,
      'animation': animation,
      'validationLogic': validationLogic,
      'feedback': feedback,
      'duration': duration,
    };
  }
}

class RecipeIngredient {
  final String name;
  final double quantity;
  final String unit;

  RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'quantity': quantity, 'unit': unit};
  }
}

class RecipeTool {
  final String name;
  final bool isOptional;

  RecipeTool({required this.name, required this.isOptional});

  factory RecipeTool.fromJson(Map<String, dynamic> json) {
    return RecipeTool(
      name: json['name'] ?? '',
      isOptional: json['isOptional'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'isOptional': isOptional};
  }
}

class Recipe {
  final String id;
  final String countryId;
  final String title;
  final String description;
  final String difficulty; // easy, medium, hard
  final int xpReward;
  final int servings;
  final int prepTime; // minutes
  final int cookTime; // minutes
  final List<RecipeIngredient> ingredients;
  final List<RecipeTool> tools;
  final List<RecipeStep> steps;
  final List<String> requiredSkills;
  final List<String> requiredRecipes;
  final Map<String, dynamic>? nutrition;
  final List<String> tips;
  final List<String> tags;
  final bool isPremium;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.countryId,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.xpReward,
    required this.servings,
    required this.prepTime,
    required this.cookTime,
    required this.ingredients,
    required this.tools,
    required this.steps,
    required this.requiredSkills,
    required this.requiredRecipes,
    this.nutrition,
    required this.tips,
    required this.tags,
    required this.isPremium,
    required this.createdAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['_id'] ?? '',
      countryId: json['countryId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? 'medium',
      xpReward: json['xpReward'] ?? 50,
      servings: json['servings'] ?? 1,
      prepTime: json['prepTime'] ?? 0,
      cookTime: json['cookTime'] ?? 0,
      ingredients:
          (json['ingredients'] as List?)
              ?.map((item) => RecipeIngredient.fromJson(item))
              .toList() ??
          [],
      tools:
          (json['tools'] as List?)
              ?.map((item) => RecipeTool.fromJson(item))
              .toList() ??
          [],
      steps:
          (json['steps'] as List?)
              ?.map((item) => RecipeStep.fromJson(item))
              .toList() ??
          [],
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      requiredRecipes: List<String>.from(json['requiredRecipes'] ?? []),
      nutrition: json['nutrition'],
      tips: List<String>.from(json['tips'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      isPremium: json['isPremium'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'countryId': countryId,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'xpReward': xpReward,
      'servings': servings,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'tools': tools.map((t) => t.toJson()).toList(),
      'steps': steps.map((s) => s.toJson()).toList(),
      'requiredSkills': requiredSkills,
      'requiredRecipes': requiredRecipes,
      'nutrition': nutrition,
      'tips': tips,
      'tags': tags,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  int get totalTime => prepTime + cookTime;
}
