import 'package:dio/dio.dart';
import 'package:get/get.dart';

class GuidelinesController extends GetxController {
  var isLoading = true.obs;
  var htmlContent = ''.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadGuidelines();
  }

  Future<void> loadGuidelines() async {
    try {
      isLoading.value = true;
      final response = await Dio().get('https://ruang-it.vibedev.my.id/guidelines');
      if (response.statusCode == 200) {
        final body = response.data.toString();
        htmlContent.value = _extractBody(body) ?? body;
      } else {
        errorMessage.value = 'Gagal memuat panduan. Silakan coba lagi.';
      }
    } catch (e) {
      errorMessage.value = 'Gagal memuat panduan. Silakan coba lagi.';
    } finally {
      isLoading.value = false;
    }
  }

  String? _extractBody(String html) {
    final bodyRegExp = RegExp(r'<body[^>]*>([\s\S]*?)<\/body>', caseSensitive: false);
    final match = bodyRegExp.firstMatch(html);
    return match?.group(1);
  }
}
