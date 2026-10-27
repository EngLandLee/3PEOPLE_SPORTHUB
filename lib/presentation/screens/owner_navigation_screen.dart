import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/venue_owner_store.dart';
import '../../core/theme/theme_store.dart';
import 'owner_tabs/owner_checkin_tab.dart';
import 'owner_tabs/owner_revenue_tab.dart';
import 'owner_tabs/owner_schedule_tab.dart';
import '../../core/state/notification_store.dart';
import '../../domain/entities/app_notification.dart';
import '../widgets/notification_center_sheet.dart';
import '../widgets/chat/floating_chat_bubble.dart';

class OwnerNavigationScreen extends StatefulWidget {
  const OwnerNavigationScreen({super.key});

  @override
  State<OwnerNavigationScreen> createState() => _OwnerNavigationScreenState();
}

class _OwnerNavigationScreenState extends State<OwnerNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeStore.instance.themeModeNotifier,
      builder: (context, themeMode, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: const FloatingChatBubble(currentRoute: '/owner'),
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            titleSpacing: 12,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.warning, Color(0xFFF97316)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warning.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storefront_rounded, size: 14, color: Colors.black),
                      SizedBox(width: 4),
                      Text(
                        'SportHub Partner',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    VenueOwnerStore.instance.activeVenueName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeStore.instance.themeModeNotifier,
                builder: (context, _, __) {
                  return IconButton(
                    key: const Key('theme_toggle_button_owner'),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Đổi giao diện sáng/tối',
                    icon: Icon(
                      ThemeStore.instance.isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: AppColors.primary,
                    ),
                    onPressed: () => ThemeStore.instance.toggleTheme(),
                  );
                },
              ),
              // Notification Bell with Badge
              ValueListenableBuilder<List<AppNotification>>(
                valueListenable:
                    NotificationStore.instance.notificationsNotifier,
                builder: (context, notifs, _) {
                  final unreadCount = NotificationStore.instance
                      .getUnreadCount(role: NotificationRole.owner);
                  return IconButton(
                    key: const Key('notification_bell_button_owner'),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Thông báo',
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textPrimary,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -1,
                            right: -1,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.surface, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      NotificationCenterSheet.show(
                        context,
                        role: NotificationRole.owner,
                        onNotificationTap: (notif) {
                          if (notif.title.contains('Check-in') ||
                              notif.message.contains('quét mã QR')) {
                            setState(() => _currentIndex = 1);
                          } else if (notif.title.contains('doanh thu') ||
                              notif.title.contains('Báo cáo')) {
                            setState(() => _currentIndex = 2);
                          } else {
                            setState(() => _currentIndex = 0);
                          }
                        },
                      );
                    },
                  );
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Quay lại chế độ người chơi',
                icon: Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                onPressed: () => VenueOwnerStore.instance.toggleOwnerMode(false),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeStore.instance.themeModeNotifier,
            builder: (context, themeMode, _) {
              return KeyedSubtree(
                key: ValueKey('owner_tab_${_currentIndex}_${themeMode.name}'),
                child: _buildTab(_currentIndex),
              );
            },
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                        alpha: AppColors.isDark ? 0.35 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildNavItem(
                      key: const Key('owner_tab_schedule'),
                      index: 0,
                      icon: Icons.calendar_month_rounded,
                      label: 'Lịch sân',
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      key: const Key('owner_tab_checkin'),
                      index: 1,
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Soát vé',
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      key: const Key('owner_tab_revenue'),
                      index: 2,
                      icon: Icons.analytics_rounded,
                      label: 'Doanh thu',
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      key: const Key('owner_tab_settings'),
                      index: 3,
                      icon: Icons.settings_rounded,
                      label: 'Cài đặt',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return _buildScheduleTab();
      case 1:
        return _buildCheckinTab();
      case 2:
        return _buildRevenueTab();
      case 3:
      default:
        return _buildSettingsTab();
    }
  }

  Widget _buildScheduleTab() {
    return const OwnerScheduleTab();
  }

  Widget _buildCheckinTab() {
    return const OwnerCheckinTab();
  }

  Widget _buildRevenueTab() {
    return const OwnerRevenueTab();
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      key: const PageStorageKey<String>('owner_settings_scroll'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Active Venue Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.stadium_rounded,
                        color: AppColors.warning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            VenueOwnerStore.instance.activeVenueName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quận 1, TP. Hồ Chí Minh',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: AppColors.cardBorder),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.sports_tennis_rounded, 'Quy mô cơ sở',
                    '8 sân hoạt động (4 Cầu lông, 4 Pickleball)'),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.access_time_rounded, 'Khung giờ phục vụ',
                    '06:00 - 22:00 hàng ngày'),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.verified_rounded, 'Trạng thái đối tác',
                    'Đã xác thực SportHub Verified'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Owner Profile Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin Người đại diện',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        'TV',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trần Văn Chủ Sân',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '0988 888 777 • Chủ sân',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Theme Settings Card
          Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeStore.instance.themeModeNotifier,
              builder: (context, _, __) {
                final isDark = ThemeStore.instance.isDarkMode;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Giao diện',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    isDark ? 'Chế độ tối' : 'Chế độ sáng',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: Switch.adaptive(
                    key: const Key('owner_settings_theme_toggle'),
                    value: isDark,
                    onChanged: (_) => ThemeStore.instance.toggleTheme(),
                    activeTrackColor: AppColors.primary,
                  ),
                  onTap: () => ThemeStore.instance.toggleTheme(),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Exit Owner Mode Button
          ElevatedButton.icon(
            key: const Key('exit_owner_mode_button'),
            onPressed: () => VenueOwnerStore.instance.toggleOwnerMode(false),
            icon: const Icon(Icons.swap_horiz_rounded, size: 20),
            label: const Text(
              '🔄 Quay lại Chế độ Người Chơi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chuyển về giao diện người chơi để tìm sân và tham gia cộng đồng',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required Key key,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      key: key,
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.warning.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
                  color: AppColors.warning.withValues(alpha: 0.5),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.warning : AppColors.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.warning : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 4 : 0,
              height: isSelected ? 4 : 0,
              decoration: BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
