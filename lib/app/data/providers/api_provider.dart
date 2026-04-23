import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../services/auth_service.dart';
import '../models/article_model.dart';

class ApiProvider {
  late Dio _dio;
  
  // Base URL Asli Anda!
  static const String baseUrl = 'https://ruang-it.vibedev.my.id/api';

  ApiProvider() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Interceptor untuk menyisipkan Bearer Token otomatis
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final authService = Get.find<AuthService>();
        final token = authService.token;

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 403) {
          Get.find<AuthService>().logout();
          Get.snackbar('Akses Ditolak', 'Akun Anda telah ditangguhkan.');
        } else if (e.response?.statusCode == 401) {
          Get.find<AuthService>().logout();
          Get.snackbar('Sesi Habis', 'Silakan login kembali.');
        }
        return handler.next(e);
      },
    ));
  }

  // ===========================================================================
  // AUTHENTICATION ROUTES
  // ===========================================================================
  
  Future<Response> login(String email, String password) async {
    return await _dio.post('/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> register(String name, String email, String password, String passwordConfirmation) async {
    return await _dio.post('/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation, // Sesuaikan dengan field validasi Laravel Anda
    });
  }

  Future<Response> logout() async {
    return await _dio.post('/logout');
  }

  // ===========================================================================
  // PUBLIC ROUTES (Articles & Categories)
  // ===========================================================================

  Future<List<ArticleModel>> getArticles({int page = 1, String? category}) async {
    try {
      Map<String, dynamic> queryParams = {'page': page};
      if (category != null && category != 'Semua') {
        queryParams['category'] = category; // Pastikan backend Laravel Anda menerima filter ini
      }

      final response = await _dio.get('/articles', queryParameters: queryParams);

      if (response.statusCode == 200) {
        // Asumsi data array berada di dalam response.data['data'] (Bawaan Pagination Laravel)
        List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => ArticleModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<ArticleModel> getArticleDetail(String identifier) async {
    final response = await _dio.get('/articles/$identifier');
    return ArticleModel.fromJson(response.data['data'] ?? response.data);
  }

  Future<Response> getCategories() async {
    return await _dio.get('/categories');
  }

  Future<Response> getComments(int articleId) async {
    return await _dio.get('/articles/$articleId/comments');
  }

  // ===========================================================================
  // PROTECTED ROUTES (User Actions)
  // ===========================================================================

  Future<Response> toggleLike(int articleId) async {
    return await _dio.post('/articles/$articleId/like');
  }

  Future<Response> postComment(int articleId, String content) async {
    return await _dio.post('/articles/$articleId/comments', data: {
      'content': content,
    });
  }

  Future<Response> getProfile() async {
    return await _dio.get('/profile');
  }
}