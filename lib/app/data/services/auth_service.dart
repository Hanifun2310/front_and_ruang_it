import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../routes/app_routes.dart';
import 'like_sync_service.dart';

class AuthService extends GetxService {
  final box = GetStorage();
  
  final RxBool isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  void checkLoginStatus() {
    String? token = box.read('token');
    if (token != null && token.isNotEmpty) {
      isLoggedIn.value = true;
    }
  }

  Future<void> saveSession(String token, Map<String, dynamic> userData) async {
    await box.write('token', token);
    await box.write('user', userData);
    isLoggedIn.value = true;
  }

  Future<void> logout() async {
    await box.remove('token');
    await box.remove('user');
    isLoggedIn.value = false;
    
    try {
      if (Get.isRegistered<LikeSyncService>()) {
        Get.find<LikeSyncService>().clearAll();
      }
    } catch (_) {}
    
    Get.offAllNamed(Routes.DASHBOARD);
  }

  String? get token => box.read('token');
  Map<String, dynamic>? get currentUser => box.read('user');
}
