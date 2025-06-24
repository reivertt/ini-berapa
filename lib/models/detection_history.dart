class DetectionHistory {
  final int? id;
  final String label;
  final String imagePath;
  final DateTime timestamp;

  DetectionHistory({
    this.id,
    required this.label,
    required this.imagePath,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DetectionHistory.fromMap(Map<String, dynamic> map) {
    return DetectionHistory(
      id: map['id'],
      label: map['label'],
      imagePath: map['imagePath'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}