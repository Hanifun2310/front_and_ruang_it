import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/profile_controller.dart';
import '../../../data/models/article_model.dart';
import '../../../routes/app_routes.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../data/services/theme_service.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Ruang IT',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: context.theme.appBarTheme.foregroundColor,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.settings,
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
                      style: GoogleFonts.kulimPark(
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
                      style: GoogleFonts.kulimPark(
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Get.isDarkMode ? Colors.white10 : const Color(0xFFE2E7FF), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- PROFILE HEADER ---
            _buildProfileHeader(context),

            // --- STATS GRID ---
            _buildStatsGrid(),

            const SizedBox(height: 32), // Perlebar jarak ke section bawah

            // --- TABS & ARTICLES ---
            _buildArticlesSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Obx(
            () => Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E7FF), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.network(
                  controller.photoProfile.value,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.network(
                    'https://ui-avatars.com/api/?name=${controller.name.value}',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Text(
              controller.name.value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: context.theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Obx(
            () => Text(
              controller.profession.value.isNotEmpty
                  ? controller.profession.value
                  : "Tech Enthusiast",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Get.isDarkMode ? Colors.blueAccent : const Color(0xFF092BA2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                controller.bio.value.isNotEmpty
                    ? controller.bio.value
                    : "No bio yet.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Get.isDarkMode ? Colors.grey.shade400 : const Color(0xFF444653),
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showEditProfileSheet(context),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text("EDIT PROFILE"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF092BA2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _showLogoutConfirmation(context),
            icon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
            label: Text(
              "LOGOUT",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
                letterSpacing: 1,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Card: Articles
            Expanded(flex: 1, child: _buildArticlesCard()),
            const SizedBox(width: 12),
            // Right Column: Likes & Comments
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildHorizontalStatCard(
                    "LIKES",
                    controller.likesCount,
                    Icons.favorite,
                    const Color(0xFFFFEFE2), // Light Orange/Brown circle
                    const Color(0xFF8B4513), // Brown heart
                  ),
                  const SizedBox(height: 12),
                  _buildHorizontalStatCard(
                    "COMMENTS",
                    controller.commentsCount,
                    Icons.chat_bubble_rounded,
                    const Color(0xFFEEF2FF), // Light Blue circle
                    const Color(0xFF4B5563), // Grey bubble
                    fontSize: 6.5,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
    Color iconColor, {
    double fontSize = 10,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Get.isDarkMode ? Colors.white10 : const Color(0xFFE2E7FF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                      fontSize: fontSize,
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

  Widget _buildArticlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Buat jarak space evenly
                children: [
                  GestureDetector(
                    onTap: () => controller.selectedTab.value = 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Semua Artikel",
                          style: GoogleFonts.kulimPark(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: controller.selectedTab.value == 0 ? (Get.isDarkMode ? Colors.blueAccent : const Color(0xFF092BA2)) : Colors.grey,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (controller.selectedTab.value == 0)
                          Container(height: 2, width: 40, color: Get.isDarkMode ? Colors.blueAccent : const Color(0xFF092BA2))
                        else
                          const SizedBox(height: 2),
                      ],
                    ),
                  ),
                  // Hapus SizedBox(width: 24) karena sudah pakai spaceEvenly
                  GestureDetector(
                    onTap: () => controller.selectedTab.value = 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Artikel Favorit",
                          style: GoogleFonts.kulimPark(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: controller.selectedTab.value == 1 ? (Get.isDarkMode ? Colors.blueAccent : const Color(0xFF092BA2)) : Colors.grey,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (controller.selectedTab.value == 1)
                          Container(height: 2, width: 40, color: Get.isDarkMode ? Colors.blueAccent : const Color(0xFF092BA2))
                        else
                          const SizedBox(height: 2),
                      ],
                    ),
                  ),
                ],
              )),
            ],
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
              return _buildArticleCard(context, article);
            },
          );
        }),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildArticleCard(BuildContext context, ArticleModel article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Get.isDarkMode ? Colors.white10 : const Color(0xFFE2E7FF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: () =>
                  Get.toNamed(Routes.ARTICLE_DETAIL, arguments: article.slug),
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
                                  article.category?.name?.toUpperCase() ??
                                      "GENERAL",
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
          ),
          // Show menu only if user is author
          if (article.user?.id == controller.userId.value)
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: Color(0xFF757685),
                ),
                padding: EdgeInsets.zero,
                onSelected: (value) async {
                  if (value == 'edit') {
                    final result = await Get.toNamed(
                      Routes.ARTICLE_EDIT,
                      arguments: article,
                    );
                    if (result == true) {
                      controller.fetchUserArticles();
                    }
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context, article);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ArticleModel article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Hapus Artikel',
          style: GoogleFonts.kulimPark(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus artikel "${article.title}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteArticle(article.id!);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        border: Border(top: BorderSide(color: Get.isDarkMode ? Colors.white10 : const Color(0xFFE2E7FF))),
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
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Get.offAllNamed(Routes.DASHBOARD);
          } else if (index == 1) {
            Get.offNamed(Routes.ARTICLE_CREATE);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home)),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.add_circle_outline)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.add_circle)),
            label: 'Tambah',
          ),
          BottomNavigationBarItem(
            icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline)),
            activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person)),
            label: 'Profil',
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
              style: GoogleFonts.kulimPark(
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
                      onTap: () => controller.pickImage(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF092BA2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            _buildTextField(
              controller: controller.nameController,
              label: "Nama Lengkap",
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.professionController,
              label: "Pekerjaan / Bidang",
              icon: Icons.work_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.bioController,
              label: "Bio Singkat",
              icon: Icons.info_outline,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () async {
                          await controller.updateProfile();
                        },
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
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Simpan Perubahan",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.kulimPark(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Get.isDarkMode ? Colors.white70 : const Color(0xFF444653),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.kulimPark(fontSize: 14, color: Get.isDarkMode ? Colors.white : const Color(0xFF131B2E)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF757685)),
            filled: true,
            fillColor: Get.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFAF8FF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Get.isDarkMode ? Colors.white24 : const Color(0xFFE2E7FF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Get.isDarkMode ? Colors.white24 : const Color(0xFFE2E7FF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Get.isDarkMode ? Colors.blueAccent : const Color(0xFF092BA2)),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: GoogleFonts.kulimPark(
            fontWeight: FontWeight.w800,
            color: Get.isDarkMode ? Colors.white : const Color(0xFF131B2E),
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Anda?',
          style: GoogleFonts.kulimPark(color: Get.isDarkMode ? Colors.white70 : const Color(0xFF444653)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Batal',
              style: GoogleFonts.kulimPark(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF757685),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.kulimPark(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
