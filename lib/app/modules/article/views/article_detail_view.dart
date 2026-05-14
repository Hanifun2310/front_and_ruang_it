import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' hide DefaultStyles;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/loading_widget.dart';
import '../controllers/article_detail_controller.dart';
import '../../../data/services/auth_service.dart';

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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      art.title ?? 'Tanpa Judul',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              art.formattedDate,
                              style: const TextStyle(
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
                              TextStyle(
                                fontSize: 16,
                                color: Get.isDarkMode ? Colors.white70 : Colors.black87,
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
                        textStyle: TextStyle(
                          fontSize: 16,
                          height: 1.8,
                          color: Get.isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    const SizedBox(height: 48),
                    const Divider(),
                    const SizedBox(height: 32),
                    Text(
                      "Komentar",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (controller.comments.isEmpty)
                      Text(
                        "Belum ada komentar. Jadilah yang pertama!",
                        style: const TextStyle(
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
                        final currentUserId = Get.find<AuthService>().currentUser?['id'];
                        final isCommentOwner = comment.user?.id != null && comment.user?.id == currentUserId;
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment.isHidden == true
                                        ? 'Komentar ini telah disembunyikan oleh moderator'
                                        : (comment.content ?? ''),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Get.isDarkMode ? Colors.white70 : Colors.black87,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCommentOwner)
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_horiz, size: 20, color: Colors.grey),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditCommentDialog(context, comment);
                                  } else if (value == 'delete') {
                                    _showDeleteCommentDialog(context, comment);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit Komentar'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Hapus Komentar', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
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

  void _showEditCommentDialog(BuildContext context, dynamic comment) {
    final TextEditingController editController = TextEditingController(text: comment.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Komentar'),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Tulis komentar Anda...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                controller.updateComment(comment.id, editController.text.trim());
                Get.back();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCommentDialog(BuildContext context, dynamic comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Komentar'),
        content: const Text('Apakah Anda yakin ingin menghapus komentar ini?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteComment(comment.id);
              Get.back();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
                    ? Icons.thumb_up
                    : Icons.thumb_up_outlined,
                color: controller.article.value.isLiked == true
                    ? Colors.blueAccent
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
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Tulis komentar...",
                  hintStyle: const TextStyle(fontSize: 14),
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
