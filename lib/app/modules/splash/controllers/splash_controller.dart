import 'package:get/get.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToDashboard();
  }

  Future<void> _navigateToDashboard() async {
    // Extended delay to allow the light theme animations to fully show off
    await Future.delayed(const Duration(milliseconds: 5000));
    Get.offAllNamed(Routes.DASHBOARD);
  }
}
