import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../../../data/models/category_model.dart';
import '../../../data/models/article_model.dart' hide CategoryModel;
import '../../../data/providers/api_provider.dart';
import '../../../routes/app_routes.dart';

class TopicRecommendationController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  
  var selectedCategories = <CategoryModel>[].obs;
  var categoryTopAuthors = <int, UserModel?>{}.obs;
  var isLoading = true.obs;

  // Predefined pastel colors matching the design system
  final List<Color> _palette = [
    const Color(0xFFFF8A80), // Red
    const Color(0xFFFFEB3B), // Yellow
    const Color(0xFF98FB98), // Green
    const Color(0xFF80D8FF), // Light Blue
    const Color(0xFFB388FF), // Purple
    const Color(0xFFFF8A65), // Orange
  ];
  
  var backgroundColors = <int, Color>{}.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is List<CategoryModel>) {
      selectedCategories.value = Get.arguments as List<CategoryModel>;
      _assignRandomColors();
      _fetchTopAuthors();
    } else {
      isLoading.value = false;
    }
  }

  void _assignRandomColors() {
    final random = Random();
    for (var category in selectedCategories) {
      backgroundColors[category.id] = _palette[random.nextInt(_palette.length)];
    }
  }

  Future<void> _fetchTopAuthors() async {
    isLoading.value = true;
    
    for (var category in selectedCategories) {
      try {
        // Fetch articles for this category
        final articles = await _apiProvider.getArticles(category: category.name);
        
        if (articles.isNotEmpty) {
          // Count author occurrences
          Map<int, int> authorCounts = {};
          Map<int, UserModel> authorDetails = {};
          
          for (var article in articles) {
            if (article.user != null && article.user!.id != null) {
              int userId = article.user!.id!;
              authorCounts[userId] = (authorCounts[userId] ?? 0) + 1;
              authorDetails[userId] = article.user!;
            }
          }
          
          if (authorCounts.isNotEmpty) {
            // Find author with max count
            int topUserId = authorCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
            categoryTopAuthors[category.id] = authorDetails[topUserId];
          }
        }
      } catch (e) {
        Get.log("Failed to fetch articles for category ${category.name}: $e");
      }
    }
    
    isLoading.value = false;
  }

  void lanjutkan() {
    Get.offAllNamed(Routes.DASHBOARD);
  }
}
