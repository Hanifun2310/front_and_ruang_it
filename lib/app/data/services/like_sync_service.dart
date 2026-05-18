import 'package:get/get.dart';
import '../models/article_model.dart';

class LikeSyncService {
  final RxMap<int, bool> likedStatus = <int, bool>{}.obs;

  void updateLikeStatus(int articleId, bool isLiked) {
    likedStatus[articleId] = isLiked;
  }

  bool? getLikeStatus(int articleId) {
    return likedStatus[articleId];
  }

  ArticleModel applyLikeStateToArticle(ArticleModel article) {
    if (article.id == null) return article;

    final cachedStatus = likedStatus[article.id!];

    if (cachedStatus == null) {
      // Tidak ada cache lokal (misal setelah restart app).
      // Percaya data dari API sepenuhnya dan seed cache dari sana
      // agar in-session toggle berikutnya berjalan benar.
      if (article.isLiked != null) {
        likedStatus[article.id!] = article.isLiked!;
      }
      return article;
    }

    // Ada cache lokal (pengguna sudah toggle dalam sesi ini).
    // Cache lokal lebih akurat dari API karena sudah optimistic update.
    if (article.isLiked != cachedStatus) {
      // Hanya sesuaikan count jika status berbeda dengan yang ada di API.
      article.likesCount = (article.likesCount ?? 0) + (cachedStatus ? 1 : -1);
      article.isLiked = cachedStatus;
    }
    return article;
  }

  List<ArticleModel> applyLikeStateToArticles(List<ArticleModel> articles) {
    return articles.map(applyLikeStateToArticle).toList();
  }
}
