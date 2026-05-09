import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../data/services/theme_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/auth_service.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller untuk mendeteksi scroll mentok ke bawah (untuk load more)
    final ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 50) {
        controller.loadMoreArticles();
      }
    });

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.appBarTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/images/newlogo.png',
          height: 36,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Get.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Get.isDarkMode ? Colors.white : const Color(0xFF131B2E),
            ),
            onPressed: () => Get.find<ThemeService>().switchTheme(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade200,
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Get.isDarkMode ? Colors.white12 : const Color(0xFFC5C5D6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                textInputAction: TextInputAction.search,
                onSubmitted: (value) => controller.searchArticles(value),
                style: GoogleFonts.kulimPark(fontSize: 15, color: Get.isDarkMode ? Colors.white : const Color(0xFF131B2E)),
                decoration: InputDecoration(
                  hintText: 'Cari judul atau penulis...',
                  hintStyle: GoogleFonts.kulimPark(color: const Color(0xFF757685), fontSize: 15),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF757685)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          
          // --- HORIZONTAL KATEGORI ---
          SizedBox(
            height: 40,
            child: Obx(() => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: controller.categories.length + 1,
              itemBuilder: (context, index) {
                final isSemua = index == 0;
                final category = isSemua ? null : controller.categories[index - 1];
                final isSelected = isSemua 
                    ? controller.selectedCategory.value == null 
                    : controller.selectedCategory.value?.id == category?.id;
                final categoryName = isSemua ? 'Semua' : (category?.name ?? '');

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () => controller.changeCategory(category),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF092BA2) 
                            : (Get.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF2F3FF)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected 
                              ? Colors.transparent 
                              : (Get.isDarkMode ? Colors.white10 : const Color(0xFFC5C5D6)),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          categoryName,
                          style: GoogleFonts.kulimPark(
                            color: isSelected 
                                ? Colors.white 
                                : (Get.isDarkMode ? Colors.white70 : const Color(0xFF444653)),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            )),
          ),
          const SizedBox(height: 16),
          
          // --- DAFTAR ARTIKEL (INFINITE SCROLL) ---
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.articles.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.articles.isEmpty) {
                return Center(child: Text("Belum ada artikel di kategori ini.", style: GoogleFonts.kulimPark()));
              }

              return RefreshIndicator(
                onRefresh: () async => controller.changeCategory(controller.selectedCategory.value),
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: controller.articles.length + (controller.hasMoreData.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    
                    if (index == controller.articles.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final article = controller.articles[index];
                    final String imageUrl = article.imageUrl ?? 'https://via.placeholder.com/600x400';
                    final String avatarUrl = article.user?.photoProfile ?? 'https://via.placeholder.com/150';
                    final String categoryName = article.category?.name ?? 'Umum';
                    final authService = Get.find<AuthService>();
                    final currentUserId = authService.currentUser?['id'];
                    final bool isAuthor = article.user?.id != null && article.user?.id == currentUserId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Get.isDarkMode ? Colors.white10 : const Color(0xFFC5C5D6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Get.toNamed(Routes.ARTICLE_DETAIL, arguments: article.slug);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Gambar dan Kategori
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    height: 180,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: double.infinity,
                                        height: 180,
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      categoryName,
                                      style: GoogleFonts.kulimPark(
                                        color: const Color(0xFF092BA2),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isAuthor)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () {
                                        _showArticleOptions(context, article);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.more_vert,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            
                            // Konten
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article.title ?? 'Tanpa Judul',
                                    style: GoogleFonts.kulimPark(
                                      fontSize: 18, 
                                      fontWeight: FontWeight.w700,
                                      color: context.theme.textTheme.bodyLarge?.color,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    article.snippet,
                                    style: GoogleFonts.kulimPark(
                                      color: Get.isDarkMode ? Colors.white70 : const Color(0xFF444653), 
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Footer Card
                                  Container(
                                    padding: const EdgeInsets.only(top: 12),
                                    decoration: const BoxDecoration(
                                      border: Border(top: BorderSide(color: Color(0xFFC5C5D6))),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Author
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundImage: NetworkImage(avatarUrl),
                                              onBackgroundImageError: (_, _) {},
                                              backgroundColor: Colors.grey.shade300,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              article.user?.name ?? 'Admin',
                                              style: GoogleFonts.kulimPark(
                                                fontSize: 13, 
                                                fontWeight: FontWeight.w600, 
                                                color: Get.isDarkMode ? Colors.white : const Color(0xFF131B2E),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Likes & Comments
                                        Row(
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                if (article.id != null) {
                                                  controller.toggleLike(article.id!);
                                                }
                                              },
                                              child: Icon(
                                                (article.isLiked ?? false) ? Icons.favorite : Icons.favorite_border, 
                                                size: 18, 
                                                color: (article.isLiked ?? false) ? Colors.red : const Color(0xFF5F6473),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${article.likesCount ?? 0}', 
                                              style: GoogleFonts.kulimPark(fontSize: 12, color: const Color(0xFF5F6473)),
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(Icons.chat_bubble, size: 18, color: Color(0xFF5F6473)),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${article.commentsCount ?? 0}', 
                                              style: GoogleFonts.kulimPark(fontSize: 12, color: const Color(0xFF5F6473)),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
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
          selectedItemColor: Get.isDarkMode ? Colors.blueAccent : const Color(0xFF092BA2),
          unselectedItemColor: const Color(0xFF757685),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: GoogleFonts.kulimPark(fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.kulimPark(fontWeight: FontWeight.w600),
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) {
              Get.offNamed(Routes.ARTICLE_CREATE);
            } else if (index == 2) {
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
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.add_circle_outline)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.add_circle)),
              label: 'Add',
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
              style: GoogleFonts.kulimPark(
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
                style: GoogleFonts.kulimPark(
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
                style: GoogleFonts.kulimPark(
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
          style: GoogleFonts.kulimPark(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus artikel ini secara permanen?',
          style: GoogleFonts.kulimPark(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Batal',
              style: GoogleFonts.kulimPark(color: Colors.grey),
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
              style: GoogleFonts.kulimPark(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}