import 'article_model.dart';

class CommentModel {
  int? id;
  String? content;
  int? userId;
  int? articleId;
  String? createdAt;
  UserModel? user;

  CommentModel({this.id, this.content, this.userId, this.articleId, this.createdAt, this.user});

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      content: json['content'],
      userId: json['user_id'],
      articleId: json['article_id'],
      createdAt: json['created_at'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}