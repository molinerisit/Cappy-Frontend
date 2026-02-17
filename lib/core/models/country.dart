class Country {
  final String id;
  final String name;
  final String code;
  final String icon;
  final String? flagUrl;
  final bool hasRecipes;
  final bool hasCookingSchool;
  final bool hasCulture;
  final bool isPremium;
  final bool isActive;
  final int order;

  Country({
    required this.id,
    required this.name,
    required this.code,
    required this.icon,
    this.flagUrl,
    required this.hasRecipes,
    required this.hasCookingSchool,
    required this.hasCulture,
    required this.isPremium,
    required this.isActive,
    required this.order,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      icon: json['icon'] ?? '🌍',
      flagUrl: json['flagUrl'],
      hasRecipes: json['hasRecipes'] ?? true,
      hasCookingSchool: json['hasCookingSchool'] ?? true,
      hasCulture: json['hasCulture'] ?? true,
      isPremium: json['isPremium'] ?? false,
      isActive: json['isActive'] ?? true,
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'code': code,
      'icon': icon,
      'flagUrl': flagUrl,
      'hasRecipes': hasRecipes,
      'hasCookingSchool': hasCookingSchool,
      'hasCulture': hasCulture,
      'isPremium': isPremium,
      'isActive': isActive,
      'order': order,
    };
  }
}
