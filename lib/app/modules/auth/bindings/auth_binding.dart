import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Use Get.put so the controller isn't disposed during route transitions
    // which can cause TextEditingController to be accessed after dispose.
    Get.put<AuthController>(AuthController());
  }
}
