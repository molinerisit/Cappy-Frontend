class LearningPath {
  final String id;
  final String type; // country_recipe, country_culture, goal
  final String? countryId;
  final String? goalType;
  final String title;
  final String description;
  final String icon;
  final int order;
  final List<Map<String, dynamic>> nodes;
  final Map<String, dynamic>? metadata;
  final bool isPremium;
  final bool isActive;
  final DateTime createdAt;

  LearningPath({
    required this.id,
    required this.type,
    this.countryId,
    this.goalType,
    required this.title,
    required this.description,
    required this.icon,
    required this.order,
    required this.nodes,
    this.metadata,
    required this.isPremium,
    required this.isActive,
    required this.createdAt,
  });

  factory LearningPath.fromJson(Map<String, dynamic> json) {
    return LearningPath(
      id: json['_id'] ?? '',
      type: json['type'] ?? 'country_recipe',
      countryId: json['countryId'],
      goalType: json['goalType'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '📚',
      order: json['order'] ?? 0,
      nodes: List<Map<String, dynamic>>.from(json['nodes'] ?? []),
      metadata: json['metadata'],
      isPremium: json['isPremium'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'countryId': countryId,
      'goalType': goalType,
      'title': title,
      'description': description,
      'icon': icon,
      'order': order,
      'nodes': nodes,
      'metadata': metadata,
      'isPremium': isPremium,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get typeLabel {
    switch (type) {
      case 'country_recipe':
        return '🍳 Recetas';
      case 'country_culture':
        return '🌍 Cultura';
      case 'goal':
        return '🎯 Objetivo';
      default:
        return type;
    }
  }

  bool get isGoal => type == 'goal';
  bool get isCountryRecipe => type == 'country_recipe';
  bool get isCountryCulture => type == 'country_culture';
}

class CountryHub {
  final String countryId;
  final String name;
  final String code;
  final String icon;
  final String? description;
  final LearningPath recipes;
  final LearningPath culture;

  CountryHub({
    required this.countryId,
    required this.name,
    required this.code,
    required this.icon,
    this.description,
    required this.recipes,
    required this.culture,
  });

  factory CountryHub.fromJson(Map<String, dynamic> json) {
    return CountryHub(
      countryId: json['country']['id'] ?? '',
      name: json['country']['name'] ?? '',
      code: json['country']['code'] ?? '',
      icon: json['country']['icon'] ?? '🌍',
      description: json['country']['description'],
      recipes: LearningPath.fromJson(json['recipes'] ?? {}),
      culture: LearningPath.fromJson(json['culture'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': {
        'id': countryId,
        'name': name,
        'code': code,
        'icon': icon,
        'description': description,
      },
      'recipes': recipes.toJson(),
      'culture': culture.toJson(),
    };
  }
}
