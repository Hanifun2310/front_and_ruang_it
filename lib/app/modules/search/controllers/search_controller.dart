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
      // 1. Fetch Articles dan Users secara paralel
      final results = await Future.wait([
        _apiProvider.getArticles(search: currentQuery, page: 1),
        _apiProvider.searchUsers(currentQuery),
      ]);
      
      if (searchQuery.value.trim() != currentQuery) return;

      final searchArticlesFetched = results[0] as List<ArticleModel>;
      final directUsers = results[1] as List<UserModel>;

      // SYNC: Perbarui baseline notifikasi
      Get.find<NotificationService>().syncArticleMetrics(searchArticlesFetched);

      // FILTER ARTIKEL: Hanya tampilkan artikel yang TIDAK diblokir/banned
      final filteredArticles = searchArticlesFetched.where((a) => !a.isBlocked).toList();
      articles.value = _likeSyncService.applyLikeStateToArticles(filteredArticles);

      // Split query untuk fuzzy matching
      final queryLower = currentQuery.toLowerCase();
      final queryTokens = queryLower
          .split(RegExp(r'[,\s\.]+'))
          .map((t) => t.trim())
          .where((t) => t.length >= 2)
          .toList();

      bool userMatchesQuery(UserModel user) {
        final nameLower = (user.name ?? '').toLowerCase();
        final professionLower = (user.profession ?? '').toLowerCase();
        final emailLower = (user.email ?? '').toLowerCase();
        if (queryTokens.isEmpty) {
          return nameLower.contains(queryLower) ||
              professionLower.contains(queryLower) ||
              emailLower.contains(queryLower);
        }
        for (var token in queryTokens) {
          if (nameLower.contains(token) ||
              professionLower.contains(token) ||
              emailLower.contains(token)) {
            return true;
          }
        }
        return false;
      }

      // USER SEARCH: Gunakan hasil langsung dari API /users?search= sebagai sumber utama
      // Enrich data user dari direct search jika belum lengkap
      final List<UserModel> enrichedDirectUsers = await Future.wait(
        directUsers.map((u) async {
          if (u.isBanned) return u; // skip enrichment untuk yang banned
          if (u.bio != null || u.profession != null) return u;
          try {
            final res = await _apiProvider.getAuthorProfile(u.id!);
            if (res.statusCode == 200) {
              final responseBody = res.data;
              Map<String, dynamic>? userData;
              if (responseBody is Map<String, dynamic>) {
                if (responseBody['data'] is Map && (responseBody['data'] as Map).containsKey('user')) {
                  userData = Map<String, dynamic>.from((responseBody['data'] as Map)['user']);
                } else if (responseBody['data'] is Map<String, dynamic>) {
                  userData = Map<String, dynamic>.from(responseBody['data']);
                } else if (responseBody.containsKey('user') && responseBody['user'] is Map) {
                  userData = Map<String, dynamic>.from(responseBody['user']);
                } else if (responseBody.containsKey('id') || responseBody.containsKey('name')) {
                  userData = Map<String, dynamic>.from(responseBody);
                }
              }
              if (userData != null) {
                final enriched = UserModel.fromJson(userData);
                // Preserve data dari direct search jika enriched tidak punya
                return UserModel(
                  id: enriched.id ?? u.id,
                  name: enriched.name ?? u.name,
                  email: enriched.email ?? u.email,
                  role: enriched.role ?? u.role,
                  status: enriched.status ?? u.status,
                  photoProfile: (enriched.photoProfile?.isNotEmpty == true) ? enriched.photoProfile : u.photoProfile,
                  profession: (enriched.profession?.isNotEmpty == true) ? enriched.profession : u.profession,
                  bio: (enriched.bio?.isNotEmpty == true) ? enriched.bio : u.bio,
                  articlesCount: enriched.articlesCount ?? u.articlesCount,
                  likesCount: enriched.likesCount ?? u.likesCount,
                  commentsCount: enriched.commentsCount ?? u.commentsCount,
                );
              }
            }
          } catch (_) {}
          return u;
        }).toList()
      );

      final Set<int> addedUserIds = {};
      final List<UserModel> matchingUsers = [];

      // PERTAMA: Tambahkan semua hasil direct search yang tidak banned
      for (var user in enrichedDirectUsers) {
        if (user.isBanned) continue;
        if (user.id == null) continue;
        if (!addedUserIds.contains(user.id!)) {
          addedUserIds.add(user.id!);
          matchingUsers.add(user);
        }
      }

      // KEDUA: Cari user dari artikel hasil pencarian (sebagai suplemen)
      // Hanya tambahkan jika belum ada di hasil direct search DAN cocok dengan query
      for (var article in searchArticlesFetched) {
        final u = article.user;
        if (u == null || u.id == null || u.isBanned) continue;
        if (addedUserIds.contains(u.id!)) continue;
        if (userMatchesQuery(u)) {
          addedUserIds.add(u.id!);
          matchingUsers.add(u);
        }
      }

      // Sort: exact match di atas, prefix match, lalu alphabetical
      matchingUsers.sort((a, b) {
        final aName = (a.name ?? '').toLowerCase();
        final bName = (b.name ?? '').toLowerCase();
        if (aName == queryLower && bName != queryLower) return -1;
        if (bName == queryLower && aName != queryLower) return 1;
        if (aName.startsWith(queryLower) && !bName.startsWith(queryLower)) return -1;
        if (bName.startsWith(queryLower) && !aName.startsWith(queryLower)) return 1;
        return aName.compareTo(bName);
      });
      
      users.value = matchingUsers;

      if (filteredArticles.isNotEmpty || matchingUsers.isNotEmpty) {
        saveToHistory(currentQuery);
      }
    } catch (e) {
      print('Error searching: $e');
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
