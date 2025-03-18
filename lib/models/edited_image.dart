class EditedImage {
  final String id;
  final String title;
  final String prompt;
  final String localPath; // This will now store a relative path
  final String? originalImagePath;
  final DateTime timestamp;

  const EditedImage({
    required this.id,
    required this.title,
    required this.prompt,
    required this.localPath,
    this.originalImagePath,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'prompt': prompt,
      'localPath': localPath,
      'originalImagePath': originalImagePath,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory EditedImage.fromJson(Map<String, dynamic> json) {
    return EditedImage(
      id: json['id'] as String,
      title: json['title'] as String,
      prompt: json['prompt'] as String,
      localPath: json['localPath'] as String,
      originalImagePath: json['originalImagePath'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'EditedImage{id: $id, title: $title, prompt: $prompt}';
  }
}
