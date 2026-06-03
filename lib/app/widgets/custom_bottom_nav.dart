import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routes/app_routes.dart';
import '../modules/dashboard/controllers/dashboard_controller.dart';
import '../modules/explore/controllers/explore_controller.dart';
import '../modules/profile/controllers/profile_controller.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool showCreateButton;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    this.showCreateButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FF);
    final Color activeColor =
        isDark ? Colors.blueAccent : const Color(0xFF0058BE);
    final Color inactiveColor =
        isDark ? Colors.white54 : const Color(0xFF424754);
    final Color borderColor =
        isDark ? Colors.white10 : const Color(0xFFC2C6D6);

    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom * 0.5,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom * 0.3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(
                  iconPath: 'assets/images/icon/Vector.png',
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () {
                    if (currentIndex != 0) Get.offNamed(Routes.DASHBOARD);
                  },
                ),
                _buildNavItem(
                  iconPath: 'assets/images/icon/Vector-1.png',
                  label: 'Explore',
                  isSelected: currentIndex == 1,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () {
                    if (currentIndex != 1) Get.offNamed(Routes.EXPLORE);
                  },
                ),
                const Expanded(child: SizedBox()),
                _buildNavItem(
                  iconPath: 'assets/images/icon/Group-1.png',
                  label: 'Search',
                  isSelected: currentIndex == 2,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () {
                    if (currentIndex != 2) Get.offNamed(Routes.SEARCH);
                  },
                ),
                _buildNavItem(
                  iconPath: 'assets/images/icon/Group.png',
                  label: 'Profile',
                  isSelected: currentIndex == 3,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () {
                    if (currentIndex != 3) Get.offNamed(Routes.PROFILE);
                  },
                ),
              ],
            ),
          ),
          if (showCreateButton)
            Positioned(
              top: -24,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () async {
                    final result = await Get.toNamed(Routes.ARTICLE_CREATE);
                    if (result == true) {
                      if (Get.isRegistered<DashboardController>()) {
                        Get.find<DashboardController>().refreshArticles();
                      }
                      if (Get.isRegistered<ExploreController>()) {
                        Get.find<ExploreController>().fetchArticles();
                      }
                      if (Get.isRegistered<ProfileController>()) {
                        Get.find<ProfileController>().fetchUserArticles(reset: true);
                        Get.find<ProfileController>().loadUserData();
                      }
                    }
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: backgroundColor,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/icon/Vector-2.png',
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String iconPath,
    required String label,
    required bool isSelected,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              color: isSelected ? activeColor : inactiveColor,
              colorBlendMode: BlendMode.srcIn,
              width: 24,
              height: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
