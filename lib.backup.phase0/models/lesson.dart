class Lesson {
  final String id;
  final String title;
  final String description;
  final String language;
  final String difficulty;
  final int order;
  final int xpReward;
  final List<dynamic> ingredients;
  final List<String> steps;
  final Map<String, dynamic>? nutrition;
  final List<String> tips;
  final List<Exercise>? exercises;
  final bool isPremium;
  final bool locked;
  final bool completed;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.language,
    required this.difficulty,
    required this.order,
    required this.xpReward,
    required this.ingredients,
    required this.steps,
    required this.nutrition,
    required this.tips,
    required this.exercises,
    required this.isPremium,
    required this.locked,
    required this.completed,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final status = json["status"]?.toString() ?? "locked";
    final rawSteps = (json["steps"] as List?) ?? const [];
    final steps = rawSteps
        .map((step) {
          if (step is String) {
            return step;
          }

          if (step is Map) {
            final instruction = step["instruction"]?.toString();
            final content = step["content"]?.toString();
            final text = step["text"]?.toString();
            final description = step["description"]?.toString();
            final title = step["title"]?.toString();

            for (final value in [
              instruction,
              content,
              text,
              description,
              title,
            ]) {
              if (value != null && value.trim().isNotEmpty) {
                return value;
              }
            }
          }

          return step.toString();
        })
        .where((value) => value.trim().isNotEmpty)
        .toList();

    return Lesson(
      id: json["id"]?.toString() ?? json["_id"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      language: json["language"]?.toString() ?? "English",
      difficulty: json["difficulty"]?.toString() ?? "medium",
      order: (json["order"] as num?)?.toInt() ?? 0,
      xpReward: (json["xpReward"] as num?)?.toInt() ?? 0,
      ingredients: (json["ingredients"] as List?) ?? const [],
      steps: steps,
      nutrition: json["nutrition"] as Map<String, dynamic>?,
      tips: ((json["tips"] as List?) ?? const [])
          .map((tip) => tip.toString())
          .toList(),
      exercises: ((json["exercises"] as List?) ?? const [])
          .map((ex) => Exercise.fromJson(ex as Map<String, dynamic>))
          .toList(),
      isPremium: json["isPremium"] == true,
      locked: status == "locked",
      completed: status == "completed",
    );
  }
}

class Exercise {
  String id;
  String question;
  String type; // 'multiple_choice' | 'translation'
  String correctAnswer;
  List<String>? options;
  String? hint;
  String? explanation;

  Exercise({
    required this.id,
    required this.question,
    required this.type,
    required this.correctAnswer,
    this.options,
    this.hint,
    this.explanation,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json["id"]?.toString() ?? "",
      question: json["question"]?.toString() ?? "",
      type: json["type"]?.toString() ?? "multiple_choice",
      correctAnswer: json["correctAnswer"]?.toString() ?? "",
      options: json["options"] != null
          ? List<String>.from(json["options"] as List)
          : null,
      hint: json["hint"]?.toString(),
      explanation: json["explanation"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'type': type,
      'correctAnswer': correctAnswer,
      'options': options,
      'hint': hint,
      'explanation': explanation,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }
}
