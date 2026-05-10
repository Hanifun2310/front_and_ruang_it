import 'package:get/get.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/article_model.dart' hide CategoryModel;
import '../../../data/providers/api_provider.dart';

class CategoryDetailController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  late CategoryModel category;
  UserModel? author;
  
  var isLoading = true.obs;
  var authorArticles = <ArticleModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      category = Get.arguments['category'] as CategoryModel;
      author = Get.arguments['author'] as UserModel?;
      fetchAuthorArticles();
    } else {
      isLoading.value = false;
    }
  }

  Future<void> fetchAuthorArticles() async {
    if (author == null) {
      isLoading.value = false;
      return;
    }
    
    try {
      isLoading.value = true;
      final response = await _apiProvider.getArticles(category: category.name);
      // Filter dynamically: get articles belonging to this specific author
      authorArticles.value = response.where((a) => a.user?.id == author!.id && !a.isBlocked).toList();
    } catch (e) {
      Get.log("Failed to fetch author articles: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
