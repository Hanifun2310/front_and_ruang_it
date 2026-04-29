import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/models/article_model.dart';

class ArticleEditController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  
  late ArticleModel article;
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  
  final Rx<XFile?> selectedImage = Rx<XFile?>(null);
  final RxInt selectedCategoryId = 0.obs;
  final RxBool isLoading = false.obs;
  final RxList<dynamic> categories = <dynamic>[].obs;
  final RxString currentImageUrl = "".obs;

  @override
  void onInit() {
    super.onInit();
    print("Initializing ArticleEditController with arguments: ${Get.arguments}");
    article = Get.arguments as ArticleModel;
    
    // Pre-fill data
    titleController.text = article.title ?? "";
    contentController.text = (article.content ?? "").replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
    selectedCategoryId.value = article.category?.id ?? 0;
    currentImageUrl.value = article.imageUrl ?? "";

    fetchCategories();
  }

  // Remove _stripHtmlTags function as we use regex directly for simplicity

  Future<void> fetchCategories() async {
    try {
      final response = await _apiProvider.getCategories();
      if (response.statusCode == 200) {
        categories.value = response.data['data'] ?? response.data;
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImage.value = image;
    }
  }

  Future<void> updateArticle() async {
    if (titleController.text.isEmpty || contentController.text.isEmpty || selectedCategoryId.value == 0) {
      Get.snackbar('Error', 'Judul, konten, dan kategori harus diisi');
      return;
    }

    isLoading.value = true;
    try {
      List<int>? imageBytes;
      String? fileName;
      
      if (selectedImage.value != null) {
        imageBytes = await selectedImage.value!.readAsBytes();
        fileName = selectedImage.value!.name;
      }

      final response = await _apiProvider.updateArticle(
        id: article.id!,
        title: titleController.text,
        content: contentController.text,
        categoryId: selectedCategoryId.value,
        imageBytes: imageBytes,
        fileName: fileName,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back(result: true); // Return true to indicate success
        Get.snackbar('Sukses', 'Artikel berhasil diperbarui');
      } else {
        Get.snackbar('Gagal', 'Gagal memperbarui artikel: ${response.statusMessage}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    contentController.dispose();
    super.onClose();
  }
}
