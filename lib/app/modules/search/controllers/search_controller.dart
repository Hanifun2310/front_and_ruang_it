import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/models/article_model.dart';
import '../../../data/providers/api_provider.dart';

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
      articles.value = fetched;
      
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
}
