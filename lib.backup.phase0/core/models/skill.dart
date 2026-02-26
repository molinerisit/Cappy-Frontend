class SkillStep {
  final String instruction;
  final String? image;
  final String? video;
  final Map<String, dynamic>? practice;
  final String? tips;
  final int duration;

  SkillStep({
    required this.instruction,
    this.image,
    this.video,
    this.practice,
    this.tips,
    required this.duration,
  });

  factory SkillStep.fromJson(Map<String, dynamic> json) {
    return SkillStep(
      instruction: json['instruction'] ?? '',
      image: json['image'],
      video: json['video'],
      practice: json['practice'],
      tips: json['tips'],
      duration: json['duration'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instruction': instruction,
      'image': image,
      'video': video,
      'practice': practice,
      'tips': tips,
      'duration': duration,
    };
  }
}

class Skill {
  final String id;
  final String countryId;
  final String name;
  final String description;
  final String
  category; // knife_skills, heat_control, seasoning, technique, preparation
  final int level; // 1-10
  final int order;
  final int xpReward;
  final List<String> prerequisites;
  final List<String> unlocksRecipes;
  final List<String> unlocksSkills;
  final List<SkillStep> steps;
  final List<String> tips;
  final bool isPremium;
  final DateTime createdAt;

  Skill({
    required this.id,
    required this.countryId,
    required this.name,
    required this.description,
    required this.category,
    required this.level,
    required this.order,
    required this.xpReward,
    required this.prerequisites,
    required this.unlocksRecipes,
    required this.unlocksSkills,
    required this.steps,
    required this.tips,
    required this.isPremium,
    required this.createdAt,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['_id'] ?? '',
      countryId: json['countryId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'technique',
      level: json['level'] ?? 1,
      order: json['order'] ?? 0,
      xpReward: json['xpReward'] ?? 30,
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      unlocksRecipes: List<String>.from(json['unlocksRecipes'] ?? []),
      unlocksSkills: List<String>.from(json['unlocksSkills'] ?? []),
      steps:
          (json['steps'] as List?)
              ?.map((item) => SkillStep.fromJson(item))
              .toList() ??
          [],
      tips: List<String>.from(json['tips'] ?? []),
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
      'name': name,
      'description': description,
      'category': category,
      'level': level,
      'order': order,
      'xpReward': xpReward,
      'prerequisites': prerequisites,
      'unlocksRecipes': unlocksRecipes,
      'unlocksSkills': unlocksSkills,
      'steps': steps.map((s) => s.toJson()).toList(),
      'tips': tips,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get categoryLabel {
    switch (category) {
      case 'knife_skills':
        return 'Técnicas de Cuchillo';
      case 'heat_control':
        return 'Control del Calor';
      case 'seasoning':
        return 'Sabores y Condimentos';
      case 'technique':
        return 'Técnicas Culinarias';
      case 'preparation':
        return 'Preparación';
      default:
        return category;
    }
  }
}

class UserSkillProgress {
  final String skillId;
  final DateTime? completedAt;
  final int progress; // 0-100

  UserSkillProgress({
    required this.skillId,
    this.completedAt,
    required this.progress,
  });

  factory UserSkillProgress.fromJson(Map<String, dynamic> json) {
    return UserSkillProgress(
      skillId: json['skillId'] ?? '',
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      progress: json['progress'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillId': skillId,
      'completedAt': completedAt?.toIso8601String(),
      'progress': progress,
    };
  }

  bool get isCompleted => progress == 100;
}
