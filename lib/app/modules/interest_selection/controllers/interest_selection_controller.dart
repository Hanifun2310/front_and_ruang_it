import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../data/models/category_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../routes/app_routes.dart';

class InterestSelectionController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  
  var isLoading = true.obs;
  var categories = <CategoryModel>[].obs;
  var selectedCategoryIds = <int>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      final response = await _apiProvider.getCategories();
      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'] ?? response.data;
        categories.value = data.map((e) => CategoryModel.fromJson(e)).toList();
      }
    } catch (e) {
      Get.snackbar(
        'Error', 
        'Gagal memuat kategori.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void toggleSelection(int id) {
    if (selectedCategoryIds.contains(id)) {
      selectedCategoryIds.remove(id);
    } else {
      selectedCategoryIds.add(id);
    }
  }

  void lanjutkan() {
    if (selectedCategoryIds.length < 3) {
      Get.snackbar(
        'Perhatian', 
        'Pilih minimal 3 topik atau lebih',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    
    // Filter categories that are selected to pass them
    final selectedCategoriesList = categories.where((c) => selectedCategoryIds.contains(c.id)).toList();
    Get.toNamed(Routes.TOPIC_RECOMMENDATION, arguments: selectedCategoriesList);
  }
}
