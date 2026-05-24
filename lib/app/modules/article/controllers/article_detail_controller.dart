import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/models/article_model.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/like_sync_service.dart'; // Pastikan import service ini ada
import '../../../data/services/auth_service.dart';

// Import controller lain tidak wajib lagi jika tidak dipakai, tapi biarkan saja agar tidak ada error di file lain
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../explore/controllers/explore_controller.dart';
import '../../search/controllers/search_controller.dart';


import '../../../data/services/notification_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';

class ArticleDetailController extends GetxController {
  // SENIOR REFACTOR: Gunakan Get.find untuk performa memory pool Dio yang efisien
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final LikeSyncService _likeSyncService = Get.find<LikeSyncService>();
  
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

    // SENIOR REFACTOR: WORKER SINKRONISASI OTOMATIS
    // Jika status like diubah dari halaman luar (misal Dashboard) saat halaman detail ini sedang terbuka,
    // UI detail artikel akan langsung ikut ter-update secara otomatis tanpa bentrok.
    ever(_likeSyncService.rxLikeEvent, (LikeEvent? event) {
      if (event != null && article.value.id == event.articleId) {
        if (article.value.isLiked != event.isLiked) {
          article.update((val) {
            val!.isLiked = event.isLiked;
            val.likesCount = (val.likesCount ?? 0) + (event.isLiked ? 1 : -1);
          });
        }
      }
    });
  }

  Future<void> loadDetail() async {
    try {
      isLoading.value = true;
      // 1. Ambil Detail Artikel
      article.value = await _apiProvider.getArticleDetail(identifier);
      
      // SYNC: Perbarui baseline notifikasi
      Get.find<NotificationService>().syncArticleMetrics([article.value]);
      
      if (article.value.isBlocked) {
        Get.back();
        Get.snackbar(
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

      // Increment views count locally using GetStorage
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

      // Inisialisasi Quill Controller setelah data artikel didapat
      _initQuillController(article.value.content ?? "");
      // 2. Ambil Komentar
      if (article.value.id != null) {
        await fetchComments();
        // SYNC: Cek perubahan status komentar user
        Get.find<NotificationService>().syncCommentStatus(comments);
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

  // SENIOR REFACTOR: Logika Like Baru yang fully Optimistic, Instant, & Safe
  Future<void> toggleLike() async {

    if (article.value.id == null || isLiking.value) return;

    final authService = Get.find<AuthService>();
    if (!authService.isLoggedIn.value) {
      Get.snackbar('Akses Ditolak', 'Anda harus login untuk menyukai artikel.', backgroundColor: Colors.redAccent, colorText: Colors.white);
      Get.toNamed(Routes.LOGIN);
      return;
    }

    if (isLiking.value) return;

    isLiking.value = true;

    final articleId = article.value.id!;
    final isCurrentlyLiked = article.value.isLiked ?? false;
    final newLikedState = !isCurrentlyLiked;

    // 1. Langsung update ke service utama (UI lokal detail & UI halaman lain otomatis berubah instant via Worker)
    _likeSyncService.updateLikeStatus(articleId, newLikedState);

    try {
      // 2. Kirim request ke backend di latar belakang tanpa me-blocking UI thread
      await _apiProvider.toggleLike(articleId);
    } catch (e) {
      // 3. ROLLBACK: Jika internet putus/gagal, kembalikan status data ke semula
      _likeSyncService.updateLikeStatus(articleId, isCurrentlyLiked);
      Get.snackbar('Oops', 'Gagal memperbarui status Like, silakan periksa koneksi internet Anda.');
    } finally {
      isLiking.value = false;
    }
  }

  // LOGIKA POST KOMENTAR
  Future<void> sendComment() async {
    final authService = Get.find<AuthService>();
    if (!authService.isLoggedIn.value) {
      Get.snackbar('Akses Ditolak', 'Anda harus login untuk berkomentar.', backgroundColor: Colors.redAccent, colorText: Colors.white);
      Get.toNamed(Routes.LOGIN);
      return;
    }

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