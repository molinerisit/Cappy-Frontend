class CountryModel {
  final String id;
  final String name;
  final String code;
  final String icon;
  final String description;
  final int order;
  final bool isActive;
  final bool isPremium;

  const CountryModel({
    required this.id,
    required this.name,
    required this.code,
    required this.icon,
    required this.description,
    required this.order,
    required this.isActive,
    required this.isPremium,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      order: json['order'] ?? 0,
      isActive: json['isActive'] ?? true,
      isPremium: json['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'icon': icon,
      'description': description,
      'order': order,
      'isActive': isActive,
      'isPremium': isPremium,
    };
  }
}
