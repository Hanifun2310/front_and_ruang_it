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
    
    if (userArticles.isEmpty) return [];

    return userArticles.where((a) {
      final matchQuery = q.isEmpty || (a.title ?? '').toLowerCase().contains(q);
      final matchCategory = cat == null || a.category?.name == cat;
      
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
        final responseBody = response.data;
        Map<String, dynamic>? userData;

        if (responseBody is Map<String, dynamic>) {
          if (responseBody['data'] is Map && (responseBody['data'] as Map).containsKey('user')) {
            userData = Map<String, dynamic>.from((responseBody['data'] as Map)['user']);
          }
          else if (responseBody['data'] is Map<String, dynamic>) {
            userData = Map<String, dynamic>.from(responseBody['data']);
          }
          else if (responseBody.containsKey('user') && responseBody['user'] is Map) {
            userData = Map<String, dynamic>.from(responseBody['user']);
          }
          else if (responseBody.containsKey('id') || responseBody.containsKey('name')) {
            userData = Map<String, dynamic>.from(responseBody);
          }
          else {
            userData = Map<String, dynamic>.from(responseBody['data'] ?? responseBody);
          }
        }

        if (userData == null) return;

        final detailedUser = UserModel.fromJson(userData);
        
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

        final currentAuthor = rxAuthor.value;
        final mergedUser = UserModel(
          id: detailedUser.id ?? currentAuthor.id,
          name: (detailedUser.name?.isNotEmpty == true) ? detailedUser.name : currentAuthor.name,
          email: detailedUser.email ?? currentAuthor.email,
          role: detailedUser.role ?? currentAuthor.role,
          status: detailedUser.status ?? currentAuthor.status,
          photoProfile: (detailedUser.photoProfile?.isNotEmpty == true) ? detailedUser.photoProfile : currentAuthor.photoProfile,
          profession: (detailedUser.profession?.isNotEmpty == true) ? detailedUser.profession : currentAuthor.profession,
          bio: (detailedUser.bio?.isNotEmpty == true) ? detailedUser.bio : currentAuthor.bio,
          articlesCount: detailedUser.articlesCount ?? userData['articles_count'] ?? userData['posts_count'] ?? currentAuthor.articlesCount,
          likesCount: detailedUser.likesCount ?? userData['likes_count'] ?? userData['total_likes'] ?? currentAuthor.likesCount,
          commentsCount: detailedUser.commentsCount ?? userData['comments_count'] ?? userData['total_comments'] ?? currentAuthor.commentsCount,
        );

        rxAuthor.value = mergedUser;
        rxAuthor.refresh();

        if (mergedUser.articlesCount != null && mergedUser.articlesCount! > 0) {
          articlesCount.value = mergedUser.articlesCount!;
        }
        if (mergedUser.likesCount != null && mergedUser.likesCount! > 0) {
          likesCount.value = mergedUser.likesCount!;
        }
        if (mergedUser.commentsCount != null && mergedUser.commentsCount! > 0) {
          commentsCount.value = mergedUser.commentsCount!;
        }
      }
    } catch (e) {
      print('Error fetching detailed author info: $e');
      
      try {
        var userArticle = userArticles.firstWhereOrNull((a) => a.user?.id == author.id);
        if (userArticle == null) {
          final fetched = await _apiProvider.getArticles(page: 1);
          userArticle = fetched.firstWhereOrNull((a) => a.user?.id == author.id);
        }
        if (userArticle != null && userArticle.slug != null) {
          final detail = await _apiProvider.getArticleDetail(userArticle.slug!);
          if (detail.user != null) {
            final currentAuthor = rxAuthor.value;
            final mergedUser = UserModel(
              id: detail.user!.id ?? currentAuthor.id,
              name: (detail.user!.name?.isNotEmpty == true) ? detail.user!.name : currentAuthor.name,
              email: detail.user!.email ?? currentAuthor.email,
              role: detail.user!.role ?? currentAuthor.role,
              status: detail.user!.status ?? currentAuthor.status,
              photoProfile: (detail.user!.photoProfile?.isNotEmpty == true) ? detail.user!.photoProfile : currentAuthor.photoProfile,
              profession: (detail.user!.profession?.isNotEmpty == true) ? detail.user!.profession : currentAuthor.profession,
              bio: (detail.user!.bio?.isNotEmpty == true) ? detail.user!.bio : currentAuthor.bio,
              articlesCount: detail.user!.articlesCount ?? currentAuthor.articlesCount,
              likesCount: detail.user!.likesCount ?? currentAuthor.likesCount,
              commentsCount: detail.user!.commentsCount ?? currentAuthor.commentsCount,
            );
            rxAuthor.value = mergedUser;
            rxAuthor.refresh();

            if (articlesCount.value == 0 && likesCount.value == 0 && commentsCount.value == 0) {
              articlesCount.value = mergedUser.articlesCount ?? articlesCount.value;
              likesCount.value = mergedUser.likesCount ?? likesCount.value;
              commentsCount.value = mergedUser.commentsCount ?? commentsCount.value;
            }
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
      List<ArticleModel> fetchedArticles = [];
      bool useUserEndpoint = false;

      try {
        final userSpecificArticles = await _apiProvider.getUserArticles(
          author.id!,
          page: _currentArticlesPage,
        );
        if (userSpecificArticles.isNotEmpty || _currentArticlesPage > 1) {
          fetchedArticles = userSpecificArticles;
          useUserEndpoint = true;
        }
      } catch (_) {}

      if (!useUserEndpoint) {
        fetchedArticles = await _apiProvider.getArticles(page: _currentArticlesPage);
      }
      
      final updatedArticles = _likeSyncService.applyLikeStateToArticles(fetchedArticles);

      final authorArticles = useUserEndpoint
          ? updatedArticles.where((a) {
              final articleStatus = a.status?.toLowerCase();
              final isArticleBanned = articleStatus == 'banned' || articleStatus == 'blocked';
              final isUserBanned = a.user?.isBanned == true;
              return !isArticleBanned && !isUserBanned;
            }).toList()
          : updatedArticles.where((a) {
              final isThisAuthor = a.user?.id == author.id;
              final articleStatus = a.status?.toLowerCase();
              final isArticleBanned = articleStatus == 'banned' || articleStatus == 'blocked';
              final isUserBanned = a.user?.isBanned == true;
              return isThisAuthor && !isArticleBanned && !isUserBanned;
            }).toList();

      if (reset) {
        userArticles.value = authorArticles;
      } else {
        userArticles.addAll(authorArticles);
      }

      hasMoreUserArticles.value = fetchedArticles.length >= _articlesPageSize;
      if (hasMoreUserArticles.value) {
        _currentArticlesPage++;
      }

      if (likesCount.value == 0 && commentsCount.value == 0 && articlesCount.value == 0) {
        int totalLikes = 0;
        int totalComments = 0;
        for (var article in userArticles) {
          totalLikes += article.likesCount ?? 0;
          totalComments += article.commentsCount ?? 0;
        }
        likesCount.value = totalLikes;
        commentsCount.value = totalComments;
        articlesCount.value = userArticles.length;
      }
      
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

      article.isLiked = newLikedStatus;
      article.likesCount = (article.likesCount ?? 0) + (newLikedStatus ? 1 : -1);
      userArticles[userIndex] = article;
      userArticles.refresh();

      _likeSyncService.updateLikeStatus(articleId, newLikedStatus);
      await _apiProvider.toggleLike(articleId);
    } catch (e) {
      fetchAuthorArticles();
    }
  }

  @override
  void onClose() {
    articleSearchController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
