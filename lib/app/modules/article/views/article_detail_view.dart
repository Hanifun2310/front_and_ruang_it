import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' hide DefaultStyles;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/article_detail_controller.dart';

class ArticleDetailView extends GetView<ArticleDetailController> {
  const ArticleDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.appBarTheme.backgroundColor,
        title: Text(
          "Detail Artikel", 
          style: TextStyle(
            fontSize: 18,
            color: context.theme.appBarTheme.foregroundColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final art = controller.article.value;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- GAMBAR ARTIKEL (ANTI-CRASH) ---
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        art.imageUrl ?? 'https://via.placeholder.com/600x400',
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        // Jika gambar gagal dimuat, tampilkan kotak abu-abu dengan icon
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 220,
                          color: Colors.grey.shade100,
                          child: const Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Judul Artikel
                    Text(
                      art.title ?? 'Tanpa Judul',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- INFO PENULIS & KATEGORI ---
                    Row(
                      children: [
                        // Foto Profil Penulis (ANTI-CRASH)
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: NetworkImage(
                            art.user?.photoProfile ??
                                'https://ui-avatars.com/api/?name=${art.user?.name ?? "User"}',
                          ),
                        ),
                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            art.user?.name ?? 'Penulis Anonim',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            art.category?.name ?? 'Umum',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      height: 40,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
                    ),

                    // --- ISI KONTEN HTML/QUILL ---
                    if (controller.quillController != null)
                      QuillEditor.basic(
                        configurations: QuillEditorConfigurations(
                          controller: controller.quillController!,
                          readOnly: true,
                          autoFocus: false,
                          expands: false,
                          padding: EdgeInsets.zero,
                          customStyles: DefaultStyles(
                            paragraph: DefaultTextBlockStyle(
                              GoogleFonts.kulimPark(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.6,
                              ),
                              const VerticalSpacing(0, 0),
                              const VerticalSpacing(0, 0),
                              null,
                            ),
                          ),
                        ),
                      )
                    else
                      HtmlWidget(
                        art.content ?? '<p>Konten tidak tersedia.</p>',
                        textStyle: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: context.theme.textTheme.bodyLarge?.color ?? Colors.black87,
                        ),
                      ),
                    const SizedBox(height: 40),

                    const Text(
                      "Komentar",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- LIST KOMENTAR ---
                    if (controller.comments.isEmpty)
                      const Text(
                        "Belum ada komentar. Jadilah yang pertama!",
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.comments.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final comment = controller.comments[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar Komentator (ANTI-CRASH)
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: NetworkImage(
                                  comment.user?.photoProfile ??
                                      'https://ui-avatars.com/api/?name=${comment.user?.name ?? "User"}',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comment.user?.name ?? 'User',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment.content ?? '',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Bar Like & Komentar
            _buildBottomAction(),
          ],
        );
      }),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: controller.toggleLike,
              icon: Icon(
                controller.article.value.isLiked == true
                    ? Icons.thumb_up_rounded
                    : Icons.thumb_up_outlined,
                color: controller.article.value.isLiked == true
                    ? Colors.blue
                    : Colors.grey,
              ),
            ),
            Text(
              "${controller.article.value.likesCount ?? 0}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: controller.commentController,
                decoration: InputDecoration(
                  hintText: "Tulis komentar...",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Get.isDarkMode ? const Color(0xFF0F172A) : Colors.grey.shade100,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: IconButton(
                onPressed: controller.sendComment,
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
