import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../routes/app_routes.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
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
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Ruang IT', 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 20, 
            color: Color(0xFF0F172A),
            fontFamily: 'Manrope',
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: const NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuB3s6aUqDqZhug8-pC0sZfO2QGoQKDxLmtcJE6J_gRYXRQg1B7UXEZMr_-nmns99W1Q59IOtxu4gtnq7aW6HeeogkxJUiQC_HWdQ1-hmSUnMi1GhN3HWcq-bFTLMzYc3VkgSqCQfUah0cGfYQtTdcD4eV2r0uj-5PC5ogJ7DflWiG30QYJj3oyKJUVWAO8l4HDteZIAQFmuDBBYJttaSGB-mdhh0mtHNTwLF8hE1G0xCpGpDpR5u6X_7FQlyHyh0DnPkw1h8ShZk2rF'),
            ),
          )
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFC5C5D6)),
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
                decoration: const InputDecoration(
                  hintText: 'Cari judul atau penulis...',
                  hintStyle: TextStyle(color: Color(0xFF757685), fontSize: 15),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF757685)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
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
                        color: isSelected ? const Color(0xFF092BA2) : const Color(0xFFF2F3FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : const Color(0xFFC5C5D6),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF444653),
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
                return const Center(child: Text("Belum ada artikel di kategori ini."));
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

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC5C5D6)),
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
                                      style: const TextStyle(
                                        color: Color(0xFF092BA2),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
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
                                    style: const TextStyle(
                                      fontSize: 18, 
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF131B2E),
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  HtmlWidget(
                                    '<div class="truncate">${article.content ?? 'Tidak ada ringkasan...'}</div>',
                                    customStylesBuilder: (element) {
                                      if (element.classes.contains('truncate')) {
                                        return {
                                          'max-lines': '2',
                                          'text-overflow': 'ellipsis',
                                        };
                                      }
                                      return null;
                                    },
                                    textStyle: const TextStyle(
                                      color: Color(0xFF444653), 
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
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
                                              style: const TextStyle(
                                                fontSize: 13, 
                                                fontWeight: FontWeight.w600, 
                                                color: Color(0xFF131B2E),
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
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF5F6473)),
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(Icons.chat_bubble, size: 18, color: Color(0xFF5F6473)),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${article.commentsCount ?? 0}', 
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF5F6473)),
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
          color: Colors.white.withValues(alpha: 0.9),
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF2D46B9),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) {
              Get.toNamed(Routes.ARTICLE_CREATE);
            } else if (index == 2) {
              Get.toNamed(Routes.PROFILE);
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.add_circle_outline)),
              label: 'Add',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}