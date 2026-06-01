import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../data/models/article_model.dart';
import '../routes/app_routes.dart';
import '../data/services/auth_service.dart';
import 'bouncing_widget.dart';

class ArticleCard extends StatelessWidget {
  final ArticleModel article;
  final void Function(int) onLikeToggle;
  final void Function(int)? onDelete;

  const ArticleCard({
    super.key,
    required this.article,
    required this.onLikeToggle,
    this.onDelete,
  });

  Widget _buildSnippetPreview(String? content) {
    if (content == null || content.trim().isEmpty) {
      return Text(
        'Tidak ada ringkasan...',
        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
      );
    }
    return _RichTextSnippet(content: content);
  }

  void _showArticleOptions(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Opsi Artikel',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Get.isDarkMode ? Colors.white : const Color(0xFF131B2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blueAccent),
              title: Text(
                'Edit Artikel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Get.isDarkMode ? Colors.white : const Color(0xFF131B2E),
                ),
              ),
              onTap: () {
                Get.back();
                Get.toNamed(Routes.ARTICLE_EDIT, arguments: article);
              },
            ),
            const Divider(),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: Text(
                  'Hapus Artikel',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                onTap: () {
                  Get.back();
                  _showDeleteConfirmation();
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Artikel',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus artikel ini secara permanen?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              if (article.id != null) {
                onDelete?.call(article.id!);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Hapus', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = article.imageUrl ?? 'https://via.placeholder.com/600x400';
    final String avatarUrl = (article.user?.photoProfile?.isNotEmpty == true) ? article.user!.photoProfile! : '';
    final String categoryName = article.category?.name ?? 'Umum';
    
    final authService = Get.find<AuthService>();
    final currentUserId = authService.currentUser?['id'];
    final bool isAuthor = article.user?.id != null && article.user?.id == currentUserId;

    return BouncingWidget(
      onTap: () {
        Get.toNamed(Routes.ARTICLE_DETAIL, arguments: article.slug);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? context.theme.scaffoldBackgroundColor : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Get.isDarkMode ? Colors.white10 : Colors.grey.shade100,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 16,
                  color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Theme: $categoryName',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                if (article.status == 'banned' || article.status == 'blocked') ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      'BANNED',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                if (article.user != null) {
                  Get.toNamed(Routes.AUTHOR_PROFILE, arguments: article.user);
                }
              },
              child: Row(
                children: [
                  avatarUrl.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: avatarUrl,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/images/fallback_pp.png',
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                            ),
                            placeholder: (context, url) => Container(
                              width: 24,
                              height: 24,
                              color: Colors.grey.shade200,
                            ),
                          ),
                        )
                      : const CircleAvatar(
                          radius: 12,
                          backgroundImage: AssetImage('assets/images/fallback_pp.png'),
                        ),
                  const SizedBox(width: 12),
                  Text(
                    article.user?.name ?? 'Admin',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Get.isDarkMode ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title ?? 'Tanpa Judul',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: Get.isDarkMode ? Colors.white : Colors.grey.shade900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _buildSnippetPreview(article.content),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 120,
                    height: 80,
                    fit: BoxFit.cover,
                    errorWidget: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  article.formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Get.isDarkMode ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (article.id != null) {
                          onLikeToggle(article.id!);
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            (article.isLiked ?? false) ? Icons.thumb_up : Icons.thumb_up_outlined,
                            size: 20,
                            color: (article.isLiked ?? false)
                                ? Colors.blueAccent
                                : (Get.isDarkMode ? Colors.white70 : Colors.grey.shade700),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${article.likesCount ?? 0}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 20,
                          color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${article.commentsCount ?? 0}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 20,
                          color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${article.viewsCount ?? 0}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    if (isAuthor) ...[
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () => _showArticleOptions(context),
                        child: Icon(
                          Icons.more_horiz,
                          size: 20,
                          color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RichTextSnippet extends StatefulWidget {
  final String content;
  const _RichTextSnippet({required this.content});

  @override
  State<_RichTextSnippet> createState() => _RichTextSnippetState();
}

class _RichTextSnippetState extends State<_RichTextSnippet> {
  quill.QuillController? _quillController;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    try {
      if (widget.content.trim().startsWith('[')) {
        final List<dynamic> deltaList = jsonDecode(widget.content);
        final document = quill.Document.fromJson(deltaList);
        _quillController = quill.QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _quillController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: IgnorePointer(
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.4, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: ClipRect(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: _quillController != null
                  ? quill.QuillEditor.basic(
                      configurations: quill.QuillEditorConfigurations(
                        controller: _quillController!,
                        readOnly: true,
                        showCursor: false,
                        autoFocus: false,
                        expands: false,
                        padding: EdgeInsets.zero,
                        customStyles: quill.DefaultStyles(
                          paragraph: quill.DefaultTextBlockStyle(
                            GoogleFonts.inter(
                              fontSize: 14,
                              color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                              height: 1.5,
                            ),
                            const quill.VerticalSpacing(0, 0),
                            const quill.VerticalSpacing(0, 0),
                            null,
                          ),
                        ),
                      ),
                    )
                  : HtmlWidget(
                      widget.content,
                      textStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: Get.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

