import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../data/models/article_model.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../explore/controllers/explore_controller.dart';
import '../../search/controllers/search_controller.dart';
import '../../../data/services/auth_service.dart';

class ArticleDetailController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  
  // Ambil identifier (slug/id) dari argument navigasi
  final String identifier = Get.arguments?.toString() ?? "";

  var article = ArticleModel().obs;
  var comments = <CommentModel>[].obs;
  var isLoading = true.obs;
  var isLiking = false.obs;

  // Controller untuk membaca format Quill
  QuillController? quillController;
  final commentController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadDetail();
  }

  Future<void> loadDetail() async {
    try {
      isLoading.value = true;
      // 1. Ambil Detail Artikel
      article.value = await _apiProvider.getArticleDetail(identifier);
      
      // Keamanan: Jika artikel diblokir, hanya penulis yang bisa lihat
      if (article.value.isBlocked) {
        final authService = Get.find<AuthService>();
        final currentUserId = authService.currentUser?['id'];
        if (article.value.user?.id != currentUserId) {
          Get.back();
          Get.snackbar('Akses Terbatas', 'Artikel ini sedang diblokir.');
          return;
        }
      }

      // Inisialisasi Quill Controller setelah data artikel didapat
      _initQuillController(article.value.content ?? "");
      // 2. Ambil Komentar
      if (article.value.id != null) {
        await fetchComments();
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat detail artikel');
    } finally {
      isLoading.value = false;
    }
  }

  // Fungsi pintar untuk membaca JSON Quill atau teks biasa
  void _initQuillController(String content) {
    try {
      // Cek apakah content berupa list json (Quill format)
      if (content.trim().startsWith('[')) {
        final deltaJson = jsonDecode(content);
        quillController = QuillController(
          document: Document.fromJson(deltaJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } else {
        quillController = null; // Biarkan null agar menggunakan HtmlWidget
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
      }
    } catch (e) {
      print("Error comments: $e");
    }
  }

  // LOGIKA LIKE
  Future<void> toggleLike() async {
    if (isLiking.value) return;
    isLiking.value = true;
    try {
      final response = await _apiProvider.toggleLike(article.value.id!);
      if (response.statusCode == 200) {
        // Update UI secara lokal agar responsif
        bool currentStatus = article.value.isLiked ?? false;
        article.update((val) {
          val!.isLiked = !currentStatus;
          val.likesCount = currentStatus 
              ? (val.likesCount! - 1) 
              : (val.likesCount! + 1);
        });

        // SYNC: Update DashboardController if registered
        try {
          if (Get.isRegistered<DashboardController>()) {
            Get.find<DashboardController>().updateArticleLikeState(
              article.value.id!, 
              !currentStatus
            );
          }
          if (Get.isRegistered<ProfileController>()) {
            Get.find<ProfileController>().updateArticleLikeState(
              article.value.id!, 
              !currentStatus
            );
          }
          if (Get.isRegistered<ExploreController>()) {
            Get.find<ExploreController>().updateArticleLikeState(
              article.value.id!, 
              !currentStatus
            );
          }
          if (Get.isRegistered<ArticleSearchController>()) {
            Get.find<ArticleSearchController>().updateArticleLikeState(
              article.value.id!, 
              !currentStatus
            );
          }
        } catch (e) {
          // Ignore sync errors
        }
      }
    } catch (e) {
      Get.snackbar('Oops', 'Gagal memberikan Like');
    } finally {
      isLiking.value = false;
    }
  }

  // LOGIKA POST KOMENTAR
  Future<void> sendComment() async {
    if (commentController.text.isEmpty) return;

    try {
      final response = await _apiProvider.postComment(
        article.value.id!, 
        commentController.text
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        commentController.clear();
        fetchComments(); // Refresh list komentar
        Get.snackbar('Sukses', 'Komentar terkirim');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengirim komentar');
    }
  }

  // LOGIKA UPDATE KOMENTAR
  Future<void> updateComment(int commentId, String content) async {
    try {
      final response = await _apiProvider.updateComment(commentId, content);
      if (response.statusCode == 200) {
        fetchComments(); // Refresh list komentar
        Get.snackbar('Sukses', 'Komentar berhasil diperbarui');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memperbarui komentar');
    }
  }

  // LOGIKA HAPUS KOMENTAR
  Future<void> deleteComment(int commentId) async {
    try {
      final response = await _apiProvider.deleteComment(commentId);
      if (response.statusCode == 200) {
        fetchComments(); // Refresh list komentar
        Get.snackbar('Sukses', 'Komentar berhasil dihapus');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus komentar');
    }
  }
}
