class Bottle {
  final String id;
  final String content;
  final String moodEmoji;
  final int likesCount;
  final String createdAt;
  final bool isLiked;

  const Bottle({
    required this.id,
    required this.content,
    required this.moodEmoji,
    required this.likesCount,
    required this.createdAt,
    this.isLiked = false,
  });

  factory Bottle.fromJson(Map<String, dynamic> json) => Bottle(
        id: json['objectId'] ?? '',
        content: json['content'] ?? '',
        moodEmoji: json['moodEmoji'] ?? '',
        likesCount: json['likesCount'] ?? 0,
        createdAt: json['createdAt'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'content': content,
        'moodEmoji': moodEmoji,
        'likesCount': likesCount,
      };

  Bottle copyWith({
    String? id,
    String? content,
    String? moodEmoji,
    int? likesCount,
    String? createdAt,
    bool? isLiked,
  }) {
    return Bottle(
      id: id ?? this.id,
      content: content ?? this.content,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      likesCount: likesCount ?? this.likesCount,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

