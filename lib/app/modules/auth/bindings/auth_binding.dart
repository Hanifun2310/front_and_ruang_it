import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Menyuntikkan AuthController agar bisa dipakai di View
    Get.lazyPut<AuthController>(
      () => AuthController(),
    );
  }
}