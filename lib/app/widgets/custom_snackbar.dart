import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// A premium, beautiful global snackbar notification utility that matches the 
/// high-end, glassmorphic aesthetic of the "Ruang IT" application.
void showCustomSnackbar(
  String title,
  String message, {
  Color? backgroundColor,
  Color? colorText,
  Duration? duration,
  SnackPosition? snackPosition,
  Widget? mainButton,
}) {
  final isDarkMode = Get.isDarkMode;
  
  // Normalize checking state via text content or custom fallback parameters
  final titleLower = title.toLowerCase();
  final messageLower = message.toLowerCase();
  
  bool isSuccess = titleLower.contains('sukses') || 
                   titleLower.contains('berhasil') || 
                   messageLower.contains('berhasil') ||
                   backgroundColor == Colors.green;
                   
  bool isError = titleLower.contains('gagal') || 
                 titleLower.contains('error') || 
                 titleLower.contains('ditolak') || 
                 messageLower.contains('gagal') || 
                 backgroundColor == Colors.redAccent ||
                 backgroundColor == Colors.red;
                 
  bool isWarning = titleLower.contains('peringatan') || 
                   titleLower.contains('timeout') || 
                   titleLower.contains('sesi') || 
                   titleLower.contains('oops') ||
                   titleLower.contains('habis') ||
                   titleLower.contains('batas') ||
                   backgroundColor == Colors.orange || 
                   backgroundColor == Colors.amber;

  Color primaryColor;
  IconData iconData;

  // Modern neon matching colors
  if (isSuccess) {
    primaryColor = const Color(0xFF10B981); // Emerald Green
    iconData = Icons.check_circle_outline_rounded;
  } else if (isError) {
    primaryColor = const Color(0xFFEF4444); // Neon Coral Red
    iconData = Icons.error_outline_rounded;
  } else if (isWarning) {
    primaryColor = const Color(0xFFF59E0B); // Golden Amber
    iconData = Icons.warning_amber_rounded;
  } else {
    primaryColor = const Color(0xFF3B82F6); // Electric Blue (Default / Info)
    iconData = Icons.info_outline_rounded;
  }

  // Frosted glass background setup
  final Color baseBgColor = isDarkMode 
      ? const Color(0xFF0D1527) // Slate Navy
      : const Color(0xFFFAF8FF); // Pristine White/Cream

  final Color finalBgColor = baseBgColor.withOpacity(0.88);
  final Color finalBorderColor = primaryColor.withOpacity(0.28);
  final Color glowShadowColor = primaryColor.withOpacity(0.12);

  // Close snackbar manually if already open to avoid overlapping multiple snackbars
  if (Get.isSnackbarOpen) {
    Get.back();
  }

  Get.rawSnackbar(
    titleText: Text(
      title,
      style: GoogleFonts.kulimPark(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
        letterSpacing: 0.5,
      ),
    ),
    messageText: Text(
      message,
      style: GoogleFonts.kulimPark(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDarkMode ? Colors.white.withOpacity(0.75) : const Color(0xFF334155),
        height: 1.45,
      ),
    ),
    icon: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: primaryColor,
        size: 22,
      ),
    ),
    backgroundColor: finalBgColor,
    borderRadius: 16,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    borderColor: finalBorderColor,
    borderWidth: 1.5,
    barBlur: 15, // Frosted glass effect
    snackPosition: snackPosition ?? SnackPosition.TOP,
    duration: duration ?? const Duration(seconds: 3),
    mainButton: mainButton ?? TextButton(
      onPressed: () {
        if (Get.isSnackbarOpen) {
          Get.back();
        }
      },
      child: Icon(
        Icons.close_rounded,
        color: isDarkMode ? Colors.white38 : Colors.black38,
        size: 20,
      ),
    ),
    boxShadows: [
      BoxShadow(
        color: glowShadowColor,
        blurRadius: 22,
        spreadRadius: 1,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(isDarkMode ? 0.35 : 0.06),
        blurRadius: 18,
        spreadRadius: -4,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
