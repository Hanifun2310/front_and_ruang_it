import 'package:flutter/material.dart';
import '../../../widgets/article_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/skeleton_widget.dart';
import '../../../widgets/custom_bottom_nav.dart';
import '../../../data/services/auth_service.dart';
import '../controllers/explore_controller.dart';
import '../../../routes/app_routes.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart'
    hide DefaultStyles;

class ExploreView extends GetView<ExploreController> {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.appBarTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Image.asset(
          'assets/images/newlogo.png',
          height: 28,
          fit: BoxFit.contain,
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'Ruang IT',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Get.isDarkMode
                      ? Colors.white
                      : const Color(0xFF1056C9),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Get.isDarkMode ? Colors.white10 : Colors.grey.shade200,
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          SizedBox(
            height: 40,
            child: Obx(
              () {
                if (controller.isCategoriesLoading.value &&
                    controller.categories.isEmpty) {
                  return const SkeletonChips();
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.categories.length,
                  itemBuilder: (context, index) {
                    final category = controller.categories[index];
                    final isSelected =
                        controller.selectedCategory.value?.id == category.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category.name ?? ''),
                        selected: isSelected,
                        onSelected: (selected) =>
                            controller.filterByCategory(category),
                        backgroundColor: Colors.white,
                        selectedColor: Colors.grey.shade200,
                        checkmarkColor: Colors.blueAccent,
                        labelStyle: GoogleFonts.inter(
                          color: isSelected
                              ? Colors.blueAccent
                              : (Get.isDarkMode
                                    ? Colors.black87
                                    : Colors.black87),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? Colors.blueAccent : Colors.black,
                            width: 1,
                          ),
                        ),
                        side: BorderSide.none,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const SkeletonList(itemCount: 4);
              }

              if (controller.articles.isEmpty) {
                return Center(
                  child: Text(
                    'Tidak ada artikel ditemukan',
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.fetchArticles(),
                child: ListView.builder(
                  itemCount: controller.articles.length,
                  itemBuilder: (context, index) {
                    final article = controller.articles[index];
                    return ArticleCard(article: article, onLikeToggle: (id) => controller.toggleLike(id));
                  },
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }
}
