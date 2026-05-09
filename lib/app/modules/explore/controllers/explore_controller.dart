import 'package:get/get.dart';
import '../../../data/models/article_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../search/controllers/search_controller.dart';

class ExploreController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  var articles = <ArticleModel>[].obs;
  var categories = <CategoryModel>[].obs;
  var selectedCategory = Rxn<CategoryModel>();
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    fetchArticles();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await _apiProvider.getCategories();
      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'] ?? response.data;
        categories.value = data.map((e) => CategoryModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> fetchArticles() async {
    isLoading.value = true;
    try {
      final fetchedArticles = await _apiProvider.getArticles(
        category: selectedCategory.value?.id.toString(),
      );
      // FILTER: Jangan tampilkan artikel terblokir di Explore
      articles.value = fetchedArticles.where((a) => !a.isBlocked).toList();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat artikel');
    } finally {
      isLoading.value = false;
    }
  }

  void filterByCategory(CategoryModel? category) {
    if (selectedCategory.value?.id == category?.id) {
      selectedCategory.value = null;
    } else {
      selectedCategory.value = category;
    }
    fetchArticles();
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
      fetchArticles(); // Revert on error
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
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().updateArticleLikeState(articleId, isLiked);
      }
      if (Get.isRegistered<ArticleSearchController>()) {
        Get.find<ArticleSearchController>().updateArticleLikeState(articleId, isLiked);
      }
    } catch (_) {}
  }
}
