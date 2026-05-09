import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/explore_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../data/services/auth_service.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' hide DefaultStyles;

class ExploreView extends GetView<ExploreController> {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Explore',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Get.isDarkMode ? Colors.white : const Color(0xFF131B2E),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => controller.search(value),
              decoration: InputDecoration(
                hintText: 'Cari artikel...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Get.isDarkMode ? Colors.white10 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Categories filter
          SizedBox(
            height: 40,
            child: Obx(() => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.categories.length,
              itemBuilder: (context, index) {
                final category = controller.categories[index];
                final isSelected = controller.selectedCategory.value?.id == category.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category.name ?? ''),
                    selected: isSelected,
                    onSelected: (selected) => controller.filterByCategory(category),
                    backgroundColor: Get.isDarkMode ? Colors.white10 : Colors.grey.shade100,
                    selectedColor: Colors.blueAccent.withOpacity(0.2),
                    checkmarkColor: Colors.blueAccent,
                    labelStyle: GoogleFonts.inter(
                      color: isSelected ? Colors.blueAccent : (Get.isDarkMode ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                  ),
                );
              },
            )),
          ),

          const SizedBox(height: 16),

          // Article List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildArticleCard(BuildContext context, dynamic article) {
    final String imageUrl = article.imageUrl ?? 'https://via.placeholder.com/600x400';
    final String avatarUrl = article.user?.photoProfile ?? 'https://via.placeholder.com/150';
    final String categoryName = article.category?.name ?? 'Umum';
    final authService = Get.find<AuthService>();
    final currentUserId = authService.currentUser?['id'];
    final bool isAuthor = article.user?.id != null && article.user?.id == currentUserId;

    return InkWell(
      onTap: () {
        Get.toNamed(Routes.ARTICLE_DETAIL, arguments: article.slug);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? context.theme.scaffoldBackgroundColor : Colors.white,
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
                Icon(Icons.grid_view_rounded, size: 16, color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  'Theme: $categoryName',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage(avatarUrl),
                  backgroundColor: Colors.grey.shade200,
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
                          color: Get.isDarkMode ? Colors.white : Colors.grey.shade900,
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
                  child: Image.network(
                    imageUrl,
                    width: 100,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 100,
                      height: 70,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => controller.toggleLike(article.id!),
                  child: Row(
                    children: [
                      Icon(
                        (article.isLiked ?? false) ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                        size: 20,
                        color: (article.isLiked ?? false) ? Colors.blueAccent : (Get.isDarkMode ? Colors.white70 : Colors.grey.shade700),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${article.likesCount ?? 0}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 20, color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700),
                    const SizedBox(width: 6),
                    Text(
                      '${article.commentsCount ?? 0}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnippetPreview(String? content) {
    if (content == null || content.isEmpty) return const SizedBox();
    try {
      if (content.trim().startsWith('[')) {
        final deltaJson = jsonDecode(content);
        final quillController = QuillController(
          document: Document.fromJson(deltaJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
        return SizedBox(
          height: 40,
          child: AbsorbPointer(
            child: QuillEditor.basic(
              configurations: QuillEditorConfigurations(
                controller: quillController,
                readOnly: true,
                showCursor: false,
                autoFocus: false,
                expands: false,
                padding: EdgeInsets.zero,
                customStyles: DefaultStyles(
                  paragraph: DefaultTextBlockStyle(
                    GoogleFonts.inter(fontSize: 13, color: Get.isDarkMode ? Colors.white54 : Colors.grey.shade500),
                    const VerticalSpacing(0, 0),
                    const VerticalSpacing(0, 0),
                    null,
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        return HtmlWidget(
          content,
          textStyle: GoogleFonts.inter(fontSize: 13, color: Get.isDarkMode ? Colors.white54 : Colors.grey.shade500),
        );
      }
    } catch (e) {
      return const SizedBox();
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        border: Border(top: BorderSide(color: Get.isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0))),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Get.isDarkMode ? Colors.blueAccent : const Color(0xFF1056C9),
        unselectedItemColor: Get.isDarkMode ? Colors.white54 : Colors.grey.shade800,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Get.offNamed(Routes.DASHBOARD);
          } else if (index == 1) {
            // Already here
          } else if (index == 2) {
            Get.snackbar('Coming Soon', 'Fitur Search sedang dalam pengembangan');
          } else if (index == 3) {
            Get.offNamed(Routes.PROFILE);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.explore_outlined)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.explore)),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.search_outlined)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.search)),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
