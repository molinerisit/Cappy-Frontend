class ProgressModel {
  final int xp;
  final int level;
  final int streak;
  final List<String> unlockedLessons;
  final List<String> completedLessons;

  const ProgressModel({
    required this.xp,
    required this.level,
    required this.streak,
    required this.unlockedLessons,
    required this.completedLessons,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      xp: (json["xp"] as num?)?.toInt() ?? 0,
      level: (json["level"] as num?)?.toInt() ?? 1,
      streak: (json["streak"] as num?)?.toInt() ?? 0,
      unlockedLessons: ((json["unlockedLessons"] as List?) ?? const [])
          .map((id) => id.toString())
          .toList(),
      completedLessons: ((json["completedLessons"] as List?) ?? const [])
          .map((id) => id.toString())
          .toList(),
    );
  }
}
