class Bottle {
  final String id;
  final String content;
  final String moodEmoji;
  final int likesCount;
  final String createdAt;

  const Bottle({
    required this.id,
    required this.content,
    required this.moodEmoji,
    required this.likesCount,
    required this.createdAt,
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
}
