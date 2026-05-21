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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Storage
  await GetStorage.init();

  // 2. Registrasi Services secara global

  Get.put(ApiProvider());
  Get.put(AuthService());
  Get.put(NotificationService());

  final themeService = Get.put(ThemeService());
  Get.put(LikeSyncService());

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => GetMaterialApp(
        useInheritedMediaQuery: true,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        debugShowCheckedModeBanner: false,
        title: "Ruang IT",
        initialRoute: Routes.DASHBOARD,
        getPages: AppPages.routes,
        theme: ThemeService.lightTheme,
        darkTheme: ThemeService.darkTheme,
        themeMode: themeService.theme,
      ),
    ),
  );
}
