import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/article_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/like_sync_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';

class AuthorProfileController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final LikeSyncService _likeSyncService = Get.find<LikeSyncService>();

  late UserModel author;
  var isArticlesLoading = true.obs;
  var isLoadingMoreArticles = false.obs;
  var hasMoreUserArticles = false.obs;
  int _currentArticlesPage = 1;
  static const int _articlesPageSize = 10;
  final ScrollController scrollController = ScrollController();

  var userArticles = <ArticleModel>[].obs;
  
  // Search & Filter
  var articleSearchQuery = ''.obs;
  var selectedCategoryFilter = Rxn<String>();
  final articleSearchController = TextEditingController();

  List<String> get availableCategories {
    final cats = userArticles
        .map((a) => a.category?.name)
        .whereType<String>()
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }

  List<ArticleModel> get filteredUserArticles {
    final q = articleSearchQuery.value.trim().toLowerCase();
    final cat = selectedCategoryFilter.value;
    return userArticles.where((a) {
      final matchQuery = q.isEmpty || (a.title ?? '').toLowerCase().contains(q);
      final matchCategory = cat == null || a.category?.name == cat;
      return matchQuery && matchCategory;
    }).toList();
  }

  void clearArticleSearch() {
    articleSearchQuery.value = '';
    articleSearchController.clear();
  }

  var articlesCount = 0.obs;
  var likesCount = 0.obs;
  var commentsCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_handleScroll);
    if (Get.arguments != null) {
      author = Get.arguments as UserModel;
      fetchAuthorArticles(reset: true);
    } else {
      isArticlesLoading.value = false;
    }
  }

  void _handleScroll() {
    if (!hasMoreUserArticles.value || isLoadingMoreArticles.value) return;
    if (!scrollController.hasClients) return;
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 180) {
      loadMoreAuthorArticles();
    }
  }

  Future<void> fetchAuthorArticles({bool reset = true}) async {
    if (reset) {
      _currentArticlesPage = 1;
      userArticles.clear();
      hasMoreUserArticles.value = false;
    }

    if (reset) {
      isArticlesLoading.value = true;
    } else {
      isLoadingMoreArticles.value = true;
    }

    try {
      final fetchedArticles = await _apiProvider.getArticles(page: _currentArticlesPage);
      final updatedArticles = _likeSyncService.applyLikeStateToArticles(fetchedArticles);

      if (reset) {
        userArticles.value = updatedArticles;
      } else {
        userArticles.addAll(updatedArticles);
      }

      userArticles.value = userArticles
          .where((a) => a.user?.id == author.id && !a.isBlocked)
          .toList();

      hasMoreUserArticles.value = fetchedArticles.length >= _articlesPageSize;
      if (hasMoreUserArticles.value) {
        _currentArticlesPage++;
      }

      int totalLikes = 0;
      int totalComments = 0;
      for (var article in userArticles) {
        totalLikes += article.likesCount ?? 0;
        totalComments += article.commentsCount ?? 0;
      }
      
      likesCount.value = totalLikes;
      commentsCount.value = totalComments;
      articlesCount.value = userArticles.length;
      
    } catch (e) {
      print('Error fetching author articles: $e');
    } finally {
      if (reset) {
        isArticlesLoading.value = false;
      } else {
        isLoadingMoreArticles.value = false;
      }
    }
  }

  Future<void> loadMoreAuthorArticles() async {
    if (isLoadingMoreArticles.value || !hasMoreUserArticles.value) return;
    await fetchAuthorArticles(reset: false);
  }

  Future<void> toggleLike(int articleId) async {
    final authService = Get.find<AuthService>();
    if (!authService.isLoggedIn.value) {
      Get.snackbar('Akses Ditolak', 'Anda harus login untuk menyukai artikel.', backgroundColor: Colors.redAccent, colorText: Colors.white);
      Get.toNamed(Routes.LOGIN);
      return;
    }

    try {
      final userIndex = userArticles.indexWhere((a) => a.id == articleId);
      if (userIndex == -1) return;

      final article = userArticles[userIndex];
      final isCurrentlyLiked = article.isLiked ?? false;
      final newLikedStatus = !isCurrentlyLiked;

      // Optimistic update
      article.isLiked = newLikedStatus;
      article.likesCount = (article.likesCount ?? 0) + (newLikedStatus ? 1 : -1);
      userArticles[userIndex] = article;
      userArticles.refresh();

      _likeSyncService.updateLikeStatus(articleId, newLikedStatus);
      await _apiProvider.toggleLike(articleId);
    } catch (e) {
      fetchAuthorArticles(); // Revert on error
    }
  }

  @override
  void onClose() {
    articleSearchController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
