import 'content.dart';

class DiaryEntry implements Content {
  @override
  final String id;
  @override
  final String title;
  final String content;
  final String? moodTag;
  @override
  final DateTime createdAt;
  final int userId;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    this.moodTag,
    required this.createdAt,
    required this.userId,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      moodTag: json['mood_tag'],
      createdAt: DateTime.parse(json['created_at']),
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'mood_tag': moodTag,
      // 'created_at': createdAt.toIso8601String(), // Supabase auto handles created_at
    };
  }
}
