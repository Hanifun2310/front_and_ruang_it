import 'package:get/get.dart';
import 'app_routes.dart';

// Import file yang baru saja kita buat
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_view.dart';

import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/dashboard/views/dashboard_view.dart';

import '../modules/article/views/article_detail_view.dart';
import '../modules/article/controllers/article_detail_controller.dart';

class AppPages {
  AppPages._();

  // UBAH INI: Jadikan Login sebagai rute awal saat aplikasi dibuka
  static const INITIAL = Routes.LOGIN; 

  static final routes = <GetPage>[
    // Daftarkan rute Login
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.DASHBOARD,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),

      GetPage(
    name: Routes.ARTICLE_DETAIL,
    page: () => const ArticleDetailView(),
    binding: BindingsBuilder(() {
      Get.lazyPut<ArticleDetailController>(() => ArticleDetailController());
    }),
  ),
  ];
}