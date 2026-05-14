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
  var topArticles = <int, ArticleModel?>{}.obs;
  var isLoading = true.obs;
  var currentIndex = 0.obs;
  final PageController pageController = PageController();

  // Predefined pastel colors matching the design system
  final List<Color> _palette = [
    const Color(0xFFFFEB3B), // Yellow
    const Color(0xFFFF8A80), // Red
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
      _fetchPopularArticles();
    } else {
      isLoading.value = false;
    }
  }

  void _assignRandomColors() {
    for (int i = 0; i < selectedCategories.length; i++) {
      final category = selectedCategories[i];
      backgroundColors[category.id!] = _palette[i % _palette.length];
    }
  }

  Future<void> _fetchPopularArticles() async {
    isLoading.value = true;
    
    for (var category in selectedCategories) {
      try {
        // Fetch articles for this category
        final articles = await _apiProvider.getArticles(category: category.name);
        
        if (articles.isNotEmpty) {
          // Sort by likesCount descending and take first
          articles.sort((a, b) => (b.likesCount ?? 0).compareTo(a.likesCount ?? 0));
          topArticles[category.id!] = articles.first;
        } else {
          topArticles[category.id!] = null;
        }
      } catch (e) {
        Get.log("Failed to fetch popular article for category ${category.name}: $e");
        topArticles[category.id!] = null;
      }
    }
    
    isLoading.value = false;
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
  }

  void lanjutkan() {
    if (currentIndex.value < selectedCategories.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Get.offAllNamed(Routes.ONBOARDING_FINISH);
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
