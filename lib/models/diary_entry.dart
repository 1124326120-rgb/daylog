class DiaryEntry {
  final int? id;
  final String date;
  final String content;
  final String moodEmoji;
  final String? imagePath;
  final int isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiaryEntry({
    this.id,
    required this.date,
    required this.content,
    required this.moodEmoji,
    this.imagePath,
    this.isFavorite = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'content': content,
      'mood_emoji': moodEmoji,
      'image_path': imagePath,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      content: map['content'] as String,
      moodEmoji: map['mood_emoji'] as String,
      imagePath: map['image_path'] as String?,
      isFavorite: (map['is_favorite'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  DiaryEntry copyWith({
    int? id,
    String? date,
    String? content,
    String? moodEmoji,
    String? imagePath,
    int? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      imagePath: imagePath ?? this.imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
