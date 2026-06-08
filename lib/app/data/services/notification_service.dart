import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/article_model.dart';
import '../models/notification_model.dart';
import 'auth_service.dart';

import '../models/comment_model.dart';

class NotificationService extends GetxService {
  final notifications = <NotificationItem>[].obs;
  final unreadCount = 0.obs;
  final _box = GetStorage();

  int? get currentUserId {
    try {
      final authService = Get.find<AuthService>();
      final userData = authService.currentUser;
      if (userData == null) return null;
      return userData['id'] is int 
          ? userData['id'] as int 
          : int.tryParse(userData['id']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  String get _storageKey => 'app_notifications_${currentUserId ?? "guest"}';
  String get _baselineKey => 'notification_article_baseline_${currentUserId ?? "guest"}';
  String get _commentBaselineKey => 'notification_comment_baseline_${currentUserId ?? "guest"}';

  final Map<int, Map<String, dynamic>> _articleBaseline = {};
  final Map<int, Map<String, dynamic>> _commentBaseline = {};

  @override
  void onInit() {
    super.onInit();
    loadNotificationsForCurrentUser();
  }

  void loadNotificationsForCurrentUser() {
    notifications.clear();
    _articleBaseline.clear();
    _commentBaseline.clear();

    final userId = currentUserId;
    if (userId == null) {
      unreadCount.value = 0;
      return;
    }

    final rawNotifications = _box.read<List<dynamic>>(_storageKey);
    if (rawNotifications != null) {
      notifications.value = rawNotifications
          .whereType<Map<String, dynamic>>()
          .map(NotificationItem.fromJson)
          .toList();
    }

    final rawBaseline = _box.read<List<dynamic>>(_baselineKey);
    if (rawBaseline != null) {
      for (final item in rawBaseline.whereType<Map<String, dynamic>>()) {
        final id = item['id'] as int?;
        final likes = item['likes'] as int?;
        final comments = item['comments'] as int?;
        final status = item['status'] as String?;
        if (id != null) {
          _articleBaseline[id] = {
            'likes': likes ?? 0,
            'comments': comments ?? 0,
            'status': status ?? 'published',
          };
        }
      }
    }

    final rawCommentBaseline = _box.read<List<dynamic>>(_commentBaselineKey);
    if (rawCommentBaseline != null) {
      for (final item in rawCommentBaseline.whereType<Map<String, dynamic>>()) {
        final id = item['id'] as int?;
        final isHidden = item['is_hidden'] as bool?;
        if (id != null) {
          _commentBaseline[id] = {
            'is_hidden': isHidden ?? false,
          };
        }
      }
    }

    _recalculateUnreadCount();
  }

  void clearAll() {
    notifications.clear();
    _articleBaseline.clear();
    _commentBaseline.clear();
    unreadCount.value = 0;
  }

  void _saveNotifications() {
    final data = notifications.map((e) => e.toJson()).toList();
    _box.write(_storageKey, data);
  }

  void _saveBaseline() {
    final data = _articleBaseline.entries
        .map(
          (entry) => {
            'id': entry.key,
            'likes': entry.value['likes'],
            'comments': entry.value['comments'],
            'status': entry.value['status'],
          },
        )
        .toList();
    _box.write(_baselineKey, data);

    final commentData = _commentBaseline.entries
        .map(
          (entry) => {
            'id': entry.key,
            'is_hidden': entry.value['is_hidden'],
          },
        )
        .toList();
    _box.write(_commentBaselineKey, commentData);
  }

  void _recalculateUnreadCount() {
    unreadCount.value = notifications.where((item) => !item.isRead).length;
  }

  void addNotification(NotificationItem notification) {
    notifications.insert(0, notification);
    _saveNotifications();
    _recalculateUnreadCount();
  }

  void markAsRead(int notificationId) {
    final index = notifications.indexWhere((item) => item.id == notificationId);
    if (index == -1) return;
    if (!notifications[index].isRead) {
      notifications[index].isRead = true;
      notifications.refresh();
      _saveNotifications();
      _recalculateUnreadCount();
    }
  }

  void markAllRead() {
    for (var item in notifications) {
      item.isRead = true;
    }
    notifications.refresh();
    _saveNotifications();
    _recalculateUnreadCount();
  }

  void syncArticleMetrics(List<ArticleModel> articles) {
    final authService = Get.find<AuthService>();
    final userData = authService.currentUser;
    if (userData == null) return;
    
    final int? currentUserId = userData['id'] is int 
        ? userData['id'] as int 
        : int.tryParse(userData['id']?.toString() ?? '');
        
    if (currentUserId == null) return;

    var shouldSaveBaseline = false;

    for (final article in articles) {
      if (article.id == null) continue;
      if (article.user?.id != currentUserId) continue;

      final previous =
          _articleBaseline[article.id!] ??
          {
            'likes': article.likesCount ?? 0,
            'comments': article.commentsCount ?? 0,
            'status': article.status ?? 'published',
          };
      
      final int currentLikes = article.likesCount ?? 0;
      final int currentComments = article.commentsCount ?? 0;
      final String currentStatus = article.status?.toLowerCase() ?? 'published';
      final String previousStatus = (previous['status'] as String?)?.toLowerCase() ?? 'published';

      final int prevLikes = previous['likes'] is int ? previous['likes'] as int : 0;
      final int prevComments = previous['comments'] is int ? previous['comments'] as int : 0;

      final int likeDiff = currentLikes - prevLikes;
      final int commentDiff = currentComments - prevComments;

      if (likeDiff > 0) {
        addNotification(
          NotificationItem(
            id: DateTime.now().microsecondsSinceEpoch,
            articleId: article.id!,
            articleTitle: article.title ?? 'Artikel Anda',
            message:
                'Artikel "${article.title ?? 'artikel Anda'}" mendapatkan $likeDiff like baru.',
            type: 'like',
            createdAt: DateTime.now(),
          ),
        );
      }

      if (commentDiff > 0) {
        addNotification(
          NotificationItem(
            id: DateTime.now().microsecondsSinceEpoch + 1,
            articleId: article.id!,
            articleTitle: article.title ?? 'Artikel Anda',
            message:
                'Artikel "${article.title ?? 'artikel Anda'}" mendapatkan $commentDiff komentar baru.',
            type: 'comment',
            createdAt: DateTime.now(),
          ),
        );
      }

      final bool isNowBlocked = currentStatus == 'banned' || currentStatus == 'blocked';
      final bool wasBlocked = previousStatus == 'banned' || previousStatus == 'blocked';

      if (isNowBlocked && !wasBlocked) {
        addNotification(
          NotificationItem(
            id: DateTime.now().microsecondsSinceEpoch + 2,
            articleId: article.id!,
            articleTitle: article.title ?? 'Artikel Anda',
            message:
                'Artikel "${article.title ?? 'artikel Anda'}" telah diblokir oleh admin karena melanggar ketentuan. Silakan baca panduan penulisan untuk info lebih lanjut.',
            type: 'blocked',
            createdAt: DateTime.now(),
          ),
        );
      } else if (!isNowBlocked && wasBlocked) {
        addNotification(
          NotificationItem(
            id: DateTime.now().microsecondsSinceEpoch + 3,
            articleId: article.id!,
            articleTitle: article.title ?? 'Artikel Anda',
            message:
                'Artikel "${article.title ?? 'artikel Anda'}" telah diaktifkan kembali oleh admin.',
            type: 'notifications',
            createdAt: DateTime.now(),
          ),
        );
      }

      _articleBaseline[article.id!] = {
        'likes': currentLikes,
        'comments': currentComments,
        'status': currentStatus,
      };
      shouldSaveBaseline = true;
    }

    if (shouldSaveBaseline) {
      _saveBaseline();
    }
  }

  void syncCommentStatus(List<CommentModel> comments) {
    final authService = Get.find<AuthService>();
    final userData = authService.currentUser;
    if (userData == null) return;

    final int? currentUserId = userData['id'] is int
        ? userData['id'] as int
        : int.tryParse(userData['id']?.toString() ?? '');

    if (currentUserId == null) return;

    var shouldSaveBaseline = false;

    for (final comment in comments) {
      if (comment.id == null) continue;
      if (comment.user?.id != currentUserId) continue;

      final previous = _commentBaseline[comment.id!] ??
          {
            'is_hidden': false,
          };

      final bool currentIsHidden = comment.isHidden ?? false;
      final bool previousIsHidden = previous['is_hidden'] as bool? ?? false;

      if (currentIsHidden && !previousIsHidden) {
        addNotification(
          NotificationItem(
            id: DateTime.now().microsecondsSinceEpoch,
            articleId: comment.articleId ?? 0,
            articleTitle: 'Komentar Anda',
            message:
                'Komentar Anda telah disembunyikan oleh moderator karena melanggar ketentuan. Silakan baca panduan penulisan.',
            type: 'blocked',
            createdAt: DateTime.now(),
          ),
        );
      } else if (!currentIsHidden && previousIsHidden) {
        addNotification(
          NotificationItem(
            id: DateTime.now().microsecondsSinceEpoch + 1,
            articleId: comment.articleId ?? 0,
            articleTitle: 'Komentar Anda',
            message: 'Komentar Anda telah diaktifkan kembali oleh moderator.',
            type: 'notifications',
            createdAt: DateTime.now(),
          ),
        );
      }

      _commentBaseline[comment.id!] = {
        'is_hidden': currentIsHidden,
      };
      shouldSaveBaseline = true;
    }

    if (shouldSaveBaseline) {
      _saveBaseline();
    }
  }
}
