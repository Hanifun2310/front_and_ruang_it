import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart'; // Import Quill
import '../controllers/article_edit_controller.dart';

class ArticleEditView extends GetView<ArticleEditController> {
  const ArticleEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF131B2E)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Ruang IT',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF131B2E),
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode, color: Color(0xFF131B2E)),
            onPressed: () {}, // placeholder for dark/light toggle
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E7FF), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Artikel',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF131B2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Perbarui wawasan teknologi Anda.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF444653),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Simpan Perubahan Button
            Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.updateArticle(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF092BA2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    elevation: 0,
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Simpan Perubahan',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle_outline, size: 18),
                          ],
                        ),
                )),
            const SizedBox(height: 24),

            // Cover Image Upload
            GestureDetector(
              onTap: () => controller.pickImage(),
              child: Obx(() {
                if (controller.selectedImage.value != null) {
                  return _buildImageContainer(
                    child: kIsWeb
                        ? Image.network(
                            controller.selectedImage.value!.path,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(controller.selectedImage.value!.path),
                            fit: BoxFit.cover,
                          ),
                  );
                } else if (controller.currentImageUrl.value.isNotEmpty) {
                  return _buildImageContainer(
                    child: Image.network(
                      controller.currentImageUrl.value,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    ),
                  );
                } else {
                  return _buildPlaceholder();
                }
              }),
            ),
            const SizedBox(height: 24),

            // Title Field
            TextField(
              controller: controller.titleController,
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF131B2E),
              ),
              decoration: InputDecoration(
                hintText: 'Judul Artikel...',
                hintStyle: GoogleFonts.manrope(
                  color: const Color(0xFFC5C5D6),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFDAE2FD), width: 2),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF092BA2), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // Category Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kategori Utama',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF444653),
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFC5C5D6)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: controller.selectedCategoryId.value == 0
                              ? null
                              : controller.selectedCategoryId.value,
                          hint: Text('Pilih Kategori...',
                              style: GoogleFonts.inter(fontSize: 13)),
                          isExpanded: true,
                          items: controller.categories.map((cat) {
                            return DropdownMenuItem<int>(
                              value: cat['id'],
                              child: Text(cat['name'],
                                  style: GoogleFonts.inter(fontSize: 13)),
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
              ],
            ),
            const SizedBox(height: 24),

            // Quill Content Area
            Text(
              'Isi Konten',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF444653),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC5C5D6)),
              ),
              child: Column(
                children: [
                  // Quill Toolbar
                  QuillToolbar.simple(
                    configurations: QuillSimpleToolbarConfigurations(
                      controller: controller.quillController,
                      multiRowsDisplay: true,
                      showFontFamily: false,
                      showFontSize: false,
                      showSubscript: false,
                      showSuperscript: false,
                      showSearchButton: false,
                      showInlineCode: false,
                      showColorButton: false,
                      showBackgroundColorButton: false,
                      showClearFormat: false,
                      showAlignmentButtons: false,
                      showLeftAlignment: false,
                      showCenterAlignment: false,
                      showRightAlignment: false,
                      showJustifyAlignment: false,
                      showHeaderStyle: false,
                      showListCheck: false,
                      showCodeBlock: false,
                      showQuote: false,
                      showIndent: false,
                      showDirection: false,
                      showUndo: false,
                      showRedo: false,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F3FF),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFC5C5D6)),
                  // Quill Editor
                  Container(
                    height: 400, // Memberi ruang cukup untuk menulis di HP
                    padding: const EdgeInsets.all(16),
                    child: QuillEditor.basic(
                      configurations: QuillEditorConfigurations(
                        controller: controller.quillController,
                        placeholder: 'Mulai perbarui artikel Anda di sini...',
                        scrollable: true,
                        autoFocus: false,
                        readOnly: false,
                        expands: false,
                        padding: EdgeInsets.zero,
                        customStyles: DefaultStyles(
                          paragraph: DefaultTextBlockStyle(
                            GoogleFonts.inter(
                              fontSize: 15,
                              color: const Color(0xFF131B2E),
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
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget Helper: Image Container
  Widget _buildImageContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC5C5D6), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: child,
      ),
    );
  }

  // Widget Helper: Placeholder
  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC5C5D6), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 40, color: Color(0xFF444653)),
          const SizedBox(height: 12),
          Text(
            'Klik untuk ganti cover artikel',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF131B2E),
            ),
          ),
        ],
      ),
    );
  }
}