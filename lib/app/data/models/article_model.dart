import 'package:get_storage/get_storage.dart';

class ArticleModel {
  int? id;
  String? title;
  String? slug;
  String? content;
  String? imageUrl;
  int? viewsCount;
  int? likesCount;
  int? commentsCount;
  bool? isLiked;
  DateTime? createdAt;
  String? status;

  bool get isBlocked {
    // Robust check for banned status (support both 'banned' and 'blocked')
    final String? articleStatus = status?.toLowerCase();
    final String? userStatus = user?.status?.toLowerCase();
    
    final bool articleIsBanned = articleStatus == 'banned' || articleStatus == 'blocked';
    final bool userIsBanned = userStatus == 'banned' || userStatus == 'blocked' || user?.isBanned == true;
    
    return articleIsBanned || userIsBanned;
  }

  String get formattedDate {
    if (createdAt == null) return '';
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${createdAt!.day} ${months[createdAt!.month - 1]} ${createdAt!.year}';
  }

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
    this.viewsCount,
    this.likesCount,
    this.commentsCount,
    this.isLiked,
    this.createdAt,
    this.status,
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
    final articleId = json['id'];
    int localViews = json['views_count'] ?? json['view_count'] ?? json['views'] ?? 0;
    try {
      final box = GetStorage();
      final key = 'article_views_$articleId';
      if (box.hasData(key)) {
        localViews = box.read<int>(key) ?? localViews;
      }
    } catch (_) {}

    return ArticleModel(
      id: articleId,
      title: json['title'],
      slug: json['slug'],
      content: json['content'],
      imageUrl: formatImageUrl(json['image_url'] ?? json['image']),
      viewsCount: localViews,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] == true || 
               json['is_liked'] == 1 || 
               json['is_liked'] == '1' || 
               json['liked'] == true || 
               json['liked'] == 1 ||
               json['isLiked'] == true ||
               json['isLiked'] == 1,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      status: json['status']?.toString().toLowerCase(),
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
      'views_count': viewsCount,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked': isLiked,
      'status': status,
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
  String? status;
  String? photoProfile;
  String? profession;
  String? bio;
  int? articlesCount;
  int? likesCount;
  int? commentsCount;

  bool get isBanned {
    final s = status?.toLowerCase();
    return s == 'banned' || s == 'blocked' || s == 'suspended';
  }

  UserModel({
    this.id,
    this.name,
    this.email,
    this.role,
    this.status,
    this.photoProfile,
    this.profession,
    this.bio,
    this.articlesCount,
    this.likesCount,
    this.commentsCount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    name: json['name'] ?? 'User',
    email: json['email'],
    role: json['role'],
    status: json['status']?.toString().toLowerCase(),
    photoProfile: (json['photo_profile'] == null && json['profile_photo'] == null)
      ? ''
      : ArticleModel.formatImageUrl(
          json['photo_profile'] ?? json['profile_photo'],
        ),
    profession: json['profession'],
    bio: json['bio'],
    articlesCount: json['articles_count'] ?? json['posts_count'] ?? json['articles'] ?? 0,
    likesCount: json['likes_count'] ?? json['total_likes'] ?? json['likes'] ?? 0,
    commentsCount: json['comments_count'] ?? json['total_comments'] ?? json['comments'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'status': status,
    'photo_profile': photoProfile,
    'profession': profession,
    'bio': bio,
    'articles_count': articlesCount,
    'likes_count': likesCount,
    'comments_count': commentsCount,
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
