import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:dio/dio.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/models/article_model.dart';
import '../../../widgets/custom_snackbar.dart';

class ArticleEditController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  
  late ArticleModel article;
  final titleController = TextEditingController();
  late QuillController quillController;
  
  final Rx<XFile?> selectedImage = Rx<XFile?>(null);
  final RxInt selectedCategoryId = 0.obs;
  final RxBool isLoading = false.obs;
  final RxList<dynamic> categories = <dynamic>[].obs;
  final RxString currentImageUrl = "".obs;

  @override
  void onInit() {
    super.onInit();
    article = Get.arguments as ArticleModel;
    
    titleController.text = article.title ?? "";
    selectedCategoryId.value = article.category?.id ?? 0;
    currentImageUrl.value = article.imageUrl ?? "";

    _initQuillController(article.content ?? "");

    fetchCategories();
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
        final delta = HtmlToDelta().convert(content);
        quillController = QuillController(
          document: Document.fromDelta(delta),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } catch (e) {
      String plainText = content
          .replaceAll(RegExp(r'</p>|<br\s*/?>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '')
          .trim();
          
      quillController = QuillController(
        document: Document()..insert(0, plainText),
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await _apiProvider.getCategories();
      if (response.statusCode == 200) {
        categories.value = response.data['data'] ?? response.data;
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImage.value = image;
    }
  }

  Future<void> updateArticle() async {
    if (titleController.text.isEmpty || quillController.document.isEmpty() || selectedCategoryId.value == 0) {
      showCustomSnackbar('Error', 'Judul, konten, dan kategori harus diisi');
      return;
    }

    isLoading.value = true;
    try {
      List<int>? imageBytes;
      String? fileName;
      
      if (selectedImage.value != null) {
        imageBytes = await selectedImage.value!.readAsBytes();
        fileName = selectedImage.value!.name;
      }

      final deltaJson = quillController.document.toDelta().toJson();
      final converter = QuillDeltaToHtmlConverter(
        List.castFrom(deltaJson),
        ConverterOptions(),
      );
      final htmlContent = converter.convert();

      final response = await _apiProvider.updateArticle(
        id: article.id!,
        title: titleController.text,
        content: htmlContent,
        categoryId: selectedCategoryId.value,
        imageBytes: imageBytes,
        fileName: fileName,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back(result: true);
        showCustomSnackbar('Sukses', 'Artikel berhasil diperbarui');
      } else {
        showCustomSnackbar('Gagal', 'Gagal memperbarui artikel: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      String message = _parseError(e, 'Gagal memperbarui artikel.');
      showCustomSnackbar('Error', message, backgroundColor: Colors.redAccent, colorText: Colors.white, duration: const Duration(seconds: 4));
    } catch (e) {
      showCustomSnackbar('Error', 'Terjadi kesalahan sistem: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String _parseError(DioException e, String defaultMessage) {
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi ke server terputus. Pastikan internet stabil (gambar mungkin terlalu besar).';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server.';
    }
    
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (e.response?.statusCode == 422 && data['errors'] != null && data['errors'] is Map) {
        final Map<String, dynamic> errors = data['errors'];
        if (errors.isNotEmpty) {
          return errors.values.first[0].toString();
        }
      }
      if (data['message'] != null) {
        return data['message'].toString();
      }
    }
    return defaultMessage;
  }

  @override
  void onClose() {
    titleController.dispose();
    quillController.dispose();
    super.onClose();
  }
}
