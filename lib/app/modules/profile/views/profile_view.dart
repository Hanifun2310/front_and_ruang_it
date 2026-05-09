import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' hide DefaultStyles;
import '../controllers/profile_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/theme_service.dart';
import '../../../routes/app_routes.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../widgets/loading_widget.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Area (Placeholder for Settings Icon)
            Padding(
              padding: const EdgeInsets.only(top: 16.0, right: 16.0, left: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      size: 28,
                      color: Get.isDarkMode ? Colors.white : const Color(0xFF131B2E),
                    ),
                    onPressed: () => Get.toNamed(Routes.ARTICLE_CREATE),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.settings_outlined,
                      size: 28,
                      color: Get.isDarkMode ? Colors.white : const Color(0xFF131B2E),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                              Get.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                              color: Get.isDarkMode ? Colors.white : const Color(0xFF131B2E),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              Get.isDarkMode ? 'Mode Terang' : 'Mode Gelap',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Get.isDarkMode ? Colors.white : const Color(0xFF131B2E),
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
                child: Column(
                  children: [
                    // Profile Header Info
                    _buildProfileHeader(context),
                    
                    // Action Buttons
                    _buildActionButtons(context),

                    const SizedBox(height: 12),

                    // Navigation Tabs
                    _buildNavigationTabs(),

                    // Article Feed
                    _buildArticlesSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Obx(() => Container(
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
                ? Image.network(
                    controller.photoProfile.value,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                  )
                : _buildAvatarFallback(),
            ),
          )),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                  controller.name.value.isNotEmpty ? controller.name.value : "Sobat IT",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Get.isDarkMode ? Colors.white : Colors.black87,
                  ),
                )),
                const SizedBox(height: 4),
                Obx(() => Text(
                  controller.profession.value.isNotEmpty ? controller.profession.value : "Pekerjaan belum diisi",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade600,
                  ),
                )),
                const SizedBox(height: 4),
                Obx(() => Text(
                  controller.bio.value.isNotEmpty ? controller.bio.value : "Bio belum diisi.",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Get.isDarkMode ? Colors.white54 : Colors.grey.shade500,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Icon(Icons.person, size: 50, color: Colors.grey.shade300);
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
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showEditProfileSheet(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Get.isDarkMode ? Colors.white : Colors.grey.shade800,
                side: BorderSide(color: Get.isDarkMode ? Colors.white30 : Colors.grey.shade400),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Edit profil Anda',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
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
        border: Border(bottom: BorderSide(color: Get.isDarkMode ? Colors.white10 : Colors.grey.shade200)),
      ),
      child: Obx(() => Row(
        children: [
          _buildTab('Semua Artikel', 0),
          _buildTab('Artikel Favorit', 1),
        ],
      )),
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
        backgroundColor: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Statistik Anda',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Get.isDarkMode ? Colors.white : Colors.black87),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow(Icons.article_outlined, 'Artikel', '${controller.articlesCount.value}', Colors.blue),
            const Divider(height: 24),
            _buildStatRow(Icons.thumb_up_alt_outlined, 'Total Likes', '${controller.likesCount.value}', Colors.redAccent),
            const Divider(height: 24),
            _buildStatRow(Icons.chat_bubble_outline, 'Komentar', '${controller.commentsCount.value}', Colors.green),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Tutup', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 16, color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Get.isDarkMode ? Colors.white : Colors.black87),
        ),
      ],
    );
  }

  Widget _buildArticlesSection() {
    return Obx(() {
      if (controller.isArticlesLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: const LoadingWidget(),
          ),
        );
      }

      final currentArticles = controller.selectedTab.value == 0 
          ? controller.userArticles 
          : controller.likedArticles;

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
                  controller.selectedTab.value == 0 ? "Belum ada artikel" : "Belum ada artikel favorit",
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        itemCount: currentArticles.length,
        itemBuilder: (context, index) {
          final article = currentArticles[index];
          return _buildArticleCard(context, article);
        },
      );
    });
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
            if (article.isBlocked) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Artikel ini telah diblokir dan tidak tampil di publik.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                _showDeleteConfirmation(context, article);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, dynamic article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          'Hapus Artikel',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus artikel "${article.title}"? Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteArticle(article.id!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Hapus', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Get.offNamed(Routes.DASHBOARD);
          } else if (index == 1) {
            Get.offNamed(Routes.EXPLORE);
          } else if (index == 2) {
            Get.offNamed(Routes.SEARCH);
          } else if (index == 3) {
            // Already on profile
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

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          'Keluar',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: GoogleFonts.inter(),
        ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text('Keluar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              "Edit Profil",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Get.isDarkMode ? Colors.white : const Color(0xFF131B2E),
              ),
            ),
            const SizedBox(height: 24),
            
            // Edit Photo Section
            Center(
              child: Stack(
                children: [
                  Obx(
                    () => Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Get.isDarkMode ? Colors.white24 : const Color(0xFFE2E7FF), width: 4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: controller.selectedImagePath.value.isNotEmpty
                            ? (kIsWeb
                                ? Image.network(
                                    controller.selectedImagePath.value,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(controller.selectedImagePath.value),
                                    fit: BoxFit.cover,
                                  ))
                            : Image.network(
                                controller.photoProfile.value,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.network(
                                  'https://ui-avatars.com/api/?name=${controller.name.value}',
                                ),
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: controller.pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF092BA2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            TextField(
              controller: controller.nameController,
              style: GoogleFonts.inter(color: Get.isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: "Nama Lengkap",
                labelStyle: GoogleFonts.inter(color: Colors.grey),
                prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Get.isDarkMode ? Colors.white24 : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Get.isDarkMode ? Colors.white24 : Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.professionController,
              style: GoogleFonts.inter(color: Get.isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: "Pekerjaan",
                labelStyle: GoogleFonts.inter(color: Colors.grey),
                prefixIcon: const Icon(Icons.work_outline, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Get.isDarkMode ? Colors.white24 : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Get.isDarkMode ? Colors.white24 : Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.bioController,
              style: GoogleFonts.inter(color: Get.isDarkMode ? Colors.white : Colors.black87),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Bio",
                labelStyle: GoogleFonts.inter(color: Colors.grey),
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Get.isDarkMode ? Colors.white24 : Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Get.isDarkMode ? Colors.white24 : Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF092BA2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: controller.isLoading.value
                      ? const LoadingWidget(
                          size: 20,
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : Text(
                          "SIMPAN PERUBAHAN",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
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
