import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../data/models/article_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/like_sync_service.dart';
import '../../../data/services/notification_service.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../explore/controllers/explore_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../../widgets/custom_snackbar.dart';

class ArticleSearchController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final GetStorage _storage = GetStorage();
  final LikeSyncService _likeSyncService = Get.find<LikeSyncService>();

  var searchQuery = ''.obs;
  var articles = <ArticleModel>[].obs;
  var isLoading = false.obs;
  var searchHistory = <String>[].obs;
  var searchTab = 0.obs; // 0 for Artikel, 1 for Penulis
  var users = <UserModel>[].obs;

  final String _historyKey = 'search_history';

  @override
  void onInit() {
    super.onInit();
    loadSearchHistory();

    // Real-time search with debounce (500ms)
    debounce(
      searchQuery,
      (_) => fetchArticles(),
      time: const Duration(milliseconds: 500),
    );
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
    final currentQuery = searchQuery.value.trim();
    if (currentQuery.isEmpty) {
      articles.clear();
      users.clear();
      return;
    }

    isLoading.value = true;
    try {
      final List<Future<List<ArticleModel>>> futures = [
        _apiProvider.getArticles(search: currentQuery, page: 1),
        _apiProvider.getArticles(search: currentQuery, page: 2),
        _apiProvider.getArticles(search: currentQuery, page: 3),
      ];
      
      // Concurrently fetch general articles to discover all active authors in the system
      futures.addAll([
        _apiProvider.getArticles(page: 1),
        _apiProvider.getArticles(page: 2),
        _apiProvider.getArticles(page: 3),
      ]);

      final results = await Future.wait(futures);
      
      // Prevent race conditions: discard responses if the query has changed in the meantime
      if (searchQuery.value.trim() != currentQuery) {
        return;
      }

      // Combine search-specific articles for the Articles tab
      final List<ArticleModel> searchArticlesFetched = [];
      for (int i = 0; i < 3; i++) {
        searchArticlesFetched.addAll(results[i]);
      }

      // Combine ALL fetched articles (search + general) for user extraction
      final List<ArticleModel> fetched = [];
      for (var pageResult in results) {
        fetched.addAll(pageResult);
      }

      // SYNC: Perbarui baseline notifikasi
      Get.find<NotificationService>().syncArticleMetrics(fetched);

      // FILTER ARTIKEL: Hanya tampilkan artikel yang TIDAK diblokir (status artikel atau status user)
      final filteredArticles = searchArticlesFetched.where((a) => !a.isBlocked).toList();
      articles.value = _likeSyncService.applyLikeStateToArticles(filteredArticles);

      // EXTRACT USERS: Cari user yang cocok dari SEMUA artikel yang ditarik (bahkan jika artikelnya sendiri diblokir)
      final List<UserModel> uniqueUsers = [];
      final Set<int> userIds = {};

      for (var article in fetched) { 
        if (article.user != null && article.user!.id != null) {
          final user = article.user!;
          if (!userIds.contains(user.id!)) {
            userIds.add(user.id!);
            uniqueUsers.add(user);
          }
        }
      }

      // ENRICH USERS: Concurrently fetch detailed user info (for bio/profession) from API or single article details
      final List<UserModel> enrichedUsers = await Future.wait(
        uniqueUsers.map((u) async {
          try {
            final res = await _apiProvider.getAuthorProfile(u.id!);
            if (res.statusCode == 200) {
              final rawData = res.data['data'] ?? res.data;
              final userData = (rawData is Map<String, dynamic> && rawData.containsKey('user'))
                  ? rawData['user']
                  : rawData;
              final detailedUser = UserModel.fromJson(userData);
              return detailedUser;
            }
          } catch (_) {
            // Fallback: Fetch a single article's detail written by this author, which contains the bio field!
            try {
              final userArticle = fetched.firstWhereOrNull((a) => a.user?.id == u.id);
              if (userArticle != null && userArticle.slug != null) {
                final detail = await _apiProvider.getArticleDetail(userArticle.slug!);
                if (detail.user != null) {
                  final du = detail.user!;
                  return UserModel(
                    id: u.id,
                    name: du.name ?? u.name,
                    email: du.email ?? u.email,
                    role: du.role ?? u.role,
                    status: du.status ?? u.status,
                    photoProfile: du.photoProfile?.isNotEmpty == true ? du.photoProfile : u.photoProfile,
                    profession: du.profession ?? u.profession,
                    bio: du.bio ?? u.bio,
                  );
                }
              }
            } catch (_) {}
          }
          return u;
        }).toList()
      );

      // Split the search query into clean lowercase words/tokens for fuzzy matching
      final queryTokens = currentQuery.toLowerCase()
          .split(RegExp(r'[,\s\.]+'))
          .map((t) => t.trim())
          .where((t) => t.length >= 2) // Only match tokens with 2+ characters
          .toList();

      final List<UserModel> matchingUsers = [];
      for (var user in enrichedUsers) {
        // Sembunyikan user dari hasil pencarian jika mereka dibanned (Aturan Baru)
        if (user.isBanned) continue;

        final nameLower = (user.name ?? '').toLowerCase();
        final professionLower = (user.profession ?? '').toLowerCase();
        final bioLower = (user.bio ?? '').toLowerCase();

        bool matches = false;
        // A user matches if their profile contains any of the search tokens
        if (queryTokens.isEmpty) {
          final q = currentQuery.toLowerCase();
          if (nameLower.contains(q) || professionLower.contains(q) || bioLower.contains(q)) {
            matches = true;
          }
        } else {
          for (var token in queryTokens) {
            if (nameLower.contains(token) || 
                professionLower.contains(token) || 
                bioLower.contains(token)) {
              matches = true;
              break;
            }
          }
        }

        if (matches) {
          matchingUsers.add(user);
        }
      }

      // Sort users: exact name matches first
      matchingUsers.sort((a, b) {
        final aName = (a.name ?? '').toLowerCase();
        final bName = (b.name ?? '').toLowerCase();
        final q = currentQuery.toLowerCase();
        
        if (aName == q && bName != q) return -1;
        if (bName == q && aName != q) return 1;
        if (aName.startsWith(q) && !bName.startsWith(q)) return -1;
        if (bName.startsWith(q) && !aName.startsWith(q)) return 1;
        return aName.compareTo(bName);
      });
      
      users.value = matchingUsers;

      // History management
      if (searchArticlesFetched.isNotEmpty || matchingUsers.isNotEmpty) {
        saveToHistory(currentQuery);
      }
    } catch (e) {
      print('Error searching articles: $e');
    } finally {
      if (searchQuery.value.trim() == currentQuery) {
        isLoading.value = false;
      }
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

      // Optimistic update
      article.isLiked = !isCurrentlyLiked;
      article.likesCount =
          (article.likesCount ?? 0) + (isCurrentlyLiked ? -1 : 1);

      articles[index] = article;
      articles.refresh();

      await _apiProvider.toggleLike(articleId);
      _likeSyncService.updateLikeStatus(articleId, !isCurrentlyLiked);

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

  void _syncLikeState(int articleId, bool isLiked) {
    try {
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().updateArticleLikeState(
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
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().updateArticleLikeState(
          articleId,
          isLiked,
        );
      }
    } catch (_) {}
  }
}
