import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final AuthService _authService = Get.find<AuthService>();

  // Form Controllers untuk Login
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Form Controllers tambahan untuk Register
  final nameController = TextEditingController();
  final professionController = TextEditingController();

  var isLoading = false.obs;
  var isPasswordHidden = true.obs;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

 // LOGIKA LOGIN YANG DIPERBARUI
  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Email dan password tidak boleh kosong!');
      return;
    }

    isLoading.value = true;
    try {
      final response = await _apiProvider.login(
        emailController.text, 
        passwordController.text
      );

      // 1. PRINT KE TERMINAL UNTUK DEBUGGING
      print("========== BALASAN DARI LARAVEL ==========");
      print(response.data);
      print("==========================================");

      if (response.statusCode == 200) {
        // 2. AMAN DARI SILENT ERROR: Coba cari 'token' atau 'access_token'
        String? token = response.data['token'] ?? response.data['access_token'];
        
        // Amankan data user, berikan map kosong jika ternyata API tidak mengirim objek 'user'
        Map<String, dynamic> user = response.data['user'] ?? {};

        if (token != null && token.isNotEmpty) {
          await _authService.saveSession(token, user);
          Get.snackbar('Sukses', 'Login berhasil!');
          FocusManager.instance.primaryFocus?.unfocus();
          Get.offAllNamed(Routes.DASHBOARD); 
        } else {
          // Jika login sukses 200 tapi token tidak ada di JSON
          Get.snackbar('Format Error', 'Login berhasil, tapi token tidak ditemukan di response API.', backgroundColor: Colors.orange, colorText: Colors.white);
        }
      }
    } on DioException catch (e) {
      // 3. ERROR JARINGAN ATAU PASSWORD SALAH (401/422)
      print("DIO ERROR: ${e.response?.data}");
      String message = _parseError(e, 'Gagal melakukan login. Silakan periksa kredensial Anda.');
      Get.snackbar('Login Gagal', message, backgroundColor: Colors.redAccent, colorText: Colors.white, duration: const Duration(seconds: 4));
    } catch (e) {
      // 4. PENANGKAP SILENT ERROR
      print("ERROR SISTEM/CODE: $e");
      Get.snackbar(
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

  // LOGIKA REGISTER
Future<void> register() async {
    if (nameController.text.isEmpty || 
        emailController.text.isEmpty || 
        passwordController.text.isEmpty || 
        professionController.text.isEmpty) {
      Get.snackbar('Error', 'Semua kolom wajib diisi!');
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
        // --- LOGIKA AUTO-LOGIN SETELAH REGISTER ---
        
        // 1. Ambil token dan data user dari balasan Laravel
        String? token = response.data['token'] ?? response.data['access_token'];
        Map<String, dynamic> user = response.data['user'] ?? {};

        if (token != null && token.isNotEmpty) {
          // 2. Simpan token ke GetStorage menggunakan AuthService
          await _authService.saveSession(token, user);
          
          Get.snackbar('Sukses', 'Akun berhasil dibuat dan otomatis masuk!');
          
          // 3. LANGSUNG ARAHKAN KE INTEREST SELECTION
          FocusManager.instance.primaryFocus?.unfocus();
          Get.offAllNamed(Routes.INTEREST_SELECTION); 
        } else {
          // Jika Laravel tidak mengirim token, terpaksa diarahkan ke Login saja
          Get.snackbar('Sukses', 'Akun dibuat, silakan login manual.');
          Get.offNamed(Routes.LOGIN);
        }
      }
    } on DioException catch (e) {
      print("ERROR REGISTRASI: ${e.response?.data}");
      String message = _parseError(e, 'Gagal memproses pendaftaran. Pastikan data yang dimasukkan benar.');
      Get.snackbar('Registrasi Gagal', message, backgroundColor: Colors.redAccent, colorText: Colors.white, duration: const Duration(seconds: 4));
    } catch (e) {
      print("ERROR SISTEM REGIS: $e");
      Get.snackbar('Terjadi Kesalahan', 'Gagal memproses pendaftaran.');
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  // Helper untuk mem-parsing error dari API agar lebih informatif bagi User
  String _parseError(DioException e, String defaultMessage) {
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi ke server terputus. Pastikan internet Anda stabil dan coba lagi.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    
    if (e.response?.data != null) {
      final data = e.response!.data;
      
      // Jika ada error validasi spesifik (biasanya dari Laravel 422)
      if (e.response?.statusCode == 422 && data['errors'] != null && data['errors'] is Map) {
        final Map<String, dynamic> errors = data['errors'];
        if (errors.isNotEmpty) {
          // Mengambil pesan error pertama dari field pertama yang gagal
          return errors.values.first[0].toString();
        }
      }
      
      // Fallback ke pesan error message umum
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
