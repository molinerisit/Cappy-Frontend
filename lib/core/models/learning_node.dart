class NodeStep {
  final String title;
  final String? description;
  final String instruction;
  final String type; // text, image, video, quiz, interactive, checklist
  final String? image;
  final String? video;
  final String? animationUrl;
  final String? question;
  final List<String>? options;
  final String? correctAnswer;
  final List<Map<String, dynamic>>? checklist;
  final Map<String, dynamic>? validationLogic;
  final String? feedback;
  final int duration;
  final List<String>? tips;
  final String? media;
  final List<Map<String, dynamic>>? cards;

  NodeStep({
    required this.title,
    this.description,
    required this.instruction,
    required this.type,
    this.image,
    this.video,
    this.animationUrl,
    this.question,
    this.options,
    this.correctAnswer,
    this.checklist,
    this.validationLogic,
    this.feedback,
    required this.duration,
    this.tips,
    this.media,
    this.cards,
  });

  factory NodeStep.fromJson(Map<String, dynamic> json) {
    String _firstNonEmpty(List<dynamic> values, String fallback) {
      for (final value in values) {
        if (value == null) {
          continue;
        }
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
      return fallback;
    }

    List<String>? _parseOptions() {
      final rawOptions = json['options'] is List
          ? List<dynamic>.from(json['options'])
          : (json['answers'] is List
                ? List<dynamic>.from(json['answers'])
                : null);
      if (rawOptions == null) {
        return null;
      }

      return rawOptions
          .map((option) {
            if (option is Map) {
              return _firstNonEmpty([
                option['text'],
                option['label'],
                option['value'],
                option['title'],
              ], '');
            }
            return option?.toString() ?? '';
          })
          .map((option) => option.trim())
          .where((option) => option.isNotEmpty)
          .toList();
    }

    final cards = json['cards'] != null
        ? List<Map<String, dynamic>>.from(json['cards'])
        : null;
    final description = json['description']?.toString();
    String instruction = _firstNonEmpty([
      json['instruction'],
      json['content'],
      json['text'],
      description,
    ], '');
    String? question = json['question'] ?? json['prompt'] ?? json['statement'];
    List<String>? options = _parseOptions();
    String? correctAnswer = json['correctAnswer']?.toString();

    if (cards != null && cards.isNotEmpty) {
      for (final card in cards) {
        final cardType = card['type']?.toString();
        final content = card['content'] as Map? ?? {};

        if (instruction.isEmpty) {
          instruction = _firstNonEmpty([
            content['text'],
            content['description'],
            content['instruction'],
            content['title'],
          ], instruction);
        }

        if ((question == null || question.toString().trim().isEmpty) &&
            cardType == 'quiz') {
          question = content['question']?.toString();
        }

        if ((options == null || options.isEmpty) && cardType == 'quiz') {
          if (content['options'] is List) {
            options = (content['options'] as List)
                .map((option) {
                  if (option is Map) {
                    return _firstNonEmpty([
                      option['text'],
                      option['label'],
                      option['value'],
                      option['title'],
                    ], '');
                  }
                  return option?.toString() ?? '';
                })
                .map((option) => option.trim())
                .where((option) => option.isNotEmpty)
                .toList();
          }
        }

        if ((correctAnswer == null || correctAnswer!.trim().isEmpty) &&
            cardType == 'quiz' &&
            content['options'] is List) {
          for (final option in content['options'] as List) {
            if (option is Map && option['correct'] == true) {
              correctAnswer = _firstNonEmpty([
                option['text'],
                option['label'],
                option['value'],
                option['title'],
              ], '');
              break;
            }
          }
        }
      }
    }

    return NodeStep(
      title: json['title'] ?? json['name'] ?? '',
      description: description,
      instruction: instruction,
      type: json['type'] ?? 'text',
      image: json['image'],
      video: json['video'],
      animationUrl: json['animationUrl'],
      question: question?.toString(),
      options: options,
      correctAnswer: correctAnswer,
      checklist: json['checklist'] != null
          ? List<Map<String, dynamic>>.from(json['checklist'])
          : null,
      validationLogic: json['validationLogic'],
      feedback: json['feedback'],
      duration: json['duration'] ?? 0,
      tips: (json['tips'] as List?)
          ?.map((item) => item?.toString() ?? '')
          .toList(),
      media: json['media'],
      cards: cards,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'instruction': instruction,
      'type': type,
      'image': image,
      'video': video,
      'animationUrl': animationUrl,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'checklist': checklist,
      'validationLogic': validationLogic,
      'feedback': feedback,
      'duration': duration,
      'tips': tips,
      'media': media,
      'cards': cards,
    };
  }
}

class NodeIngredient {
  final String name;
  final double quantity;
  final String unit;
  final bool optional;

  NodeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.optional,
  });

  factory NodeIngredient.fromJson(Map<String, dynamic> json) {
    return NodeIngredient(
      name: json['name'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'unit',
      optional: json['optional'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'optional': optional,
    };
  }
}

class LearningNode {
  final String id;
  final String countryId;
  final String title;
  final String description;
  final String type; // recipe, skill, quiz
  final String difficulty; // easy, medium, hard
  final int xpReward;
  final int order;
  final List<String> requiredNodes;
  final int level;
  final String category;
  final List<NodeStep> steps;
  final int? servings;
  final int? prepTime;
  final int? cookTime;
  final List<NodeIngredient>? ingredients;
  final List<Map<String, dynamic>>? tools;
  final Map<String, dynamic>? nutrition;
  final List<String>? tips;
  final List<String>? tags;
  final bool isPremium;
  final String? media;
  final List<String>? unlocksNodes;
  final DateTime createdAt;

  // Status (determined by user progress)
  String? status; // completed, available, locked
  String? position; // left, right (for alternating layout)

  LearningNode({
    required this.id,
    required this.countryId,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.xpReward,
    required this.order,
    required this.requiredNodes,
    required this.level,
    required this.category,
    required this.steps,
    this.servings,
    this.prepTime,
    this.cookTime,
    this.ingredients,
    this.tools,
    this.nutrition,
    this.tips,
    this.tags,
    required this.isPremium,
    this.media,
    this.unlocksNodes,
    required this.createdAt,
    this.status,
    this.position,
  });

  factory LearningNode.fromJson(Map<String, dynamic> json) {
    return LearningNode(
      id: json['_id']?.toString() ?? '',
      countryId: json['countryId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? 'skill',
      difficulty: json['difficulty']?.toString() ?? 'medium',
      xpReward: json['xpReward'] ?? 50,
      order: json['order'] ?? 0,
      requiredNodes:
          (json['requiredNodes'] as List?)
              ?.map((item) => item?.toString() ?? '')
              .toList() ??
          [],
      level: json['level'] ?? 1,
      category: json['category']?.toString() ?? 'technique',
      steps:
          (json['steps'] as List?)
              ?.map((item) => NodeStep.fromJson(item))
              .toList() ??
          [],
      servings: json['servings'],
      prepTime: json['prepTime'],
      cookTime: json['cookTime'],
      ingredients: (json['ingredients'] as List?)
          ?.map((item) => NodeIngredient.fromJson(item))
          .toList(),
      tools: json['tools'] != null
          ? List<Map<String, dynamic>>.from(json['tools'])
          : null,
      nutrition: json['nutrition'],
      tips: (json['tips'] as List?)
          ?.map((item) => item?.toString() ?? '')
          .toList(),
      tags: (json['tags'] as List?)
          ?.map((item) => item?.toString() ?? '')
          .toList(),
      isPremium: json['isPremium'] ?? false,
      media: json['media'],
      unlocksNodes: (json['unlocksNodes'] as List?)
          ?.map((item) => item?.toString() ?? '')
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      status: json['status']?.toString(),
      position: json['position']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'countryId': countryId,
      'title': title,
      'description': description,
      'type': type,
      'difficulty': difficulty,
      'xpReward': xpReward,
      'order': order,
      'requiredNodes': requiredNodes,
      'level': level,
      'category': category,
      'steps': steps.map((s) => s.toJson()).toList(),
      'servings': servings,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'ingredients': ingredients?.map((i) => i.toJson()).toList(),
      'tools': tools,
      'nutrition': nutrition,
      'tips': tips,
      'tags': tags,
      'isPremium': isPremium,
      'media': media,
      'unlocksNodes': unlocksNodes,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'position': position,
    };
  }

  String get typeLabel {
    switch (type) {
      case 'recipe':
        return '🍳 Receta';
      case 'skill':
        return '🎯 Habilidad';
      case 'quiz':
        return '📝 Quiz';
      default:
        return type;
    }
  }

  String get difficultyLabel {
    switch (difficulty) {
      case 'easy':
        return 'Fácil';
      case 'medium':
        return 'Medio';
      case 'hard':
        return 'Difícil';
      default:
        return difficulty;
    }
  }

  bool get isCompleted => status == 'completed';
  bool get isAvailable => status == 'available';
  bool get isLocked => status == 'locked';

  int get totalDuration => steps.fold(0, (sum, step) => sum + step.duration);
}

class CompletedNode {
  final String nodeId;
  final DateTime completedAt;
  final int score;
  final int attempts;

  CompletedNode({
    required this.nodeId,
    required this.completedAt,
    required this.score,
    required this.attempts,
  });

  factory CompletedNode.fromJson(Map<String, dynamic> json) {
    return CompletedNode(
      nodeId: json['nodeId'] ?? '',
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : DateTime.now(),
      score: json['score'] ?? 0,
      attempts: json['attempts'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nodeId': nodeId,
      'completedAt': completedAt.toIso8601String(),
      'score': score,
      'attempts': attempts,
    };
  }
}
