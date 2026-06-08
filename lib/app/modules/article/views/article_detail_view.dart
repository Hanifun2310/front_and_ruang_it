import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' hide DefaultStyles;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:share_plus/share_plus.dart';
import '../../../widgets/skeleton_widget.dart';
import '../controllers/article_detail_controller.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';

class ArticleDetailView extends GetView<ArticleDetailController> {
  const ArticleDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const SkeletonArticleDetail();
        }

        final art = controller.article.value;

        return Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: controller.scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: context.theme.scaffoldBackgroundColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(imageUrl: 
                      art.imageUrl ?? 'https://via.placeholder.com/600x400',
                      fit: BoxFit.cover,
                      errorWidget: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    final String articleUrl = 'https://ruang-it.vibedev.my.id/guest/article/${art.slug ?? art.id}';
                    Share.share(
                      'Baca artikel "${art.title}" di Ruang IT!\n\nLink: $articleUrl',
                      subject: art.title,
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: Obx(() => LinearProgressIndicator(
                  value: controller.readingProgress.value,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  minHeight: 4.0,
                )),
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
                    InkWell(
                      onTap: () {
                        if (art.user != null) {
                          Get.toNamed(Routes.AUTHOR_PROFILE, arguments: art.user);
                        }
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: (art.user?.photoProfile != null && art.user!.photoProfile!.isNotEmpty)
                                ? NetworkImage(art.user!.photoProfile!) as ImageProvider
                                : const AssetImage('assets/images/fallback_pp.png'),
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
                              Row(
                                children: [
                                  Text(
                                    art.formattedDate,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.visibility,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${art.viewsCount ?? 0} kali dibaca',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
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
                    Obx(() {
                      if (controller.comments.isEmpty) {
                        return const Text(
                          "Belum ada komentar. Jadilah yang pertama!",
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }
                      return ListView.separated(
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
                              (comment.user?.photoProfile != null && comment.user!.photoProfile!.isNotEmpty)
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: comment.user!.photoProfile!,
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) => Image.asset(
                                          'assets/images/fallback_pp.png',
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                        ),
                                        placeholder: (context, url) => Container(
                                          width: 36,
                                          height: 36,
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                    )
                                  : const CircleAvatar(
                                      radius: 18,
                                      backgroundImage: AssetImage('assets/images/fallback_pp.png'),
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
                                    if (comment.isHidden == true)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Komentar ini telah disembunyikan oleh moderator karena melanggar ketentuan.',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          GestureDetector(
                                            onTap: () => Get.toNamed(Routes.GUIDELINES),
                                            child: const Text(
                                              'Pelajari Panduan Penulisan',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blueAccent,
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Text(
                                        comment.content ?? '',
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
                      );
                    }),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
            _buildBottomAction(context),
          ],
        );
      }),
    );
  }

  void _showEditCommentDialog(BuildContext context, dynamic comment) {
    final TextEditingController editController = TextEditingController(text: comment.content);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Obx(() {
        final isLoading = controller.isCommentActionLoading.value;
        return AlertDialog(
          title: const Text('Edit Komentar'),
          content: isLoading
              ? const SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : TextField(
                  controller: editController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Tulis komentar Anda...',
                  ),
                ),
          actions: isLoading ? null : [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (editController.text.trim().isNotEmpty) {
                  final success = await controller.updateComment(comment.id, editController.text.trim());
                  if (success) {
                    Get.back();
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      }),
    );
  }

  void _showDeleteCommentDialog(BuildContext context, dynamic comment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Obx(() {
        final isLoading = controller.isCommentActionLoading.value;
        return AlertDialog(
          title: const Text('Hapus Komentar'),
          content: isLoading
              ? const SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : const Text('Apakah Anda yakin ingin menghapus komentar ini?'),
          actions: isLoading ? null : [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final success = await controller.deleteComment(comment.id);
                if (success) {
                  Get.back();
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    final authService = Get.find<AuthService>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + (bottomPadding > 0 ? bottomPadding * 0.8 : 0),
      ),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Obx(() => GestureDetector(
            onTap: authService.isLoggedIn.value
                ? controller.toggleLike
                : null,
            child: Icon(
              authService.isLoggedIn.value && controller.rxIsLiked.value == true
                  ? Icons.thumb_up
                  : Icons.thumb_up_outlined,
              size: 22,
              color: authService.isLoggedIn.value && controller.rxIsLiked.value == true
                  ? Colors.blueAccent
                  : Colors.grey,
            ),
          )),
          const SizedBox(width: 6),
          Obx(() => Text(
            "${controller.rxLikesCount.value}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          )),
          const SizedBox(width: 14),
          Expanded(
            child: Obx(() => TextField(
              controller: controller.commentController,
              enabled: authService.isLoggedIn.value,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                isDense: true,
                hintText: authService.isLoggedIn.value
                    ? "Tulis komentar..."
                    : "Login untuk komentar...",
                hintStyle: const TextStyle(fontSize: 15),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Get.isDarkMode ? const Color(0xFF0F172A) : Colors.grey.shade100,
              ),
            )),
          ),
          const SizedBox(width: 10),
          Obx(() => CircleAvatar(
            radius: 18,
            backgroundColor: authService.isLoggedIn.value ? Colors.blueAccent : Colors.grey,
            child: controller.isCommenting.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : GestureDetector(
                    onTap: authService.isLoggedIn.value
                        ? controller.sendComment
                        : null,
                    child: const Icon(Icons.send, color: Colors.white, size: 16),
                  ),
          )),
        ],
      ),
    );
  }
}
