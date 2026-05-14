import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart'; // Tambahkan import ini
import '../../../data/models/article_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../explore/controllers/explore_controller.dart';
import '../../search/controllers/search_controller.dart';

class DashboardController extends GetxController {
  // Inisialisasi ApiProvider
  final ApiProvider _apiProvider = ApiProvider();

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
      // Menggunakan ApiProvider yang sesungguhnya!
      List<ArticleModel> newArticles = await _apiProvider.getArticles(
        page: currentPage,
        category: selectedCategory.value?.id.toString(),
        search: searchQuery.value,
      );

      if (newArticles.isEmpty) {
        hasMoreData.value = false;
      } else {
        // FILTER: Jangan tampilkan artikel terblokir di Dashboard
        final publicArticles = newArticles.where((a) => !a.isBlocked).toList();
        articles.addAll(publicArticles);

        // Jika semua artikel di halaman ini terblokir, tapi masih ada data di server,
        // kita mungkin perlu fetch page berikutnya secara otomatis, tapi untuk
        // simplifikasi kita biarkan pagination berjalan normal.
        if (publicArticles.isEmpty && newArticles.isNotEmpty) {
          currentPage++;
          fetchArticles();
          return;
        }

        currentPage++;
      }
    } catch (e) {
      // Jika terjadi error (misal server mati), tampilkan snackbar
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

  Future<void> toggleLike(int articleId) async {
    if (isLiking.value) return;
    isLiking.value = true;
    try {
      final index = articles.indexWhere((a) => a.id == articleId);
      if (index == -1) return;

      final article = articles[index];
      final isCurrentlyLiked = article.isLiked ?? false;

      // Optimistic update
      article.isLiked = !isCurrentlyLiked;
      article.likesCount =
          (article.likesCount ?? 0) + (isCurrentlyLiked ? -1 : 1);

      articles[index] = article; // trigger reactivity
      articles.refresh();

      await _apiProvider.toggleLike(articleId);

      // SYNC: Update other controllers
      _syncLikeState(articleId, !isCurrentlyLiked);
    } catch (e) {
      final index = articles.indexWhere((a) => a.id == articleId);
      if (index != -1) {
        final article = articles[index];
        final isCurrentlyLiked = article.isLiked ?? false;
        // Revert
        article.isLiked = !isCurrentlyLiked;
        article.likesCount =
            (article.likesCount ?? 0) + (isCurrentlyLiked ? -1 : 1);
        articles[index] = article;
        articles.refresh();
      }
      Get.snackbar('Gagal', 'Tidak dapat menyukai artikel saat ini');
    } finally {
      isLiking.value = false;
    }
  }

  // Sync method for other controllers to update state
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

  // --- FUNGSI BARU UNTUK MENGUBAH JSON MENJADI TEKS PREVIEW ---
  String getSnippetText(String? content) {
    if (content == null || content.trim().isEmpty)
      return 'Tidak ada ringkasan...';

    try {
      // Cek apakah ini format JSON dari Quill
      if (content.trim().startsWith('[')) {
        final deltaJson = jsonDecode(content);
        final document = Document.fromJson(deltaJson);
        // Ambil teks asli dan ubah "enter" menjadi "spasi"
        return document.toPlainText().replaceAll('\n', ' ').trim();
      }
      // Fallback untuk artikel lama yang mungkin pakai HTML
      return content.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
    } catch (e) {
      // Jika error, bersihkan sebisa mungkin
      return content.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
    }
  }

  Future<void> deleteArticle(int id) async {
    try {
      final response = await _apiProvider.deleteArticle(id);
      if (response.statusCode == 200 || response.statusCode == 204) {
        articles.removeWhere((article) => article.id == id);
        Get.snackbar('Sukses', 'Artikel berhasil dihapus');

        // SYNC: Update ProfileController if registered
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
