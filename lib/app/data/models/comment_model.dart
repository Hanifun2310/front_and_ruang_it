import 'article_model.dart';

class CommentModel {
  int? id;
  String? content;
  int? userId;
  int? articleId;
  String? createdAt;
  UserModel? user;
  bool? isHidden;

  CommentModel({
    this.id,
    this.content,
    this.userId,
    this.articleId,
    this.createdAt,
    this.user,
    this.isHidden,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      content: json['content'],
      userId: json['user_id'],
      articleId: json['article_id'],
      createdAt: json['created_at'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      isHidden: json['is_hidden'] == true ||
          json['is_hidden'] == 1 ||
          json['status'] == 'hidden' ||
          json['status'] == 'inactive',
    );
  }
}