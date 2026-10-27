import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/domain/entities/app_notification.dart';
import 'package:sporthub/domain/entities/user_profile.dart';
import 'package:sporthub/core/state/notification_store.dart';

void main() {
  late NotificationStore store;

  setUp(() {
    store = NotificationStore.instance;
    store.resetSeedData();
  });

  test('NotificationStore initializes with realistic seed data for player and owner', () {
    final playerNotifs = store.getNotificationsForRole(NotificationRole.player);
    final ownerNotifs = store.getNotificationsForRole(NotificationRole.owner);

    expect(playerNotifs, isNotEmpty);
    expect(ownerNotifs, isNotEmpty);
    expect(store.getUnreadCount(role: NotificationRole.player), greaterThan(0));
    expect(store.getUnreadCount(role: NotificationRole.owner), greaterThan(0));
  });

  test('markAsRead marks specific notification as read and decrements unread count', () {
    final playerNotifs = store.getNotificationsForRole(NotificationRole.player);
    final unreadItem = playerNotifs.firstWhere((n) => !n.isRead);
    final initialUnread = store.getUnreadCount(role: NotificationRole.player);

    store.markAsRead(unreadItem.id);

    final updatedItem = store.notificationsNotifier.value.firstWhere((n) => n.id == unreadItem.id);
    expect(updatedItem.isRead, isTrue);
    expect(store.getUnreadCount(role: NotificationRole.player), equals(initialUnread - 1));
  });

  test('markAllAsRead marks all notifications as read for specified role', () {
    expect(store.getUnreadCount(role: NotificationRole.player), greaterThan(0));

    store.markAllAsRead(role: NotificationRole.player);

    expect(store.getUnreadCount(role: NotificationRole.player), equals(0));
    // Owner unread count is preserved
    expect(store.getUnreadCount(role: NotificationRole.owner), greaterThan(0));
  });

  test('addNotification prepends new notification and increments unread count', () {
    final initialCount = store.getNotificationsForRole(NotificationRole.player).length;
    final initialUnread = store.getUnreadCount(role: NotificationRole.player);

    final newNotif = AppNotification(
      id: 'notif_test_1',
      title: 'Đặt sân thành công!',
      message: 'Mã vé BK-999 đã được tạo.',
      timestamp: DateTime.now(),
      type: NotificationType.booking,
      role: NotificationRole.player,
      isRead: false,
      targetId: 'BK-999',
    );

    store.addNotification(newNotif);

    final updatedNotifs = store.getNotificationsForRole(NotificationRole.player);
    expect(updatedNotifs.length, equals(initialCount + 1));
    expect(updatedNotifs.first.id, equals('notif_test_1'));
    expect(store.getUnreadCount(role: NotificationRole.player), equals(initialUnread + 1));
  });

  test('deleteNotification removes notification from store', () {
    final playerNotifs = store.getNotificationsForRole(NotificationRole.player);
    final itemToDelete = playerNotifs.first;
    final initialCount = store.notificationsNotifier.value.length;

    store.deleteNotification(itemToDelete.id);

    expect(store.notificationsNotifier.value.any((n) => n.id == itemToDelete.id), isFalse);
    expect(store.notificationsNotifier.value.length, equals(initialCount - 1));
  });

  test('clearAll clears notifications for specified role or all roles', () {
    expect(store.getNotificationsForRole(NotificationRole.player), isNotEmpty);
    expect(store.getNotificationsForRole(NotificationRole.owner), isNotEmpty);

    store.clearAll(role: NotificationRole.player);
    expect(store.getNotificationsForRole(NotificationRole.player), isEmpty);
    expect(store.getNotificationsForRole(NotificationRole.owner), isNotEmpty);

    store.clearAll();
    expect(store.notifications, isEmpty);
  });

  test('AppNotification.timeAgoDisplay formats correctly for Vietnamese UI', () {
    final justNow = AppNotification(
      id: '1',
      title: 'T',
      message: 'M',
      timestamp: DateTime.now(),
      type: NotificationType.system,
    );
    expect(justNow.timeAgoDisplay, equals('Vừa xong'));

    final minutesAgo = AppNotification(
      id: '2',
      title: 'T',
      message: 'M',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      type: NotificationType.system,
    );
    expect(minutesAgo.timeAgoDisplay, equals('15 phút trước'));

    final hoursAgo = AppNotification(
      id: '3',
      title: 'T',
      message: 'M',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      type: NotificationType.system,
    );
    expect(hoursAgo.timeAgoDisplay, equals('3 giờ trước'));

    final daysAgo = AppNotification(
      id: '4',
      title: 'T',
      message: 'M',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      type: NotificationType.system,
    );
    expect(daysAgo.timeAgoDisplay, equals('3 ngày trước'));

    final pastDate = DateTime(2026, 1, 15);
    final longAgo = AppNotification(
      id: '5',
      title: 'T',
      message: 'M',
      timestamp: pastDate,
      type: NotificationType.system,
    );
    expect(longAgo.timeAgoDisplay, equals('15/01/2026'));
  });

  test('AppNotification copyWith updates fields properly', () {
    final initial = AppNotification(
      id: 'orig',
      title: 'Orig Title',
      message: 'Orig Message',
      timestamp: DateTime(2026, 9, 1),
      type: NotificationType.booking,
      role: NotificationRole.player,
      isRead: false,
      targetId: 'target_1',
    );

    final copied = initial.copyWith(
      title: 'New Title',
      isRead: true,
    );

    expect(copied.id, equals('orig'));
    expect(copied.title, equals('New Title'));
    expect(copied.message, equals('Orig Message'));
    expect(copied.isRead, isTrue);
    expect(copied.targetId, equals('target_1'));
  });

  test('loadForUser with isNewUser: true creates a single fresh welcome notification without old demo notifications', () {
    final newUser = UserProfile(
      userId: 'user_fresh_999',
      fullName: 'Lê Quốc Anh',
      phone: '0901 234 567',
      email: 'quocanh@gmail.com',
      role: 'player',
      preferredSport: 'football',
      skillLevel: 'Intermediate',
      district: 'Quận 7',
      playTimePreference: 'Tối',
      matchesPlayed: 0,
      reputationRating: 5.0,
      onTimeRate: 100,
    );

    store.loadForUser(newUser, isNewUser: true);

    expect(store.notifications.length, equals(1));
    final notif = store.notifications.first;
    expect(notif.title, contains('Chào mừng Lê Quốc Anh đến với SportHub! 🎉'));
    expect(notif.timeAgoDisplay, equals('Vừa xong'));
    // Ensure no old 2-hour or booking reminder notifications from demo users exist
    expect(store.notifications.any((n) => n.id == 'notif_p_01'), isFalse);
    expect(store.notifications.any((n) => n.id == 'notif_p_02'), isFalse);
  });

  test('loadForUser with null clears all notifications', () {
    store.loadForUser(null);
    expect(store.notifications, isEmpty);
    expect(store.getUnreadCount(), equals(0));
  });
}
