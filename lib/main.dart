import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/routes/app_pages.dart';
import 'app/data/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inisialisasi Storage
  await GetStorage.init();
  
  // 2. Registrasi AuthService secara global
  Get.put(AuthService());

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Ruang IT",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue, // Sesuaikan dengan warna Mazer/Tailwind Anda
      ),
    ),
  );
}