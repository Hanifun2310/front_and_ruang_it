import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/models/notification_model.dart';

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

  String _formatTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'comment':
        return Icons.comment;
      case 'like':
        return Icons.favorite;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'comment':
        return Colors.green;
      case 'like':
        return Colors.redAccent;
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = Get.find<NotificationService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            tooltip: 'Tandai semua telah dibaca',
            onPressed: notificationService.markAllRead,
          ),
        ],
      ),
      body: Obx(() {
        final notifications = notificationService.notifications;
        if (notifications.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_off,
                    size: 72,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada notifikasi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final item = notifications[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                leading: CircleAvatar(
                  backgroundColor: _colorForType(item.type),
                  child: Icon(_iconForType(item.type), color: Colors.white),
                ),
                title: Text(
                  item.articleTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(item.message),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(item.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                trailing: item.isRead
                    ? null
                    : Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                        ),
                      ),
                onTap: () {
                  notificationService.markAsRead(item.id);
                },
              ),
            );
          },
        );
      }),
    );
  }
}
