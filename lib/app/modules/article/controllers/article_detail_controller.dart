import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/models/article_model.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/like_sync_service.dart';
import '../../../data/services/auth_service.dart';

import '../../dashboard/controllers/dashboard_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../explore/controllers/explore_controller.dart';
import '../../search/controllers/search_controller.dart';

import '../../../data/services/notification_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/custom_snackbar.dart';

class ArticleDetailController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final LikeSyncService _likeSyncService = Get.find<LikeSyncService>();
  
  final String identifier = Get.arguments?.toString() ?? "";

  var article = ArticleModel().obs;
  var comments = <CommentModel>[].obs;
  var isLoading = true.obs;
  var isLiking = false.obs;

  QuillController? quillController;
  final commentController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  var readingProgress = 0.0.obs;
  var isCommenting = false.obs;
  
  var rxIsLiked = false.obs;
  var rxLikesCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadDetail();

    scrollController.addListener(() {
      if (scrollController.hasClients) {
        final maxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.position.pixels;
        if (maxScroll > 0) {
          readingProgress.value = (currentScroll / maxScroll).clamp(0.0, 1.0);
        }
      }
    });

    ever(_likeSyncService.rxLikeEvent, (LikeEvent? event) {
      if (event != null && article.value.id == event.articleId) {
        if (rxIsLiked.value != event.isLiked) {
          rxIsLiked.value = event.isLiked;
          rxLikesCount.value += event.isLiked ? 1 : -1;
        }
      }
    });
  }

  Future<void> loadDetail() async {
    try {
      isLoading.value = true;
      article.value = await _apiProvider.getArticleDetail(identifier);
      
      rxIsLiked.value = article.value.isLiked ?? false;
      rxLikesCount.value = article.value.likesCount ?? 0;
      
      Get.find<NotificationService>().syncArticleMetrics([article.value]);
      
      if (article.value.isBlocked) {
        Get.back();
        showCustomSnackbar(
          'Akses Terbatas',
          'Artikel ini tidak dapat diakses karena artikel atau penulis telah diblokir. Silakan baca panduan penulisan kami.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          mainButton: TextButton(
            onPressed: () => Get.toNamed(Routes.GUIDELINES),
            child: const Text(
              'PANDUAN',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
        return;
      }

      if (article.value.id != null) {
        final box = GetStorage();
        final key = 'article_views_${article.value.id}';
        int currentViews = box.read<int>(key) ?? article.value.viewsCount ?? 0;
        currentViews += 1;
        box.write(key, currentViews);
        article.update((val) {
          val!.viewsCount = currentViews;
        });
      }

      _initQuillController(article.value.content ?? "");
      if (article.value.id != null) {
        await fetchComments();
        Get.find<NotificationService>().syncCommentStatus(comments);
        _syncArticleMetricsToOtherControllers();
      }
    } catch (e) {
      showCustomSnackbar('Error', 'Gagal memuat detail artikel');
    } finally {
      isLoading.value = false;
    }
  }

  void _initQuillController(String content) {
    try {
      if (content.trim().startsWith('[')) {
        final deltaJson = jsonDecode(content);
        quillController = QuillController(
          document: Document.fromJson(deltaJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } else {
        quillController = null;
      }
    } catch (e) {
      quillController = null;
    }
  }

  Future<void> fetchComments() async {
    try {
      final response = await _apiProvider.getComments(article.value.id!);
      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'] ?? response.data;
        comments.value = data.map((e) => CommentModel.fromJson(e)).toList();
        
        article.update((val) {
          val!.commentsCount = comments.length;
        });
        _syncArticleMetricsToOtherControllers();
      }
    } catch (e) {
      print("Error comments: $e");
    }
  }

  Future<void> toggleLike() async {
    if (article.value.id == null || isLiking.value) return;

    final authService = Get.find<AuthService>();
    if (!authService.isLoggedIn.value) {
      showCustomSnackbar('Akses Ditolak', 'Anda harus login untuk menyukai artikel.', backgroundColor: Colors.redAccent, colorText: Colors.white);
      Get.toNamed(Routes.LOGIN);
      return;
    }

    if (isLiking.value) return;

    isLiking.value = true;

    final articleId = article.value.id!;
    final isCurrentlyLiked = rxIsLiked.value;
    final newLikedState = !isCurrentlyLiked;

    _likeSyncService.updateLikeStatus(articleId, newLikedState);

    // Update local state immediately for fast feedback
    rxIsLiked.value = newLikedState;
    rxLikesCount.value += newLikedState ? 1 : -1;

    try {
      await _apiProvider.toggleLike(articleId);
    } catch (e) {
      _likeSyncService.updateLikeStatus(articleId, isCurrentlyLiked);
      rxIsLiked.value = isCurrentlyLiked;
      rxLikesCount.value += isCurrentlyLiked ? 1 : -1;
      showCustomSnackbar('Oops', 'Gagal memperbarui status Like, silakan periksa koneksi internet Anda.');
    } finally {
      isLiking.value = false;
    }
  }

  Future<void> sendComment() async {
    final authService = Get.find<AuthService>();
    if (!authService.isLoggedIn.value) {
      showCustomSnackbar('Akses Ditolak', 'Anda harus login untuk berkomentar.', backgroundColor: Colors.redAccent, colorText: Colors.white);
      Get.toNamed(Routes.LOGIN);
      return;
    }

    if (commentController.text.isEmpty || isCommenting.value) return;

    isCommenting.value = true;
    try {
      final response = await _apiProvider.postComment(
        article.value.id!, 
        commentController.text
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        commentController.clear();
        FocusManager.instance.primaryFocus?.unfocus();
        await fetchComments();
        showCustomSnackbar('Sukses', 'Komentar terkirim');
      }
    } catch (e) {
      showCustomSnackbar('Error', 'Gagal mengirim komentar');
    } finally {
      isCommenting.value = false;
    }
  }

  Future<void> updateComment(int commentId, String content) async {
    try {
      final response = await _apiProvider.updateComment(commentId, content);
      if (response.statusCode == 200) {
        fetchComments();
        showCustomSnackbar('Sukses', 'Komentar berhasil diperbarui');
      }
    } catch (e) {
      showCustomSnackbar('Error', 'Gagal memperbarui komentar');
    }
  }

  Future<void> deleteComment(int commentId) async {
    try {
      final response = await _apiProvider.deleteComment(commentId);
      if (response.statusCode == 200) {
        fetchComments();
        showCustomSnackbar('Sukses', 'Komentar berhasil dihapus');
      }
    } catch (e) {
      showCustomSnackbar('Error', 'Gagal menghapus komentar');
    }
  }

  void _syncArticleMetricsToOtherControllers() {
    final artId = article.value.id;
    if (artId == null) return;
    final views = article.value.viewsCount ?? 0;
    final commentsCnt = article.value.commentsCount ?? 0;
    _syncMetrics(artId, views, commentsCnt);
  }

  void _syncMetrics(int articleId, int viewsCount, int commentsCount) {
    try {
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().updateArticleMetrics(articleId, viewsCount, commentsCount);
      }
    } catch (_) {}
    try {
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().updateArticleMetrics(articleId, viewsCount, commentsCount);
      }
    } catch (_) {}
    try {
      if (Get.isRegistered<ExploreController>()) {
        Get.find<ExploreController>().updateArticleMetrics(articleId, viewsCount, commentsCount);
      }
    } catch (_) {}
    try {
      if (Get.isRegistered<ArticleSearchController>()) {
        Get.find<ArticleSearchController>().updateArticleMetrics(articleId, viewsCount, commentsCount);
      }
    } catch (_) {}
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}