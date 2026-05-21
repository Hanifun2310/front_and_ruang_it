import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import 'package:flutter_quill/flutter_quill.dart'; // Tambahkan import ini
import '../../../data/models/article_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/like_sync_service.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../explore/controllers/explore_controller.dart';
import '../../search/controllers/search_controller.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/auth_service.dart';

class DashboardController extends GetxController {
  // SENIOR REFACTOR: Gunakan Get.find agar menggunakan satu instance Dio global yang sama
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  // Observables
  var articles = <ArticleModel>[].obs;
  var categories = <CategoryModel>[].obs;
  var selectedCategory = Rxn<CategoryModel>();
  var searchQuery = ''.obs;

  // Pagination states
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

    // SENIOR REFACTOR: WORKER OTOMATIS
    // Kunci sinkronisasi! Setiap kali ada perubahan status like di LikeSyncService (dari halaman mana pun),
    // fungsi di bawah ini akan otomatis berjalan menyinkronkan list artikel di dashboard.
    ever(_likeSyncService.rxLikeEvent, (LikeEvent? event) {
      if (event != null) {
        _handleLocalArticleListSync(event.articleId, event.isLiked);
      }
    });
  }

  // Fungsi internal baru khusus untuk meng-update UI internal list dashboard secara reaktif
  void _handleLocalArticleListSync(int articleId, bool isLiked) {
    final index = articles.indexWhere((a) => a.id == articleId);
    if (index != -1) {
      final article = articles[index];
      if (article.isLiked != isLiked) {
        article.isLiked = isLiked;
        article.likesCount = (article.likesCount ?? 0) + (isLiked ? 1 : -1);
        articles[index] = article; // Perbarui data di dalam list
        articles.refresh();        // Memicu Obx di View untuk gambar ulang layar
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
      // Abaikan jika gagal
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
        // SYNC: Perbarui baseline notifikasi jika ada perubahan status/metrik
        Get.find<NotificationService>().syncArticleMetrics(newArticles);

        // FILTER: Jangan tampilkan artikel terblokir di Dashboard
        final publicArticles = newArticles.where((a) => !a.isBlocked).toList();
        
        articles.addAll(
          _likeSyncService.applyLikeStateToArticles(publicArticles),
        );

        if (publicArticles.isEmpty && newArticles.isNotEmpty) {
          currentPage++;
          // Wait for the recursive call to finish to maintain correct loading state
          await fetchArticles();
          return;
        }

        currentPage++;
      }
    } catch (e) {
      Get.snackbar(
        'Gagal Memuat',
        'Terjadi kesalahan saat mengambil artikel',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      isFetchingMore.value = false;
    }
  }

  // SENIOR REFACTOR: Logika toggleLike Baru yang fully Optimistic & Safe
  Future<void> toggleLike(int articleId) async {

    final index = articles.indexWhere((a) => a.id == articleId);
    if (index == -1) return;

    final article = articles[index];
    final isCurrentlyLiked = article.isLiked ?? false;
    final newLikedState = !isCurrentlyLiked;

    // 1. Simpan ke service utama (Ini memicu worker internal dashboard agar UI langsung berubah instan)
    _likeSyncService.updateLikeStatus(articleId, newLikedState);
    // 2. Jembatan Sementara: Beri tahu controller lain yang BELUM di-refactor agar tidak patah sinkronisasinya
    _syncLikeState(articleId, newLikedState);


    final authService = Get.find<AuthService>();
    if (!authService.isLoggedIn.value) {
      Get.snackbar('Akses Ditolak', 'Anda harus login untuk menyukai artikel.', backgroundColor: Colors.redAccent, colorText: Colors.white);
      Get.toNamed(Routes.LOGIN);
      return;
    }
    if (isLiking.value) return;
    isLiking.value = true;
    try {
      // 3. Eksekusi request API di background
      await _apiProvider.toggleLike(articleId);
    } catch (e) {
      // 4. ROLLBACK: Jika internet putus/gagal, kembalikan ke status semula
      _likeSyncService.updateLikeStatus(articleId, isCurrentlyLiked);
      _syncLikeState(articleId, isCurrentlyLiked);
      Get.snackbar('Gagal', 'Tidak dapat menyukai artikel saat ini, periksa koneksi Anda.');
    }
  }

  // JEMBATAN SEMENTARA: Tetap dipertahankan agar Profile/Explore/Search controller yang lama 
  // tidak error saat mereka memanggil fungsi ini sebelum mereka di-refactor.
  void updateArticleLikeState(int articleId, bool isLiked) {
    // Alihkan langsung ke pusat data tunggal
    _likeSyncService.updateLikeStatus(articleId, isLiked);
  }

  // JEMBATAN SEMENTARA: Tetap dipertahankan agar halaman lain yang belum menggunakan worker
  // tetap bisa ter-update ketika Dashboard melakukan toggle like.
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

  // --- FUNGSI MENGUBAH JSON MENJADI TEKS PREVIEW ---
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
        Get.snackbar('Sukses', 'Artikel berhasil dihapus');

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
      Get.snackbar('Error', 'Gagal menghapus artikel');
    }
  }
}