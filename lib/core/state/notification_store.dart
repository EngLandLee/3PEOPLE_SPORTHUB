import 'package:flutter/foundation.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/user_profile.dart';

class NotificationStore {
  NotificationStore._internal() {
    resetSeedData();
  }

  static final NotificationStore instance = NotificationStore._internal();

  final ValueNotifier<List<AppNotification>> notificationsNotifier =
      ValueNotifier<List<AppNotification>>([]);

  final Map<String, List<AppNotification>> _userNotifications = {};
  String? _currentUserId;

  List<AppNotification> get notifications => notificationsNotifier.value;

  void loadForUser(UserProfile? user, {bool isNewUser = false}) {
    if (user == null) {
      _currentUserId = null;
      notificationsNotifier.value = const [];
      return;
    }

    _currentUserId = user.userId;

    if (isNewUser) {
      final now = DateTime.now();
      final welcome = AppNotification(
        id: 'notif_welcome_${user.userId}',
        title: user.isOwner
            ? 'Chào mừng Đối tác Cụm sân mới! 🏟️'
            : 'Chào mừng ${user.fullName} đến với SportHub! 🎉',
        message: user.isOwner
            ? 'Cụm sân của bạn đã được thiết lập thành công. Hãy bắt đầu quản lý lịch và quầy lễ tân ngay.'
            : 'Tài khoản của bạn đã được kích hoạt thành công. Hãy khám phá và đặt sân thể thao ngay nhé!',
        timestamp: now,
        type: NotificationType.system,
        role: user.isOwner ? NotificationRole.owner : NotificationRole.player,
        isRead: false,
      );
      _userNotifications[user.userId] = [welcome];
      notificationsNotifier.value = List.unmodifiable([welcome]);
      return;
    }

    if (_userNotifications.containsKey(user.userId)) {
      notificationsNotifier.value =
          List.unmodifiable(_userNotifications[user.userId]!);
      return;
    }

    if (user.userId == 'user_demo_01') {
      final notifs = _generatePlayerSeedNotifications();
      _userNotifications[user.userId] = notifs;
      notificationsNotifier.value = List.unmodifiable(notifs);
    } else if (user.isOwner) {
      final notifs = _generateOwnerSeedNotifications();
      _userNotifications[user.userId] = notifs;
      notificationsNotifier.value = List.unmodifiable(notifs);
    } else {
      final now = DateTime.now();
      final welcome = AppNotification(
        id: 'notif_welcome_${user.userId}',
        title: 'Chào mừng ${user.fullName} quay lại! 👋',
        message:
            'SportHub sẵn sàng hỗ trợ bạn tìm sân và kết nối đồng đội thể thao hôm nay.',
        timestamp: now,
        type: NotificationType.system,
        role: NotificationRole.player,
        isRead: false,
      );
      _userNotifications[user.userId] = [welcome];
      notificationsNotifier.value = List.unmodifiable([welcome]);
    }
  }

  void _syncCurrentUserNotifications() {
    if (_currentUserId != null) {
      _userNotifications[_currentUserId!] = notificationsNotifier.value;
    }
  }

  int getUnreadCount({NotificationRole? role}) {
    return notificationsNotifier.value.where((n) {
      if (n.isRead) return false;
      if (role == null || role == NotificationRole.all) return true;
      return n.role == role || n.role == NotificationRole.all;
    }).length;
  }

  List<AppNotification> getNotificationsForRole(NotificationRole role) {
    if (role == NotificationRole.all) return notificationsNotifier.value;
    return notificationsNotifier.value
        .where((n) => n.role == role || n.role == NotificationRole.all)
        .toList();
  }

  void markAsRead(String id) {
    final list = notificationsNotifier.value;
    final index = list.indexWhere((n) => n.id == id);
    if (index != -1 && !list[index].isRead) {
      final updated = List<AppNotification>.from(list);
      updated[index] = updated[index].copyWith(isRead: true);
      notificationsNotifier.value = List.unmodifiable(updated);
      _syncCurrentUserNotifications();
    }
  }

  void markAllAsRead({NotificationRole? role}) {
    final list = notificationsNotifier.value;
    final updated = list.map((n) {
      if (role == null ||
          role == NotificationRole.all ||
          n.role == role ||
          n.role == NotificationRole.all) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    notificationsNotifier.value = List.unmodifiable(updated);
    _syncCurrentUserNotifications();
  }

  void addNotification(AppNotification notification) {
    final updated = [notification, ...notificationsNotifier.value];
    notificationsNotifier.value = List.unmodifiable(updated);
    _syncCurrentUserNotifications();
  }

  void deleteNotification(String id) {
    final updated =
        notificationsNotifier.value.where((n) => n.id != id).toList();
    notificationsNotifier.value = List.unmodifiable(updated);
    _syncCurrentUserNotifications();
  }

  void clearAll({NotificationRole? role}) {
    if (role == null || role == NotificationRole.all) {
      notificationsNotifier.value = const [];
    } else {
      final updated = notificationsNotifier.value
          .where((n) => n.role != role && n.role != NotificationRole.all)
          .toList();
      notificationsNotifier.value = List.unmodifiable(updated);
    }
    _syncCurrentUserNotifications();
  }

  List<AppNotification> _generatePlayerSeedNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'notif_p_01',
        title: 'Nhắc lịch thi đấu sắp tới 🏸',
        message:
            'Bạn có trận đấu tại Sân Cầu Lông Bình Thạnh vào 18:00 hôm nay. Sẵn sàng ra sân nhé!',
        timestamp: now.subtract(const Duration(minutes: 25)),
        type: NotificationType.booking,
        role: NotificationRole.player,
        isRead: false,
        targetId: 'BK-20260906-889',
      ),
      AppNotification(
        id: 'notif_p_02',
        title: 'Lời mời ghép trận mới 👥',
        message:
            'Minh Hoàng đã mời bạn tham gia trận Pickleball giao lưu tại Thảo Điền Hub.',
        timestamp: now.subtract(const Duration(hours: 2)),
        type: NotificationType.community,
        role: NotificationRole.player,
        isRead: false,
        targetId: 'post_01',
      ),
      AppNotification(
        id: 'notif_p_03',
        title: 'Ưu đãi Giờ Vàng 20% 🎁',
        message:
            'Đặt sân ca sáng (08:00 - 16:00) tại CLB Tao Đàn để nhận mức giá ưu đãi đặc biệt hôm nay.',
        timestamp: now.subtract(const Duration(hours: 5)),
        type: NotificationType.system,
        role: NotificationRole.player,
        isRead: true,
      ),
    ];
  }

  List<AppNotification> _generateOwnerSeedNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'notif_o_01',
        title: 'Đơn đặt sân mới qua App ⚡',
        message:
            'Khách hàng Nguyễn Văn A vừa đặt Sân Cầu Lông 01 (18:00 - 19:00). Mã vé: SH-8291.',
        timestamp: now.subtract(const Duration(minutes: 10)),
        type: NotificationType.partner,
        role: NotificationRole.owner,
        isRead: false,
        targetId: 'SH-8291',
      ),
      AppNotification(
        id: 'notif_o_02',
        title: 'Soát vé Check-in thành công ✅',
        message:
            'Vé SH-9120 đã được quét mã QR và hoàn tất nhận sân tại Sân Pickleball 05.',
        timestamp: now.subtract(const Duration(hours: 1)),
        type: NotificationType.partner,
        role: NotificationRole.owner,
        isRead: false,
        targetId: 'SH-9120',
      ),
      AppNotification(
        id: 'notif_o_03',
        title: 'Báo cáo doanh thu ngày 📊',
        message:
            'Doanh thu hôm nay đã đạt 2.850.000 đ với tỷ lệ lấp đầy 81.2%.',
        timestamp: now.subtract(const Duration(hours: 8)),
        type: NotificationType.system,
        role: NotificationRole.owner,
        isRead: true,
      ),
    ];
  }

  void resetSeedData() {
    _currentUserId = 'user_demo_01';
    final playerNotifs = _generatePlayerSeedNotifications();
    final ownerNotifs = _generateOwnerSeedNotifications();
    _userNotifications['user_demo_01'] = playerNotifs;
    _userNotifications['user_owner_01'] = ownerNotifs;
    notificationsNotifier.value = List.unmodifiable([
      ...playerNotifs,
      ...ownerNotifs,
    ]);
  }
}
