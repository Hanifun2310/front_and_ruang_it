import 'package:flutter/material.dart';
import '../../../widgets/article_card.dart';
import '../../../widgets/custom_network_image.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart'
    hide DefaultStyles;
import '../controllers/profile_controller.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/theme_service.dart';
import '../../../routes/app_routes.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/skeleton_widget.dart';
import '../../../widgets/custom_bottom_nav.dart';
import '../../../widgets/guest_prompt_widget.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    if (!authService.isLoggedIn.value) {
      return Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Profil',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: const GuestPromptWidget(),
        bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
      );
    }

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 16.0,
                right: 16.0,
                left: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() {
                    final service = Get.find<NotificationService>();
                    return Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.notifications_rounded,
                            size: 28,
                            color: Get.isDarkMode
                                ? Colors.white
                                : const Color(0xFF131B2E),
                          ),
                          onPressed: () {
                            Get.toNamed(Routes.NOTIFICATIONS);
                          },
                        ),
                        if (service.unreadCount.value > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  service.unreadCount.value > 9
                                      ? '9+'
                                      : service.unreadCount.value.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.settings_rounded,
                      size: 28,
                      color: Get.isDarkMode
                          ? Colors.white
                          : const Color(0xFF131B2E),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (value) {
                      if (value == 'theme') {
                        Get.find<ThemeService>().switchTheme();
                      } else if (value == 'logout') {
                        _showLogoutConfirmation(context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'theme',
                        child: Row(
                          children: [
                            Icon(
                              Get.isDarkMode
                                  ? Icons.light_mode
                                  : Icons.dark_mode,
                              color: Get.isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF131B2E),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              Get.isDarkMode ? 'Mode Terang' : 'Mode Gelap',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Get.isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF131B2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            const Icon(Icons.logout, color: Colors.redAccent),
                            const SizedBox(width: 12),
                            Text(
                              'Keluar',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.redAccent,
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

            Expanded(
              child: SingleChildScrollView(
                controller: controller.scrollController,
                child: Column(
                  children: [
                    _buildProfileHeader(context),

                    _buildActionButtons(context),

                    const SizedBox(height: 12),

                    _buildNavigationTabs(),

                    _buildArticlesSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
          Obx(() {
            if (controller.isDeleting.value) {
              return Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: const Center(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: LoadingWidget(),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 3),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Obx(() {
      if (controller.isProfileLoading.value) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SkeletonBox(
                width: 80,
                height: 80,
                borderRadius: BorderRadius.all(Radius.circular(40)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(
                      width: 150,
                      height: 24,
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    SizedBox(height: 8),
                    SkeletonBox(
                      width: 120,
                      height: 14,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    SizedBox(height: 8),
                    SkeletonBox(
                      width: 200,
                      height: 12,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent.shade100, width: 2),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: controller.photoProfile.value.isNotEmpty
                    ? CustomNetworkImage(imageUrl: 
                        controller.photoProfile.value,
                        fit: BoxFit.cover,
                        errorWidget: (context, error, stackTrace) =>
                            _buildAvatarFallback(),
                      )
                    : _buildAvatarFallback(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.name.value.isNotEmpty
                        ? controller.name.value
                        : "Sobat IT",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Get.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.profession.value.isNotEmpty
                        ? controller.profession.value
                        : "Pekerjaan belum diisi",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Get.isDarkMode
                          ? Colors.white70
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.bio.value.isNotEmpty
                        ? controller.bio.value
                        : "Bio belum diisi.",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Get.isDarkMode
                          ? Colors.white54
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAvatarFallback() {
    return Image.asset('assets/images/fallback_pp.png', fit: BoxFit.cover);
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showStatsPopup(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Text(
                'Statistik',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showEditProfileSheet(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Get.isDarkMode
                    ? Colors.white
                    : Colors.grey.shade800,
                side: BorderSide(
                  color: Get.isDarkMode ? Colors.white30 : Colors.grey.shade400,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Edit profil Anda',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Get.isDarkMode ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Obx(
        () => Row(
          children: [
            _buildTab('Semua Artikel', 0),
            _buildTab('Artikel Favorit', 1),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = controller.selectedTab.value == index;
    return Expanded(
      child: InkWell(
        onTap: () => controller.selectedTab.value = index,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? (Get.isDarkMode ? Colors.white : Colors.black)
                    : Colors.transparent,
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
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _showStatsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Get.isDarkMode
            ? const Color(0xFF1E293B)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Statistik Anda',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Get.isDarkMode ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow(
              Icons.article_outlined,
              'Artikel',
              '${controller.articlesCount.value}',
              Colors.blue,
            ),
            const Divider(height: 24),
            _buildStatRow(
              Icons.thumb_up,
              'Total Likes',
              '${controller.likesCount.value}',
              Colors.blueAccent,
            ),
            const Divider(height: 24),
            _buildStatRow(
              Icons.chat_bubble_outline,
              'Komentar',
              '${controller.commentsCount.value}',
              Colors.green,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Tutup',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withAlpha((0.1 * 255).round()),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Get.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildArticlesSection() {
    return Obx(() {
      if (controller.isArticlesLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: SkeletonList(itemCount: 3, scrollable: false),
        );
      }

      final isMyArticlesTab = controller.selectedTab.value == 0;
      final currentArticles = isMyArticlesTab
          ? controller.filteredUserArticles
          : controller.filteredLikedArticles;
      final hasActiveFilter = isMyArticlesTab
          ? (controller.articleSearchQuery.value.isNotEmpty ||
              controller.selectedCategoryFilter.value != null)
          : (controller.likedSearchQuery.value.isNotEmpty ||
              controller.selectedLikedCategoryFilter.value != null);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar & chip kategori: Semua Artikel ──
          if (isMyArticlesTab) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: controller.articleSearchController,
                onChanged: (v) => controller.articleSearchQuery.value = v,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Get.isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari artikel kamu...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  suffixIcon: Obx(
                    () => controller.articleSearchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: controller.clearArticleSearch,
                          )
                        : const SizedBox.shrink(),
                  ),
                  filled: true,
                  fillColor: Get.isDarkMode
                      ? const Color.fromRGBO(255, 255, 255, 0.06)
                      : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (controller.availableCategories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            'Semua',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          selected:
                              controller.selectedCategoryFilter.value == null,
                          onSelected: (_) =>
                              controller.selectedCategoryFilter.value = null,
                          selectedColor: const Color(0xFF092BA2),
                          checkmarkColor: Colors.white,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color:
                                controller.selectedCategoryFilter.value == null
                                ? Colors.white
                                : (Get.isDarkMode
                                      ? Colors.white70
                                      : Colors.black87),
                          ),
                          backgroundColor: Get.isDarkMode
                              ? const Color.fromRGBO(255, 255, 255, 0.08)
                              : Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide.none,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                      ),
                      ...controller.availableCategories.map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              cat,
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            selected:
                                controller.selectedCategoryFilter.value == cat,
                            onSelected: (_) {
                              controller.selectedCategoryFilter.value =
                                  controller.selectedCategoryFilter.value == cat
                                  ? null
                                  : cat;
                            },
                            selectedColor: const Color(0xFF092BA2),
                            checkmarkColor: Colors.white,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              color:
                                  controller.selectedCategoryFilter.value == cat
                                  ? Colors.white
                                  : (Get.isDarkMode
                                        ? Colors.white70
                                        : Colors.black87),
                            ),
                            backgroundColor: Get.isDarkMode
                                ? const Color.fromRGBO(255, 255, 255, 0.08)
                                : Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide.none,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],

          // ── Search bar & chip kategori: Artikel Favorit ──
          if (!isMyArticlesTab) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: controller.likedArticleSearchController,
                onChanged: (v) => controller.likedSearchQuery.value = v,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Get.isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari artikel favorit...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  suffixIcon: Obx(
                    () => controller.likedSearchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: controller.clearLikedSearch,
                          )
                        : const SizedBox.shrink(),
                  ),
                  filled: true,
                  fillColor: Get.isDarkMode
                      ? const Color.fromRGBO(255, 255, 255, 0.06)
                      : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (controller.availableLikedCategories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            'Semua',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          selected: controller.selectedLikedCategoryFilter.value == null,
                          onSelected: (_) =>
                              controller.selectedLikedCategoryFilter.value = null,
                          selectedColor: const Color(0xFF092BA2),
                          checkmarkColor: Colors.white,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color: controller.selectedLikedCategoryFilter.value == null
                                ? Colors.white
                                : (Get.isDarkMode ? Colors.white70 : Colors.black87),
                          ),
                          backgroundColor: Get.isDarkMode
                              ? const Color.fromRGBO(255, 255, 255, 0.08)
                              : Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide.none,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                      ),
                      ...controller.availableLikedCategories.map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              cat,
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            selected: controller.selectedLikedCategoryFilter.value == cat,
                            onSelected: (_) {
                              controller.selectedLikedCategoryFilter.value =
                                  controller.selectedLikedCategoryFilter.value == cat
                                  ? null
                                  : cat;
                            },
                            selectedColor: const Color(0xFF092BA2),
                            checkmarkColor: Colors.white,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              color: controller.selectedLikedCategoryFilter.value == cat
                                  ? Colors.white
                                  : (Get.isDarkMode ? Colors.white70 : Colors.black87),
                            ),
                            backgroundColor: Get.isDarkMode
                                ? const Color.fromRGBO(255, 255, 255, 0.08)
                                : Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide.none,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],

          if (currentArticles.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  children: [
                    Icon(
                      hasActiveFilter
                          ? Icons.search_off_rounded
                          : Icons.article_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      hasActiveFilter
                          ? 'Tidak ada artikel yang cocok'
                          : isMyArticlesTab
                          ? 'Belum ada artikel'
                          : 'Belum ada artikel favorit',
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 8,
                  ),
                  itemCount: currentArticles.length,
                  itemBuilder: (context, index) {
                    final article = currentArticles[index];
                    return ArticleCard(article: article, onLikeToggle: (id) => controller.toggleLike(id), onDelete: (id) => controller.deleteArticle(id));
                  },
                ),
                if (isMyArticlesTab && controller.hasMoreUserArticles.value)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: controller.isLoadingMoreArticles.value
                            ? null
                            : controller.loadMoreUserArticles,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: controller.isLoadingMoreArticles.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Muat lebih banyak',
                                style: TextStyle(fontSize: 14),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      );
    });
  }


  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin keluar?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Keluar', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPhotoOptions(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Obx(() {
          final hasPhoto = controller.selectedImagePath.value.isNotEmpty ||
              controller.photoProfile.value.isNotEmpty;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Foto Profil',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Get.isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  controller.pickImage();
                },
                icon: const Icon(Icons.photo_library, color: Colors.white),
                label: Text(
                  'Pilih dari Galeri',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (hasPhoto) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Get.back();
                    controller.clearProfilePhoto();
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: Text(
                    'Hapus Foto Profil',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, color: Colors.redAccent),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Batal',
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    final originalSelectedPath = controller.selectedImagePath.value;
    final originalSelectedBytes = List<int>.from(controller.selectedImageBytes);
    final originalSelectedFileName = controller.selectedFileName.value;
    final originalPhotoProfile = controller.photoProfile.value;
    final originalShouldRemove = controller.shouldRemovePhotoOnServer.value;

    controller.nameController.text = controller.name.value;
    controller.professionController.text = controller.profession.value;
    controller.bioController.text = controller.bio.value;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profil',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Get.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => _showPhotoOptions(context),
                  child: Obx(() {
                    ImageProvider? imageProvider;
                    if (controller.selectedImagePath.value.isNotEmpty) {
                      imageProvider = kIsWeb 
                          ? NetworkImage(controller.selectedImagePath.value) 
                          : FileImage(File(controller.selectedImagePath.value)) as ImageProvider;
                    } else if (controller.photoProfile.value.isNotEmpty) {
                      imageProvider = NetworkImage(controller.photoProfile.value);
                    } else {
                      imageProvider = const AssetImage('assets/images/fallback_pp.png');
                    }

                    return Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: imageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller.nameController,
                style: TextStyle(color: Get.isDarkMode ? Colors.white : Colors.black87),
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.professionController,
                style: TextStyle(color: Get.isDarkMode ? Colors.white : Colors.black87),
                decoration: const InputDecoration(labelText: 'Pekerjaan / Jabatan'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.bioController,
                style: TextStyle(color: Get.isDarkMode ? Colors.white : Colors.black87),
                decoration: const InputDecoration(labelText: 'Bio Singkat'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : () => controller.updateProfile(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Simpan Perubahan', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                )),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    ).then((_) {
      if (!controller.isLoading.value) {
        controller.selectedImagePath.value = originalSelectedPath;
        controller.selectedImageBytes.value = originalSelectedBytes;
        controller.selectedFileName.value = originalSelectedFileName;
        controller.photoProfile.value = originalPhotoProfile;
        controller.shouldRemovePhotoOnServer.value = originalShouldRemove;
      }
    });
  }
}
