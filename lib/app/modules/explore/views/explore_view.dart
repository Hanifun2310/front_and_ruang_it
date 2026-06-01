import 'package:flutter/material.dart';
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
                    return _buildArticleCard(context, article);
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

  Widget _buildArticleCard(BuildContext context, dynamic article) {
    final String imageUrl =
        article.imageUrl ?? 'https://via.placeholder.com/600x400';
    final String avatarUrl =
        (article.user?.photoProfile?.isNotEmpty == true)
            ? article.user!.photoProfile!
            : '';
    final String categoryName = article.category?.name ?? 'Umum';
    final authService = Get.find<AuthService>();
    return InkWell(
      onTap: () {
        Get.toNamed(Routes.ARTICLE_DETAIL, arguments: article.slug);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.isDarkMode
              ? context.theme.scaffoldBackgroundColor
              : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Get.isDarkMode ? Colors.white10 : Colors.grey.shade100,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 16,
                  color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Theme: $categoryName',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Get.isDarkMode
                        ? Colors.white70
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                if (article.user != null) {
                  Get.toNamed(Routes.AUTHOR_PROFILE, arguments: article.user);
                }
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl) as ImageProvider
                        : const AssetImage('assets/images/fallback_pp.png'),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    article.user?.name ?? 'Admin',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Get.isDarkMode ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title ?? 'Tanpa Judul',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: Get.isDarkMode
                              ? Colors.white
                              : Colors.grey.shade900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _buildSnippetPreview(article.content),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(imageUrl: 
                    imageUrl,
                    width: 100,
                    height: 70,
                    fit: BoxFit.cover,
                    errorWidget: (context, error, stackTrace) => Container(
                      width: 100,
                      height: 70,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  article.formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Get.isDarkMode
                        ? Colors.white54
                        : Colors.grey.shade600,
                  ),
                ),
                Obx(() => Row(
                  children: [
                    InkWell(
                      onTap: authService.isLoggedIn.value
                          ? () => controller.toggleLike(article.id!)
                          : null,
                      child: Row(
                        children: [
                          Icon(
                            authService.isLoggedIn.value && (article.isLiked ?? false)
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            size: 20,
                            color: authService.isLoggedIn.value && (article.isLiked ?? false)
                                ? Colors.blueAccent
                                : (Get.isDarkMode
                                      ? Colors.white70
                                      : Colors.grey.shade700),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${article.likesCount ?? 0}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Get.isDarkMode
                                  ? Colors.white70
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 20,
                          color: Get.isDarkMode
                              ? Colors.white70
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${article.commentsCount ?? 0}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Get.isDarkMode
                                ? Colors.white70
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 20,
                          color: Get.isDarkMode
                              ? Colors.white70
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${article.viewsCount ?? 0}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Get.isDarkMode
                                ? Colors.white70
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnippetPreview(String? content) {
    if (content == null || content.trim().isEmpty) {
      return Text(
        'Tidak ada ringkasan...',
        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
      );
    }

    String plainText = '';
    try {
      if (content.trim().startsWith('[')) {
        final List<dynamic> deltaList = jsonDecode(content);
        final buffer = StringBuffer();
        for (var op in deltaList) {
          if (op is Map && op.containsKey('insert')) {
            final insertValue = op['insert'];
            if (insertValue is String) {
              buffer.write(insertValue);
            }
          }
        }
        plainText = buffer.toString().trim().replaceAll('\n', ' ');
      } else {
        final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
        plainText = content.replaceAll(exp, '').trim().replaceAll('\n', ' ');
        plainText = plainText
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"');
      }
    } catch (e) {
      plainText = 'Gagal memuat ringkasan...';
    }

    if (plainText.isEmpty) {
      plainText = 'Tidak ada ringkasan...';
    }

    return SizedBox(
      height: 44,
      child: Text(
        plainText,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Get.isDarkMode ? Colors.white54 : Colors.grey.shade500,
          height: 1.4,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
