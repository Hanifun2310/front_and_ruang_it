import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/article_model.dart';

// 1. Buat model event sederhana untuk membawa data perubahan
class LikeEvent {
  final int articleId;
  final bool isLiked;
  LikeEvent({required this.articleId, required this.isLiked});
}

class LikeSyncService extends GetxService {
  final RxSet<int> likedArticleIds = <int>{}.obs;
  final _box = GetStorage();
  static const _storageKey = 'liked_article_ids';

  final rxLikeEvent = Rxn<LikeEvent>();

  @override
  void onInit() {
    super.onInit();
    _loadFromStorage();
  }

  LikeSyncService() {
    _loadFromStorage();
  }

  // ─── Persistence ────────────────────────────────────────────────────────────

  void _loadFromStorage() {
    final List<dynamic>? stored = _box.read<List<dynamic>>(_storageKey);
    if (stored != null) {
      for (final item in stored) {
        if (item is Map) {
          final id = item['id'] as int?;
          final liked = item['liked'] as bool?;
          if (id != null && liked == true) {
            likedArticleIds.add(id);
          }
        }
      }
    }
  }

  void _saveToStorage() {
    final List<Map<String, dynamic>> data = likedArticleIds
        .map((id) => {'id': id, 'liked': true})
        .toList();
    _box.write(_storageKey, data);
  }

  // ─── Public API ──────────────────────────────────────────────────────────────

  void updateLikeStatus(int articleId, bool isLiked) {
    if (isLiked) {
      likedArticleIds.add(articleId);
    } else {
      likedArticleIds.remove(articleId);
    }
    _saveToStorage();

    rxLikeEvent.value = LikeEvent(articleId: articleId, isLiked: isLiked);
  }

  bool? getLikeStatus(int articleId) {
    return likedArticleIds.contains(articleId) ? true : null;
  }

  /// Terapkan state like lokal ke artikel.
  ///
  /// Prioritas:
  /// 1. Cache lokal (hanya like yang sudah pasti diubah oleh user)
  /// 2. Data dari API
  ArticleModel applyLikeStateToArticle(ArticleModel article) {
    if (article.id == null) return article;

    final locallyLiked = likedArticleIds.contains(article.id!);

    if (!locallyLiked) {
      if (article.isLiked == true) {
        likedArticleIds.add(article.id!);
        _saveToStorage();
      }
      return article;
    }

    // Jika cache lokal menunjukkan artikel sudah liked, gunakan status tersebut,
    // tetapi jangan override API false dengan nilai negative yang tersimpan.
    if (article.isLiked != true) {
      article.likesCount = (article.likesCount ?? 0) + 1;
      article.isLiked = true;
    }
    return article;
  }

  List<ArticleModel> applyLikeStateToArticles(List<ArticleModel> articles) {
    return articles.map(applyLikeStateToArticle).toList();
  }

  /// Hapus semua data like (dipanggil saat logout)
  void clearAll() {
    likedArticleIds.clear();
    rxLikeEvent.value = null;
    _box.remove(_storageKey);
  }
}
