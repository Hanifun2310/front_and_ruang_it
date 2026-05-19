import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/services/auth_service.dart';
import 'app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();
    if (!authService.isLoggedIn.value) {
      Get.snackbar(
        'Akses Ditolak', 
        'Anda harus login terlebih dahulu.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return const RouteSettings(name: Routes.LOGIN);
    }
    return null;
  }
}
