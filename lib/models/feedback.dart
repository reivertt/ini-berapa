class Feedback {
  final int? id;
  final DateTime timestamp;
  final String detectedValue;
  final bool isCorrect;
  final String? actualValue;
  final String? imagePath;
  final double? confidenceScore;

  Feedback({
    this.id,
    required this.timestamp,
    required this.detectedValue,
    required this.isCorrect,
    this.actualValue,
    this.imagePath,
    this.confidenceScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'detected_value': detectedValue,
      'is_correct': isCorrect ? 1 : 0,
      'actual_value': actualValue,
      'image_path': imagePath,
      'confidence_score': confidenceScore,
    };
  }

  factory Feedback.fromMap(Map<String, dynamic> map) {
    return Feedback(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      detectedValue: map['detected_value'],
      isCorrect: map['is_correct'] == 1,
      actualValue: map['actual_value'],
      imagePath: map['image_path'],
      confidenceScore: map['confidence_score'],
    );
  }
}