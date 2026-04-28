import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/providers/api_provider.dart';

class ArticleCreateController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  
  final Rx<XFile?> selectedImage = Rx<XFile?>(null);
  final RxInt selectedCategoryId = 0.obs;
  final RxBool isLoading = false.obs;
  final RxList<dynamic> categories = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

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

  Future<void> publishArticle() async {
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

      final response = await _apiProvider.createArticle(
        title: titleController.text,
        content: contentController.text,
        categoryId: selectedCategoryId.value,
        imageBytes: imageBytes,
        fileName: fileName,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        Get.snackbar('Sukses', 'Artikel berhasil diterbitkan');
      } else {
        Get.snackbar('Gagal', 'Gagal menerbitkan artikel: ${response.statusMessage}');
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
