import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../data/models/article_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/like_sync_service.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../explore/controllers/explore_controller.dart';
import '../../search/controllers/search_controller.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../widgets/custom_snackbar.dart';

class DashboardController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  var articles = <ArticleModel>[].obs;
  var categories = <CategoryModel>[].obs;
  var selectedCategory = Rxn<CategoryModel>();
  var searchQuery = ''.obs;

  var isLoading = false.obs;
  var isFetchingMore = false.obs;
  var currentPage = 1;
  var hasMoreData = true.obs;
  var activeTab = 0.obs;
  var isLiking = false.obs;
  final LikeSyncService _likeSyncService = Get.find<LikeSyncService>();

  void switchTab(int index) {
    activeTab.value = index;
  }

  List<ArticleModel> get trendingArticles {
    var sorted = List<ArticleModel>.from(articles);
    sorted.sort((a, b) => (b.likesCount ?? 0).compareTo(a.likesCount ?? 0));
    return sorted.take(5).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    fetchArticles();

    ever(_likeSyncService.rxLikeEvent, (LikeEvent? event) {
      if (event != null) {
        _handleLocalArticleListSync(event.articleId, event.isLiked);
      }
    });
  }

  void _handleLocalArticleListSync(int articleId, bool isLiked) {
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

  Future<void> fetchCategories() async {
    try {
      final response = await _apiProvider.getCategories();
      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'] ?? response.data;
        List<CategoryModel> fetchedCategories = data
            .map((e) => CategoryModel.fromJson(e))
            .toList();
        categories.value = fetchedCategories;
      }
    } catch (e) {
    }
  }

  void changeCategory(CategoryModel? category) {
    if (selectedCategory.value?.id == category?.id) return;

    selectedCategory.value = category;
    currentPage = 1;
    hasMoreData.value = true;
    articles.clear();
    fetchArticles();
  }

  void searchArticles(String query) {
    searchQuery.value = query;
    currentPage = 1;
    hasMoreData.value = true;
    articles.clear();
    fetchArticles();
  }

  Future<void> fetchArticles() async {
    if (!hasMoreData.value) return;

    if (currentPage == 1) {
      isLoading.value = true;
    } else {
      isFetchingMore.value = true;
    }

    try {
      List<ArticleModel> newArticles = await _apiProvider.getArticles(
        page: currentPage,
        category: selectedCategory.value?.id.toString(),
        search: searchQuery.value,
      );

      if (newArticles.isEmpty) {
        hasMoreData.value = false;
      } else {
        Get.find<NotificationService>().syncArticleMetrics(newArticles);

        final publicArticles = newArticles.where((a) => !a.isBlocked).toList();
        
        final processedArticles = _likeSyncService.applyLikeStateToArticles(publicArticles);
        
        if (currentPage == 1) {
          articles.assignAll(processedArticles);
        } else {
          articles.addAll(processedArticles);
        }

        if (publicArticles.isEmpty && newArticles.isNotEmpty) {
          currentPage++;
          await fetchArticles();
          return;
        }

        currentPage++;
      }
    } catch (e) {
      showCustomSnackbar(
        'Gagal Memuat',
        'Terjadi kesalahan saat mengambil artikel',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      isFetchingMore.value = false;
    }
  }

  Future<void> toggleLike(int articleId) async {

    final index = articles.indexWhere((a) => a.id == articleId);
    if (index == -1) return;

    final article = articles[index];
    final isCurrentlyLiked = article.isLiked ?? false;
    final newLikedState = !isCurrentlyLiked;

    _likeSyncService.updateLikeStatus(articleId, newLikedState);
    _syncLikeState(articleId, newLikedState);


    final authService = Get.find<AuthService>();
    if (!authService.isLoggedIn.value) {
      showCustomSnackbar('Akses Ditolak', 'Anda harus login untuk menyukai artikel.', backgroundColor: Colors.redAccent, colorText: Colors.white);
      Get.toNamed(Routes.LOGIN);
      return;
    }
    if (isLiking.value) return;
    isLiking.value = true;
    try {
      await _apiProvider.toggleLike(articleId);
    } catch (e) {
      _likeSyncService.updateLikeStatus(articleId, isCurrentlyLiked);
      _syncLikeState(articleId, isCurrentlyLiked);
      showCustomSnackbar('Gagal', 'Tidak dapat menyukai artikel saat ini, periksa koneksi Anda.');
    } finally {
      isLiking.value = false;
    }
  }

  void updateArticleLikeState(int articleId, bool isLiked) {
    _likeSyncService.updateLikeStatus(articleId, isLiked);
  }

  void _syncLikeState(int articleId, bool isLiked) {
    try {
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().updateArticleLikeState(
          articleId,
          isLiked,
        );
      }
      if (Get.isRegistered<ExploreController>()) {
        Get.find<ExploreController>().updateArticleLikeState(
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

  void loadMoreArticles() {
    if (!isLoading.value && !isFetchingMore.value && hasMoreData.value) {
      fetchArticles();
    }
  }

  Future<void> refreshArticles() async {
    currentPage = 1;
    hasMoreData.value = true;
    articles.clear();
    await fetchArticles();
  }

  String getSnippetText(String? content) {
    if (content == null || content.trim().isEmpty) {
      return 'Tidak ada ringkasan...';
    }

    try {
      if (content.trim().startsWith('[')) {
        final deltaJson = jsonDecode(content);
        final document = Document.fromJson(deltaJson);
        return document.toPlainText().replaceAll('\n', ' ').trim();
      }
      return content.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
    } catch (e) {
      return content.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
    }
  }

  Future<void> deleteArticle(int id) async {
    try {
      final response = await _apiProvider.deleteArticle(id);
      if (response.statusCode == 200 || response.statusCode == 204) {
        articles.removeWhere((article) => article.id == id);
        articles.refresh();
        showCustomSnackbar('Sukses', 'Artikel berhasil dihapus');

        try {
          if (Get.isRegistered<ProfileController>()) {
            Get.find<ProfileController>().userArticles.removeWhere(
              (article) => article.id == id,
            );
            Get.find<ProfileController>().articlesCount.value--;
          }
        } catch (e) {
          // ignore
        }
      }
    } catch (e) {
      showCustomSnackbar('Error', 'Gagal menghapus artikel');
    }
  }
}