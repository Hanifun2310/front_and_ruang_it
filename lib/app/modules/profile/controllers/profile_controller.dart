import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/providers/api_provider.dart';

class ProfileController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final AuthService _authService = Get.find<AuthService>();

  var isLoading = false.obs;
  
  // Controllers sesuai field di Laravel
  final nameController = TextEditingController();
  final professionController = TextEditingController();
  final bioController = TextEditingController();
  var email = "".obs;
  var photoProfile = "".obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  void loadUserData() {
    // Ambil data dari sesi yang tersimpan di GetStorage
    final user = _authService.currentUser;
    if (user != null) {
      nameController.text = user['name'] ?? "";
      professionController.text = user['profession'] ?? "";
      bioController.text = user['bio'] ?? "";
      email.value = user['email'] ?? "";
      photoProfile.value = user['photo_profile'] ?? "";
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
        // Update data user di lokal storage agar UI dashboard ikut berubah
        Map<String, dynamic> updatedUser = response.data['data'];
        await _authService.box.write('user', updatedUser);
        
        Get.snackbar('Sukses', 'Profil berhasil diperbarui');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memperbarui profil');
    } finally {
      isLoading.value = false;
    }
  }
}