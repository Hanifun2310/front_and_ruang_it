import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
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

  final nameController = TextEditingController();
  final professionController = TextEditingController();
  final bioController = TextEditingController();
  var email = "".obs;
  var photoProfile = "".obs;
  var profession = "".obs;
  var bio = "".obs;
  var name = "".obs;
  var userId = 0.obs;

  final ImagePicker _picker = ImagePicker();
  var selectedImagePath = "".obs;
  var selectedImageBytes = <int>[].obs;
  var selectedFileName = "".obs;
  var shouldRemovePhotoOnServer = false.obs;

  var userArticles = <ArticleModel>[].obs;
  var likedArticles = <ArticleModel>[].obs;
  var selectedTab = 0.obs;

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

        articlesCount.value = user.articlesCount ?? userData['articles_count'] ?? userData['posts_count'] ?? userData['articles'] ?? 0;
        likesCount.value = user.likesCount ?? userData['likes_count'] ?? userData['total_likes'] ?? userData['likes'] ?? 0;
        commentsCount.value = user.commentsCount ?? userData['comments_count'] ?? userData['total_comments'] ?? userData['comments'] ?? 0;
        
        await _authService.saveSession(_authService.token ?? '', userData);

        if (userId.value != 0) {
          try {
            final userDetailResponse = await _apiProvider.getAuthorProfile(userId.value);
            if (userDetailResponse.statusCode == 200) {
              final responseBody = userDetailResponse.data;
              Map<String, dynamic>? userDetailData;

              if (responseBody is Map<String, dynamic>) {
                if (responseBody['data'] is Map && (responseBody['data'] as Map).containsKey('user')) {
                  userDetailData = Map<String, dynamic>.from((responseBody['data'] as Map)['user']);
                }
                else if (responseBody['data'] is Map<String, dynamic>) {
                  userDetailData = Map<String, dynamic>.from(responseBody['data']);
                }
                else if (responseBody.containsKey('user') && responseBody['user'] is Map) {
                  userDetailData = Map<String, dynamic>.from(responseBody['user']);
                }
                else if (responseBody.containsKey('id') || responseBody.containsKey('name')) {
                  userDetailData = Map<String, dynamic>.from(responseBody);
                }
                else {
                  userDetailData = Map<String, dynamic>.from(responseBody['data'] ?? responseBody);
                }
              }

              if (userDetailData != null) {
                final detailedUser = UserModel.fromJson(userDetailData);
                
                final newArticlesCount = detailedUser.articlesCount ?? userDetailData['articles_count'] ?? userDetailData['posts_count'] ?? userDetailData['articles'];
                final newLikesCount = detailedUser.likesCount ?? userDetailData['likes_count'] ?? userDetailData['total_likes'] ?? userDetailData['likes'];
                final newCommentsCount = detailedUser.commentsCount ?? userDetailData['comments_count'] ?? userDetailData['total_comments'] ?? userDetailData['comments'];
                
                if (newArticlesCount != null) articlesCount.value = newArticlesCount;
                if (newLikesCount != null) likesCount.value = newLikesCount;
                if (newCommentsCount != null) commentsCount.value = newCommentsCount;
              }
            }
          } catch (e) {
            print('Error fetching detailed user profile for stats: $e');
          }
        }
      }
    } catch (e) {
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
        articlesCount.value = user.articlesCount ?? userData['articles_count'] ?? userData['posts_count'] ?? userData['articles'] ?? 0;
        likesCount.value = user.likesCount ?? userData['likes_count'] ?? userData['total_likes'] ?? userData['likes'] ?? 0;
        commentsCount.value = user.commentsCount ?? userData['comments_count'] ?? userData['total_comments'] ?? userData['comments'] ?? 0;
      }
    } finally {
      isProfileLoading.value = false;
    }
  }

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

  Future<void> fetchLikedArticles() async {
    final List<ArticleModel> allArticles = [];
    int page = 1;
    bool hasMore = true;

    try {
      while (hasMore && page <= 10) {
        final fetched = await _apiProvider.getArticles(page: page);
        if (fetched.isEmpty) {
          hasMore = false;
          break;
        }
        allArticles.addAll(fetched);
        if (fetched.length < 10) {
          hasMore = false;
        } else {
          page++;
        }
      }

      final updatedArticles = _likeSyncService.applyLikeStateToArticles(allArticles);

      // Sync with LikeSyncService so that it stays in sync
      for (var a in updatedArticles) {
        if (a.isLiked == true && a.id != null) {
          _likeSyncService.updateLikeStatus(a.id!, true);
        }
      }

      likedArticles.value = updatedArticles.where((a) => a.isLiked == true).toList();
    } catch (e) {
      print('Error fetching liked articles from server: $e');

      // Fallback: load using local likedArticleIds
      final ids = _likeSyncService.likedArticleIds.toList();
      if (ids.isEmpty) {
        likedArticles.clear();
        return;
      }

      final List<ArticleModel> fetched = [];
      final List<int> idsToFetch = [];

      for (var id in ids) {
        final ownArticle = userArticles.firstWhereOrNull((a) => a.id == id);
        if (ownArticle != null) {
          fetched.add(ownArticle);
        } else {
          idsToFetch.add(id);
        }
      }

      if (idsToFetch.isNotEmpty) {
        try {
          final List<Future<ArticleModel?>> futures = idsToFetch.map((id) async {
            try {
              final article = await _apiProvider.getArticleDetail(id.toString());
              article.isLiked = true;
              return article;
            } catch (e) {
              return null;
            }
          }).toList();

          final results = await Future.wait(futures);
          for (var a in results) {
            if (a != null) {
              fetched.add(a);
            }
          }
        } catch (_) {}
      }

      likedArticles.value = fetched;
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
        userId: userId.value,
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
        await fetchLikedArticles();
      } else {
        userArticles.addAll(filteredResults);
      }

      hasMoreUserArticles.value = fetchedArticles.length >= _articlesPageSize;
      if (hasMoreUserArticles.value) {
        _currentArticlesPage++;
      }

      Get.find<NotificationService>().syncArticleMetrics(userArticles);

      if (articlesCount.value == 0 && likesCount.value == 0 && commentsCount.value == 0) {
        int totalLikes = 0;
        int totalComments = 0;
        for (var article in userArticles) {
          totalLikes += article.likesCount ?? 0;
          totalComments += article.commentsCount ?? 0;
        }
        articlesCount.value = userArticles.length;
        likesCount.value = totalLikes;
        commentsCount.value = totalComments;
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
        imagePath: !kIsWeb && selectedImagePath.value.isNotEmpty
            ? selectedImagePath.value
            : null,
        imageBytes: selectedImageBytes.isNotEmpty
            ? selectedImageBytes.toList()
            : null,
        fileName: selectedFileName.value.isNotEmpty
            ? selectedFileName.value
            : null,
        removePhoto: shouldRemovePhotoOnServer.value,
      );

      if (response.statusCode == 200) {
        print('UPDATE PROFILE RESPONSE: ${response.data}');

        final dynamic responseData =
            response.data['data'] ?? response.data['user'] ?? response.data;

        if (responseData is Map<String, dynamic>) {
          final Map<String, dynamic> oldData = Map<String, dynamic>.from(
            _authService.currentUser ?? {},
          );
          final Map<String, dynamic> newData = Map<String, dynamic>.from(
            responseData,
          );

          final mergedData = {...oldData, ...newData};

          await _authService.saveSession(_authService.token ?? '', mergedData);

          loadUserData();

          selectedImagePath.value = "";
          selectedImageBytes.clear();
          selectedFileName.value = "";
          shouldRemovePhotoOnServer.value = false;

          // Tutup bottom sheet / dialog edit profil
          Get.back();

          showCustomSnackbar('Sukses', 'Profil berhasil diperbarui');
        }
      }
    } catch (e) {
      print('===== ERROR UPDATE PROFILE =====');
      print('Exception type: ${e.runtimeType}');
      print('Exception: $e');

      // Tampilkan detail response dari server jika ada
      if (e is DioException) {
        print('Status code  : ${e.response?.statusCode}');
        print('Server message: ${e.response?.statusMessage}');
        print('Response body : ${e.response?.data}');
        print('Request URL  : ${e.requestOptions.uri}');
        print('Request method: ${e.requestOptions.method}');

        // Ekstrak pesan error dari body Laravel
        final responseData = e.response?.data;
        String errorMsg = 'Gagal memperbarui profil.';
        if (responseData is Map) {
          final serverMsg = responseData['message'] ??
              responseData['error'] ??
              responseData['errors']?.toString();
          if (serverMsg != null) {
            errorMsg = serverMsg.toString();
            print('Laravel error msg: $serverMsg');
          }
          if (responseData['errors'] is Map) {
            print('Validation errors: ${responseData['errors']}');
          }
        }

        showCustomSnackbar('Error', errorMsg);
      } else {
        showCustomSnackbar(
          'Error',
          'Gagal memperbarui profil. Pastikan semua data valid.',
        );
      }
      print('================================');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // kompres gambar sedikit agar tidak terlalu besar
      );
      if (image != null) {
        // Validasi tipe file
        final String ext = image.name.split('.').last.toLowerCase();
        const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
        if (!allowedExtensions.contains(ext)) {
          showCustomSnackbar(
            'Format tidak didukung',
            'Gunakan format gambar: JPG, PNG, WebP, atau GIF',
          );
          return;
        }

        // Validasi ukuran file (maks 2MB)
        final bytes = await image.readAsBytes();
        const int maxSizeBytes = 2 * 1024 * 1024; // 2MB
        if (bytes.length > maxSizeBytes) {
          showCustomSnackbar(
            'Ukuran terlalu besar',
            'Ukuran foto maksimal 2MB. Pilih gambar yang lebih kecil.',
          );
          return;
        }

        selectedImagePath.value = image.path;
        selectedImageBytes.assignAll(bytes);
        selectedFileName.value = image.name;
        shouldRemovePhotoOnServer.value = false;
      }
    } catch (e) {
      showCustomSnackbar('Error', 'Gagal memilih gambar');
    }
  }

  void clearProfilePhoto() {
    selectedImagePath.value = "";
    selectedImageBytes.clear();
    selectedFileName.value = "";
    photoProfile.value = "";
    shouldRemovePhotoOnServer.value = true;
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

  void updateArticleLikeState(int articleId, bool isLiked) {
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

    if (isLiked) {
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
          existsInAll = ArticleModel(
            id: articleId,
            isLiked: true,
            title: "Loading...",
            likesCount: 1,
            commentsCount: 0,
          );

          _apiProvider
              .getArticleDetail(articleId.toString())
              .then((fetched) {
                final idx = likedArticles.indexWhere(
                  (a) => a.id == articleId,
                );
                if (idx != -1) {
                  fetched.isLiked = true;
                  likedArticles[idx] = fetched;
                  likedArticles.refresh();
                }
              })
              .catchError((err) {
                print('Error updating placeholder article details: $err');
              });
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
      final userIndex = userArticles.indexWhere((a) => a.id == articleId);
      final likedIndex = likedArticles.indexWhere((a) => a.id == articleId);

      bool isCurrentlyLiked = false;
      if (userIndex != -1) {
        isCurrentlyLiked = userArticles[userIndex].isLiked ?? false;
      } else if (likedIndex != -1) {
        isCurrentlyLiked = likedArticles[likedIndex].isLiked ?? false;
      }

      final newLikedStatus = !isCurrentlyLiked;

      updateArticleLikeState(articleId, newLikedStatus);

      await _apiProvider.toggleLike(articleId);
      _likeSyncService.updateLikeStatus(articleId, newLikedStatus);

      _syncLikeState(articleId, newLikedStatus);
    } catch (e) {
      fetchUserArticles();
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
