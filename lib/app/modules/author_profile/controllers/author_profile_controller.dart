import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/article_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/like_sync_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/custom_snackbar.dart';

class AuthorProfileController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final LikeSyncService _likeSyncService = Get.find<LikeSyncService>();

  late UserModel author;
  var rxAuthor = UserModel().obs;
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
    
    // Safety check: ensure userArticles is not empty and author data is consistent
    if (userArticles.isEmpty) return [];

    return userArticles.where((a) {
      final matchQuery = q.isEmpty || (a.title ?? '').toLowerCase().contains(q);
      final matchCategory = cat == null || a.category?.name == cat;
      
      // Secondary safety: ensure we only show articles for THIS author
      final bool isCorrectAuthor = a.user?.id == author.id || a.user?.name == author.name;
      
      return matchQuery && matchCategory && isCorrectAuthor;
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
      rxAuthor.value = author;

      // Centralized banned user enforcement! If author is banned, block profile viewing.
      if (author.isBanned) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showCustomSnackbar(
            'Akses Ditolak',
            'Akun penulis ini telah dinonaktifkan.',
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
          Get.back();
        });
        return;
      }

      fetchAuthorArticles(reset: true);
      fetchDetailedAuthorInfo();
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

  Future<void> fetchDetailedAuthorInfo() async {
    try {
      final response = await _apiProvider.getAuthorProfile(author.id!);
      if (response.statusCode == 200) {
        final rawData = response.data['data'] ?? response.data;
        final userData = (rawData is Map<String, dynamic> && rawData.containsKey('user'))
            ? rawData['user']
            : rawData;
        final detailedUser = UserModel.fromJson(userData);
        
        // Re-enforce banned check with latest data from server
        if (detailedUser.isBanned) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showCustomSnackbar(
              'Akses Ditolak',
              'Akun penulis ini telah dinonaktifkan.',
              backgroundColor: Colors.redAccent,
              colorText: Colors.white,
            );
            Get.back();
          });
          return;
        }

        rxAuthor.value = detailedUser;
        rxAuthor.refresh();
      }
    } catch (e) {
      print('Error fetching detailed author info: $e');
      
      // Fallback: If getAuthorProfile fails (e.g. 404), try to find a rich user object from one of their articles
      try {
        final userArticle = userArticles.firstWhereOrNull((a) => a.user?.id == author.id);
        if (userArticle != null && userArticle.slug != null) {
          final detail = await _apiProvider.getArticleDetail(userArticle.slug!);
          if (detail.user != null) {
            rxAuthor.value = detail.user!;
            rxAuthor.refresh();
          }
        }
      } catch (err) {
        print('Error fetching user fallback from article detail: $err');
      }
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
      showCustomSnackbar('Akses Ditolak', 'Anda harus login untuk menyukai artikel.', backgroundColor: Colors.redAccent, colorText: Colors.white);
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
