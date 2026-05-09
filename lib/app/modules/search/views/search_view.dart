import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/search_controller.dart';
import '../../../routes/app_routes.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' hide DefaultStyles;
import '../../../data/services/auth_service.dart';

class SearchView extends GetView<ArticleSearchController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController textController = TextEditingController();
    
    // Sync text controller with observable query (for history selection)
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
          // Search Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: textController,
              onChanged: controller.onSearchChanged,
              autofocus: true,
              style: GoogleFonts.inter(
                color: Get.isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Cari artikel, penulis, atau kategori...',
                hintStyle: GoogleFonts.inter(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          textController.clear();
                          controller.onSearchChanged('');
                        },
                      )
                    : const SizedBox()),
                filled: true,
                fillColor: Get.isDarkMode ? Colors.white10 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),

          // Search Results or History
          Expanded(
            child: Obx(() {
              if (controller.searchQuery.value.isEmpty) {
                return _buildHistorySection();
              }

              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.articles.isEmpty) {
                return _buildNoResults();
              }

              return ListView.builder(
                itemCount: controller.articles.length,
                itemBuilder: (context, index) {
                  final article = controller.articles[index];
                  return _buildArticleCard(context, article);
                },
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
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

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Tidak ada artikel ditemukan',
            style: GoogleFonts.inter(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, dynamic article) {
    final String imageUrl = article.imageUrl ?? 'https://via.placeholder.com/600x400';
    final String avatarUrl = article.user?.photoProfile ?? 'https://via.placeholder.com/150';
    final String categoryName = article.category?.name ?? 'Umum';
    
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
                    Row(
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
          height: 44,
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
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Get.offNamed(Routes.DASHBOARD);
          } else if (index == 1) {
            Get.offNamed(Routes.EXPLORE);
          } else if (index == 2) {
            // Already here
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
