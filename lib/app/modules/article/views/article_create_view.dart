import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart'; // Import library Quill
import '../controllers/article_create_controller.dart';
import '../../../routes/app_routes.dart';

class ArticleCreateView extends GetView<ArticleCreateController> {
  const ArticleCreateView({super.key});

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
          style: GoogleFonts.kulimPark(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tulis Artikel Baru',
                        style: GoogleFonts.kulimPark(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF131B2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bagikan wawasan teknologi Anda kepada komunitas.',
                        style: GoogleFonts.kulimPark(
                          fontSize: 13,
                          color: const Color(0xFF444653),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Tombol Terbitkan
            Row(
              children: [
                Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : () => controller.publishArticle(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF092BA2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 0,
                  ),
                  child: controller.isLoading.value 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        children: [
                          Text(
                            'Terbitkan',
                            style: GoogleFonts.kulimPark(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.send, size: 18),
                        ],
                      ),
                )),
              ],
            ),
            const SizedBox(height: 24),
            
            // Cover Image Upload
            GestureDetector(
              onTap: () => controller.pickImage(),
              child: Obx(() => Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC5C5D6),
                    width: 2,
                    style: BorderStyle.solid, 
                  ),
                ),
                child: controller.selectedImage.value != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: kIsWeb 
                        ? Image.network(
                            controller.selectedImage.value!.path,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(controller.selectedImage.value!.path),
                            fit: BoxFit.cover,
                          ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_outlined, size: 40, color: Color(0xFF444653)),
                        const SizedBox(height: 12),
                        Text(
                          'Klik untuk unggah atau seret file',
                          style: GoogleFonts.kulimPark(
                            fontSize: 15,
                            color: const Color(0xFF131B2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rekomendasi ukuran: 1200 x 630 px (Max 2MB)',
                          style: GoogleFonts.kulimPark(
                            fontSize: 13,
                            color: const Color(0xFF444653),
                          ),
                        ),
                      ],
                    ),
              )),
            ),
            const SizedBox(height: 24),

            // Form Title (Judul)
            TextField(
              controller: controller.titleController,
              style: GoogleFonts.kulimPark(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF131B2E),
              ),
              decoration: InputDecoration(
                hintText: 'Judul Artikel...',
                hintStyle: GoogleFonts.kulimPark(
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

            // Dropdown Kategori
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kategori Utama',
                  style: GoogleFonts.kulimPark(
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
                      value: controller.selectedCategoryId.value == 0 ? null : controller.selectedCategoryId.value,
                      hint: Text('Pilih Kategori...', style: GoogleFonts.kulimPark(fontSize: 13)),
                      isExpanded: true,
                      items: controller.categories.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat['id'],
                          child: Text(cat['name'], style: GoogleFonts.kulimPark(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) controller.selectedCategoryId.value = val;
                      },
                    ),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 24),

            // Area Quill Editor
            Text(
              'Isi Konten',
              style: GoogleFonts.kulimPark(
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
                  // Toolbar bawaan Quill
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
                            topRight: Radius.circular(12)),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFC5C5D6)),
                  // Area mengetik Quill
                  Container(
                    height: 400, // Diperbesar agar nyaman mengetik panjang
                    padding: const EdgeInsets.all(16),
                    child: QuillEditor.basic(
                      configurations: QuillEditorConfigurations(
                        controller: controller.quillController,
                        placeholder: 'Mulai menulis intisari teknologi Anda di sini...',
                        scrollable: true,
                        customStyles: DefaultStyles(
                          paragraph: DefaultTextBlockStyle(
                            GoogleFonts.kulimPark(
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
            const SizedBox(height: 100), // Extra space untuk bottom nav
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E7FF))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, 'Home', false, () => Get.offAllNamed(Routes.DASHBOARD)),
            _buildNavItem(Icons.add_circle, 'Add', true, () {}),
            _buildNavItem(Icons.person_outline, 'Profile', false, () => Get.offNamed(Routes.PROFILE)),
          ],
        ),
      ),
    );
  }

  // Widget _toolbarButton yang lama sudah saya hapus karena tidak dipakai lagi

  // Navigasi Bawah tetap dipertahankan
  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF092BA2) : const Color(0xFF757685),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.kulimPark(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive ? const Color(0xFF092BA2) : const Color(0xFF757685),
            ),
          ),
        ],
      ),
    );
  }
}