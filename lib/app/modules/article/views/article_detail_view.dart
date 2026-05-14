import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' hide DefaultStyles;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/loading_widget.dart';
import '../controllers/article_detail_controller.dart';

class ArticleDetailView extends GetView<ArticleDetailController> {
  const ArticleDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingWidget();
        }

        final art = controller.article.value;

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: context.theme.scaffoldBackgroundColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Image.network(
                  art.imageUrl ?? 'https://via.placeholder.com/600x400',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      art.category?.name?.toUpperCase() ?? 'UMUM',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      art.title ?? 'Tanpa Judul',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        color: context.theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: NetworkImage(
                            art.user?.photoProfile ??
                                'https://ui-avatars.com/api/?name=${art.user?.name ?? "User"}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              art.user?.name ?? 'Penulis Anonim',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              art.formattedDate,
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (controller.quillController != null)
                      QuillEditor.basic(
                        configurations: QuillEditorConfigurations(
                          controller: controller.quillController!,
                          readOnly: true,
                          showCursor: false,
                          autoFocus: false,
                          expands: false,
                          padding: EdgeInsets.zero,
                          customStyles: DefaultStyles(
                            paragraph: DefaultTextBlockStyle(
                              GoogleFonts.inter(
                                fontSize: 16,
                                color: Get.isDarkMode ? Colors.white : Colors.black87,
                                height: 1.8,
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
                        textStyle: GoogleFonts.inter(
                          fontSize: 16,
                          height: 1.8,
                          color: context.theme.textTheme.bodyLarge?.color ?? Colors.black87,
                        ),
                      ),
                    const SizedBox(height: 48),
                    const Divider(),
                    const SizedBox(height: 32),
                    Text(
                      "Komentar",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (controller.comments.isEmpty)
                      Text(
                        "Belum ada komentar. Jadilah yang pertama!",
                        style: GoogleFonts.inter(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.comments.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        final comment = controller.comments[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: NetworkImage(
                                comment.user?.photoProfile ??
                                    'https://ui-avatars.com/api/?name=${comment.user?.name ?? "User"}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.user?.name ?? 'User',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment.isHidden == true
                                        ? 'Komentar ini telah disembunyikan oleh moderator'
                                        : (comment.content ?? ''),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontStyle: comment.isHidden == true ? FontStyle.italic : FontStyle.normal,
                                      color: comment.isHidden == true 
                                          ? Colors.grey 
                                          : (Get.isDarkMode ? Colors.white70 : Colors.black87),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() => _buildBottomAction()),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: controller.toggleLike,
              icon: Icon(
                controller.article.value.isLiked == true
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: controller.article.value.isLiked == true
                    ? Colors.red
                    : Colors.grey,
              ),
            ),
            Text(
              "${controller.article.value.likesCount ?? 0}",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: controller.commentController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Tulis komentar...",
                  hintStyle: GoogleFonts.inter(fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
