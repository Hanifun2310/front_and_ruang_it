import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/like_sync_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/models/article_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../explore/controllers/explore_controller.dart';
import '../../search/controllers/search_controller.dart';
import '../../../widgets/custom_snackbar.dart';

class ProfileController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final AuthService _authService = Get.find<AuthService>();
  final LikeSyncService _likeSyncService = Get.find<LikeSyncService>();

  var isLoading = false.obs;
  var isProfileLoading = false.obs;
  var isArticlesLoading = false.obs;
  var isLoadingMoreArticles = false.obs;
  var hasMoreUserArticles = false.obs;
  int _currentArticlesPage = 1;
  static const int _articlesPageSize = 10;
  final ScrollController scrollController = ScrollController();

  // Controllers sesuai field di Laravel
  final nameController = TextEditingController();
  final professionController = TextEditingController();
  final bioController = TextEditingController();
  var email = "".obs;
  var photoProfile = "".obs;
  var profession = "".obs;
  var bio = "".obs;
  var name = "".obs;
  var userId = 0.obs;

  // Image Picking
  final ImagePicker _picker = ImagePicker();
  var selectedImagePath = "".obs;
  var selectedImageBytes = <int>[].obs;
  var selectedFileName = "".obs;

  // Articles & Tabs
  var userArticles = <ArticleModel>[].obs;
  var likedArticles = <ArticleModel>[].obs;
  var selectedTab = 0.obs;

  // Search & Filter
  var articleSearchQuery = ''.obs;
  var selectedCategoryFilter = Rxn<String>();
  final articleSearchController = TextEditingController();
  var allUserCategories = <String>[].obs;

  List<String> get availableCategories => allUserCategories;

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

  // Stats
  var articlesCount = 0.obs;
  var likesCount = 0.obs;
  var commentsCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_handleScroll);
    initProfile();
  }

  Future<void> initProfile() async {
    await loadUserData();
    await fetchUserArticles(reset: true);
    await fetchAllUserCategories();
  }

  void _handleScroll() {
    if (!hasMoreUserArticles.value || isLoadingMoreArticles.value) return;
    if (!scrollController.hasClients) return;
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 180) {
      loadMoreUserArticles();
    }
  }

  Future<void> loadUserData() async {
    isProfileLoading.value = true;
    try {
      final response = await _apiProvider.getProfile();
      if (response.statusCode == 200) {
        final userData = response.data['data'] ?? response.data;
        final user = UserModel.fromJson(userData);

        name.value = user.name ?? "User";
        nameController.text = user.name ?? "";
        profession.value = user.profession ?? "";
        professionController.text = user.profession ?? "";
        bio.value = user.bio ?? "";
        bioController.text = user.bio ?? "";
        email.value = user.email ?? "";
        photoProfile.value = user.photoProfile ?? '';
        userId.value = user.id ?? 0;

        // Stats dari profile response (biasanya backend menyertakan total)
        articlesCount.value = userData['articles_count'] ?? 0;
        likesCount.value = userData['likes_count'] ?? 0;
        commentsCount.value = userData['comments_count'] ?? 0;
        
        // Simpan ke storage agar sinkron
        await _authService.saveSession(_authService.token ?? '', userData);
      }
    } catch (e) {
      // Fallback ke data local jika offline/error
      final userData = _authService.currentUser;
      if (userData != null) {
        final user = UserModel.fromJson(userData);
        name.value = user.name ?? "User";
        nameController.text = user.name ?? "";
        profession.value = user.profession ?? "";
        professionController.text = user.profession ?? "";
        bio.value = user.bio ?? "";
        bioController.text = user.bio ?? "";
        email.value = user.email ?? "";
        photoProfile.value = user.photoProfile ?? '';
        userId.value = user.id ?? 0;
        articlesCount.value = userData['articles_count'] ?? 0;
        likesCount.value = userData['likes_count'] ?? 0;
        commentsCount.value = userData['comments_count'] ?? 0;
      }
    } finally {
      isProfileLoading.value = false;
    }
  }

  // Fungsi baru untuk mengambil SEMUA kategori milik user tanpa terpengaruh pagination artikel
  Future<void> fetchAllUserCategories() async {
    try {
      final Set<String> cats = {};
      int page = 1;
      bool hasMore = true;
      
      while (hasMore && page <= 5) {
        final fetched = await _apiProvider.getArticles(page: page);
        if (fetched.isEmpty) {
          hasMore = false;
          break;
        }
        
        final myArticles = fetched.where((a) => a.user?.id == userId.value || a.user?.name == name.value);
        for (var a in myArticles) {
          if (a.category?.name != null) {
            cats.add(a.category!.name!);
          }
        }
        
        if (fetched.length < 10) {
          hasMore = false;
        }
        
        page++;
      }
      
      final sortedCats = cats.toList();
      sortedCats.sort();
      allUserCategories.value = sortedCats;
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> fetchUserArticles({bool reset = true}) async {
    if (reset) {
      _currentArticlesPage = 1;
      userArticles.clear();
      likedArticles.clear();
      hasMoreUserArticles.value = false;
    }

    if (reset) {
      isArticlesLoading.value = true;
    } else {
      isLoadingMoreArticles.value = true;
    }

    try {
      final fetchedArticles = await _apiProvider.getArticles(
        page: _currentArticlesPage,
      );
      final updatedArticles = _likeSyncService.applyLikeStateToArticles(
        fetchedArticles,
      );

      List<ArticleModel> filteredResults = updatedArticles;
      if (name.value.isNotEmpty) {
        filteredResults = updatedArticles
            .where((a) => a.user?.name == name.value)
            .toList();
      }

      if (reset) {
        userArticles.value = filteredResults;
      } else {
        userArticles.addAll(filteredResults);
      }

      likedArticles.value = userArticles
          .where((a) => a.isLiked == true)
          .toList();

      hasMoreUserArticles.value = fetchedArticles.length >= _articlesPageSize;
      if (hasMoreUserArticles.value) {
        _currentArticlesPage++;
      }

      Get.find<NotificationService>().syncArticleMetrics(userArticles);

      // JANGAN update stats di sini jika ingin stats berdasarkan SELURUH data (sudah dihandle di loadUserData)
      // Namun jika loadUserData gagal, kita bisa hitung total dari yang ada sebagai fallback minimum
      if (articlesCount.value == 0) {
        articlesCount.value = userArticles.length;
      }
    } catch (e) {
      print('Error fetching user articles: $e');
    } finally {
      if (reset) {
        isArticlesLoading.value = false;
      } else {
        isLoadingMoreArticles.value = false;
      }
    }
  }

  Future<void> loadMoreUserArticles() async {
    if (!hasMoreUserArticles.value || isLoadingMoreArticles.value) return;
    await fetchUserArticles(reset: false);
  }

  Future<void> updateProfile() async {
    isLoading.value = true;
    try {
      final response = await _apiProvider.updateProfile(
        name: nameController.text,
        profession: professionController.text,
        bio: bioController.text,
        // Tetap kirim path untuk mobile jika ada, tapi utamakan bytes jika tersedia di ApiProvider
        imagePath: !kIsWeb && selectedImagePath.value.isNotEmpty
            ? selectedImagePath.value
            : null,
        imageBytes: selectedImageBytes.isNotEmpty
            ? selectedImageBytes.toList()
            : null,
        fileName: selectedFileName.value.isNotEmpty
            ? selectedFileName.value
            : null,
      );

      if (response.statusCode == 200) {
        print('UPDATE PROFILE RESPONSE: ${response.data}');

        // Ambil data user, tangani jika dibungkus 'data', 'user', atau tidak
        final dynamic responseData =
            response.data['data'] ?? response.data['user'] ?? response.data;

        if (responseData is Map<String, dynamic>) {
          // Merge data lama dengan data baru agar stats tidak hilang jika API tidak mengirimnya kembali
          final Map<String, dynamic> oldData = Map<String, dynamic>.from(
            _authService.currentUser ?? {},
          );
          final Map<String, dynamic> newData = Map<String, dynamic>.from(
            responseData,
          );

          // Gabungkan: newData akan menimpa oldData
          final mergedData = {...oldData, ...newData};

          await _authService.box.write('user', mergedData);

          // Refresh local observable state
          loadUserData();

          // Reset selection
          selectedImagePath.value = "";
          selectedImageBytes.clear();
          selectedFileName.value = "";

          showCustomSnackbar('Sukses', 'Profil berhasil diperbarui');

          // AUTO CLOSE BOTTOM SHEET ON SUCCESS
          if (Get.isBottomSheetOpen ?? false) {
            Get.back();
          } else if (Get.isDialogOpen ?? false) {
            Get.back();
          }
        }
      }
    } catch (e) {
      print('Error update profile: $e');
      showCustomSnackbar(
        'Error',
        'Gagal memperbarui profil. Pastikan semua data valid.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        selectedImagePath.value = image.path;
        // Baca bytes untuk semua platform agar konsisten dengan logic Article
        selectedImageBytes.assignAll(await image.readAsBytes());
        selectedFileName.value = image.name;
      }
    } catch (e) {
      showCustomSnackbar('Error', 'Gagal memilih gambar');
    }
  }

  Future<void> deleteArticle(int id) async {
    try {
      final response = await _apiProvider.deleteArticle(id);
      if (response.statusCode == 200 || response.statusCode == 204) {
        userArticles.removeWhere((article) => article.id == id);
        articlesCount.value--;
        showCustomSnackbar('Sukses', 'Artikel berhasil dihapus');
      }
    } catch (e) {
      showCustomSnackbar('Error', 'Gagal menghapus artikel');
    }
  }

  // Sync method for other controllers to update state
  void updateArticleLikeState(int articleId, bool isLiked) {
    // Sync user articles
    final userIndex = userArticles.indexWhere((a) => a.id == articleId);
    if (userIndex != -1) {
      final article = userArticles[userIndex];
      final bool currentIsLiked = article.isLiked ?? false;
      if (currentIsLiked != isLiked) {
        article.isLiked = isLiked;
        article.likesCount = (article.likesCount ?? 0) + (isLiked ? 1 : -1);
        userArticles[userIndex] = article;
        userArticles.refresh();
      }
    }

    // Sync liked articles (add or remove)
    if (isLiked) {
      // If liked, check if it's already in the likedArticles list
      if (!likedArticles.any((a) => a.id == articleId)) {
        ArticleModel? existsInAll;
        for (var a in userArticles) {
          if (a.id == articleId) {
            existsInAll = a;
            break;
          }
        }

        if (existsInAll == null && Get.isRegistered<DashboardController>()) {
          try {
            final dashboardArticles = Get.find<DashboardController>().articles;
            for (var a in dashboardArticles) {
              if (a.id == articleId) {
                existsInAll = a;
                break;
              }
            }
          } catch (e) {
            // ignore
          }
        }

        if (existsInAll == null &&
            Get.isRegistered<dynamic>(tag: 'ArticleDetailController')) {
          try {
            final detailArticle = Get.find<dynamic>(
              tag: 'ArticleDetailController',
            ).article.value;
            if (detailArticle.id == articleId) {
              existsInAll = detailArticle;
            }
          } catch (e) {
            // ignore
          }
        }

        if (existsInAll == null) {
          // Placeholder that gets updated asynchronously
          existsInAll = ArticleModel(
            id: articleId,
            isLiked: true,
            title: "Article #$articleId",
            likesCount: 1,
            commentsCount: 0,
          );

          _apiProvider
              .getArticles()
              .then((articles) {
                final fetched = articles.firstWhereOrNull(
                  (a) => a.id == articleId,
                );
                if (fetched != null) {
                  final idx = likedArticles.indexWhere(
                    (a) => a.id == articleId,
                  );
                  if (idx != -1) {
                    fetched.isLiked = true;
                    likedArticles[idx] = fetched;
                    likedArticles.refresh();
                  }
                }
              })
              .catchError((_) {});
        }

        likedArticles.add(existsInAll);
      }
    } else {
      likedArticles.removeWhere((a) => a.id == articleId);
    }
    likedArticles.refresh();
    _likeSyncService.updateLikeStatus(articleId, isLiked);
  }

  Future<void> toggleLike(int articleId) async {
    try {
      // Sync userArticles
      final userIndex = userArticles.indexWhere((a) => a.id == articleId);
      final likedIndex = likedArticles.indexWhere((a) => a.id == articleId);

      bool isCurrentlyLiked = false;
      if (userIndex != -1) {
        isCurrentlyLiked = userArticles[userIndex].isLiked ?? false;
      } else if (likedIndex != -1) {
        isCurrentlyLiked = likedArticles[likedIndex].isLiked ?? false;
      }

      final newLikedStatus = !isCurrentlyLiked;

      // Update local state
      updateArticleLikeState(articleId, newLikedStatus);

      // API Call
      await _apiProvider.toggleLike(articleId);
      _likeSyncService.updateLikeStatus(articleId, newLikedStatus);

      // SYNC: Update other controllers
      _syncLikeState(articleId, newLikedStatus);
    } catch (e) {
      fetchUserArticles(); // Revert on error
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

  Future<void> logout() async {
    await _authService.logout();
  }

  @override
  void onClose() {
    articleSearchController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
