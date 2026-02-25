class CultureStep {
  final String id;
  final String cultureNodeId;
  final String type;
  final String content;

  CultureStep({
    required this.id,
    required this.cultureNodeId,
    required this.type,
    required this.content,
  });

  factory CultureStep.fromJson(Map<String, dynamic> json) {
    return CultureStep(
      id: json['id'],
      cultureNodeId: json['cultureNodeId'],
      type: json['type'],
      content: json['content'],
    );
  }
}
