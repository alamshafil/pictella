import 'package:uuid/uuid.dart';

class SavedStyle {
  final String id;
  final String name;
  final String styleJson;
  final DateTime timestamp;

  SavedStyle({
    required this.id,
    required this.name,
    required this.styleJson,
    required this.timestamp,
  });

  // Factory constructor for creating a new style with a generated ID
  factory SavedStyle.create({required String name, required String styleJson}) {
    return SavedStyle(
      id: const Uuid().v4(),
      name: name,
      styleJson: styleJson,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'styleJson': styleJson,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SavedStyle.fromJson(Map<String, dynamic> json) {
    return SavedStyle(
      id: json['id'] as String,
      name: json['name'] as String,
      styleJson: json['styleJson'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'SavedStyle{id: $id, name: $name}';
  }
}
