import 'package:get/get.dart';
import '../../../routes/app_routes.dart';

class OnboardingFinishController extends GetxController {
  void goToDashboard() {
    Get.offAllNamed(Routes.DASHBOARD);
  }
}
