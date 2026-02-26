import 'learning_node_model.dart';

class LearningPathModel {
  final String id;
  final String type; // 'country_recipe' | 'country_culture' | 'goal'
  final String? countryId;
  final String? goalType; // 'cooking_school' | 'lose_weight' | 'become_vegan'
  final String title;
  final String? description;
  final String icon;
  final int order;
  final bool isActive;
  final bool isPremium;
  final List<LearningNodeModel> nodes;

  const LearningPathModel({
    required this.id,
    required this.type,
    this.countryId,
    this.goalType,
    required this.title,
    this.description,
    required this.icon,
    required this.order,
    required this.isActive,
    required this.isPremium,
    required this.nodes,
  });

  factory LearningPathModel.fromJson(Map<String, dynamic> json) {
    return LearningPathModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      countryId: json['countryId']?.toString(),
      goalType: json['goalType']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      icon: json['icon']?.toString() ?? '📚',
      order: json['order'] ?? 0,
      isActive: json['isActive'] ?? true,
      isPremium: json['isPremium'] ?? false,
      nodes:
          (json['nodes'] as List?)
              ?.map(
                (n) => LearningNodeModel.fromJson(n as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'countryId': countryId,
      'goalType': goalType,
      'title': title,
      'description': description,
      'icon': icon,
      'order': order,
      'isActive': isActive,
      'isPremium': isPremium,
      'nodes': nodes.map((n) => n.toJson()).toList(),
    };
  }
}
