class ArticleModel {
  int? id;
  String? title;
  String? slug;
  String? content;
  String? imageUrl;
  int? likesCount;
  int? commentsCount;
  bool? isLiked;
  // Relasi
  UserModel? user;
  CategoryModel? category;

  ArticleModel({
    this.id,
    this.title,
    this.slug,
    this.content,
    this.imageUrl,
    this.likesCount,
    this.commentsCount,
    this.isLiked,
    this.user,
    this.category,
  });

factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      content: json['content'],
      // Kita tambahkan pencarian ganda: cek 'image_url' dulu, kalau null cek 'image'
      imageUrl: json['image_url'] ?? json['image'], 
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      category: json['category'] != null ? CategoryModel.fromJson(json['category']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'content': content,
      'image_url': imageUrl,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked': isLiked,
      'user': user?.toJson(),
      'category': category?.toJson(),
    };
  }
}

// --- Dummy Model User & Category agar tidak error ---
// Nanti pisahkan ke file user_model.dart dan category_model.dart
class UserModel {
  int? id;
  String? name;
  String? email;
  String? role;
  String? photoProfile;

  UserModel({this.id, this.name, this.email, this.role, this.photoProfile});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        name: json['name']?? 'User',
        email: json['email'],
        role: json['role'],
        photoProfile: json['photo_profile']?? json['profile_photo'],
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'role': role, 'photo_profile': photoProfile};
}

class CategoryModel {
  int? id;
  String? name;
  CategoryModel({this.id, this.name});
  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(id: json['id'], name: json['name']);
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}