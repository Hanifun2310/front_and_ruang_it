import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/author_profile_controller.dart';
import '../../../routes/app_routes.dart';

class AuthorProfileView extends GetView<AuthorProfileController> {
  const AuthorProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.appBarTheme.foregroundColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Profil Penulis',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: context.theme.appBarTheme.foregroundColor,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Get.isDarkMode ? Colors.white10 : const Color(0xFFE2E7FF),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(context),
            // Stats Grid
            _buildStatsGrid(),
            const SizedBox(height: 24),
            // Articles Section
            _buildArticlesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final author = controller.author;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E7FF), width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.network(
                author.photoProfile ?? 'https://via.placeholder.com/150',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.network(
                  'https://ui-avatars.com/api/?name=${author.name}',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            author.name ?? 'Penulis',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            author.profession ?? "Tech Enthusiast",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Get.isDarkMode ? Colors.blueAccent : const Color(0xFF092BA2),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              author.bio ?? "Belum ada bio.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Get.isDarkMode ? Colors.grey.shade400 : const Color(0xFF444653),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 1, child: _buildArticlesCard()),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildHorizontalStatCard(
                    "LIKES",
                    controller.likesCount,
                    Icons.favorite,
                    const Color(0xFFFFEFE2),
                    const Color(0xFF8B4513),
                  ),
                  const SizedBox(height: 12),
                  _buildHorizontalStatCard(
                    "COMMENTS",
                    controller.commentsCount,
                    Icons.chat_bubble_rounded,
                    const Color(0xFFEEF2FF),
                    const Color(0xFF4B5563),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Get.isDarkMode ? Colors.white12 : const Color(0xFFE2E7FF)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.article_rounded,
              color: Color(0xFF092BA2),
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Obx(
            () => Text(
              "${controller.articlesCount.value}",
              style: GoogleFonts.kulimPark(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Get.isDarkMode ? Colors.white : const Color(0xFF131B2E),
              ),
            ),
          ),
          Text(
            "ARTICLES",
            style: GoogleFonts.kulimPark(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Get.isDarkMode ? Colors.white70 : const Color(0xFF444653),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStatCard(
    String label,
    RxInt count,
    IconData icon,
    Color iconBg,
    Color iconColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Get.isDarkMode ? Colors.white10 : const Color(0xFFE2E7FF)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.kulimPark(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF757685),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Obx(
              () => Text(
                count.value > 999
                    ? "${(count.value / 1000).toStringAsFixed(1)}k"
                    : "${count.value}",
                style: GoogleFonts.kulimPark(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Get.isDarkMode ? Colors.white : const Color(0xFF131B2E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "ARTIKEL PENULIS",
            style: GoogleFonts.kulimPark(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.isArticlesLoading.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final currentArticles = controller.userArticles;

          if (currentArticles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Penulis belum menerbitkan artikel.",
                      style: GoogleFonts.kulimPark(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: currentArticles.length,
            itemBuilder: (context, index) {
              final article = currentArticles[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Get.isDarkMode ? Colors.white10 : const Color(0xFFE2E7FF)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => Get.toNamed(Routes.ARTICLE_DETAIL, arguments: article.slug),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child: Image.network(
                          article.imageUrl ?? 'https://via.placeholder.com/150',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey.shade100,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Get.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF2F3FF),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      article.category?.name?.toUpperCase() ?? "GENERAL",
                                      style: GoogleFonts.kulimPark(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Get.isDarkMode ? Colors.blueAccent : const Color(0xFF092BA2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                article.title ?? "Untitled",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.kulimPark(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: context.theme.textTheme.bodyLarge?.color,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
        const SizedBox(height: 32),
      ],
    );
  }
}
