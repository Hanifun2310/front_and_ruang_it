import 'package:get/get.dart';
import '../controllers/interest_selection_controller.dart';

class InterestSelectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InterestSelectionController>(
      () => InterestSelectionController(),
    );
  }
}
