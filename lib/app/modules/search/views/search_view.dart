import 'package:flutter/material.dart';
import '../../../widgets/article_card.dart';
import '../../../widgets/custom_network_image.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/custom_bottom_nav.dart';
import '../controllers/search_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../data/models/article_model.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart'
    hide DefaultStyles;

class SearchView extends GetView<ArticleSearchController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController textController = TextEditingController();

    ever(controller.searchQuery, (String query) {
      if (textController.text != query) {
        textController.text = query;
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: textController,
              onChanged: controller.onSearchChanged,
              onSubmitted: (value) {
                controller.searchQuery.value = value;
                controller.fetchArticles();
              },
              autofocus: true,
              style: GoogleFonts.inter(
                color: Get.isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Cari artikel, penulis, atau kategori...',
                hintStyle: GoogleFonts.inter(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            textController.clear();
                            controller.onSearchChanged('');
                          },
                        )
                      : const SizedBox(),
                ),
                filled: true,
                fillColor: Get.isDarkMode
                    ? Colors.white10
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
          ),

          Obx(() {
            if (controller.searchQuery.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Get.isDarkMode ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => controller.searchTab.value = 0,
                        borderRadius: BorderRadius.circular(8),
                        child: Obx(() {
                          final active = controller.searchTab.value == 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: active
                                  ? (Get.isDarkMode ? Colors.white12 : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: active && !Get.isDarkMode
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.article_outlined,
                                    size: 16,
                                    color: active
                                        ? (Get.isDarkMode ? Colors.white : const Color(0xFF1056C9))
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Artikel',
                                    style: GoogleFonts.inter(
                                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                                      color: active
                                          ? (Get.isDarkMode ? Colors.white : const Color(0xFF1056C9))
                                          : Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => controller.searchTab.value = 1,
                        borderRadius: BorderRadius.circular(8),
                        child: Obx(() {
                          final active = controller.searchTab.value == 1;
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: active
                                  ? (Get.isDarkMode ? Colors.white12 : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: active && !Get.isDarkMode
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_alt_outlined,
                                    size: 16,
                                    color: active
                                        ? (Get.isDarkMode ? Colors.white : const Color(0xFF1056C9))
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Penulis',
                                    style: GoogleFonts.inter(
                                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                                      color: active
                                          ? (Get.isDarkMode ? Colors.white : const Color(0xFF1056C9))
                                          : Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          Expanded(
            child: Obx(() {
              if (controller.searchQuery.value.isEmpty) {
                return _buildHistorySection();
              }

              if (controller.isLoading.value) {
                return const LoadingWidget();
              }

              if (controller.searchTab.value == 0) {
                if (controller.articles.isEmpty) {
                  return _buildNoResults('Tidak ada artikel ditemukan');
                }

                return ListView.builder(
                  itemCount: controller.articles.length,
                  itemBuilder: (context, index) {
                    final article = controller.articles[index];
                    return ArticleCard(article: article, onLikeToggle: (id) => controller.toggleLike(id));
                  },
                );
              } else {
                if (controller.users.isEmpty) {
                  return _buildNoResults('Tidak ada penulis ditemukan');
                }

                return ListView.builder(
                  itemCount: controller.users.length,
                  itemBuilder: (context, index) {
                    final user = controller.users[index];
                    return _buildUserCard(context, user);
                  },
                );
              }
            }),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }

  Widget _buildHistorySection() {
    if (controller.searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Cari sesuatu yang menarik...',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat Pencarian',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Get.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              TextButton(
                onPressed: controller.clearAllHistory,
                child: Text(
                  'Hapus Semua',
                  style: GoogleFonts.inter(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: controller.searchHistory.length,
            itemBuilder: (context, index) {
              final query = controller.searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(
                  query,
                  style: GoogleFonts.inter(
                    color: Get.isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: () => controller.removeFromHistory(query),
                ),
                onTap: () => controller.selectHistory(query),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoResults([String message = 'Tidak ada artikel ditemukan']) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    final String avatarUrl = user.photoProfile ?? '';
    final String profession = user.profession?.isNotEmpty == true
        ? user.profession!
        : 'Pekerjaan belum diisi';
    final String bio = user.bio?.isNotEmpty == true
        ? user.bio!
        : 'Bio belum diisi.';

    return InkWell(
      onTap: () {
        Get.toNamed(Routes.AUTHOR_PROFILE, arguments: user);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Get.isDarkMode
              ? Colors.white10
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Get.isDarkMode ? Colors.white10 : Colors.grey.shade100,
          ),
        ),
        child: Row(
          children: [
            avatarUrl.isNotEmpty
                ? ClipOval(
                    child: CustomNetworkImage(
                      imageUrl: avatarUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/images/fallback_pp.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                      placeholder: (context, url) => Container(
                        width: 56,
                        height: 56,
                        color: Get.isDarkMode ? Colors.white24 : Colors.grey.shade200,
                      ),
                    ),
                  )
                : const CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage('assets/images/fallback_pp.png'),
                  ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? 'User',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Get.isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profession,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1056C9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bio,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Get.isDarkMode ? Colors.white54 : Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Get.isDarkMode ? Colors.white38 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
