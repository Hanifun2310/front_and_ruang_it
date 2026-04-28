import 'package:get/get.dart';
import '../controllers/article_create_controller.dart';

class ArticleCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ArticleCreateController>(
      () => ArticleCreateController(),
    );
  }
}
