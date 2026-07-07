import 'package:get/get.dart';
import 'package:orland_sports/const/supabase_tables.dart';
import 'package:orland_sports/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for a notification item
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String? imageUrl;
  final DateTime createdAt;
  final RxBool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.createdAt,
    bool read = false,
  }) : isRead = read.obs;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      read: json['is_read'] as bool? ?? false,
    );
  }

  /// Human-readable time ago string
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}hr ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min ago';
    return 'Just now';
  }
}

/// Controller for managing notifications
class NotificationController extends GetxController {
  static NotificationController get instance =>
      Get.find<NotificationController>();

  final _supabase = Supabase.instance.client;

  final RxList<NotificationItem> notifications = <NotificationItem>[].obs;
  final RxBool isLoading = false.obs;

  /// Current user ID
  String? get _userId => _supabase.auth.currentUser?.id;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  /// Load notifications from Supabase
  Future<void> loadNotifications() async {
    if (_userId == null) return;

    isLoading.value = true;
    try {
      final response = await _supabase
          .from(SupabaseTables.notificationsTable)
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false)
          .limit(50);

      notifications.value = (response as List)
          .map((json) => NotificationItem.fromJson(json))
          .toList();
    } catch (e) {
      // Table might not exist yet or have different schema - show empty
      notifications.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from(SupabaseTables.notificationsTable)
          .update({'is_read': true}).eq('id', notificationId);

      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index].isRead.value = true;
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    try {
      await _supabase
          .from(SupabaseTables.notificationsTable)
          .update({'is_read': true})
          .eq('user_id', _userId!)
          .eq('is_read', false);

      for (final notification in notifications) {
        notification.isRead.value = true;
      }

      CustomToast.instance.showSuccessToast(
        title: 'done'.tr,
        message: 'all_notifications_read'.tr,
      );
    } catch (e) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'failed_mark_notifications'.tr,
      );
    }
  }

  /// Get unread count
  int get unreadCount => notifications.where((n) => !n.isRead.value).length;

  /// Check if there are any unread notifications
  bool get hasUnread => unreadCount > 0;
}
