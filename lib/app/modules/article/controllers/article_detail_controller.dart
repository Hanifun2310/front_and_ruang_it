import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../data/models/article_model.dart';
import '../../../data/models/comment_model.dart';
import '../../../data/providers/api_provider.dart';

class ArticleDetailController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  
  // Ambil identifier (slug/id) dari argument navigasi
  final String identifier = Get.arguments;

  var article = ArticleModel().obs;
  var comments = <CommentModel>[].obs;
  var isLoading = true.obs;
  var isLiking = false.obs;

  final commentController = TextEditingController();
  QuillController? quillController;

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
      
      try {
        final deltaJson = jsonDecode(article.value.content ?? "");
        quillController = QuillController(
          document: Document.fromJson(deltaJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        quillController = null;
      }
      
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
}