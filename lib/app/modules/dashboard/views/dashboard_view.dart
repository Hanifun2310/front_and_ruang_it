import 'package:flutter/material.dart';
import '../../../widgets/article_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/skeleton_widget.dart';
import '../../../widgets/custom_bottom_nav.dart';
import '../controllers/dashboard_controller.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart'
    hide DefaultStyles;
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/bouncing_widget.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 50) {
        if (controller.activeTab.value == 0) {
          controller.loadMoreArticles();
        }
      }
    });

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
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Get.isDarkMode ? Colors.white10 : Colors.grey.shade300,
                ),
              ),
            ),
            child: Obx(
              () => Row(
                children: [
                  _buildTab('Artikel Terbaru', 0),
                  _buildTab('Artikel Populer', 1),
                ],
              ),
            ),
          ),
          


          Expanded(
            child: Obx(() {
              final isTerbaru = controller.activeTab.value == 0;
              final displayList = isTerbaru
                  ? controller.articles
                  : controller.trendingArticles;

              if (controller.isLoading.value && displayList.isEmpty) {
                return const SkeletonList(itemCount: 5);
              }

              if (displayList.isEmpty) {
                return Center(
                  child: Text("Belum ada artikel.", style: GoogleFonts.inter()),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  if (isTerbaru) {
                    controller.changeCategory(
                      controller.selectedCategory.value,
                    );
                  }
                },
                child: ListView.builder(
                  controller: isTerbaru
                      ? scrollController
                      : null,
                  itemCount:
                      displayList.length +
                      (isTerbaru && controller.hasMoreData.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (isTerbaru && index == displayList.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: LoadingWidget(size: 30),
                      );
                    }

                    final article = displayList[index];
                    return ArticleCard(article: article, onLikeToggle: (id) => controller.toggleLike(id), onDelete: (id) => controller.deleteArticle(id));
                  },
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  Widget _buildTab(String title, int index) {
    final controller = Get.find<DashboardController>();
    final isSelected = controller.activeTab.value == index;

    return Expanded(
      child: InkWell(
        onTap: () => controller.switchTab(index),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? (Get.isDarkMode ? Colors.white : Colors.black)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: isSelected
                  ? (Get.isDarkMode ? Colors.white : Colors.black)
                  : (Get.isDarkMode ? Colors.white54 : Colors.grey.shade600),
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
