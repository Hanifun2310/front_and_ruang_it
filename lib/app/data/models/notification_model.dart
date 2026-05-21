class NotificationItem {
  final int id;
  final int articleId;
  final String articleTitle;
  final String message;
  final String type;
  final DateTime createdAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.articleId,
    required this.articleTitle,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      articleId: json['article_id'] as int,
      articleTitle: json['article_title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'article_id': articleId,
      'article_title': articleTitle,
      'message': message,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}
