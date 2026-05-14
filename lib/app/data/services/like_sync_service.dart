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
    if (cachedStatus == null) return article;

    if (article.isLiked != cachedStatus) {
      article.likesCount = (article.likesCount ?? 0) + (cachedStatus ? 1 : -1);
      article.isLiked = cachedStatus;
    }
    return article;
  }

  List<ArticleModel> applyLikeStateToArticles(List<ArticleModel> articles) {
    return articles.map(applyLikeStateToArticle).toList();
  }
}
