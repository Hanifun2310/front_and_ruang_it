import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/article_model.dart';

class LikeSyncService {
  final RxMap<int, bool> likedStatus = <int, bool>{}.obs;
  final _box = GetStorage();
  static const _storageKey = 'liked_article_ids';

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
          if (id != null && liked != null) {
            likedStatus[id] = liked;
          }
        }
      }
    }
  }

  void _saveToStorage() {
    final List<Map<String, dynamic>> data = likedStatus.entries
        .map((e) => {'id': e.key, 'liked': e.value})
        .toList();
    _box.write(_storageKey, data);
  }

  // ─── Public API ──────────────────────────────────────────────────────────────

  void updateLikeStatus(int articleId, bool isLiked) {
    likedStatus[articleId] = isLiked;
    _saveToStorage();
  }

  bool? getLikeStatus(int articleId) {
    return likedStatus[articleId];
  }

  /// Terapkan state like lokal ke artikel.
  ///
  /// Prioritas:
  /// 1. Cache lokal (dari toggle user dalam sesi ini / sesi sebelumnya)
  /// 2. Data dari API (jika tidak ada cache sama sekali — biasanya tidak terjadi)
  ArticleModel applyLikeStateToArticle(ArticleModel article) {
    if (article.id == null) return article;

    final cachedStatus = likedStatus[article.id!];

    if (cachedStatus == null) {
      // Belum ada di cache lokal sama sekali (artikel baru dilihat pertama kali).
      // Gunakan data dari API dan seed ke cache.
      if (article.isLiked != null) {
        likedStatus[article.id!] = article.isLiked!;
        _saveToStorage();
      }
      return article;
    }

    // Ada cache lokal → pakai cache, override nilai dari API.
    if (article.isLiked != cachedStatus) {
      article.likesCount = (article.likesCount ?? 0) + (cachedStatus ? 1 : -1);
      article.isLiked = cachedStatus;
    }
    return article;
  }

  List<ArticleModel> applyLikeStateToArticles(List<ArticleModel> articles) {
    return articles.map(applyLikeStateToArticle).toList();
  }

  /// Hapus semua data like (dipanggil saat logout)
  void clearAll() {
    likedStatus.clear();
    _box.remove(_storageKey);
  }
}
