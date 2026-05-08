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

  String get snippet {
    if (content == null || content!.isEmpty) return "";
    // Simple HTML strip
    String plainText = content!.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
    plainText = plainText.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (plainText.length <= 100) return plainText;
    return '${plainText.substring(0, 100)}...';
  }

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

  static String formatImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://via.placeholder.com/600x400';
    }
    if (path.startsWith('http')) return path;

    // Remove leading slash if exists
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;

    // Avoid double 'storage/' if the backend already provides it
    if (cleanPath.startsWith('storage/')) {
      return 'https://ruang-it.vibedev.my.id/$cleanPath';
    }

    return 'https://ruang-it.vibedev.my.id/storage/$cleanPath';
  }

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      content: json['content'],
      imageUrl: formatImageUrl(json['image_url'] ?? json['image']),
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : null,
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
  String? profession;
  String? bio;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.role,
    this.photoProfile,
    this.profession,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    name: json['name'] ?? 'User',
    email: json['email'],
    role: json['role'],
    photoProfile: ArticleModel.formatImageUrl(
      json['photo_profile'] ?? json['profile_photo'],
    ),
    profession: json['profession'],
    bio: json['bio'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'photo_profile': photoProfile,
    'profession': profession,
    'bio': bio,
  };
}

class CategoryModel {
  int? id;
  String? name;
  CategoryModel({this.id, this.name});
  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      CategoryModel(id: json['id'], name: json['name']);
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
