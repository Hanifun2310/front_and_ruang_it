import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:device_preview/device_preview.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/data/services/auth_service.dart';
import 'app/data/services/notification_service.dart';
import 'app/data/services/theme_service.dart';
import 'app/data/services/like_sync_service.dart';
import 'app/data/providers/api_provider.dart';
import 'app/controllers/network_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();


  Get.put(NetworkController(), permanent: true);
  // 2. Registrasi Services secara global

  Get.put(ApiProvider());
  
  final authService = AuthService();
  await authService.initStorage();
  Get.put(authService);

  Get.put(NotificationService());

  final themeService = Get.put(ThemeService());
  Get.put(LikeSyncService());

  runApp(
    DevicePreview(
      // UBAH DI SINI: Set ke true agar selalu aktif, termasuk saat di-deploy ke web
      enabled: true, 
      builder: (context) => GetMaterialApp(
        useInheritedMediaQuery: true,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        debugShowCheckedModeBanner: false,
        title: "Ruang IT",
        initialRoute: Routes.SPLASH,
        getPages: AppPages.routes,
        theme: ThemeService.lightTheme,
        darkTheme: ThemeService.darkTheme,
        themeMode: themeService.theme,
      ),
    ),
  );
}