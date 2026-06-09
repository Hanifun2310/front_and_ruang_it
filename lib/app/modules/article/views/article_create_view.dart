import 'dart:io';
import '../../../widgets/custom_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../widgets/guest_prompt_widget.dart';
import '../../../data/services/auth_service.dart';
import '../controllers/article_create_controller.dart';
import '../../../routes/app_routes.dart';

class ArticleCreateView extends GetView<ArticleCreateController> {
  const ArticleCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Get.isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Get.back(),
        ),
        title: Obx(() {
          final authService = Get.find<AuthService>();
          if (!authService.isLoggedIn.value) {
            return const SizedBox.shrink();
          }
          return Text(
            'Tulis Artikel Baru',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Get.isDarkMode ? Colors.white : Colors.black,
            ),
          );
        }),
        actions: [
          Obx(() {
            final authService = Get.find<AuthService>();
            if (!authService.isLoggedIn.value) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blueAccent,
                        ),
                      )
                    : OutlinedButton(
                        onPressed: () => controller.publishArticle(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Get.isDarkMode ? Colors.white : Colors.black,
                          side: BorderSide(
                            color:
                                Get.isDarkMode ? Colors.white : Colors.black,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'Publish',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
              ),
            );
          }),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Get.isDarkMode ? Colors.white10 : Colors.grey.shade200,
            height: 1,
          ),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final authService = Get.find<AuthService>();
    if (!authService.isLoggedIn.value) {
      return const GuestPromptWidget();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner/Info guidelines
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Get.isDarkMode
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Get.isDarkMode ? Colors.white12 : const Color(0xFFE5E7EB),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sebelum menulis, pastikan mengikuti panduan penulisan artikel agar kontenmu sesuai standar komunitas.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Get.isDarkMode ? Colors.white70 : const Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.GUIDELINES),
                  child: Text(
                    'Buka Panduan Penulisan',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Get.isDarkMode
                          ? Colors.blue.shade300
                          : const Color(0xFF2563EB),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cover Image Upload Container
          GestureDetector(
            onTap: () => controller.pickImage(),
            child: Obx(() => Container(
                  width: double.infinity,
                  height: 208,
                  decoration: BoxDecoration(
                    color: Get.isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Get.isDarkMode ? Colors.white24 : const Color(0xFFD1D5DB),
                      width: 1,
                    ),
                  ),
                  child: controller.selectedImage.value != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? CustomNetworkImage(
                                  imageUrl: controller.selectedImage.value!.path,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(controller.selectedImage.value!.path),
                                  fit: BoxFit.cover,
                                ),
                        )
                      : Center(
                          child: Text(
                            'Upload sampul artikel disini',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: const Color(0xFF8C8C8C),
                            ),
                          ),
                        ),
                )),
          ),
          const SizedBox(height: 24),

          // Title Input Section
          Text(
            'Judul',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Get.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.titleController,
            maxLines: 3,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Get.isDarkMode ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Tulis judul disini',
              hintStyle: GoogleFonts.inter(
                color: const Color(0xFF8C8C8C),
                fontSize: 15,
              ),
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Get.isDarkMode ? Colors.white24 : const Color(0xFFD1D5DB),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Get.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              filled: true,
              fillColor:
                  Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Content Editor Box
          Text(
            'Isi Artikel',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Get.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 400,
            decoration: BoxDecoration(
              color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Get.isDarkMode ? Colors.white24 : const Color(0xFFD1D5DB),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: QuillEditor.basic(
                      configurations: QuillEditorConfigurations(
                        controller: controller.quillController,
                        placeholder: 'Tulis isi artikel disini',
                        scrollable: true,
                        autoFocus: false,
                        readOnly: false,
                        expands: false,
                        padding: EdgeInsets.zero,
                        customStyles: DefaultStyles(
                          paragraph: DefaultTextBlockStyle(
                            GoogleFonts.inter(
                              fontSize: 15,
                              color: Get.isDarkMode ? Colors.white : Colors.black,
                              height: 1.5,
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
                const Divider(height: 1, color: Color(0xFFD1D5DB)),
                QuillToolbar.simple(
                  configurations: QuillSimpleToolbarConfigurations(
                    controller: controller.quillController,
                    multiRowsDisplay: false,
                    buttonOptions: const QuillSimpleToolbarButtonOptions(
                      base: QuillToolbarBaseButtonOptions(
                        iconSize: 18,
                      ),
                    ),
                    toolbarSectionSpacing: 8,
                    showDividers: false,
                    showFontFamily: false,
                    showFontSize: false,
                    showBoldButton: true,
                    showItalicButton: true,
                    showUnderLineButton: true,
                    showStrikeThrough: true,
                    showInlineCode: true,
                    showLink: true,
                    showListNumbers: true,
                    showListBullets: true,
                    showColorButton: false,
                    showBackgroundColorButton: false,
                    showClearFormat: false,
                    showAlignmentButtons: false,
                    showHeaderStyle: false,
                    showListCheck: false,
                    showCodeBlock: false,
                    showQuote: false,
                    showIndent: false,
                    showDirection: false,
                    showSearchButton: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showUndo: true,
                    showRedo: true,
                    decoration: BoxDecoration(
                      color: Get.isDarkMode
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFFAFAFA),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Category Dropdown Section
          Text(
            'Kategori',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Get.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        Get.isDarkMode ? Colors.white24 : const Color(0xFFD1D5DB),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    dropdownColor:
                        Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                    value: controller.selectedCategoryId.value == 0
                        ? null
                        : controller.selectedCategoryId.value,
                    hint: Text(
                      'Masukan topik',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: const Color(0xFF8C8C8C),
                      ),
                    ),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: Colors.black54),
                    items: controller.categories.map((cat) {
                      return DropdownMenuItem<int>(
                        value: cat['id'],
                        child: Text(
                          cat['name'],
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Get.isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        controller.selectedCategoryId.value = val;
                      }
                    },
                  ),
                ),
              )),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
