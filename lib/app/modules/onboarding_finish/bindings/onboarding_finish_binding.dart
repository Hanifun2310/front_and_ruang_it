import 'package:get/get.dart';
import '../controllers/onboarding_finish_controller.dart';

class OnboardingFinishBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingFinishController>(
      () => OnboardingFinishController(),
    );
  }
}
