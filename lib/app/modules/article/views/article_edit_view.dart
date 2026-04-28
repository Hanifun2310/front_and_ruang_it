import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import '../controllers/article_edit_controller.dart';
import '../../../routes/app_routes.dart';

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
            icon: const Icon(Icons.search, color: Color(0xFF131B2E)),
            onPressed: () {},
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : () => controller.updateArticle(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF092BA2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 0,
                  ),
                  child: controller.isLoading.value 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
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
              ],
            ),
            const SizedBox(height: 24),
            
            // Cover Image Upload
            GestureDetector(
              onTap: () => controller.pickImage(),
              child: Obx(() {
                if (controller.selectedImage.value != null) {
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
                      child: kIsWeb 
                        ? Image.network(
                            controller.selectedImage.value!.path,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(controller.selectedImage.value!.path),
                            fit: BoxFit.cover,
                          ),
                    ),
                  );
                } else if (controller.currentImageUrl.value.isNotEmpty) {
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
                      child: Image.network(
                        controller.currentImageUrl.value,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      ),
                    ),
                  );
                } else {
                  return _buildPlaceholder();
                }
              }),
            ),
            const SizedBox(height: 24),

            // Form Fields
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
                      value: controller.selectedCategoryId.value == 0 ? null : controller.selectedCategoryId.value,
                      hint: Text('Pilih Kategori...', style: GoogleFonts.inter(fontSize: 13)),
                      isExpanded: true,
                      items: controller.categories.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat['id'],
                          child: Text(cat['name'], style: GoogleFonts.inter(fontSize: 13)),
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

            // Content Area
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
                  // Toolbar Mockup
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F3FF),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                      border: Border(bottom: BorderSide(color: Color(0xFFC5C5D6))),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.format_bold, size: 20, color: Color(0xFF444653)),
                        SizedBox(width: 12),
                        Icon(Icons.format_italic, size: 20, color: Color(0xFF444653)),
                        SizedBox(width: 12),
                        Icon(Icons.format_underlined, size: 20, color: Color(0xFF444653)),
                        SizedBox(width: 12),
                        Container(width: 1, height: 20, color: Color(0xFFC5C5D6)),
                        SizedBox(width: 12),
                        Text('H2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF444653))),
                        SizedBox(width: 12),
                        Icon(Icons.format_list_bulleted, size: 20, color: Color(0xFF444653)),
                        SizedBox(width: 12),
                        Icon(Icons.link, size: 20, color: Color(0xFF444653)),
                        SizedBox(width: 12),
                        Icon(Icons.image, size: 20, color: Color(0xFF444653)),
                      ],
                    ),
                  ),
                  TextField(
                    controller: controller.contentController,
                    maxLines: 15,
                    minLines: 10,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: const Color(0xFF131B2E),
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Mulai menulis intisari teknologi Anda di sini...',
                      hintStyle: GoogleFonts.inter(color: const Color(0xFFC5C5D6)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // Extra space for bottom nav
          ],
        ),
      ),
    );
  }

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
            'Klik untuk unggah atau seret file',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF131B2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rekomendasi ukuran: 1200 x 630 px (Max 2MB)',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF444653),
            ),
          ),
        ],
      ),
    );
  }
}
