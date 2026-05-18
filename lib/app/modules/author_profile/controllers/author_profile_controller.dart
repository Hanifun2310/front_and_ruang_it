import 'package:get/get.dart';
import '../../../data/models/article_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/like_sync_service.dart';

class AuthorProfileController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final LikeSyncService _likeSyncService = Get.find<LikeSyncService>();

  late UserModel author;
  var isArticlesLoading = true.obs;
  
  var userArticles = <ArticleModel>[].obs;
  
  var articlesCount = 0.obs;
  var likesCount = 0.obs;
  var commentsCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      author = Get.arguments as UserModel;
      fetchAuthorArticles();
    } else {
      isArticlesLoading.value = false;
    }
  }

  Future<void> fetchAuthorArticles() async {
    isArticlesLoading.value = true;
    try {
      List<ArticleModel> allFetchedArticles = [];
      int currentPage = 1;

      // Fetch pages to ensure we get articles for this author
      while (true) {
        final articles = await _apiProvider.getArticles(page: currentPage);
        if (articles.isEmpty) break;
        
        allFetchedArticles.addAll(articles);
        if (currentPage >= 10) break; // Safety limit
        currentPage++;
      }

      allFetchedArticles = _likeSyncService.applyLikeStateToArticles(allFetchedArticles);

      userArticles.value = allFetchedArticles
          .where((a) => a.user?.id == author.id && !a.isBlocked)
          .toList();

      // Compute stats dynamically
      int totalLikes = 0;
      int totalComments = 0;
      for (var article in userArticles) {
        totalLikes += article.likesCount ?? 0;
        totalComments += article.commentsCount ?? 0;
      }
      
      likesCount.value = totalLikes;
      commentsCount.value = totalComments;
      articlesCount.value = userArticles.length;
      
    } catch (e) {
      print('Error fetching author articles: $e');
    } finally {
      isArticlesLoading.value = false;
    }
  }

  Future<void> toggleLike(int articleId) async {
    try {
      final userIndex = userArticles.indexWhere((a) => a.id == articleId);
      if (userIndex == -1) return;

      final article = userArticles[userIndex];
      final isCurrentlyLiked = article.isLiked ?? false;
      final newLikedStatus = !isCurrentlyLiked;

      // Optimistic update
      article.isLiked = newLikedStatus;
      article.likesCount = (article.likesCount ?? 0) + (newLikedStatus ? 1 : -1);
      userArticles[userIndex] = article;
      userArticles.refresh();

      _likeSyncService.updateLikeStatus(articleId, newLikedStatus);
      await _apiProvider.toggleLike(articleId);
    } catch (e) {
      fetchAuthorArticles(); // Revert on error
    }
  }
}
