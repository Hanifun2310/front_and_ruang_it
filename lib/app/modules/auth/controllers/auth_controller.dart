import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/custom_snackbar.dart';

class AuthController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final AuthService _authService = Get.find<AuthService>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final nameController = TextEditingController();
  final professionController = TextEditingController();

  var isLoading = false.obs;
  var isPasswordHidden = true.obs;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      showCustomSnackbar('Error', 'Email dan password tidak boleh kosong!');
      return;
    }

    isLoading.value = true;
    try {
      final response = await _apiProvider.login(
        emailController.text, 
        passwordController.text
      );
      if (response.statusCode == 200) {
        String? token = response.data['token'] ?? response.data['access_token'];
        
        Map<String, dynamic> user = response.data['user'] ?? {};

        if (token != null && token.isNotEmpty) {
          await _authService.saveSession(token, user);
          showCustomSnackbar('Sukses', 'Login berhasil!');
          FocusManager.instance.primaryFocus?.unfocus();
          Get.offAllNamed(Routes.DASHBOARD); 
        } else {
          showCustomSnackbar('Format Error', 'Login berhasil, tapi token tidak ditemukan di response API.', backgroundColor: Colors.orange, colorText: Colors.white);
        }
      }
    } on DioException catch (e) {
      String message = _parseError(e, 'Gagal melakukan login. Silakan periksa kredensial Anda.');
      
      bool isBanned = message.toLowerCase().contains('banned') || 
                      message.toLowerCase().contains('blocked') || 
                      message.toLowerCase().contains('ditangguhkan');

      showCustomSnackbar(
        'Login Gagal', 
        isBanned ? '$message Silakan baca panduan penulisan kami.' : message, 
        backgroundColor: Colors.redAccent, 
        colorText: Colors.white, 
        duration: Duration(seconds: isBanned ? 6 : 4),
        mainButton: isBanned ? TextButton(
          onPressed: () => Get.toNamed(Routes.GUIDELINES),
          child: const Text(
            'PANDUAN',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ) : null,
      );
    } catch (e) {
      print("ERROR SISTEM/CODE: $e");
      showCustomSnackbar(
        'Terjadi Kesalahan', 
        'Terjadi kesalahan sistem, silakan coba lagi nanti.', 
        backgroundColor: Colors.amber, 
        colorText: Colors.black,
      );
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  Future<void> register() async {
    if (nameController.text.isEmpty || 
        emailController.text.isEmpty || 
        passwordController.text.isEmpty || 
        professionController.text.isEmpty) {
      showCustomSnackbar('Error', 'Semua kolom wajib diisi!');
      return;
    }

    isLoading.value = true;
    try {
      final response = await _apiProvider.register(
        nameController.text,
        emailController.text,
        passwordController.text,
        professionController.text,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        String? token = response.data['token'] ?? response.data['access_token'];
        Map<String, dynamic> user = response.data['user'] ?? {};

        if (token != null && token.isNotEmpty) {
          await _authService.saveSession(token, user);
          
          showCustomSnackbar('Sukses', 'Akun berhasil dibuat dan otomatis masuk!');
          
          FocusManager.instance.primaryFocus?.unfocus();
          Get.offAllNamed(Routes.INTEREST_SELECTION); 
        } else {
          showCustomSnackbar('Sukses', 'Akun dibuat, silakan login manual.');
          Get.offNamed(Routes.LOGIN);
        }
      }
    } on DioException catch (e) {
      String message = _parseError(e, 'Gagal memproses pendaftaran. Pastikan data yang dimasukkan benar.');
      showCustomSnackbar('Registrasi Gagal', message, backgroundColor: Colors.redAccent, colorText: Colors.white, duration: const Duration(seconds: 4));
    } catch (e) {
      print("ERROR SISTEM REGIS: $e");
      showCustomSnackbar('Terjadi Kesalahan', 'Gagal memproses pendaftaran.');
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  String _parseError(DioException e, String defaultMessage) {
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi ke server terputus. Pastikan internet Anda stabil dan coba lagi.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
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
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    professionController.dispose();
    super.onClose();
  }
}
