import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({Key? key}) : super(key: key);

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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Ruang IT', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => Get.find<AuthService>().logout(),
            tooltip: 'Logout',
          )
        ],
      ),
      body: Column(
        children: [
          // --- HORIZONTAL KATEGORI ---
          Container(
            color: Colors.white,
            height: 60,
            child: Obx(() => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: controller.categories.length,
              itemBuilder: (context, index) {
                final category = controller.categories[index];
                final isSelected = controller.selectedCategory.value == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) controller.changeCategory(category);
                    },
                    selectedColor: Colors.blueAccent,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                  ),
                );
              },
            )),
          ),
          
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
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.articles.length + (controller.hasMoreData.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    
                    // Jika mencapai item terakhir, tampilkan loading kecil di bawah
                    if (index == controller.articles.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final article = controller.articles[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () {
                          // Nanti akan kita arahkan ke Detail Artikel
                          Get.toNamed(Routes.ARTICLE_DETAIL, arguments: article.slug);
                          Get.snackbar('Info', 'Navigasi ke artikel: ${article.title}');
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.title ?? 'Tanpa Judul',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                             Text(
                            // Menambahkan Regex untuk membuang tag HTML (<p>, <b>, dll) dan entitas (&nbsp;)
                            (article.content ?? 'Tidak ada ringkasan...').replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim(),
                            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    article.user?.name ?? 'Admin',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('${article.likesCount ?? 0}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.comment_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('${article.commentsCount ?? 0}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
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
    );
  }
}