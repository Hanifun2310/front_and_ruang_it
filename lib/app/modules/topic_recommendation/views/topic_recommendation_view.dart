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
      final scaffoldBgColor =
          controller.backgroundColors[currentCategory.id] ??
          const Color(0xFFFFEB3B);

      return Scaffold(
        backgroundColor: scaffoldBgColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 28,
                        ),
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
                        if (controller.topArticles[currentCategory.id] != null)
                          GestureDetector(
                            onTap: () => controller.goToArticleDetail(
                              controller.topArticles[currentCategory.id]!,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1E2B),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: const Text(
                                'Baca artikel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // PageView Main Content with Navigation Arrows
              Expanded(
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: controller.pageController,
                      itemCount: controller.selectedCategories.length,
                      onPageChanged: controller.onPageChanged,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final category = controller.selectedCategories[index];
                        final article = controller.topArticles[category.id];

                        return AnimatedPadding(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40.0, // More space for arrows
                            vertical: 12.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1E2B),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: article == null
                                ? const Center(
                                    child: Text(
                                      'Mencari artikel populer...',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    padding: const EdgeInsets.all(24.0),
                                    physics: const BouncingScrollPhysics(),
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
                                            article.imageUrl ??
                                                'https://via.placeholder.com/600x400',
                                            height:
                                                MediaQuery.of(context).size.height *
                                                0.22,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => Container(
                                              height:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.height *
                                                  0.22,
                                              color: Colors.grey[800],
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        // Title
                                        Text(
                                          article.title ?? 'Untitled',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Content snippet
                                        Text(
                                          article.snippet,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 13,
                                            height: 1.5,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Divider(
                                          color: Colors.white.withOpacity(0.1),
                                          thickness: 1,
                                        ),
                                        const SizedBox(height: 12),
                                        // Bottom Author Area
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 38,
                                                    height: 38,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Colors.white24,
                                                        width: 1,
                                                      ),
                                                      image: DecorationImage(
                                                        image: NetworkImage(
                                                          article
                                                                  .user
                                                                  ?.photoProfile ??
                                                              'https://via.placeholder.com/150',
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          article.user?.name ??
                                                              'Unknown',
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Top Creator',
                                                          style: TextStyle(
                                                            color: Colors.white
                                                                .withOpacity(0.6),
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Action Pill
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.9),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.thumb_up, color: Colors.blueAccent, size: 16),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${article.likesCount ?? 0}',
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
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
                    // Navigation Arrows
                    if (controller.currentIndex.value > 0)
                      Positioned(
                        left: 5,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.black87, size: 40),
                            onPressed: () => controller.pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                          ),
                        ),
                      ),
                    if (controller.currentIndex.value < controller.selectedCategories.length - 1)
                      Positioned(
                        right: 5,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.black87, size: 40),
                            onPressed: () => controller.pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                          ),
                        ),
                      ),
                  ],
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
                            side: const BorderSide(
                              color: Colors.black,
                              width: 1.2,
                            ),
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
                          width: controller.currentIndex.value == index
                              ? 16
                              : 4,
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
