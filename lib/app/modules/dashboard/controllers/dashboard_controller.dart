import 'package:get/get.dart';
import '../../../data/models/article_model.dart';
import '../../../data/providers/api_provider.dart';

class DashboardController extends GetxController {
  // Inisialisasi ApiProvider
  final ApiProvider _apiProvider = ApiProvider();

  // Observables
  var articles = <ArticleModel>[].obs;
  var categories = <String>['Semua', 'Tech', 'Laravel', 'Flutter', 'IoT'].obs;
  var selectedCategory = 'Semua'.obs;
  
  // Pagination states
  var isLoading = false.obs;       
  var isFetchingMore = false.obs;  
  var currentPage = 1;
  var hasMoreData = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchArticles();
  }

  void changeCategory(String category) {
    if (selectedCategory.value == category) return; // Jangan fetch ulang jika kategori sama
    
    selectedCategory.value = category;
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
        category: selectedCategory.value,
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

  void loadMoreArticles() {
    if (!isLoading.value && !isFetchingMore.value && hasMoreData.value) {
      fetchArticles();
    }
  }
}