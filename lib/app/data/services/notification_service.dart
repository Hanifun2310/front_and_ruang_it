import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/article_model.dart';
import '../models/notification_model.dart';
import 'auth_service.dart';

class NotificationService extends GetxService {
  final notifications = <NotificationItem>[].obs;
  final unreadCount = 0.obs;
  final _box = GetStorage();
  static const _storageKey = 'app_notifications';
  static const _baselineKey = 'notification_article_baseline';

  final Map<int, Map<String, dynamic>> _articleBaseline = {};

  @override
  void onInit() {
    super.onInit();
    _loadFromStorage();
  }

  void _loadFromStorage() {
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

    _recalculateUnreadCount();
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
    
    // Safety parsing for userId
    final int? currentUserId = userData['id'] is int 
        ? userData['id'] as int 
        : int.tryParse(userData['id']?.toString() ?? '');
        
    if (currentUserId == null) return;

    var shouldSaveBaseline = false;

    for (final article in articles) {
      if (article.id == null) continue;
      // Only notify if the article belongs to the current user
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

      // Safety parsing for previous metrics
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
                'Artikel "${article.title ?? 'artikel Anda'}" telah diblokir oleh admin karena melanggar ketentuan.',
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
            type: 'notifications', // Use general notification type
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
}
