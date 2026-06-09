import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/models/article_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/like_sync_service.dart';
import '../../../data/services/notification_service.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../search/controllers/search_controller.dart';
import '../../../widgets/custom_snackbar.dart';

class ExploreController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final LikeSyncService _likeSyncService = Get.find<LikeSyncService>();
  final GetStorage _storage = GetStorage();

  static const String _categoriesCacheKey = 'cached_categories';
  static const String _articlesCacheKey = 'cached_articles';

  var articles = <ArticleModel>[].obs;
  var categories = <CategoryModel>[].obs;
  var selectedCategory = Rxn<CategoryModel>();
  var isLoading = false.obs;
  var isCategoriesLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCachedData();
    fetchCategories();
    fetchArticles();
  }

  void _loadCachedData() {
    try {
      final cachedCats = _storage.read<List<dynamic>>(_categoriesCacheKey);
      if (cachedCats != null) {
        categories.value = cachedCats.map((e) => CategoryModel.fromJson(e)).toList();
      }
      final cachedArts = _storage.read<List<dynamic>>(_articlesCacheKey);
      if (cachedArts != null) {
        articles.value = cachedArts.map((e) => ArticleModel.fromJson(e)).toList();
      }
    } catch (e) {
      Get.log('Error loading cached explore data: $e');
    }
  }

  Future<void> fetchCategories() async {
    if (categories.isEmpty) {
      isCategoriesLoading.value = true;
    }
    try {
      final response = await _apiProvider.getCategories();
      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'] ?? response.data;
        categories.value = data.map((e) => CategoryModel.fromJson(e)).toList();
        _storage.write(_categoriesCacheKey, data);
      }
    } catch (e) {
      Get.log('Error fetching categories: $e');
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  Future<void> fetchArticles() async {
    if (articles.isEmpty) {
      isLoading.value = true;
    }
    try {
      final fetchedArticles = await _apiProvider.getArticles(
        category: selectedCategory.value?.id.toString(),
      );
      
      Get.find<NotificationService>().syncArticleMetrics(fetchedArticles);

      final filtered = fetchedArticles.where((a) => !a.isBlocked).toList();
      final finalArticles = _likeSyncService.applyLikeStateToArticles(filtered);
      articles.value = finalArticles;

      if (selectedCategory.value == null) {
        final rawJson = fetchedArticles.map((e) => e.toJson()).toList();
        _storage.write(_articlesCacheKey, rawJson);
      }
    } catch (e) {
      showCustomSnackbar('Error', 'Gagal memuat artikel');
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
    articles.clear();
    fetchArticles();
  }

  Future<void> toggleLike(int articleId) async {
    final authService = Get.find<AuthService>();
    if (!authService.isLoggedIn.value) {
      showCustomSnackbar('Akses Ditolak', 'Anda harus login untuk menyukai artikel.', backgroundColor: Colors.redAccent, colorText: Colors.white);
      Get.toNamed(Routes.LOGIN);
      return;
    }

    try {
      final index = articles.indexWhere((a) => a.id == articleId);
      if (index == -1) return;

      final article = articles[index];
      final isCurrentlyLiked = article.isLiked ?? false;

      article.isLiked = !isCurrentlyLiked;
      article.likesCount =
          (article.likesCount ?? 0) + (isCurrentlyLiked ? -1 : 1);

      articles[index] = article;
      articles.refresh();

      await _apiProvider.toggleLike(articleId);
      _likeSyncService.updateLikeStatus(articleId, !isCurrentlyLiked);

      _syncLikeState(articleId, !isCurrentlyLiked);
    } catch (e) {
      fetchArticles();
    }
  }

  void updateArticleLikeState(int articleId, bool isLiked) {
    final index = articles.indexWhere((a) => a.id == articleId);
    if (index != -1) {
      final article = articles[index];
      final bool currentIsLiked = article.isLiked ?? false;
      if (currentIsLiked != isLiked) {
        article.isLiked = isLiked;
        article.likesCount = (article.likesCount ?? 0) + (isLiked ? 1 : -1);
        articles[index] = article;
        articles.refresh();
      }
    }

    _likeSyncService.updateLikeStatus(articleId, isLiked);
  }

  void updateArticleMetrics(int articleId, int viewsCount, int commentsCount) {
    final index = articles.indexWhere((a) => a.id == articleId);
    if (index != -1) {
      final article = articles[index];
      article.viewsCount = viewsCount;
      article.commentsCount = commentsCount;
      articles[index] = article;
      articles.refresh();
    }
  }

  void _syncLikeState(int articleId, bool isLiked) {
    try {
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().updateArticleLikeState(
          articleId,
          isLiked,
        );
      }
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().updateArticleLikeState(
          articleId,
          isLiked,
        );
      }
      if (Get.isRegistered<ArticleSearchController>()) {
        Get.find<ArticleSearchController>().updateArticleLikeState(
          articleId,
          isLiked,
        );
      }
    } catch (_) {}
  }
}
