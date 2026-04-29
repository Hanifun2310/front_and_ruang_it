import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/models/article_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ProfileController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final AuthService _authService = Get.find<AuthService>();

  var isLoading = false.obs;
  var isArticlesLoading = false.obs;

  // Controllers sesuai field di Laravel
  final nameController = TextEditingController();
  final professionController = TextEditingController();
  final bioController = TextEditingController();
  var email = "".obs;
  var photoProfile = "".obs;
  var profession = "".obs;
  var bio = "".obs;
  var name = "".obs;
  var userId = 0.obs;

  // Image Picking
  final ImagePicker _picker = ImagePicker();
  var selectedImagePath = "".obs;
  var selectedImageBytes = <int>[].obs;
  var selectedFileName = "".obs;

  // Articles & Tabs
  var userArticles = <ArticleModel>[].obs;
  var selectedTab = 0.obs;

  // Stats (Mocked or from User data)
  var articlesCount = 0.obs;
  var likesCount = 0.obs;
  var commentsCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    fetchUserArticles();
  }

  void loadUserData() {
    final userData = _authService.currentUser;
    if (userData != null) {
      // Use UserModel for consistent parsing and image formatting
      final user = UserModel.fromJson(userData);

      name.value = user.name ?? "User";
      nameController.text = user.name ?? "";
      profession.value = user.profession ?? "";
      professionController.text = user.profession ?? "";
      bio.value = user.bio ?? "";
      bioController.text = user.bio ?? "";
      email.value = user.email ?? "";
      photoProfile.value =
          user.photoProfile ?? ArticleModel.formatImageUrl(null);
      userId.value = user.id ?? 0;

      // Update stats if available in raw user object
      articlesCount.value = userData['articles_count'] ?? 0;
      likesCount.value = userData['likes_count'] ?? 0;
      commentsCount.value = userData['comments_count'] ?? 0;
    }
  }

  Future<void> fetchUserArticles() async {
    isArticlesLoading.value = true;
    try {
      // Assuming getArticles with user's name as search might work as a fallback
      // or if there's no specific my-articles endpoint.
      // For now, let's just get the first page of all articles as a placeholder
      // if we don't have a specific endpoint.
      final articles = await _apiProvider.getArticles(page: 1);

      // Filter articles by user name if we have it
      if (name.value.isNotEmpty) {
        userArticles.value = articles
            .where((a) => a.user?.name == name.value)
            .toList();
      } else {
        userArticles.value = articles;
      }

      // Update count if it was 0
      if (articlesCount.value == 0) {
        articlesCount.value = userArticles.length;
      }
    } catch (e) {
      print('Error fetching user articles: $e');
    } finally {
      isArticlesLoading.value = false;
    }
  }

  Future<void> updateProfile() async {
    isLoading.value = true;
    try {
      final response = await _apiProvider.updateProfile(
        name: nameController.text,
        profession: professionController.text,
        bio: bioController.text,
        // Tetap kirim path untuk mobile jika ada, tapi utamakan bytes jika tersedia di ApiProvider
        imagePath: !kIsWeb && selectedImagePath.value.isNotEmpty
            ? selectedImagePath.value
            : null,
        imageBytes: selectedImageBytes.isNotEmpty
            ? selectedImageBytes.toList()
            : null,
        fileName: selectedFileName.value.isNotEmpty
            ? selectedFileName.value
            : null,
      );

      if (response.statusCode == 200) {
        print('UPDATE PROFILE RESPONSE: ${response.data}');

        // Ambil data user, tangani jika dibungkus 'data', 'user', atau tidak
        final dynamic responseData =
            response.data['data'] ?? response.data['user'] ?? response.data;

        if (responseData is Map<String, dynamic>) {
          // Merge data lama dengan data baru agar stats tidak hilang jika API tidak mengirimnya kembali
          final Map<String, dynamic> oldData = Map<String, dynamic>.from(
            _authService.currentUser ?? {},
          );
          final Map<String, dynamic> newData = Map<String, dynamic>.from(
            responseData,
          );

          // Gabungkan: newData akan menimpa oldData
          final mergedData = {...oldData, ...newData};

          await _authService.box.write('user', mergedData);

          // Refresh local observable state
          loadUserData();

          // Reset selection
          selectedImagePath.value = "";
          selectedImageBytes.clear();
          selectedFileName.value = "";

          Get.snackbar('Sukses', 'Profil berhasil diperbarui');
        }
      }
    } catch (e) {
      print('Error update profile: $e');
      Get.snackbar('Error', 'Gagal memperbarui profil');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        selectedImagePath.value = image.path;
        // Baca bytes untuk semua platform agar konsisten dengan logic Article
        selectedImageBytes.assignAll(await image.readAsBytes());
        selectedFileName.value = image.name;
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memilih gambar');
    }
  }

  Future<void> deleteArticle(int id) async {
    try {
      final response = await _apiProvider.deleteArticle(id);
      if (response.statusCode == 200 || response.statusCode == 204) {
        userArticles.removeWhere((article) => article.id == id);
        articlesCount.value--;
        Get.snackbar('Sukses', 'Artikel berhasil dihapus');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus artikel');
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}
