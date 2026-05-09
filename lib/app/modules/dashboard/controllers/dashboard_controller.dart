import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart'; // Tambahkan import ini
import '../../../data/models/article_model.dart';
import '../../../data/providers/api_provider.dart';

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
        List<CategoryModel> fetchedCategories = data.map((e) => CategoryModel.fromJson(e)).toList();
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
        articles.addAll(newArticles);
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
    try {
      final index = articles.indexWhere((a) => a.id == articleId);
      if (index == -1) return;

      final article = articles[index];
      final isCurrentlyLiked = article.isLiked ?? false;
      
      // Optimistic update
      article.isLiked = !isCurrentlyLiked;
      article.likesCount = (article.likesCount ?? 0) + (isCurrentlyLiked ? -1 : 1);
      
      articles[index] = article; // trigger reactivity
      
      await _apiProvider.toggleLike(articleId);
    } catch (e) {
      final index = articles.indexWhere((a) => a.id == articleId);
      if (index != -1) {
        final article = articles[index];
        final isCurrentlyLiked = article.isLiked ?? false;
        // Revert
        article.isLiked = !isCurrentlyLiked;
        article.likesCount = (article.likesCount ?? 0) + (isCurrentlyLiked ? -1 : 1);
        articles[index] = article;
      }
      Get.snackbar('Gagal', 'Tidak dapat menyukai artikel saat ini');
    }
  }

  void loadMoreArticles() {
    if (!isLoading.value && !isFetchingMore.value && hasMoreData.value) {
      fetchArticles();
    }
  }

  // --- FUNGSI BARU UNTUK MENGUBAH JSON MENJADI TEKS PREVIEW ---
  String getSnippetText(String? content) {
    if (content == null || content.trim().isEmpty) return 'Tidak ada ringkasan...';

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
}