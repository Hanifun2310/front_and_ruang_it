import 'package:get/get.dart';
import 'app_routes.dart';

// Import file yang baru saja kita buat
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/register_view.dart';

import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/dashboard/views/dashboard_view.dart';

import '../modules/article/views/article_detail_view.dart';
import '../modules/article/controllers/article_detail_controller.dart';

import '../modules/profile/views/profile_view.dart';
import '../modules/profile/controllers/profile_controller.dart';

import '../modules/article/views/article_create_view.dart';
import '../modules/article/bindings/article_create_binding.dart';

import '../modules/article/views/article_edit_view.dart';
import '../modules/article/controllers/article_edit_controller.dart';

import '../modules/interest_selection/bindings/interest_selection_binding.dart';
import '../modules/interest_selection/views/interest_selection_view.dart';

import '../modules/topic_recommendation/bindings/topic_recommendation_binding.dart';
import '../modules/topic_recommendation/views/topic_recommendation_view.dart';

import '../modules/category_detail/bindings/category_detail_binding.dart';
import '../modules/category_detail/views/category_detail_view.dart';
import '../modules/author_profile/bindings/author_profile_binding.dart';
import '../modules/author_profile/views/author_profile_view.dart';
import '../modules/explore/views/explore_view.dart';
import '../modules/explore/bindings/explore_binding.dart';

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
    GetPage(name: Routes.REGISTER,
            page: () => const RegisterView(),
            binding: AuthBinding()),
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
  GetPage(
  name: Routes.PROFILE,
  page: () => const ProfileView(),
  binding: BindingsBuilder(() {
    Get.lazyPut<ProfileController>(() => ProfileController());
  }),
),
    GetPage(
      name: Routes.ARTICLE_CREATE,
      page: () => const ArticleCreateView(),
      binding: ArticleCreateBinding(),
    ),
    GetPage(
      name: Routes.ARTICLE_EDIT,
      page: () => const ArticleEditView(),
      binding: BindingsBuilder(() {
        Get.put(ArticleEditController());
      }),
    ),
    GetPage(
      name: Routes.INTEREST_SELECTION,
      page: () => const InterestSelectionView(),
      binding: InterestSelectionBinding(),
    ),
    GetPage(
      name: Routes.TOPIC_RECOMMENDATION,
      page: () => const TopicRecommendationView(),
      binding: TopicRecommendationBinding(),
    ),
    GetPage(
      name: Routes.CATEGORY_DETAIL,
      page: () => const CategoryDetailView(),
      binding: CategoryDetailBinding(),
    ),
    GetPage(
      name: Routes.AUTHOR_PROFILE,
      page: () => const AuthorProfileView(),
      binding: AuthorProfileBinding(),
    ),
    GetPage(
      name: Routes.EXPLORE,
      page: () => const ExploreView(),
      binding: ExploreBinding(),
    ),
  ];
  
}