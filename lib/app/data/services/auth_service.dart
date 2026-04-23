import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../routes/app_routes.dart';

class AuthService extends GetxService {
  final box = GetStorage();
  
  // Reactive variable untuk memantau status login
  final RxBool isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Cek apakah token sudah ada saat aplikasi pertama dibuka
    checkLoginStatus();
  }

  void checkLoginStatus() {
    String? token = box.read('token');
    if (token != null && token.isNotEmpty) {
      isLoggedIn.value = true;
    }
  }

  // Fungsi untuk menyimpan data setelah login berhasil
  Future<void> saveSession(String token, Map<String, dynamic> userData) async {
    await box.write('token', token);
    await box.write('user', userData);
    isLoggedIn.value = true;
  }

  // Fungsi logout & penanganan Banned (403)
  Future<void> logout() async {
    await box.remove('token');
    await box.remove('user');
    isLoggedIn.value = false;
    
    // Arahkan kembali ke halaman Login dan hapus riwayat navigasi
    Get.offAllNamed(Routes.LOGIN);
    
    // Opsional: Tampilkan notifikasi jika ini karena banned
    // Get.snackbar('Sesi Berakhir', 'Silakan login kembali.');
  }

  // Getter pembantu
  String? get token => box.read('token');
  Map<String, dynamic>? get currentUser => box.read('user');
}