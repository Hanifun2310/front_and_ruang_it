import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/models/article_model.dart';

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
    final user = _authService.currentUser;
    if (user != null) {
      name.value = user['name'] ?? "User";
      nameController.text = user['name'] ?? "";
      profession.value = user['profession'] ?? "";
      professionController.text = user['profession'] ?? "";
      bio.value = user['bio'] ?? "";
      bioController.text = user['bio'] ?? "";
      email.value = user['email'] ?? "";
      photoProfile.value = ArticleModel.formatImageUrl(user['photo_profile'] ?? user['profile_photo']);
      userId.value = user['id'] ?? 0;
      
      // Update stats if available in user object
      articlesCount.value = user['articles_count'] ?? 0;
      likesCount.value = user['likes_count'] ?? 0;
      commentsCount.value = user['comments_count'] ?? 0;
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
         userArticles.value = articles.where((a) => a.user?.name == name.value).toList();
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
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> updatedUser = response.data['data'];
        await _authService.box.write('user', updatedUser);
        
        // Refresh local observable state
        loadUserData();
        
        Get.snackbar('Sukses', 'Profil berhasil diperbarui');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memperbarui profil');
    } finally {
      isLoading.value = false;
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