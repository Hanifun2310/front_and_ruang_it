import 'package:get/get.dart';
import '../controllers/topic_recommendation_controller.dart';

class TopicRecommendationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TopicRecommendationController>(
      () => TopicRecommendationController(),
    );
  }
}
