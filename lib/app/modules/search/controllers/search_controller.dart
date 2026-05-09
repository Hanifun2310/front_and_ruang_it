import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/models/article_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../explore/controllers/explore_controller.dart';
import '../../profile/controllers/profile_controller.dart';

class ArticleSearchController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final GetStorage _storage = GetStorage();
  
  var searchQuery = ''.obs;
  var articles = <ArticleModel>[].obs;
  var isLoading = false.obs;
  var searchHistory = <String>[].obs;
  
  final String _historyKey = 'search_history';

  @override
  void onInit() {
    super.onInit();
    loadSearchHistory();
    
    // Real-time search with debounce (500ms)
    debounce(searchQuery, (_) => fetchArticles(), time: const Duration(milliseconds: 500));
  }

  void loadSearchHistory() {
    List<dynamic>? history = _storage.read<List<dynamic>>(_historyKey);
    if (history != null) {
      searchHistory.value = history.cast<String>();
    }
  }

  void saveToHistory(String query) {
    if (query.isEmpty) return;
    
    // Remove if already exists to move it to the top
    searchHistory.remove(query);
    searchHistory.insert(0, query);
    
    // Limit to 10 items
    if (searchHistory.length > 10) {
      searchHistory.removeLast();
    }
    
    _storage.write(_historyKey, searchHistory.toList());
  }

  void removeFromHistory(String query) {
    searchHistory.remove(query);
    _storage.write(_historyKey, searchHistory.toList());
  }

  void clearAllHistory() {
    searchHistory.clear();
    _storage.remove(_historyKey);
  }

  Future<void> fetchArticles() async {
    if (searchQuery.value.isEmpty) {
      articles.clear();
      return;
    }

    isLoading.value = true;
    try {
      final fetched = await _apiProvider.getArticles(search: searchQuery.value);
      // FILTER: Jangan tampilkan artikel terblokir di Hasil Pencarian
      articles.value = fetched.where((a) => !a.isBlocked).toList();
      
      // If we got results and it's a "substantial" search, save it to history when user stops typing
      // Note: In real-world, you might want to save history only on "Enter" or specific triggers,
      // but user asked for real-time history below search.
      // For history to be useful, let's only save it if the search actually happened and had results (optional)
      if (fetched.isNotEmpty) {
        saveToHistory(searchQuery.value);
      }
    } catch (e) {
      print('Error searching articles: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  void selectHistory(String query) {
    searchQuery.value = query;
    // This will trigger the debounce fetchArticles
  }

  Future<void> toggleLike(int articleId) async {
    try {
      final index = articles.indexWhere((a) => a.id == articleId);
      if (index == -1) return;

      final article = articles[index];
      final isCurrentlyLiked = article.isLiked ?? false;
      
      // Optimistic update
      article.isLiked = !isCurrentlyLiked;
      article.likesCount = (article.likesCount ?? 0) + (isCurrentlyLiked ? -1 : 1);
      
      articles[index] = article;
      articles.refresh();
      
      await _apiProvider.toggleLike(articleId);

      // SYNC: Update other controllers
      _syncLikeState(articleId, !isCurrentlyLiked);
    } catch (e) {
      // Revert if error
      fetchArticles();
    }
  }

  void updateArticleLikeState(int articleId, bool isLiked) {
    final index = articles.indexWhere((a) => a.id == articleId);
    if (index != -1) {
      final article = articles[index];
      if (article.isLiked != isLiked) {
        article.isLiked = isLiked;
        article.likesCount = (article.likesCount ?? 0) + (isLiked ? 1 : -1);
        articles[index] = article;
        articles.refresh();
      }
    }
  }

  void _syncLikeState(int articleId, bool isLiked) {
    try {
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().updateArticleLikeState(articleId, isLiked);
      }
      if (Get.isRegistered<ExploreController>()) {
        Get.find<ExploreController>().updateArticleLikeState(articleId, isLiked);
      }
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().updateArticleLikeState(articleId, isLiked);
      }
    } catch (_) {}
  }
}
