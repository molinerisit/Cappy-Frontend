/// Modelos tipados para estructura de lecciones
/// Soporta múltiples tipos de steps estilo Duolingo
library;

class LessonStep {
  final String id;
  final int order;
  final String
  type; // text, image, video, audio, multiple_choice, ingredients, interactive
  final String title;
  final String? instruction;
  final String? imageUrl;
  final String? videoUrl;
  final String? audioUrl;

  // Para múltiple choice
  final String? question;
  final List<MultipleChoiceOption>? options;

  // Para ingredientes
  final List<IngredientItem>? ingredients;

  // Validación/feedback
  final Map<String, dynamic>? feedback;
  final int? duration; // en segundos

  const LessonStep({
    required this.id,
    required this.order,
    required this.type,
    required this.title,
    this.instruction,
    this.imageUrl,
    this.videoUrl,
    this.audioUrl,
    this.question,
    this.options,
    this.ingredients,
    this.feedback,
    this.duration,
  });

  factory LessonStep.fromJson(Map<String, dynamic> json) {
    return LessonStep(
      id: json['id'] ?? '',
      order: json['order'] ?? 0,
      type: json['type'] ?? 'text',
      title: json['title'] ?? '',
      instruction: json['instruction'] ?? json['content'],
      imageUrl: json['imageUrl'],
      videoUrl: json['videoUrl'],
      audioUrl: json['audioUrl'],
      question: json['question'],
      options: (json['options'] as List?)
          ?.map((o) => MultipleChoiceOption.fromJson(o))
          .toList(),
      ingredients: (json['ingredients'] as List?)
          ?.map((i) => IngredientItem.fromJson(i))
          .toList(),
      feedback: json['feedback'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'type': type,
      'title': title,
      'instruction': instruction,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'question': question,
      'options': options?.map((o) => o.toJson()).toList(),
      'ingredients': ingredients?.map((i) => i.toJson()).toList(),
      'feedback': feedback,
      'duration': duration,
    };
  }
}

class MultipleChoiceOption {
  final String id;
  final String text;
  final String? imageUrl;
  final bool isCorrect;
  final String? feedback;

  const MultipleChoiceOption({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.isCorrect,
    this.feedback,
  });

  factory MultipleChoiceOption.fromJson(Map<String, dynamic> json) {
    return MultipleChoiceOption(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      imageUrl: json['imageUrl'],
      isCorrect: json['isCorrect'] ?? false,
      feedback: json['feedback'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'imageUrl': imageUrl,
      'isCorrect': isCorrect,
      'feedback': feedback,
    };
  }
}

class IngredientItem {
  final String name;
  final String? quantity;
  final String? unit;

  const IngredientItem({required this.name, this.quantity, this.unit});

  factory IngredientItem.fromJson(Map<String, dynamic> json) {
    return IngredientItem(
      name: json['name'] ?? '',
      quantity: json['quantity'],
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'quantity': quantity, 'unit': unit};
  }

  String get formatted {
    final parts = [name];
    if (quantity != null && quantity!.isNotEmpty) parts.add(quantity!);
    if (unit != null && unit!.isNotEmpty) parts.add(unit!);
    return parts.join(' ');
  }
}

class RecipeLesson {
  final String id;
  final String countryId;
  final String title;
  final String? description;
  final String difficulty; // easy, medium, hard
  final int xpReward;
  final int? servings;
  final int? prepTime; // minutos
  final int? cookTime; // minutos
  final String? imageUrl;
  final List<IngredientItem> ingredients;
  final List<LessonStep> steps;
  final bool isPremium;
  final bool isActive;
  final DateTime? createdAt;

  const RecipeLesson({
    required this.id,
    required this.countryId,
    required this.title,
    this.description,
    required this.difficulty,
    required this.xpReward,
    this.servings,
    this.prepTime,
    this.cookTime,
    this.imageUrl,
    required this.ingredients,
    required this.steps,
    required this.isPremium,
    required this.isActive,
    this.createdAt,
  });

  factory RecipeLesson.fromJson(Map<String, dynamic> json) {
    return RecipeLesson(
      id: json['_id'] ?? json['id'] ?? '',
      countryId: json['countryId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      difficulty: json['difficulty'] ?? 'medium',
      xpReward: json['xpReward'] ?? 50,
      servings: json['servings'],
      prepTime: json['prepTime'],
      cookTime: json['cookTime'],
      imageUrl: json['imageUrl'],
      ingredients:
          (json['ingredients'] as List?)
              ?.map((i) => IngredientItem.fromJson(i))
              .toList() ??
          [],
      steps:
          (json['steps'] as List?)
              ?.map((s) => LessonStep.fromJson(s))
              .toList() ??
          [],
      isPremium: json['isPremium'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
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
      'imageUrl': imageUrl,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'steps': steps.map((s) => s.toJson()).toList(),
      'isPremium': isPremium,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  String get totalTime {
    if (prepTime == null && cookTime == null) return '';
    final prep = prepTime ?? 0;
    final cook = cookTime ?? 0;
    final total = prep + cook;
    return '${total}m';
  }

  String get difficultyEmoji {
    switch (difficulty) {
      case 'easy':
        return '🟢';
      case 'hard':
        return '🔴';
      default:
        return '🟡';
    }
  }
}

class CultureLesson {
  final String id;
  final String countryId;
  final String title;
  final String? description;
  final String category; // traditions, history, cuisine, etc
  final String difficulty;
  final int xpReward;
  final String? imageUrl;
  final List<LessonStep> steps;
  final String? culturalSignificance;
  final String? historicalBackground;
  final bool isPremium;
  final bool isActive;
  final DateTime? createdAt;

  const CultureLesson({
    required this.id,
    required this.countryId,
    required this.title,
    this.description,
    required this.category,
    required this.difficulty,
    required this.xpReward,
    this.imageUrl,
    required this.steps,
    this.culturalSignificance,
    this.historicalBackground,
    required this.isPremium,
    required this.isActive,
    this.createdAt,
  });

  factory CultureLesson.fromJson(Map<String, dynamic> json) {
    return CultureLesson(
      id: json['_id'] ?? json['id'] ?? '',
      countryId: json['countryId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'tradition',
      difficulty: json['difficulty'] ?? 'medium',
      xpReward: json['xpReward'] ?? 50,
      imageUrl: json['imageUrl'],
      steps:
          (json['steps'] as List?)
              ?.map((s) => LessonStep.fromJson(s))
              .toList() ??
          [],
      culturalSignificance: json['culturalSignificance'],
      historicalBackground: json['historicalBackground'],
      isPremium: json['isPremium'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'countryId': countryId,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'xpReward': xpReward,
      'imageUrl': imageUrl,
      'steps': steps.map((s) => s.toJson()).toList(),
      'culturalSignificance': culturalSignificance,
      'historicalBackground': historicalBackground,
      'isPremium': isPremium,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  String get categoryEmoji {
    switch (category) {
      case 'traditions':
        return '🎭';
      case 'history':
        return '📚';
      case 'cuisine':
        return '🍽️';
      default:
        return '🌍';
    }
  }
}
