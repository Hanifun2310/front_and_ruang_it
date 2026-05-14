import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/loading_widget.dart';
import '../controllers/topic_recommendation_controller.dart';

class TopicRecommendationView extends GetView<TopicRecommendationController> {
  const TopicRecommendationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: LoadingWidget()),
        );
      }

      if (controller.selectedCategories.isEmpty) {
        return const Scaffold(
          body: Center(child: Text('Tidak ada topik yang dipilih.')),
        );
      }

      // Prevent index range errors during transition
      int idx = controller.currentIndex.value;
      if (idx >= controller.selectedCategories.length) idx = 0;
      
      final currentCategory = controller.selectedCategories[idx];
      final scaffoldBgColor = controller.backgroundColors[currentCategory.id] ?? const Color(0xFFFFEB3B);

      return Scaffold(
        backgroundColor: scaffoldBgColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 28),
                        onPressed: () => Get.back(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            currentCategory.name ?? 'Category',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: -1.0,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1E2B),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Text(
                            'Ikuti semua',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // PageView Main Content
              Expanded(
                child: PageView.builder(
                  controller: controller.pageController,
                  itemCount: controller.selectedCategories.length,
                  onPageChanged: controller.onPageChanged,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final category = controller.selectedCategories[index];
                    final article = controller.topArticles[category.id];

                    return AnimatedPadding(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1E2B),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: article == null
                            ? const Center(
                                child: Text(
                                  'Tidak ada artikel populer',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(24.0),
                                physics: const NeverScrollableScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'ARTIKEL POPULER',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.0,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Image Container
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.network(
                                        article.imageUrl ?? 'https://via.placeholder.com/600x400',
                                        height: MediaQuery.of(context).size.height * 0.25,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(
                                          height: MediaQuery.of(context).size.height * 0.25,
                                          color: Colors.grey[800],
                                          child: const Icon(Icons.image_not_supported, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Title
                                    Text(
                                      article.title ?? 'Untitled',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Content snippet
                                    Text(
                                      article.snippet,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                        height: 1.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
                                    const SizedBox(height: 16),
                                    // Bottom Author Area
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white24, width: 1),
                                                  image: DecorationImage(
                                                    image: NetworkImage(
                                                      article.user?.photoProfile ??
                                                          'https://via.placeholder.com/150',
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      article.user?.name ?? 'Unknown',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Popular Author',
                                                      style: TextStyle(
                                                        color: Colors.white.withOpacity(0.6),
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Actions Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.refresh, color: Colors.black87, size: 20),
                                              Container(
                                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                                width: 1,
                                                height: 14,
                                                color: Colors.black26,
                                              ),
                                              const Icon(Icons.thumb_up_outlined, color: Colors.black87, size: 20),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),

              // Footer Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: TextButton(
                        onPressed: () => controller.lanjutkan(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: const BorderSide(color: Colors.black, width: 1.2),
                          ),
                        ),
                        child: const Text(
                          'Lanjutkan',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        controller.selectedCategories.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 4,
                          width: controller.currentIndex.value == index ? 16 : 4,
                          decoration: BoxDecoration(
                            color: controller.currentIndex.value == index
                                ? Colors.black87
                                : Colors.black26,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
