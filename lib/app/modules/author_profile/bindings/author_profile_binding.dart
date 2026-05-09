import 'package:get/get.dart';
import '../controllers/author_profile_controller.dart';

class AuthorProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthorProfileController>(
      () => AuthorProfileController(),
    );
  }
}
