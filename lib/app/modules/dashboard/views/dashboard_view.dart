import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/loading_widget.dart';
import '../controllers/dashboard_controller.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' hide DefaultStyles;
import '../../../data/services/auth_service.dart';
import '../../../data/services/theme_service.dart';
import '../../../routes/app_routes.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller untuk mendeteksi scroll mentok ke bawah (untuk load more)
    final ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 50) {
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
                  color: Get.isDarkMode ? Colors.white : const Color(0xFF1056C9),
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
          // TABS
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Get.isDarkMode ? Colors.white10 : Colors.grey.shade300)),
            ),
            child: Obx(() => Row(
              children: [
                _buildTab('Artikel Terbaru', 0),
                _buildTab('Artikel Populer', 1),
              ],
            )),
          ),

          // --- DAFTAR ARTIKEL (INFINITE SCROLL) ---
          Expanded(
            child: Obx(() {
              final isTerbaru = controller.activeTab.value == 0;
              final displayList = isTerbaru ? controller.articles : controller.trendingArticles;

              if (controller.isLoading.value && displayList.isEmpty) {
                return const LoadingWidget();
              }

              if (displayList.isEmpty) {
                return Center(child: Text("Belum ada artikel.", style: GoogleFonts.inter()));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  if (isTerbaru) {
                    controller.changeCategory(controller.selectedCategory.value);
                  }
                },
                child: ListView.builder(
                  controller: isTerbaru ? scrollController : null, // hanya scroll paging di tab terbaru
                  itemCount: displayList.length + (isTerbaru && controller.hasMoreData.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (isTerbaru && index == displayList.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: const LoadingWidget(size: 30),
                      );
                    }

                    final article = displayList[index];
                    return _buildArticleCard(context, article);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) {
              Get.offNamed(Routes.EXPLORE);
            } else if (index == 2) {
              Get.offNamed(Routes.SEARCH);
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
      ),
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
                color: isSelected ? (Get.isDarkMode ? Colors.white : Colors.black) : Colors.transparent,
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
            // Theme Label
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
            
            // Author Info
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage(avatarUrl),
                  onBackgroundImageError: (_, _) {},
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
            
            // Article Content Preview
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
                // Thumbnail Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: 120,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Article Meta & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  article.formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Get.isDarkMode ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (article.id != null) {
                          controller.toggleLike(article.id!);
                        }
                      },
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
                        Icon(
                          Icons.mode_comment_outlined,
                          size: 20,
                          color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                        ),
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
                    if (isAuthor) ...[
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () => _showArticleOptions(context, article),
                        child: Icon(
                          Icons.more_horiz,
                          size: 20,
                          color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showArticleOptions(BuildContext context, dynamic article) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Opsi Artikel',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Get.isDarkMode ? Colors.white : const Color(0xFF131B2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blueAccent),
              title: Text(
                'Edit Artikel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Get.isDarkMode ? Colors.white : const Color(0xFF131B2E),
                ),
              ),
              onTap: () {
                Get.back(); // close bottom sheet
                Get.toNamed(Routes.ARTICLE_EDIT, arguments: article);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: Text(
                'Hapus Artikel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
              onTap: () {
                Get.back(); // close bottom sheet
                _showDeleteConfirmation(article.id);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(int? id) {
    if (id == null) return;
    Get.dialog(
      AlertDialog(
        backgroundColor: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Artikel',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus artikel ini secara permanen?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteArticle(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnippetPreview(String? content) {
    if (content == null || content.isEmpty) {
      return Text('Tidak ada ringkasan...', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey));
    }

    try {
      if (content.trim().startsWith('[')) {
        final deltaJson = jsonDecode(content);
        final quillController = QuillController(
          document: Document.fromJson(deltaJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
        return SizedBox(
          height: 44, // Sekitar 2 baris teks
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
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
                      GoogleFonts.inter(
                        fontSize: 14,
                        color: Get.isDarkMode ? Colors.white54 : Colors.grey.shade500,
                        height: 1.4,
                      ),
                      const VerticalSpacing(0, 0),
                      const VerticalSpacing(0, 0),
                      null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        return SizedBox(
          height: 44,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: AbsorbPointer(
              child: HtmlWidget(
                content,
                textStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: Get.isDarkMode ? Colors.white54 : Colors.grey.shade500,
                  height: 1.4,
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      return Text('Tidak ada ringkasan...', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey));
    }
  }
}
