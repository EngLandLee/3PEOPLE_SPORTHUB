import 'dart:async';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'core/utils/currency_formatter.dart';
import 'core/state/auth_store.dart';
import 'core/state/venue_owner_store.dart';
import 'core/theme/theme_store.dart';
import 'core/utils/seed_data.dart';
import 'core/utils/vietqr_generator.dart';
import 'domain/entities/community_post.dart';
import 'presentation/screens/owner_navigation_screen.dart';
import 'domain/entities/join_request.dart';
import 'domain/entities/user_profile.dart';
import 'domain/entities/time_slot.dart';
import 'domain/entities/venue.dart';
import 'presentation/blocs/booking/booking_bloc.dart';
import 'presentation/blocs/booking/booking_event.dart';
import 'presentation/blocs/booking/booking_state.dart';
import 'presentation/widgets/responsive_mobile_wrapper.dart';
import 'presentation/widgets/time_slot_matrix.dart';
import 'presentation/widgets/visual_court_header.dart';
import 'core/utils/shift_slot_generator.dart';
import 'core/utils/court_sport_partition.dart';
import 'domain/entities/sport_zone.dart';
import 'data/models/match_recommendation.dart';
import 'domain/entities/auth_state.dart';
import 'domain/entities/venue_addon.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/widgets/venue_addon_selector.dart';
import 'data/models/ticket_model.dart';
import 'presentation/widgets/community_image_attachment_picker.dart';
import 'presentation/widgets/auth_guard_sheet.dart';
import 'core/state/notification_store.dart';
import 'domain/entities/app_notification.dart';
import 'presentation/widgets/notification_center_sheet.dart';
import 'core/services/venue_sync_service.dart';
import 'core/state/ticket_store.dart';
import 'presentation/widgets/chat/floating_chat_bubble.dart';
import 'presentation/widgets/chat/chatbot_bottom_sheet.dart';
import 'core/services/chatbot_service.dart';

class MainNavigationController {
  static void Function(int index)? switchToTab;
}

class CommunityFeedStore {
  static final CommunityFeedStore instance = CommunityFeedStore._internal();
  CommunityFeedStore._internal() {
    reset();
  }

  final ValueNotifier<List<CommunityPost>> postsNotifier =
      ValueNotifier<List<CommunityPost>>([]);

  List<CommunityPost> get posts => postsNotifier.value;

  void reset() {
    postsNotifier.value = List.from(SeedData.sampleCommunityPosts);
  }

  void addPost(CommunityPost post) {
    postsNotifier.value = [post, ...postsNotifier.value];
  }

  void updatePost(CommunityPost post) {
    postsNotifier.value =
        postsNotifier.value.map((p) => p.id == post.id ? post : p).toList();
  }

  void sendJoinRequest(String postId, UserProfile applicant) {
    final newRequest = JoinRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      userId: applicant.userId,
      userName: applicant.fullName,
      userPhone: applicant.phone,
      skillLevel: applicant.skillLevel,
      preferredSport: applicant.preferredSport,
      createdAt: DateTime.now(),
      status: 'pending',
    );
    postsNotifier.value = postsNotifier.value.map((p) {
      if (p.id != postId) return p;
      return p.copyWith(
        pendingRequests: [...p.pendingRequests, newRequest],
      );
    }).toList();
  }

  void approveJoinRequest(String postId, String requestId) {
    postsNotifier.value = postsNotifier.value.map((p) {
      if (p.id != postId) return p;
      final updatedRequests = p.pendingRequests.map((r) {
        if (r.id == requestId) {
          return r.copyWith(status: 'approved');
        }
        return r;
      }).toList();
      final newCurrentPlayers = p.currentPlayers + 1;
      final shouldClose = newCurrentPlayers >= p.requiredPlayers || p.isClosed;
      return p.copyWith(
        pendingRequests: updatedRequests,
        currentPlayers: newCurrentPlayers,
        isClosed: shouldClose,
      );
    }).toList();
  }

  void rejectJoinRequest(String postId, String requestId) {
    postsNotifier.value = postsNotifier.value.map((p) {
      if (p.id != postId) return p;
      final updatedRequests = p.pendingRequests.map((r) {
        if (r.id == requestId) {
          return r.copyWith(status: 'rejected');
        }
        return r;
      }).toList();
      return p.copyWith(pendingRequests: updatedRequests);
    }).toList();
  }

  void closePost(String postId) {
    postsNotifier.value = postsNotifier.value.map((p) {
      if (p.id != postId) return p;
      return p.copyWith(isClosed: true);
    }).toList();
  }

  void toggleLike(String postId) {
    final list = List<CommunityPost>.from(postsNotifier.value);
    final idx = list.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final post = list[idx];
      final newLiked = !post.isLiked;
      final newCount =
          newLiked ? post.likesCount + 1 : (post.likesCount - 1).clamp(0, 9999);
      list[idx] = post.copyWith(isLiked: newLiked, likesCount: newCount);
      postsNotifier.value = list;
    }
  }
}

class UserProfileStore {
  UserProfileStore._() {
    _initAuthListener();
  }
  static final UserProfileStore instance = UserProfileStore._();

  static const _defaultProfile = UserProfile(
    userId: 'user_demo_01',
    fullName: 'Nguyễn Văn An',
    phone: '0909 123 456',
    preferredSport: 'pickleball',
    skillLevel: 'Intermediate',
    district: 'Bình Thạnh',
    playTimePreference: 'Buổi tối (18:00 - 21:00)',
    matchesPlayed: 18,
    reputationRating: 4.9,
    onTimeRate: 98,
  );

  final ValueNotifier<UserProfile> profileNotifier =
      ValueNotifier<UserProfile>(_defaultProfile);

  UserProfile get profile =>
      AuthStore.instance.currentUser ?? profileNotifier.value;

  void _initAuthListener() {
    AuthStore.instance.stateNotifier.addListener(() {
      final authUser = AuthStore.instance.currentUser;
      if (authUser != null) {
        if (profileNotifier.value != authUser) {
          profileNotifier.value = authUser;
        }
      } else {
        if (profileNotifier.value != _defaultProfile) {
          profileNotifier.value = _defaultProfile;
        }
      }
    });
  }

  void reset() {
    final current = AuthStore.instance.currentUser;
    profileNotifier.value = current ?? _defaultProfile;
  }

  void updateProfile({
    String? fullName,
    String? phone,
    String? preferredSport,
    String? skillLevel,
    String? district,
    String? playTimePreference,
  }) {
    final updated = profile.copyWith(
      fullName: fullName,
      phone: phone,
      preferredSport: preferredSport,
      skillLevel: skillLevel,
      district: district,
      playTimePreference: playTimePreference,
    );
    profileNotifier.value = updated;
    AuthStore.instance.updateCurrentUser(updated);
  }
}

void main() {
  runApp(const SportHubApp());
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class SportHubApp extends StatelessWidget {
  const SportHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookingBloc(),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeStore.instance.themeModeNotifier,
        builder: (context, themeMode, _) {
          return MaterialApp(
            title: 'SportHub',
            debugShowCheckedModeBanner: false,
            scrollBehavior: const AppScrollBehavior(),
            themeMode: themeMode,
            theme: ThemeData.light().copyWith(
              scaffoldBackgroundColor: AppColors.lightBackground,
              primaryColor: AppColors.lightPrimary,
              colorScheme: const ColorScheme.light(
                primary: AppColors.lightPrimary,
                secondary: AppColors.secondary,
                surface: AppColors.lightSurface,
                error: AppColors.error,
                onPrimary: Colors.white,
                onSurface: AppColors.lightTextPrimary,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.lightBackground,
                foregroundColor: AppColors.lightTextPrimary,
                elevation: 0,
                centerTitle: false,
              ),
            ),
            darkTheme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: AppColors.darkBackground,
              primaryColor: AppColors.darkPrimary,
              colorScheme: const ColorScheme.dark(
                primary: AppColors.darkPrimary,
                secondary: AppColors.secondary,
                surface: AppColors.darkSurface,
                error: AppColors.error,
                onPrimary: Colors.black,
                onSurface: AppColors.darkTextPrimary,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.darkBackground,
                foregroundColor: AppColors.darkTextPrimary,
                elevation: 0,
                centerTitle: false,
              ),
            ),
            builder: (context, child) => ResponsiveMobileWrapper(
              child: child!,
            ),
            home: ValueListenableBuilder<AuthState>(
              valueListenable: AuthStore.instance.stateNotifier,
              builder: (context, state, _) {
                if (!state.isAuthenticated && !state.isGuest) {
                  return const AuthScreen();
                }
                return const _SportHubShell();
              },
            ),
          );
        },
      ),
    );
  }
}

typedef _SportHubShell = MainNavigationScreen;

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    CommunityFeedStore.instance.reset();
    UserProfileStore.instance.reset();
    MainNavigationController.switchToTab = (index) {
      if (mounted) setState(() => _currentIndex = index);
    };
  }

  @override
  void dispose() {
    MainNavigationController.switchToTab = null;
    super.dispose();
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const ExploreVenuesScreen();
      case 1:
        return const MatchmakingScreen();
      case 2:
        return TicketsScreen(
          onNavigateToCommunity: () => _switchTab(1),
        );
      case 3:
        return const ProfileScreen();
      default:
        return const ExploreVenuesScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeStore.instance.themeModeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: VenueOwnerStore.instance.isOwnerModeNotifier,
          builder: (context, isOwnerMode, _) {
            if (isOwnerMode) {
              return const OwnerNavigationScreen();
            }
            return Scaffold(
              extendBody: true,
              floatingActionButton: const FloatingChatBubble(currentRoute: '/home'),
              body: ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeStore.instance.themeModeNotifier,
                builder: (context, themeMode, _) {
                  return KeyedSubtree(
                    key: ValueKey('consumer_screen_${_currentIndex}_${themeMode.name}'),
                    child: _buildScreen(_currentIndex),
                  );
                },
              ),
              bottomNavigationBar: SafeArea(
                child: Container(
                  key: const Key('consumer_bottom_nav_bar'),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppColors.cardBorder, width: 1.5),
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
                          0, Icons.sports_tennis_rounded, 'Đặt sân')),
                  Expanded(
                      child:
                          _buildNavItem(1, Icons.groups_rounded, 'Cộng đồng')),
                  Expanded(
                      child: _buildNavItem(
                          2, Icons.confirmation_number_rounded, 'Vé của tôi')),
                  Expanded(
                      child: _buildNavItem(3, Icons.person_rounded, 'Hồ sơ')),
                ],
              ),
            ),
          ),
        );
      },
    );
  },
);
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 1: KHÁM PHÁ & ĐẶT SÂN
// -------------------------------------------------------------
class ExploreVenuesScreen extends StatefulWidget {
  const ExploreVenuesScreen({super.key});

  @override
  State<ExploreVenuesScreen> createState() => _ExploreVenuesScreenState();
}

class _ExploreVenuesScreenState extends State<ExploreVenuesScreen> {
  String _selectedSport = 'all';
  String _selectedDistrict = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    VenueSyncService.instance.syncWithServer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDistrictBottomSheet(BuildContext context) {
    final districtOptions = [
      {'key': 'all', 'label': 'Tất cả TP.HCM'},
      {'key': 'Bình Thạnh', 'label': 'Bình Thạnh'},
      {'key': 'Thủ Đức', 'label': 'Thủ Đức'},
      {'key': 'Quận 7', 'label': 'Quận 7'},
      {'key': 'Quận 1', 'label': 'Quận 1'},
      {'key': 'Tân Bình', 'label': 'Tân Bình'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Chọn khu vực / Quận',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...districtOptions.map((opt) {
                    final key = opt['key']!;
                    final label = opt['label']!;
                    final isSelected =
                        _selectedDistrict.toLowerCase() == key.toLowerCase();
                    final allVenues =
                        VenueSyncService.instance.venuesNotifier.value;
                    final count = key == 'all'
                        ? allVenues.length
                        : allVenues
                            .where((v) =>
                                v.district.toLowerCase() == key.toLowerCase())
                            .length;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        label,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$count cụm sân',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.check_rounded,
                                color: AppColors.primary, size: 20),
                          ],
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _selectedDistrict = key;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Không tìm thấy sân nào phù hợp',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Thử tìm kiếm với từ khóa khác hoặc xóa bớt bộ lọc',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            key: const Key('reset_filters_button'),
            onPressed: () {
              setState(() {
                _selectedSport = 'all';
                _selectedDistrict = 'all';
                _searchQuery = '';
                _searchController.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Đặt lại bộ lọc',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Venue>>(
      valueListenable: VenueSyncService.instance.venuesNotifier,
      builder: (context, currentVenues, _) {
        final q = _searchQuery.toLowerCase();
        final venues = currentVenues.where((v) {
          final matchesSport =
              _selectedSport == 'all' || v.sportTypes.contains(_selectedSport);
          final matchesDistrict = _selectedDistrict == 'all' ||
              v.district.toLowerCase() == _selectedDistrict.toLowerCase();
          final matchesQuery = q.isEmpty ||
              v.name.toLowerCase().contains(q) ||
              v.address.toLowerCase().contains(q) ||
              v.district.toLowerCase().contains(q) ||
              v.amenities.any((a) => a.toLowerCase().contains(q));
          return matchesSport && matchesDistrict && matchesQuery;
        }).toList();

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Top App Header - Row 1: Profile & Brand + Notifications
                    Row(
                      children: [
                        // User Avatar
                        ValueListenableBuilder<UserProfile>(
                          valueListenable: UserProfileStore.instance.profileNotifier,
                          builder: (context, userProfile, _) {
                            final words = userProfile.fullName
                                .trim()
                                .split(RegExp(r'\s+'))
                                .where((w) => w.isNotEmpty)
                                .toList();
                            final initials = words.isEmpty
                                ? 'U'
                                : (words.length == 1
                                    ? words.first[0].toUpperCase()
                                    : '${words.first[0]}${words.last[0]}'.toUpperCase());
                            return GestureDetector(
                              key: const Key('header_user_avatar'),
                              onTap: () =>
                                  MainNavigationController.switchToTab?.call(3),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary
                                    ],
                                  ),
                                  border: Border.all(
                                      color: AppColors.cardBorder, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        // Brand and Greeting
                        Expanded(
                          child: ValueListenableBuilder<UserProfile>(
                            valueListenable: UserProfileStore.instance.profileNotifier,
                            builder: (context, userProfile, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SportHub',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'Chào ${userProfile.fullName} 👋',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        // Quick Theme Toggle Button
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: ThemeStore.instance.themeModeNotifier,
                          builder: (context, _, __) {
                            return IconButton(
                              key: const Key('theme_toggle_button'),
                              tooltip: 'Đổi giao diện sáng/tối',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 36),
                              visualDensity: VisualDensity.compact,
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
                        const SizedBox(width: 4),
                        // Notification Icon with Live Badge
                        ValueListenableBuilder<List<AppNotification>>(
                          valueListenable:
                              NotificationStore.instance.notificationsNotifier,
                          builder: (context, notifs, _) {
                            final unreadCount = NotificationStore.instance
                                .getUnreadCount(role: NotificationRole.player);
                            return InkWell(
                              key: const Key('notification_bell_button'),
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                NotificationCenterSheet.show(
                                  context,
                                  role: NotificationRole.player,
                                  onNotificationTap: (notif) {
                                    if (notif.type == NotificationType.booking) {
                                      MainNavigationController.switchToTab?.call(2);
                                    } else if (notif.type ==
                                        NotificationType.community) {
                                      MainNavigationController.switchToTab?.call(1);
                                    }
                                  },
                                );
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      shape: BoxShape.circle,
                                      border:
                                          Border.all(color: AppColors.cardBorder),
                                    ),
                                    child: Icon(
                                      Icons.notifications_none_rounded,
                                      size: 20,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: AppColors.surface,
                                              width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.6),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        // Top Header AI Chatbot Trigger
                        IconButton(
                          key: const Key('header_chatbot_button'),
                          tooltip: 'Trợ lý AI',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 36, minHeight: 36),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.auto_awesome,
                            color: AppColors.primary,
                          ),
                          onPressed: () => ChatbotBottomSheet.show(
                            context,
                            currentRoute: '/home',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Top App Header - Row 2: Location Pill + Subtitle
                    Row(
                      children: [
                        InkWell(
                          key: const Key('location_pill'),
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _showDistrictBottomSheet(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Text(
                              _selectedDistrict == 'all'
                                  ? '📍 Tất cả TP.HCM ▾'
                                  : '📍 $_selectedDistrict, TP.HCM ▾',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sẵn sàng ra sân hôm nay?',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Search Bar with AI Chatbot Helper
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 13),
                        onChanged: (val) => setState(
                            () => _searchQuery = val.trim().toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Tìm tên sân, địa chỉ, quận...',
                          hintStyle: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: AppColors.textSecondary, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  key: const Key('clear_search_button'),
                                  icon: Icon(Icons.close_rounded,
                                      color: AppColors.textSecondary, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : IconButton(
                                  key: const Key('search_chatbot_button'),
                                  tooltip: 'Hỏi Trợ lý AI',
                                  icon: Icon(Icons.auto_awesome,
                                      color: AppColors.primary, size: 18),
                                  onPressed: () {
                                    ChatbotBottomSheet.show(
                                      context,
                                      currentRoute: '/home',
                                    );
                                  },
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Sport Category Filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSportChip('all', 'Tất cả môn'),
                          const SizedBox(width: 8),
                          _buildSportChip('pickleball', '🏓 Pickleball'),
                          const SizedBox(width: 8),
                          _buildSportChip('badminton', '🏸 Cầu lông'),
                          const SizedBox(width: 8),
                          _buildSportChip('football', '⚽ Bóng đá'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section Title
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cụm sân nổi bật tại TP.HCM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${venues.length} cụm sân)',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Venue List
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: venues.isEmpty
                  ? SliverToBoxAdapter(
                      child: _buildEmptyState(),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final venue = venues[index];
                          return _buildVenueCard(context, venue);
                        },
                        childCount: venues.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildSportChip(String key, String label) {
    final isSelected = _selectedSport == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedSport = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildVenueCard(BuildContext context, Venue venue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: AppColors.isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VenueDetailScreen(venue: venue),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 16:9 Image with gradient overlay and badges
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    venue.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.cardBorder,
                      child: Center(
                        child: Icon(Icons.sports_tennis_rounded,
                            size: 48, color: AppColors.primary),
                      ),
                    ),
                  ),
                  // Gradient Overlay (Dark mode blends with dark card, light mode stays transparent and sharp)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.isDark
                              ? AppColors.surface.withValues(alpha: 0.8)
                              : Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Floating Tag Top-Left
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.5)),
                      ),
                      child: const Text(
                        '🔥 Đặt nhiều',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                  ),
                  // Floating Rating Badge Top-Right (always white text on dark overlay)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            '${venue.rating}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            ' (${venue.reviewCount})',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${venue.address}, ${venue.district}',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Amenities Row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildAmenityChip('❄️ Máy lạnh'),
                      _buildAmenityChip('🚗 Bãi xe'),
                      _buildAmenityChip('🟢 Còn ${venue.courtCount} sân'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Price and Gradient CTA Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Giá chỉ từ',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 11),
                            ),
                            Text(
                              CurrencyFormatter.formatWithUnit(venue.hourlyRate, 'h'),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      VenueDetailScreen(venue: venue),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 9),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Xem lịch sân',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded,
                                      size: 14, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenityChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.isDark ? AppColors.background : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.isDark
              ? AppColors.textSecondary
              : const Color(0xFF334155),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// CHI TIẾT SÂN & LƯỚI MA TRẬN 2D TIME-SLOT
// -------------------------------------------------------------
// -------------------------------------------------------------
// CHI TIẾT SÂN & LƯỚI MA TRẬN 2D TIME-SLOT & DỊCH VỤ ADD-ON
// -------------------------------------------------------------
class VenueDetailScreen extends StatefulWidget {
  final Venue venue;
  final DateTime? initialDate;
  final int? targetCourtNumber;
  final String? targetStartTime;
  final String? targetEndTime;
  final String? targetSport;
  final String? initialViewMode;
  final Map<String, int>? initialAddonCounts;

  const VenueDetailScreen({
    super.key,
    required this.venue,
    this.initialDate,
    this.targetCourtNumber,
    this.targetStartTime,
    this.targetEndTime,
    this.targetSport,
    this.initialViewMode,
    this.initialAddonCounts,
  });

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class VietQrPaymentDialog extends StatefulWidget {
  final Venue venue;
  final double grandTotal;
  final List<TimeSlot> selectedSlots;
  final Map<String, int> addonCounts;
  final VoidCallback onConfirmed;
  final List<(String, String)>? customBreakdown;
  final String? paymentTitle;

  const VietQrPaymentDialog({
    super.key,
    required this.venue,
    required this.grandTotal,
    required this.selectedSlots,
    required this.addonCounts,
    required this.onConfirmed,
    this.customBreakdown,
    this.paymentTitle,
  });

  @override
  State<VietQrPaymentDialog> createState() => _VietQrPaymentDialogState();
}

class _VietQrPaymentDialogState extends State<VietQrPaymentDialog> {
  int _secondsLeft = 299; // 04:59 initial hold reservation countdown
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final memoCode = widget.customBreakdown != null ? 'FIXED' : 'SPORTHUB';
    final qrUrl = VietQRGenerator.generateUrl(
      bankId: 'MB',
      accountNo: '0901234567',
      amount: widget.grandTotal.toInt(),
      memo: '$memoCode-${widget.venue.id}',
      accountName: 'CLB SPORTHUB VIETNAM',
    );

    final selectedAddonEntries =
        widget.addonCounts.entries.where((e) => e.value > 0).map((e) {
      final item = SeedData.sampleAddons.firstWhere(
        (a) => a.id == e.key,
        orElse: () => const VenueAddonItem(
          id: '',
          name: 'Dịch vụ',
          description: '',
          price: 0,
          unit: '',
          category: AddonCategory.gear,
          icon: '📦',
        ),
      );
      return (item: item, count: e.value);
    }).toList();

    final isExpired = _secondsLeft <= 0;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      title: Row(
        children: [
          Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            widget.paymentTitle ?? 'Thanh Toán VietQR',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 18),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 380,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tổng tiền: ${CurrencyFormatter.format(widget.grandTotal)}',
                style: TextStyle(
                    fontSize: 22,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Itemized Breakdown Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chi tiết thanh toán:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (widget.customBreakdown != null &&
                        widget.customBreakdown!.isNotEmpty) ...[
                      const Text(
                        '🔄 Thông tin hợp đồng cố định:',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      ...widget.customBreakdown!.map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '• ${row.$1}:',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  row.$2,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (widget.selectedSlots.isNotEmpty) ...[
                      Builder(
                        builder: (_) {
                          final sport = widget.venue.sportTypes.isNotEmpty
                              ? widget.venue.sportTypes.first
                              : 'badminton';
                          final sportLabel = switch (sport) {
                            'football' => '⚽ Khung giờ sân bóng đá',
                            'pickleball' => '🏓 Khung giờ sân Pickleball',
                            _ => '🏸 Khung giờ sân cầu lông',
                          };
                          return Text(
                            '$sportLabel (${widget.selectedSlots.length} slot):',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600),
                          );
                        },
                      ),
                      const SizedBox(height: 2),
                      ...widget.selectedSlots.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '• Sân ${s.courtNumber} (${s.startTime} - ${s.endTime})',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(CurrencyFormatter.format(s.price),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (selectedAddonEntries.isNotEmpty) ...[
                      Text(
                        '📦 Dịch vụ & Dụng cụ (${selectedAddonEntries.fold(0, (sum, i) => sum + i.count)} món):',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.amber,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      ...selectedAddonEntries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '• ${entry.count}x ${entry.item.name}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CurrencyFormatter.format(
                                    entry.item.price * entry.count),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // VietQR Code
              Semantics(
                label:
                    'Mã QR thanh toán VietQR chuyển khoản ${CurrencyFormatter.format(widget.grandTotal)} cho ${widget.venue.name}',
                image: true,
                child: Container(
                  height: 190,
                  width: 190,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      qrUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.qr_code_2,
                            size: 110, color: Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Expiry Countdown
              Semantics(
                liveRegion: true,
                label: isExpired
                    ? 'Thời gian giữ chỗ đã hết hạn'
                    : 'Thời gian giữ chỗ còn ${_formatCountdown(_secondsLeft)}',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.grey.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isExpired
                          ? Colors.grey.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isExpired
                        ? '⏱️ Đã hết hạn giữ chỗ (00:00)'
                        : '⏱️ Giữ chỗ trong: ${_formatCountdown(_secondsLeft)}',
                    key: const Key('vietqr_hold_countdown'),
                    style: TextStyle(
                        color: isExpired ? Colors.grey : const Color(0xFFF87171),
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isExpired ? Colors.grey : AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: isExpired
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  widget.onConfirmed();
                },
          child: const Text('Xác nhận đã chuyển',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

Map<String, int> extractAddonCountsFromCard(Map<String, dynamic>? card) {
  if (card == null) return {};
  final counts = <String, int>{};
  if (card['addonCounts'] is Map) {
    final rawMap = card['addonCounts'] as Map;
    for (final e in rawMap.entries) {
      final k = e.key.toString();
      final v = int.tryParse(e.value.toString()) ?? 0;
      if (v > 0) counts[k] = v;
    }
  }
  if (counts.isEmpty && card['addons'] is List) {
    for (final item in card['addons'] as List) {
      final s = item.toString();
      final qtyMatch = RegExp(r'^(\d+)x').firstMatch(s);
      final qty = int.tryParse(qtyMatch?.group(1) ?? '1') ?? 1;
      final lower = s.toLowerCase();
      if (lower.contains('pocari') || lower.contains('khoáng') || lower.contains('nước')) {
        counts['drink_pocari'] = (counts['drink_pocari'] ?? 0) + qty;
      } else if (lower.contains('ống cầu')) {
        counts['gear_shuttle_tube'] = (counts['gear_shuttle_tube'] ?? 0) + qty;
      } else if (lower.contains('quả cầu') || lower.contains('cầu lẻ')) {
        counts['gear_shuttle_single'] = (counts['gear_shuttle_single'] ?? 0) + qty;
      } else if (lower.contains('vợt')) {
        counts['rent_badminton'] = (counts['rent_badminton'] ?? 0) + qty;
      }
    }
  }
  return counts;
}

class _VenueDetailScreenState extends State<VenueDetailScreen>
    with TickerProviderStateMixin {
  late List<TimeSlot> _slots;
  late final PageController _imagePageController;
  late final List<String> _galleryImages;
  int _currentImageIndex = 0;
  late DateTime _selectedDate;
  late final List<DateTime> _availableDates;
  final Map<String, int> _addonCounts = {};
  String _selectedShift = 'evening';
  String _selectedMinute = ':00';
  String _viewMode = 'matrix';
  String _selectedSportFilter = 'all';

  // Highlight, animation & scroll state
  int? _highlightedCourtNumber;
  AnimationController? _pulseController;
  Timer? _highlightTimer;
  Timer? _scrollTimer;
  final Map<int, GlobalKey> _courtKeys = {};

  // Booking Mode: 'flexible' (Đặt theo buổi) vs 'fixed' (Đặt lịch cố định theo tháng)
  String _bookingMode = 'flexible';

  // Fixed schedule booking state
  late String _fixedSport;
  final Set<int> _fixedWeekdays = {1, 3, 5}; // 1 = T2, 3 = T4, 5 = T6
  String _fixedTimeSlot = '18:00 - 20:00';
  int _fixedDurationMonths = 1; // 1, 3, 6 months

  String _sportLabel(String sportType) {
    switch (sportType) {
      case 'badminton':
        return '🏸 Cầu lông';
      case 'pickleball':
        return '🏓 Pickleball';
      case 'football':
        return '⚽ Bóng đá';
      default:
        return sportType;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialAddonCounts != null) {
      _addonCounts.addAll(widget.initialAddonCounts!);
    }
    final now = widget.initialDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _selectedDate = today;
    _availableDates = List.generate(
      14,
      (i) => today.add(Duration(days: i)),
    );
    final courtSport = widget.targetCourtNumber != null
        ? CourtSportPartition.getSportForCourt(
            venue: widget.venue,
            courtNumber: widget.targetCourtNumber!,
          )
        : null;
    _fixedSport = widget.targetSport ??
        courtSport ??
        (widget.venue.sportTypes.isNotEmpty
            ? widget.venue.sportTypes.first
            : 'badminton');

    if (widget.initialViewMode != null) {
      _viewMode = widget.initialViewMode!;
    } else if (widget.targetCourtNumber != null) {
      _viewMode = 'court_map';
    }
    if (widget.targetSport != null && widget.targetSport!.isNotEmpty) {
      _selectedSportFilter = widget.targetSport!;
    }
    if (widget.targetCourtNumber != null) {
      final sportForCourt = courtSport ??
          CourtSportPartition.getSportForCourt(
            venue: widget.venue,
            courtNumber: widget.targetCourtNumber!,
          );
      if (_selectedSportFilter != 'all' &&
          _selectedSportFilter != sportForCourt) {
        _selectedSportFilter = sportForCourt;
      }
    }
    if (widget.targetStartTime != null) {
      final parts = widget.targetStartTime!.split(':');
      if (parts.isNotEmpty) {
        final hour = int.tryParse(parts[0]);
        if (hour != null) {
          if (hour < 12) {
            _selectedShift = 'morning';
          } else if (hour < 17) {
            _selectedShift = 'afternoon';
          } else {
            _selectedShift = 'evening';
          }
        }
        if (parts.length >= 2 && parts[1] == '30') {
          _selectedMinute = ':30';
        } else {
          _selectedMinute = ':00';
        }
      }
    }

    _initSlots();
    VenueSyncService.instance.inactiveCourtsNotifier
        .addListener(_onVenueSyncUpdated);
    VenueSyncService.instance.bookingsNotifier
        .addListener(_onVenueSyncUpdated);
    VenueSyncService.instance.syncWithServer();
    VenueSyncService.instance.startPolling();
    _imagePageController = PageController();
    _galleryImages = [
      ...widget.venue.imageUrls,
      if (widget.venue.imageUrls.length <= 1) ...[
        'https://images.unsplash.com/photo-1544717305-2782549b5136?w=800',
        'https://images.unsplash.com/photo-1599474924187-334a4ae5bd3c?w=800',
        'https://images.unsplash.com/photo-1521537634581-0dced2fed2a8?w=800',
      ],
    ];

    if (widget.targetCourtNumber != null) {
      _triggerCourtHighlightAndSelection(
        widget.targetCourtNumber!,
        widget.targetStartTime,
        endTime: widget.targetEndTime,
      );
    }
  }

  void _onVenueSyncUpdated() {
    if (mounted) {
      setState(() {
        _initSlots();
      });
    }
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _scrollTimer?.cancel();
    _pulseController?.dispose();
    VenueSyncService.instance.inactiveCourtsNotifier
        .removeListener(_onVenueSyncUpdated);
    VenueSyncService.instance.bookingsNotifier
        .removeListener(_onVenueSyncUpdated);
    VenueSyncService.instance.stopPolling();
    _imagePageController.dispose();
    super.dispose();
  }

  void _triggerCourtHighlightAndSelection(
    int courtNumber,
    String? startTime, {
    String? endTime,
    double durationHours = 1.0,
    bool selectSlot = true,
  }) {
    if (mounted) {
      setState(() {
        _highlightedCourtNumber = courtNumber;
      });
    } else {
      _highlightedCourtNumber = courtNumber;
    }

    if (_pulseController == null) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );
    }
    _pulseController!.reset();
    _pulseController!.repeat(reverse: true);

    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _pulseController?.stop();
        setState(() {
          _highlightedCourtNumber = null;
        });
      }
    });

    // Auto-select matching slot & auto-scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (selectSlot) {
        int? parseMinutes(String? t) {
          if (t == null) return null;
          final p = t.trim().split(':');
          if (p.isEmpty) return null;
          final h = int.tryParse(p[0]);
          if (h == null) return null;
          final m = p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0;
          return h * 60 + m;
        }

        final startMin = parseMinutes(startTime);
        final endMin = parseMinutes(endTime) ??
            (startMin != null
                ? startMin + (durationHours * 60).round()
                : null);

        List<TimeSlot> matching = [];
        if (startMin != null && endMin != null && endMin > startMin) {
          matching = _slots.where((s) {
            if (s.courtNumber != courtNumber) return false;
            final sStart = parseMinutes(s.startTime);
            final sEnd = parseMinutes(s.endTime);
            if (sStart == null || sEnd == null) return false;
            return sStart >= startMin && sEnd <= endMin;
          }).toList();
        }

        if (matching.isEmpty) {
          matching = _slots
              .where((s) =>
                  s.courtNumber == courtNumber &&
                  (startTime == null || s.startTime == startTime))
              .toList();
        }

        final availableToSelect =
            matching.where((s) => s.isAvailable).toList();
        if (availableToSelect.isNotEmpty) {
          final bookingBloc = context.read<BookingBloc>();
          final currentState = bookingBloc.state;
          final currentSelectedIds = (currentState is BookingSlotsUpdated)
              ? currentState.selectedSlots.map((s) => s.id).toSet()
              : <String>{};
          final targetIds = availableToSelect.map((s) => s.id).toSet();

          final isSame = currentSelectedIds.length == targetIds.length &&
              currentSelectedIds.containsAll(targetIds);

          if (!isSame) {
            bookingBloc.add(ClearSelectedSlotsEvent());
            for (final slot in availableToSelect) {
              bookingBloc.add(ToggleSlotEvent(slot));
            }
          }
        }
      }

      _scrollTimer?.cancel();
      _scrollTimer = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        final targetKey = _courtKeys[courtNumber];
        if (targetKey?.currentContext != null) {
          Scrollable.ensureVisible(
            targetKey!.currentContext!,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            alignment: 0.2,
          );
        }
      });
    });
  }

  void _focusCourtFromActionCard(Map<String, dynamic> actionCard) {
    Navigator.of(context).pop();

    final courtStr = actionCard['court']?.toString() ?? 'Sân 1';
    final courtNumber =
        int.tryParse(RegExp(r'\d+').firstMatch(courtStr)?.group(0) ?? '1') ?? 1;
    final startTime = actionCard['startTime']?.toString() ??
        actionCard['time']?.toString() ??
        '19:00';
    final endTime = actionCard['endTime']?.toString();
    final durationHours =
        (actionCard['durationHours'] as num?)?.toDouble() ?? 1.0;
    final rawSport = actionCard['sport']?.toString() ?? 'badminton';
    final sport = rawSport.toLowerCase().contains('pickleball')
        ? 'pickleball'
        : (rawSport.toLowerCase().contains('football') ||
                rawSport.toLowerCase().contains('bóng đá')
            ? 'football'
            : 'badminton');

    final parsedAddonCounts = extractAddonCountsFromCard(actionCard);

    final actionVenueId = actionCard['venueId']?.toString();
    if (actionVenueId != null && actionVenueId != widget.venue.id) {
      final targetVenue = SeedData.sampleVenues.firstWhere(
        (v) => v.id == actionVenueId,
        orElse: () => widget.venue,
      );
      if (targetVenue.id != widget.venue.id) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => VenueDetailScreen(
              venue: targetVenue,
              targetCourtNumber: courtNumber,
              targetStartTime: startTime,
              targetEndTime: endTime,
              targetSport: sport,
              initialViewMode: 'court_map',
              initialAddonCounts: parsedAddonCounts,
            ),
          ),
        );
        return;
      }
    }

    final isCardPaid = actionCard['isPaid'] == true ||
        actionCard['isBooked'] == true ||
        (actionCard['bookingId'] != null &&
            TicketStore.instance.tickets
                .any((t) => t.bookingId == actionCard['bookingId']));

    if (isCardPaid) {
      setState(() {
        _viewMode = 'court_map';
        _addonCounts.clear();

        final courtSport = CourtSportPartition.getSportForCourt(
          venue: widget.venue,
          courtNumber: courtNumber,
        );
        if (_selectedSportFilter != 'all' &&
            _selectedSportFilter != courtSport) {
          _selectedSportFilter = courtSport;
        }

        final parts = startTime.split(':');
        if (parts.isNotEmpty) {
          final hour = int.tryParse(parts[0]);
          if (hour != null) {
            if (hour < 12) {
              _selectedShift = 'morning';
            } else if (hour < 17) {
              _selectedShift = 'afternoon';
            } else {
              _selectedShift = 'evening';
            }
          }
          if (parts.length >= 2 && parts[1] == '30') {
            _selectedMinute = ':30';
          } else {
            _selectedMinute = ':00';
          }
        }
        _slots = _getDynamicSlots();
      });

      context.read<BookingBloc>().add(ClearSelectedSlotsEvent());
      _triggerCourtHighlightAndSelection(
        courtNumber,
        startTime,
        endTime: endTime,
        durationHours: durationHours,
        selectSlot: false,
      );

      final displayCourt =
          courtStr.startsWith('Sân') ? courtStr : 'Sân $courtStr';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Vé đặt $displayCourt ($startTime - ${actionCard['endTime'] ?? ''}) đã được thanh toán thành công!'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _viewMode = 'court_map';
      if (parsedAddonCounts.isNotEmpty) {
        _addonCounts.clear();
        _addonCounts.addAll(parsedAddonCounts);
      }

      final courtSport = CourtSportPartition.getSportForCourt(
        venue: widget.venue,
        courtNumber: courtNumber,
      );
      if (_selectedSportFilter != 'all' &&
          _selectedSportFilter != courtSport) {
        _selectedSportFilter = courtSport;
      }

      final parts = startTime.split(':');
      if (parts.isNotEmpty) {
        final hour = int.tryParse(parts[0]);
        if (hour != null) {
          if (hour < 12) {
            _selectedShift = 'morning';
          } else if (hour < 17) {
            _selectedShift = 'afternoon';
          } else {
            _selectedShift = 'evening';
          }
        }
        if (parts.length >= 2 && parts[1] == '30') {
          _selectedMinute = ':30';
        } else {
          _selectedMinute = ':00';
        }
      }
      _slots = _getDynamicSlots();
    });

    _triggerCourtHighlightAndSelection(
      courtNumber,
      startTime,
      endTime: endTime,
      durationHours: durationHours,
    );
  }

  List<TimeSlot> _getDynamicSlots() {
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final generated = ShiftSlotGenerator.generateSlots(
      date: dateStr,
      courtCount: widget.venue.courtCount,
      shift: _selectedShift,
      minuteOffset: _selectedMinute,
      venue: widget.venue,
    );

    return generated.map((slot) {
      final isCourtActive = VenueSyncService.instance.isCourtActive(
        venueId: widget.venue.id,
        courtNumber: slot.courtNumber,
        venueName: widget.venue.name,
      );
      if (!isCourtActive) {
        return slot.copyWith(
          status: SlotStatus.locked,
          lockedBy: 'maintenance',
        );
      }
      final isBooked = VenueSyncService.instance.isSlotBooked(
        venueId: widget.venue.id,
        courtNumber: slot.courtNumber,
        date: dateStr,
        startTime: slot.startTime,
        venueName: widget.venue.name,
      );
      if (isBooked) {
        return slot.copyWith(
          status: SlotStatus.booked,
        );
      }
      return slot;
    }).toList();
  }

  void _initSlots() {
    _slots = _getDynamicSlots();
  }

  double _calculateAddonsTotal() {
    double total = 0;
    for (final entry in _addonCounts.entries) {
      if (entry.value > 0) {
        final item = SeedData.sampleAddons.firstWhere(
          (a) => a.id == entry.key,
          orElse: () => const VenueAddonItem(
            id: '',
            name: '',
            description: '',
            price: 0,
            unit: '',
            category: AddonCategory.gear,
            icon: '',
          ),
        );
        total += item.price * entry.value;
      }
    }
    return total;
  }

  int _calculateAddonsCount() {
    return _addonCounts.values.fold(0, (sum, count) => sum + count);
  }

  bool _isDateMatch(String d1, String d2) {
    if (d1 == d2) return true;
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final n1 = d1.toLowerCase().contains('hôm nay') ? todayStr : d1;
    final n2 = d2.toLowerCase().contains('hôm nay') ? todayStr : d2;
    return n1 == n2;
  }

  String _formatWeekday(DateTime date) {
    const days = ['CN', 'Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7'];
    return days[date.weekday % 7];
  }

  void _showBookingSuccessModal(BuildContext context, TicketModel ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  'Đặt Sân Thành Công! 🎉',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mã vé: ${ticket.bookingId} đã được lưu offline vào máy',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sân đặt:',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${ticket.venueName} (Sân ${ticket.courtNumber})',
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Thời gian:',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${ticket.startTime} - ${ticket.endTime} (${ticket.matchDate})',
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tổng thanh toán:',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          Text(CurrencyFormatter.format(ticket.totalPrice),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                  fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('btn_stay_on_venue_detail'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(bCtx),
                        child: Text(
                          'Ở lại xem sân',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('btn_go_to_tickets'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.qr_code_rounded, size: 18),
                        label: const Text(
                          'Xem vé ngay',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(bCtx);
                          Navigator.of(context).popUntil((route) => route.isFirst);
                          MainNavigationController.switchToTab?.call(2);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showVietQrDialog(
    BuildContext context,
    double grandTotal,
    List<TimeSlot> selectedSlots,
    Map<String, int> addonCounts,
  ) {
    if (AuthStore.instance.isGuest) {
      AuthGuardSheet.show(context, actionName: 'đặt sân');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => VietQrPaymentDialog(
        venue: widget.venue,
        grandTotal: grandTotal,
        selectedSlots: selectedSlots,
        addonCounts: addonCounts,
        onConfirmed: () {
          final newBookingId = 'BK-${DateTime.now().millisecondsSinceEpoch}';
          final firstSlot =
              selectedSlots.isNotEmpty ? selectedSlots.first : null;
          final lastSlot =
              selectedSlots.isNotEmpty ? selectedSlots.last : null;
          final courtNum = firstSlot?.courtNumber ?? 1;
          final startT = firstSlot?.startTime ?? '18:00';
          final endT = lastSlot?.endTime ?? '19:00';
          final venueSport = widget.venue.sportTypes.isNotEmpty
              ? widget.venue.sportTypes.first
              : 'badminton';

          final dateStr =
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

          final currentUser = AuthStore.instance.currentUser;
          final custName = currentUser?.fullName ?? 'Khách đặt qua App';
          final custPhone = currentUser?.phone ?? '0988 123 456';

          final newTicket = TicketModel(
            id: 'ticket_${DateTime.now().millisecondsSinceEpoch}',
            bookingId: newBookingId,
            venueName: widget.venue.name,
            sportType: venueSport,
            courtNumber: courtNum,
            matchDate: dateStr,
            startTime: startT,
            endTime: endT,
            totalPrice: grandTotal,
            qrCodeData: 'SPORTHUB|$newBookingId|${grandTotal.toInt()}',
            status: 'paid',
            createdAt: DateTime.now().toIso8601String(),
            district: widget.venue.district,
          );
          TicketStore.instance.addTicket(newTicket);
          ChatbotService.instance.notifyBookingPaid(newTicket);

          // Sync booking to server & local booked slots for each selected slot
          for (final slot in selectedSlots) {
            VenueSyncService.instance.createBooking(
              bookingId: newBookingId,
              venueId: widget.venue.id,
              courtNumber: slot.courtNumber,
              courtName: 'Sân ${slot.courtNumber}',
              venueName: widget.venue.name,
              sport: venueSport,
              date: dateStr,
              startTime: slot.startTime,
              endTime: slot.endTime,
              totalPrice: grandTotal,
              customerName: custName,
              customerPhone: custPhone,
            );
          }

          NotificationStore.instance.addNotification(
            AppNotification(
              id: 'notif_booking_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Đặt sân thành công! 🎉',
              message:
                  'Bạn đã đặt thành công ${selectedSlots.length} ca tại ${widget.venue.name}. Mã vé: $newBookingId.',
              timestamp: DateTime.now(),
              type: NotificationType.booking,
              role: NotificationRole.player,
              targetId: newBookingId,
            ),
          );
          context.read<BookingBloc>().add(ClearSelectedSlotsEvent());
          setState(() {
            _slots = _slots.map<TimeSlot>((s) {
              if (selectedSlots.any((sel) =>
                  sel.id == s.id ||
                  (sel.courtNumber == s.courtNumber &&
                      sel.startTime == s.startTime))) {
                return s.copyWith(status: SlotStatus.booked);
              }
              return s;
            }).toList();
            _addonCounts.clear();
          });
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  '🎉 Đặt sân thành công! Khung giờ đã được cập nhật.'),
              backgroundColor: AppColors.primary,
            ),
          );
          _showBookingSuccessModal(context, newTicket);
        },
      ),
    );
  }

  Widget _buildPhotoCarousel() {
    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _imagePageController,
            itemCount: _galleryImages.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) {
              return Image.network(
                _galleryImages[index],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.cardBorder,
                  alignment: Alignment.center,
                  child: Icon(Icons.sports_tennis_rounded,
                      size: 48, color: AppColors.primary),
                ),
              );
            },
          ),
          // Gradient bottom scrim
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Indicator badge (e.g. 1/4)
          Positioned(
            right: 14,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${_galleryImages.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // Left arrow button
          if (_currentImageIndex > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton.filled(
                  icon: const Icon(Icons.chevron_left_rounded, size: 22),
                  onPressed: () {
                    _imagePageController.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          // Right arrow button
          if (_currentImageIndex < _galleryImages.length - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton.filled(
                  icon: const Icon(Icons.chevron_right_rounded, size: 22),
                  onPressed: () {
                    _imagePageController.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVenueHeaderAndActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Court count
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.venue.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${widget.venue.courtCount} sân con',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Rating and Address
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                '${widget.venue.rating}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(width: 4),
              Text(
                '(${widget.venue.reviewCount} đánh giá)',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 8),
              Text('•', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.venue.address}, ${widget.venue.district}',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Operating Hours Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: const Text(
              '🟢 Đang mở cửa • 06:00 - 23:00',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 14),

          // Quick Actions: Hotline, Directions, Chat
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.phone_in_talk_rounded,
                  label: 'Gọi hotline',
                  subLabel: '0909 123 456',
                  color: AppColors.primary,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('📞 Đang gọi Hotline: 0909 123 456...')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.directions_rounded,
                  label: 'Chỉ đường',
                  subLabel: widget.venue.district,
                  color: AppColors.secondary,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '🗺️ Mở bản đồ đến: ${widget.venue.address}...')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Nhắn tin CLB',
                  subLabel: 'Phản hồi nhanh',
                  color: Colors.amber,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('💬 Đang mở kênh chat với CLB...')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subLabel,
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    final isFootball = widget.venue.sportTypes.contains('football');
    final amenities = isFootball
        ? const [
            ('🅿️', 'Bãi đỗ xe ô tô & xe máy'),
            ('🚿', 'Phòng tắm nóng lạnh'),
            ('🥤', 'Căng tin giải khát'),
            ('⚽', 'Thuê bóng & áo bib'),
            ('💡', 'Dàn đèn LED cao áp đêm'),
            ('🏆', 'Cỏ nhân tạo FIFA'),
            ('🩹', 'Tủ y tế chấn thương'),
          ]
        : const [
            ('❄️', 'Máy lạnh'),
            ('🅿️', 'Bãi đỗ xe miễn phí'),
            ('🚿', 'Phòng tắm nóng lạnh'),
            ('🥤', 'Căng tin'),
            ('🏸', 'Cho thuê dụng cụ'),
            ('💡', 'Đèn LED chống lóa'),
            ('🏆', 'Thảm chuẩn BWF / USAPA'),
          ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tiện ích sân bãi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: amenities.map((item) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.$1, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingModeTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                selected: _bookingMode == 'flexible',
                label: 'Chế độ đặt theo buổi',
                child: GestureDetector(
                  key: const Key('booking_mode_flexible'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _bookingMode = 'flexible');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    decoration: BoxDecoration(
                      color: _bookingMode == 'flexible'
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.flash_on_rounded,
                            size: 18,
                            color: _bookingMode == 'flexible'
                                ? AppColors.onPrimary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Đặt theo buổi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _bookingMode == 'flexible'
                                  ? AppColors.onPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Semantics(
                button: true,
                selected: _bookingMode == 'fixed',
                label: 'Chế độ đặt lịch cố định theo tháng ưu đãi đến 20%',
                child: GestureDetector(
                  key: const Key('booking_mode_fixed'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _bookingMode = 'fixed');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    decoration: BoxDecoration(
                      color: _bookingMode == 'fixed'
                          ? AppColors.secondary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.all_inclusive_rounded,
                            size: 18,
                            color: _bookingMode == 'fixed'
                                ? Colors.black
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Đặt lịch cố định',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _bookingMode == 'fixed'
                                  ? Colors.black
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: _bookingMode == 'fixed'
                                  ? Colors.black.withValues(alpha: 0.15)
                                  : Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-20%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _bookingMode == 'fixed'
                                    ? Colors.black
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedScheduleSection() {
    final daysCount = _fixedWeekdays.isEmpty ? 1 : _fixedWeekdays.length;
    final totalSessions = daysCount * (_fixedDurationMonths * 4);
    final hourlyRate = widget.venue.hourlyRate > 0 ? widget.venue.hourlyRate : 150000.0;
    // Each fixed session is 2 hours
    final originalTotal = totalSessions * (hourlyRate * 2);
    final discountRate = _fixedDurationMonths == 6
        ? 0.20
        : (_fixedDurationMonths == 3 ? 0.15 : 0.10);
    final discountAmount = originalTotal * discountRate;
    final finalPrice = originalTotal - discountAmount;
    final avgPerSession = totalSessions > 0 ? finalPrice / totalSessions : 0.0;

    final sortedDays = _fixedWeekdays.toList()..sort();
    final fullDayNames = sortedDays
        .map((d) => d == 7 ? 'Chủ nhật' : 'Thứ ${d + 1}')
        .join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner introducing fixed booking
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_repeat_rounded,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đăng ký lịch cố định CLB & Đội',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Giữ sân độc quyền theo tháng, ưu tiên sân trung tâm, hỗ trợ dời lịch linh hoạt khi báo trước 24h.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1. Sport selector (if multi-sport)
          if (widget.venue.sportTypes.length > 1) ...[
            Text(
              'Chọn môn thể thao',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.venue.sportTypes.map((sport) {
                final isSelected = _fixedSport == sport;
                return ChoiceChip(
                  key: Key('fixed_sport_$sport'),
                  selected: isSelected,
                  label: Text(_sportLabel(sport)),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _fixedSport = sport);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // 2. Select recurring weekdays
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lịch tập trong tuần',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$daysCount buổi / tuần',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Quick Presets
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildWeekdayPresetChip('T2 - T4 - T6', {1, 3, 5}),
                const SizedBox(width: 8),
                _buildWeekdayPresetChip('T3 - T5 - T7', {2, 4, 6}),
                const SizedBox(width: 8),
                _buildWeekdayPresetChip('Cuối tuần (T7, CN)', {6, 7}),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Weekday buttons: 1..7 (T2 to CN)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [1, 2, 3, 4, 5, 6, 7].map((day) {
              final isSelected = _fixedWeekdays.contains(day);
              final label = day == 7 ? 'CN' : 'T${day + 1}';
              return GestureDetector(
                key: Key('weekday_btn_$day'),
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      if (_fixedWeekdays.length > 1) {
                        _fixedWeekdays.remove(day);
                      }
                    } else {
                      _fixedWeekdays.add(day);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 3. Time slot selection (2 hours per session)
          Text(
            'Khung giờ cố định (2 giờ / ca)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ('06:00 - 08:00', 'Sáng sớm'),
              ('16:00 - 18:00', 'Chiều tan tầm'),
              ('18:00 - 20:00', 'Giờ vàng ⭐'),
              ('20:00 - 22:00', 'Ca tối muộn'),
            ].map((slot) {
              final isSelected = _fixedTimeSlot == slot.$1;
              return GestureDetector(
                key: Key('fixed_slot_${slot.$1.replaceAll(':', '').replaceAll(' ', '').replaceAll('-', '_')}'),
                onTap: () => setState(() => _fixedTimeSlot = slot.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot.$1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        slot.$2,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 4. Contract duration package
          Text(
            'Thời hạn đăng ký gói',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDurationPackageCard(
                  months: 1,
                  weeksText: '4 tuần',
                  discountText: 'Giảm 10%',
                  tagText: null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDurationPackageCard(
                  months: 3,
                  weeksText: '12 tuần',
                  discountText: 'Giảm 15%',
                  tagText: 'Phổ biến',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDurationPackageCard(
                  months: 6,
                  weeksText: '24 tuần',
                  discountText: 'Giảm 20%',
                  tagText: 'Tiết kiệm nhất',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 5. Contract Summary & Pricing Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Tóm tắt hợp đồng cố định',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Môn thể thao:', _sportLabel(_fixedSport)),
                _buildSummaryRow('Thời hạn hợp đồng:', '$_fixedDurationMonths tháng (${_fixedDurationMonths * 4} tuần)'),
                _buildSummaryRow('Lịch tập:', '$fullDayNames ($daysCount buổi/tuần)'),
                _buildSummaryRow('Khung giờ:', '$_fixedTimeSlot (2h/buổi)'),
                _buildSummaryRow('Tổng số buổi tập:', '$totalSessions buổi'),
                Divider(color: AppColors.cardBorder, height: 20),
                _buildSummaryRow('Giá gốc niêm yết:', CurrencyFormatter.format(originalTotal)),
                _buildSummaryRow(
                  'Ưu đãi gói (${(discountRate * 100).toInt()}%):',
                  '- ${CurrencyFormatter.format(discountAmount)}',
                  valueColor: Colors.green,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng thanh toán:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(finalPrice),
                      key: const Key('fixed_grand_total'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '~ ${CurrencyFormatter.format(avgPerSession)} / buổi tập',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Commitments & Benefits
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _buildBenefitItem('🔒 Giữ sân độc quyền 100%, không bị hủy hay trùng giờ'),
                      const SizedBox(height: 4),
                      _buildBenefitItem('🔄 Miễn phí đổi ca / dời lịch khi báo trước 24 giờ'),
                      const SizedBox(height: 4),
                      _buildBenefitItem('🎁 Ưu tiên chọn sân VIP & tặng 1 thùng nước suối / tháng'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('btn_fixed_checkout'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _handleFixedScheduleCheckout(
                    finalPrice: finalPrice,
                    totalSessions: totalSessions,
                    sortedDays: sortedDays,
                    originalTotal: originalTotal,
                    discountAmount: discountAmount,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2_rounded,
                            color: AppColors.onPrimary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Thanh toán VietQR Lịch Cố Định',
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWeekdayPresetChip(String label, Set<int> days) {
    final isSelected = _fixedWeekdays.length == days.length &&
        _fixedWeekdays.containsAll(days);
    return GestureDetector(
      onTap: () {
        setState(() {
          _fixedWeekdays.clear();
          _fixedWeekdays.addAll(days);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.secondary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDurationPackageCard({
    required int months,
    required String weeksText,
    required String discountText,
    required String? tagText,
  }) {
    final isSelected = _fixedDurationMonths == months;
    return GestureDetector(
      key: Key('fixed_duration_$months'),
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _fixedDurationMonths = months),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$months Tháng',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  weeksText,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    discountText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (tagText != null)
            Positioned(
              top: -8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  tagText,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
          ),
        ),
      ],
    );
  }

  void _handleFixedScheduleCheckout({
    required double finalPrice,
    required int totalSessions,
    required List<int> sortedDays,
    required double originalTotal,
    required double discountAmount,
  }) {
    if (AuthStore.instance.isGuest) {
      AuthGuardSheet.show(context, actionName: 'đặt lịch cố định');
      return;
    }

    final fullDayNames = sortedDays
        .map((d) => d == 7 ? 'Chủ nhật' : 'Thứ ${d + 1}')
        .join(', ');

    final customBreakdown = [
      ('Môn thể thao', _sportLabel(_fixedSport)),
      ('Gói đăng ký', '$_fixedDurationMonths tháng (${_fixedDurationMonths * 4} tuần)'),
      ('Lịch cố định', fullDayNames),
      ('Khung giờ', '$_fixedTimeSlot (2h/buổi)'),
      ('Tổng số buổi', '$totalSessions buổi'),
      ('Giá niêm yết', CurrencyFormatter.format(originalTotal)),
      (
        'Ưu đãi gói (${_fixedDurationMonths == 6 ? 20 : (_fixedDurationMonths == 3 ? 15 : 10)}%)',
        '- ${CurrencyFormatter.format(discountAmount)}'
      ),
    ];

    showDialog(
      context: context,
      builder: (ctx) => VietQrPaymentDialog(
        venue: widget.venue,
        grandTotal: finalPrice,
        selectedSlots: const [],
        addonCounts: const {},
        paymentTitle: 'Thanh Toán Lịch Cố Định',
        customBreakdown: customBreakdown,
        onConfirmed: () {
          final newBookingId =
              'BK-FIXED-${DateTime.now().millisecondsSinceEpoch}';
          final times = _fixedTimeSlot.split(' - ');
          final startT = times.isNotEmpty ? times.first.trim() : '18:00';
          final endT = times.length > 1 ? times[1].trim() : '20:00';

          final newTicket = TicketModel(
            id: 'ticket_fixed_${DateTime.now().millisecondsSinceEpoch}',
            bookingId: newBookingId,
            venueName: widget.venue.name,
            sportType: _fixedSport,
            courtNumber: 1,
            matchDate: 'Cố định: $fullDayNames ($_fixedDurationMonths Tháng)',
            startTime: startT,
            endTime: endT,
            totalPrice: finalPrice,
            qrCodeData: 'SPORTHUB|$newBookingId|${finalPrice.toInt()}',
            status: 'paid',
            createdAt: DateTime.now().toIso8601String(),
            district: widget.venue.district,
          );
          TicketStore.instance.addTicket(newTicket);
          ChatbotService.instance.notifyBookingPaid(newTicket);

          final currentUser = AuthStore.instance.currentUser;
          final custName = currentUser?.fullName ?? 'Khách đặt lịch cố định';
          final custPhone = currentUser?.phone ?? '0988 123 456';

          VenueSyncService.instance.createBooking(
            bookingId: newBookingId,
            venueId: widget.venue.id,
            courtNumber: 1,
            courtName: 'Sân 1 (Lịch cố định)',
            venueName: widget.venue.name,
            sport: _fixedSport,
            date: 'Cố định: $fullDayNames',
            startTime: startT,
            endTime: endT,
            totalPrice: finalPrice,
            customerName: custName,
            customerPhone: custPhone,
          );

          NotificationStore.instance.addNotification(
            AppNotification(
              id: 'notif_fixed_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Đăng ký lịch cố định thành công! 🔄',
              message:
                  'Bạn đã đăng ký lịch cố định $fullDayNames ($_fixedTimeSlot) tại ${widget.venue.name} trong $_fixedDurationMonths tháng ($totalSessions buổi).',
              timestamp: DateTime.now(),
              type: NotificationType.booking,
              role: NotificationRole.player,
              targetId: newBookingId,
            ),
          );

          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '🎉 Đăng ký lịch cố định thành công! Hợp đồng $totalSessions buổi đã được lưu vào vé.'),
              backgroundColor: AppColors.primary,
            ),
          );
          _showBookingSuccessModal(context, newTicket);
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chọn ngày đặt sân',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tháng ${_selectedDate.month}/${_selectedDate.year}',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 84,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableDates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final date = entry.value;
                  final isSelected = date.day == _selectedDate.day &&
                      date.month == _selectedDate.month &&
                      date.year == _selectedDate.year;

                  return Padding(
                    padding: EdgeInsets.only(
                        right: index < _availableDates.length - 1 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                          _slots = _getDynamicSlots();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 60,
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 2),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.secondary
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : AppColors.cardBorder,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              index == 0 ? 'Hôm nay' : _formatWeekday(date),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.black
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.black
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingTiers() {
    final mainSport = widget.venue.sportTypes.isNotEmpty
        ? widget.venue.sportTypes.first
        : 'badminton';
    final regularPrice = ShiftSlotGenerator.calculateSlotPrice(
      sportType: mainSport,
      startTime: '09:00',
      venueBaseRate: widget.venue.hourlyRate,
    ).toInt();
    final peakPrice = ShiftSlotGenerator.calculateSlotPrice(
      sportType: mainSport,
      startTime: '19:00',
      venueBaseRate: widget.venue.hourlyRate,
    ).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bảng giá theo khung giờ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Giờ thường',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Tiết kiệm',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('06:00 - 17:00 (T2 - T6)',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text(
                        '${CurrencyFormatter.format(regularPrice)}/giờ',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Giờ cao điểm',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Giờ vàng',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('17:00 - 23:00 & Cuối tuần',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text(
                        '${CurrencyFormatter.format(peakPrice)}/giờ',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSportPartitionBar() {
    if (widget.venue.sportTypes.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Phân khu môn thể thao:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // All Chip
                _buildSportPartitionChip(
                  sportKey: 'all',
                  label: '🔥 Tất cả (${widget.venue.courtCount})',
                  key: 'venue_sport_filter_all',
                ),
                ...widget.venue.sportTypes.map((sport) {
                  final courts = CourtSportPartition.getCourtsForSport(
                    venue: widget.venue,
                    sportType: sport,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _buildSportPartitionChip(
                      sportKey: sport,
                      label: '${_sportLabel(sport)} (${courts.length})',
                      key: 'venue_sport_filter_$sport',
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportPartitionChip({
    required String sportKey,
    required String label,
    required String key,
  }) {
    final isSelected = _selectedSportFilter == sportKey;
    final Color activeColor = sportKey == 'football'
        ? const Color(0xFF4ADE80)
        : (sportKey == 'pickleball'
            ? const Color(0xFF38BDF8)
            : AppColors.primary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key(key),
        onTap: () {
          if (_selectedSportFilter != sportKey) {
            setState(() => _selectedSportFilter = sportKey);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          key: Key('zone_filter_$sportKey'),
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.18)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.cardBorder,
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? activeColor : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeToggle() {
    final unselectedTextColor =
        AppColors.isDark ? AppColors.textSecondary : const Color(0xFF475569);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              key: const Key('view_mode_matrix'),
              onTap: () {
                if (_viewMode != 'matrix') {
                  setState(() => _viewMode = 'matrix');
                }
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _viewMode == 'matrix'
                      ? AppColors.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: _viewMode == 'matrix'
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5))
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '📊 Bảng chọn giờ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _viewMode == 'matrix'
                        ? FontWeight.bold
                        : FontWeight.w600,
                    color: _viewMode == 'matrix'
                        ? AppColors.primary
                        : unselectedTextColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              key: const Key('view_mode_court_map'),
              onTap: () {
                if (_viewMode != 'court_map') {
                  setState(() => _viewMode = 'court_map');
                }
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _viewMode == 'court_map'
                      ? AppColors.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: _viewMode == 'court_map'
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5))
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '🏟️ Sơ đồ cụm sân 2D',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _viewMode == 'court_map'
                        ? FontWeight.bold
                        : FontWeight.w600,
                    color: _viewMode == 'court_map'
                        ? AppColors.primary
                        : unselectedTextColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftFilters() {
    final shifts = [
      ('morning', '🌅 Sáng (06:00 - 12:00)'),
      ('afternoon', '☀️ Chiều (12:00 - 17:00)'),
      ('evening', '🌙 Tối (17:00 - 23:00)'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: shifts.map((shift) {
          final isSelected = _selectedShift == shift.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: Key('shift_${shift.$1}'),
                onTap: () {
                  if (_selectedShift != shift.$1) {
                    setState(() {
                      _selectedShift = shift.$1;
                      _slots = _getDynamicSlots();
                    });
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : AppColors.cardBorder,
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    shift.$2,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMinuteToggle() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            key: const Key('minute_toggle_00'),
            onTap: () {
              if (_selectedMinute != ':00') {
                setState(() {
                  _selectedMinute = ':00';
                  _slots = _getDynamicSlots();
                });
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _selectedMinute == ':00'
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedMinute == ':00'
                      ? AppColors.primary
                      : AppColors.cardBorder,
                  width: _selectedMinute == ':00' ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '🕒 Giờ chẵn :00',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: _selectedMinute == ':00'
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: _selectedMinute == ':00'
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            key: const Key('minute_toggle_30'),
            onTap: () {
              if (_selectedMinute != ':30') {
                setState(() {
                  _selectedMinute = ':30';
                  _slots = _getDynamicSlots();
                });
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _selectedMinute == ':30'
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedMinute == ':30'
                      ? AppColors.primary
                      : AppColors.cardBorder,
                  width: _selectedMinute == ':30' ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '🕡 Giờ rưỡi :30',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: _selectedMinute == ':30'
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: _selectedMinute == ':30'
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoneHeaderCard(SportZone zone) {
    final Color accentColor;
    final IconData sportIcon;
    final List<Color> gradientColors;

    switch (zone.sportType) {
      case 'football':
        accentColor = AppColors.isDark
            ? const Color(0xFF4ADE80)
            : const Color(0xFF15803D);
        sportIcon = Icons.sports_soccer_rounded;
        gradientColors = AppColors.isDark
            ? [
                const Color(0xFF14532D).withValues(alpha: 0.7),
                const Color(0xFF0F172A).withValues(alpha: 0.85),
              ]
            : [
                const Color(0xFFDCFCE7),
                const Color(0xFFF0FDF4),
              ];
        break;
      case 'pickleball':
        accentColor = AppColors.isDark
            ? const Color(0xFF38BDF8)
            : const Color(0xFF0284C7);
        sportIcon = Icons.sports_tennis_rounded;
        gradientColors = AppColors.isDark
            ? [
                const Color(0xFF075985).withValues(alpha: 0.7),
                const Color(0xFF0F172A).withValues(alpha: 0.85),
              ]
            : [
                const Color(0xFFE0F2FE),
                const Color(0xFFF0F9FF),
              ];
        break;
      case 'badminton':
      default:
        accentColor = AppColors.isDark
            ? AppColors.primary
            : const Color(0xFF047857);
        sportIcon = Icons.sports_tennis_rounded;
        gradientColors = AppColors.isDark
            ? [
                const Color(0xFF064E3B).withValues(alpha: 0.7),
                const Color(0xFF0F172A).withValues(alpha: 0.85),
              ]
            : [
                const Color(0xFFD1FAE5),
                const Color(0xFFECFDF5),
              ];
        break;
    }

    return Container(
      key: Key('zone_header_${zone.sportType}'),
      margin: const EdgeInsets.only(top: 6, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(sportIcon, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  zone.zoneName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  zone.badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            zone.facilityDescription,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppColors.isDark
                      ? AppColors.cardBorder
                      : accentColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sell_rounded, size: 12, color: accentColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Bảng giá ca: ${zone.priceRangeDisplay}/slot',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtCard(int courtNumber, Set<String> selectedIds) {
    final courtKey = _courtKeys.putIfAbsent(courtNumber, () => GlobalKey());
    final isHighlighted = _highlightedCourtNumber == courtNumber;
    final courtSport = CourtSportPartition.getSportForCourt(
      venue: widget.venue,
      courtNumber: courtNumber,
    );
    final isCourtActive = VenueSyncService.instance.isCourtActive(
      venueId: widget.venue.id,
      courtNumber: courtNumber,
      venueName: widget.venue.name,
    );
    final courtSlots =
        _slots.where((s) => s.courtNumber == courtNumber).toList();
    final availableCount = isCourtActive
        ? courtSlots.where((s) => s.status == SlotStatus.available).length
        : 0;

    String priceDisplay = '';
    if (!isCourtActive) {
      priceDisplay = 'Đang bảo trì';
    } else if (courtSlots.isNotEmpty) {
      final prices = courtSlots.map((s) => s.price).toList();
      final minPrice = prices.reduce((a, b) => a < b ? a : b);
      final maxPrice = prices.reduce((a, b) => a > b ? a : b);
      if (minPrice != maxPrice) {
        priceDisplay =
            'Từ ${(minPrice / 1000).toInt()}k - ${(maxPrice / 1000).toInt()}k/slot';
      } else {
        priceDisplay = '${(minPrice / 1000).toInt()}k/slot';
      }
    }

    final String availabilityBadgeText;
    final Color availabilityBadgeBg;
    final Color availabilityBadgeBorder;
    final Color availabilityBadgeTextColor;

    if (!isCourtActive) {
      availabilityBadgeText = '🔒 Tạm dừng hoạt động';
      availabilityBadgeBg = AppColors.isDark
          ? const Color(0xFF451A03).withValues(alpha: 0.5)
          : const Color(0xFFFEF3C7);
      availabilityBadgeBorder = AppColors.isDark
          ? Colors.amber.withValues(alpha: 0.5)
          : const Color(0xFFFCD34D);
      availabilityBadgeTextColor = AppColors.isDark
          ? Colors.amber.shade300
          : const Color(0xFFB45309);
    } else if (availableCount > 0) {
      availabilityBadgeText =
          '🟢 $availableCount / ${courtSlots.length} slot trống';
      availabilityBadgeBg = AppColors.isDark
          ? const Color(0xFF064E3B).withValues(alpha: 0.4)
          : const Color(0xFFDCFCE7);
      availabilityBadgeBorder = AppColors.isDark
          ? AppColors.slotAvailable.withValues(alpha: 0.6)
          : const Color(0xFF86EFAC);
      availabilityBadgeTextColor = AppColors.isDark
          ? AppColors.slotAvailable
          : const Color(0xFF15803D);
    } else {
      availabilityBadgeText = '🔴 Hết chỗ ca này';
      availabilityBadgeBg = AppColors.isDark
          ? const Color(0xFF450A0A).withValues(alpha: 0.4)
          : const Color(0xFFFEE2E2);
      availabilityBadgeBorder = AppColors.isDark
          ? Colors.red.withValues(alpha: 0.4)
          : const Color(0xFFFCA5A5);
      availabilityBadgeTextColor = AppColors.isDark
          ? Colors.red.shade300
          : const Color(0xFFB91C1C);
    }

    Widget buildCardWidget() {
      final pulseVal = isHighlighted && _pulseController != null
          ? _pulseController!.value
          : 0.0;

      return Container(
        key: Key('court_card_$courtNumber'),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: isHighlighted
              ? Border.all(
                  color: AppColors.primary.withValues(
                    alpha: 0.5 + 0.5 * pulseVal,
                  ),
                  width: 2.0,
                )
              : Border.all(color: AppColors.cardBorder),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: 0.2 + 0.3 * pulseVal,
                    ),
                    blurRadius: 8 + 6 * pulseVal,
                    spreadRadius: 1 + 1.5 * pulseVal,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isHighlighted) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  '🎯 Sân AI gợi ý',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            // Visual court header
            VisualCourtHeader(
              courtNumber: courtNumber,
              sportType: courtSport,
              width: double.infinity,
              height: 74,
              isInactive: !isCourtActive,
            ),
          const SizedBox(height: 10),
          // Availability summary bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: availabilityBadgeBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: availabilityBadgeBorder),
                  ),
                  child: Text(
                    availabilityBadgeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: availabilityBadgeTextColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                priceDisplay,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: !isCourtActive
                      ? (AppColors.isDark
                          ? Colors.amber.shade300
                          : const Color(0xFFB45309))
                      : (AppColors.isDark
                          ? AppColors.secondary
                          : const Color(0xFF0284C7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Slot chips for this court
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: courtSlots.map((slot) {
                final isSelected = selectedIds.contains(slot.id);
                final isBooked = slot.status == SlotStatus.booked;
                final isLocked =
                    !isCourtActive || slot.status == SlotStatus.locked;

                TicketModel? myTicket;
                final curDateStr =
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
                for (final t in TicketStore.instance.tickets) {
                  final isVenue = t.venueName.toLowerCase().contains(widget.venue.name.toLowerCase()) ||
                      widget.venue.name.toLowerCase().contains(t.venueName.toLowerCase()) ||
                      (t.venueName.toLowerCase().contains('tao đàn') && widget.venue.name.toLowerCase().contains('tao đàn'));
                  final isCourt = t.courtNumber == slot.courtNumber;
                  final isTime = t.startTime == slot.startTime;
                  final isDate = _isDateMatch(t.matchDate, curDateStr);
                  if (isVenue && isCourt && isTime && isDate) {
                    myTicket = t;
                    break;
                  }
                }
                final isMyBooking = myTicket != null;

                final Color bg;
                final Color border;
                final Color textColor;
                final String statusLabel;
                final Color statusColor;

                if (isSelected) {
                  bg = AppColors.isDark
                      ? const Color(0xFF78350F).withValues(alpha: 0.7)
                      : const Color(0xFFFEF3C7);
                  border = AppColors.slotSelected;
                  textColor = AppColors.isDark
                      ? AppColors.textPrimary
                      : const Color(0xFF92400E);
                  statusLabel = 'Đang chọn';
                  statusColor = AppColors.isDark
                      ? Colors.amber.shade300
                      : const Color(0xFFB45309);
                } else if (isMyBooking) {
                  bg = AppColors.isDark
                      ? const Color(0xFF064E3B).withValues(alpha: 0.5)
                      : const Color(0xFFD1FAE5);
                  border = AppColors.primary;
                  textColor = AppColors.isDark
                      ? const Color(0xFF6EE7B7)
                      : const Color(0xFF047857);
                  statusLabel = 'Vé của bạn';
                  statusColor = AppColors.primary;
                } else if (isLocked) {
                  bg = AppColors.isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                      : const Color(0xFFF1F5F9);
                  border = AppColors.isDark
                      ? Colors.amber.withValues(alpha: 0.3)
                      : const Color(0xFFCBD5E1);
                  textColor = AppColors.isDark
                      ? AppColors.textSecondary.withValues(alpha: 0.6)
                      : const Color(0xFF94A3B8);
                  statusLabel = 'Tạm dừng';
                  statusColor = AppColors.isDark
                      ? Colors.amber.shade300
                      : const Color(0xFFB45309);
                } else if (isBooked) {
                  bg = AppColors.isDark
                      ? const Color(0xFF450A0A).withValues(alpha: 0.3)
                      : const Color(0xFFF1F5F9);
                  border = AppColors.isDark
                      ? Colors.red.withValues(alpha: 0.2)
                      : AppColors.cardBorder;
                  textColor = AppColors.isDark
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : const Color(0xFF94A3B8);
                  statusLabel = 'Đã đặt';
                  statusColor = AppColors.isDark
                      ? Colors.red.shade300
                      : const Color(0xFFDC2626);
                } else {
                  bg = AppColors.isDark
                      ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                      : const Color(0xFFECFDF5);
                  border = AppColors.isDark
                      ? AppColors.slotAvailable
                      : const Color(0xFF10B981);
                  textColor = AppColors.textPrimary;
                  statusLabel = 'Còn trống';
                  statusColor = AppColors.slotAvailable;
                }

                final startHour =
                    int.tryParse(slot.startTime.split(':').first) ?? 12;
                final isPeak = startHour >= 17 && startHour <= 20;
                final isOffPeak = startHour >= 8 && startHour <= 15;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: Key('slot_${slot.id}'),
                      onTap: isMyBooking
                          ? () => _showBookingSuccessModal(context, myTicket!)
                          : (slot.isAvailable
                              ? () => context
                                  .read<BookingBloc>()
                                  .add(ToggleSlotEvent(slot))
                              : null),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: border, width: isSelected ? 1.5 : 1),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${slot.startTime} - ${slot.endTime}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(slot.price / 1000).toInt()}k',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? (AppColors.isDark
                                            ? Colors.amber.shade200
                                            : const Color(0xFFB45309))
                                        : (AppColors.isDark
                                            ? AppColors.secondary
                                            : const Color(0xFF0284C7)),
                                  ),
                                ),
                                if (isPeak) ...[
                                  const SizedBox(width: 3),
                                  Text(
                                    '🔥 Vàng',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.isDark
                                          ? Colors.amber.shade400
                                          : const Color(0xFFB45309),
                                    ),
                                  ),
                                ] else if (isOffPeak) ...[
                                  const SizedBox(width: 3),
                                  Text(
                                    'Ưu đãi',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.isDark
                                          ? AppColors.secondary
                                          : const Color(0xFF0284C7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  if (isHighlighted && _pulseController != null) {
    return KeyedSubtree(
      key: courtKey,
      child: AnimatedBuilder(
        animation: _pulseController!,
        builder: (context, _) => buildCardWidget(),
      ),
    );
  }

  return KeyedSubtree(
    key: courtKey,
    child: buildCardWidget(),
  );
}

  Widget _buildCourtOverviewMap(Set<String> selectedIds) {
    final zones = CourtSportPartition.getZonesForVenue(widget.venue);
    final filteredZones = _selectedSportFilter == 'all'
        ? zones
        : zones.where((z) => z.sportType == _selectedSportFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final zone in filteredZones) ...[
          _buildZoneHeaderCard(zone),
          ...zone.courtNumbers.map((courtNumber) {
            return _buildCourtCard(courtNumber, selectedIds);
          }),
        ],
      ],
    );
  }

  Widget _buildTimeSlotMatrixSection(Set<String> selectedIds) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_view_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chọn khung giờ & sân',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 0. Sport Partition Filter Bar
          _buildSportPartitionBar(),

          // 1. View mode toggle
          _buildViewModeToggle(),

          const SizedBox(height: 10),

          // 2. Shift filter pills
          _buildShiftFilters(),

          const SizedBox(height: 10),

          // 3. Half-hour minute toggle (:00 vs :30)
          _buildMinuteToggle(),

          const SizedBox(height: 10),

          // 4. Info Hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.secondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _viewMode == 'matrix'
                        ? 'Chạm vào ô xanh để chọn slot. Ma trận tự động cập nhật thời gian thực.'
                        : 'Sơ đồ cụm sân trực quan với mặt thảm thi đấu và tình trạng khả dụng.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 5. 2D Matrix Container or 2D Court Overview Map
          if (_viewMode == 'matrix')
            Container(
              height: 360,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Builder(
                builder: (context) {
                  final activeCourts = CourtSportPartition.getCourtsForSport(
                    venue: widget.venue,
                    sportType: _selectedSportFilter,
                  );
                  final displayedSlots = _slots
                      .where((s) => activeCourts.contains(s.courtNumber))
                      .toList();
                  final courtSportMap = {
                    for (int c in activeCourts)
                      c: CourtSportPartition.getSportForCourt(
                          venue: widget.venue, courtNumber: c)
                  };

                  final inactiveCourts = activeCourts
                      .where((c) => !VenueSyncService.instance.isCourtActive(
                            venueId: widget.venue.id,
                            courtNumber: c,
                            venueName: widget.venue.name,
                          ))
                      .toSet();

                  return TimeSlotMatrix(
                    slots: displayedSlots,
                    selectedSlotIds: selectedIds,
                    courtSportMap: courtSportMap,
                    inactiveCourts: inactiveCourts,
                    sportType: _selectedSportFilter != 'all'
                        ? _selectedSportFilter
                        : (widget.venue.sportTypes.isNotEmpty
                            ? widget.venue.sportTypes.first
                            : 'badminton'),
                    onSlotTapped: (slot) {
                      context.read<BookingBloc>().add(ToggleSlotEvent(slot));
                    },
                  );
                },
              ),
            )
          else
            _buildCourtOverviewMap(selectedIds),
        ],
      ),
    );
  }

  Widget _buildAddonSelectorSection() {
    final activeSport = _selectedSportFilter == 'all'
        ? (widget.venue.sportTypes.isNotEmpty
            ? widget.venue.sportTypes.first
            : 'all')
        : _selectedSportFilter;
    final isFootball = activeSport == 'football';
    final filteredAddons = SeedData.sampleAddons.where((addon) {
      if (addon.sportTypes.contains('all')) return true;
      if (_selectedSportFilter != 'all') {
        return addon.sportTypes.contains(_selectedSportFilter);
      }
      return addon.sportTypes.any((st) => widget.venue.sportTypes.contains(st));
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFootball
                    ? Icons.sports_soccer_rounded
                    : Icons.sports_tennis_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dịch vụ & Thuê dụng cụ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isFootball
                ? 'Thuê bóng thi đấu, áo bib, găng tay và nước giải khát giao tận sân'
                : 'Thuê thêm vợt xịn, máy tập và nước giải khát giao tận sân',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          VenueAddonSelector(
            items: filteredAddons,
            selectedCounts: _addonCounts,
            onQuantityChanged: (item, quantity) {
              setState(() {
                if (quantity <= 0) {
                  _addonCounts.remove(item.id);
                } else {
                  _addonCounts[item.id] = quantity;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHouseRulesSection() {
    final isFootball = widget.venue.sportTypes.contains('football');
    final rules = isFootball
        ? const [
            (
              '👟',
              'Quy định giày đá bóng',
              'Bắt buộc đi giày đá bóng đinh TF (sân cỏ nhân tạo). Cấm tuyệt đối đinh sắt SG/FG tránh gây chấn thương.'
            ),
            (
              '⏰',
              'Thời gian nhận sân & bóng',
              'Có mặt trước 10 phút để nhận bóng thi đấu, áo bib chia đội tại quầy ban quản lý.'
            ),
            (
              '❌',
              'Chính sách đổi lịch & mưa bão',
              'Hỗ trợ dời lịch miễn phí trước 4 tiếng, hoặc linh động dời giờ khi trời mưa to ngập sân.'
            ),
            (
              '🚭',
              'Vệ sinh & An toàn',
              'Nghiêm cấm hút thuốc trên mặt cỏ nhân tạo. Bỏ chai nước vào thùng rác sau khi kết thúc trận đấu.'
            ),
          ]
        : const [
            (
              '👟',
              'Quy định trang phục',
              'Bắt buộc đi giày thể thao đế bám sân / non-marking. Nghiêm cấm giày đinh hoặc guốc cao gót làm hỏng thảm đấu.'
            ),
            (
              '⏰',
              'Thời gian nhận sân',
              'Vui lòng có mặt trước giờ chơi 10 phút để xác nhận mã QR và khởi động.'
            ),
            (
              '❌',
              'Chính sách hủy sân',
              'Hủy lịch trước 4 tiếng: Hoàn 100% cọc. Hủy trong vòng 4 tiếng trước giờ đấu phụ thu 50% chi phí.'
            ),
            (
              '🚭',
              'Vệ sinh & An toàn',
              'Không hút thuốc, không xả rác, không mang đồ ăn có mùi dầu mỡ vào khu vực thảm thi đấu.'
            ),
          ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quy định sân & Chính sách',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: rules.map((r) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.$1, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.$2,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              r.$3,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    final reviews = [
      (
        name: 'Nguyễn Tuấn Anh',
        avatar: 'A',
        rating: 5.0,
        time: 'Hôm qua',
        comment:
            'Sân thảm BWF rất êm, độ nảy tốt. Đèn chiếu sáng chống lóa đánh buổi tối cực thích!'
      ),
      (
        name: 'Lê Thu Trang',
        avatar: 'T',
        rating: 5.0,
        time: '3 ngày trước',
        comment:
            'Máy bắn cầu tự động hoạt động rất mượt, dịch vụ thuê vợt Yonex mới keng. Sẽ ủng hộ dài!'
      ),
      (
        name: 'Trần Minh Hoàng',
        avatar: 'H',
        rating: 4.5,
        time: '1 tuần trước',
        comment:
            'Bãi đỗ ô tô và xe máy rộng rãi, có phòng tắm nóng lạnh sạch sẽ. Giá cả hợp lý.'
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đánh giá từ người chơi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 2),
                  Text(
                    '${widget.venue.rating} / 5.0',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: reviews.map((rev) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            rev.avatar,
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rev.name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary),
                          ),
                        ),
                        Text(rev.time,
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(
                        5,
                        (star) => Icon(
                          star < rev.rating.floor()
                              ? Icons.star_rounded
                              : Icons.star_half_rounded,
                          color: Colors.amber,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rev.comment,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(
    BuildContext context,
    double grandTotal,
    double slotsTotal,
    double addonsTotal,
    List<TimeSlot> selectedSlots,
    int totalAddonsCount,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        if (selectedSlots.isNotEmpty)
                          Text(
                            '${selectedSlots.length} slot',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        if (selectedSlots.isNotEmpty && totalAddonsCount > 0)
                          Text(
                            ' • ',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        if (totalAddonsCount > 0)
                          Text(
                            '$totalAddonsCount dịch vụ',
                            style:
                                const TextStyle(fontSize: 12, color: Colors.amber),
                          ),
                      ],
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CurrencyFormatter.format(grandTotal),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showVietQrDialog(
                      context, grandTotal, selectedSlots, _addonCounts),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_2_rounded,
                            color: AppColors.onPrimary, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Thanh toán VietQR',
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingChatBubble(
        currentVenue: widget.venue,
        currentRoute: '/venue-detail',
        selectedDate: _selectedDate,
        onViewCourtMapAction: (actionCard) =>
            _focusCourtFromActionCard(actionCard),
      ),
      appBar: AppBar(
        title: Text(widget.venue.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('🔗 Đã sao chép link chia sẻ sân!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('❤️ Đã thêm sân vào danh sách yêu thích!')),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          final selectedSlots =
              state is BookingSlotsUpdated ? state.selectedSlots : <TimeSlot>[];
          final selectedIds = selectedSlots.map((s) => s.id).toSet();
          final slotsTotal =
              state is BookingSlotsUpdated ? state.totalPrice : 0.0;
          final addonsTotal = _calculateAddonsTotal();
          final grandTotal = slotsTotal + addonsTotal;
          final totalAddonsCount = _calculateAddonsCount();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. PHOTO CAROUSEL
                      _buildPhotoCarousel(),

                      // 2. VENUE INFO & OPERATING STATUS & QUICK ACTIONS
                      _buildVenueHeaderAndActions(),

                      Divider(
                          color: AppColors.cardBorder,
                          height: 28,
                          thickness: 1),

                      // 3. AMENITIES GRID
                      _buildAmenitiesSection(),

                      Divider(
                          color: AppColors.cardBorder,
                          height: 28,
                          thickness: 1),

                      // MODE SELECTOR: Đặt theo buổi (Linh hoạt) vs Đặt lịch cố định (Theo tháng)
                      _buildBookingModeTabs(),

                      const SizedBox(height: 12),

                      if (_bookingMode == 'flexible') ...[
                        // 4. HORIZONTAL DATE PICKER
                        _buildDatePicker(),

                        const SizedBox(height: 16),

                        // 5. PRICING TIER CARDS
                        _buildPricingTiers(),

                        const SizedBox(height: 16),

                        // 6. 2D TIME SLOT MATRIX
                        _buildTimeSlotMatrixSection(selectedIds),

                        Divider(
                            color: AppColors.cardBorder,
                            height: 32,
                            thickness: 1),

                        // 7. ADD-ON SERVICES & RENTALS
                        _buildAddonSelectorSection(),
                      ] else ...[
                        // FIXED SCHEDULE RECURRING BOOKING
                        _buildFixedScheduleSection(),
                      ],

                      Divider(
                          color: AppColors.cardBorder,
                          height: 32,
                          thickness: 1),

                      // 8. HOUSE RULES & CANCELLATION POLICIES
                      _buildHouseRulesSection(),

                      Divider(
                          color: AppColors.cardBorder,
                          height: 32,
                          thickness: 1),

                      // 9. PLAYER REVIEWS & RATINGS
                      _buildReviewsSection(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // 10. STICKY BOTTOM BAR (for flexible booking mode)
              if (_bookingMode == 'flexible' &&
                  (selectedSlots.isNotEmpty || totalAddonsCount > 0))
                _buildStickyBottomBar(
                  context,
                  grandTotal,
                  slotsTotal,
                  addonsTotal,
                  selectedSlots,
                  totalAddonsCount,
                ),
            ],
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 2: GHÉP KÈO THÔNG MINH BẰNG AI
// -------------------------------------------------------------
class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  String _hubMode = 'community'; // 'community' vs 'ai'
  String _selectedSport = 'all';
  String _selectedDistrict = 'all';
  String _postScope = 'all'; // 'all' vs 'my_posts'
  late List<CommunityPost> _communityPosts;

  @override
  void initState() {
    super.initState();
    _communityPosts = List.from(CommunityFeedStore.instance.posts);
    CommunityFeedStore.instance.postsNotifier.addListener(_onPostsChanged);
  }

  @override
  void dispose() {
    CommunityFeedStore.instance.postsNotifier.removeListener(_onPostsChanged);
    super.dispose();
  }

  void _onPostsChanged() {
    if (mounted) {
      setState(() {
        _communityPosts = List.from(CommunityFeedStore.instance.posts);
        _selectedSport = 'all';
      });
    }
  }

  bool _isLoading = false;
  List<MatchRecommendation> _recommendations = [];

  void _runAiMatchmaking() async {
    setState(() => _isLoading = true);

    // Simulate AI inference via Gemini service logic
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _recommendations = [
        const MatchRecommendation(
          postId: 'post_01',
          matchScore: 95,
          compatibilityLevel: 'HIGH',
          matchReason:
              'Cùng trình độ Intermediate, cùng ở Bình Thạnh, khớp khung giờ tối thứ 7!',
        ),
        const MatchRecommendation(
          postId: 'post_02',
          matchScore: 85,
          compatibilityLevel: 'HIGH',
          matchReason: 'Cùng môn Pickleball và gần khu vực Thủ Đức lân cận.',
        ),
        const MatchRecommendation(
          postId: 'post_03',
          matchScore: 80,
          compatibilityLevel: 'HIGH',
          matchReason:
              'Kèo bóng đá mini 5 người tại Sân Nam Sài Gòn (Quận 7) thiếu 3 chân đá giao lưu tối Thứ Tư!',
        ),
      ];
    });
  }

  String _formatCurrency(double amount) {
    final str = amount.toInt().toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '$formatted đ';
  }

  String _sportLabel(String sportType) {
    switch (sportType) {
      case 'badminton':
        return '🏸 Cầu lông';
      case 'pickleball':
        return '🏓 Pickleball';
      case 'football':
        return '⚽ Bóng đá';
      default:
        return sportType;
    }
  }

  void _joinPost(CommunityPost post) {
    if (AuthStore.instance.isGuest) {
      AuthGuardSheet.show(context, actionName: 'tham gia kèo đấu');
      return;
    }

    final updated = post.copyWith(
      currentPlayers: post.currentPlayers + 1,
      isJoined: true,
    );
    setState(() {
      final idx = _communityPosts.indexWhere((p) => p.id == post.id);
      if (idx != -1) {
        _communityPosts[idx] = updated;
      }
    });
    CommunityFeedStore.instance.updatePost(updated);
    _showJoinSuccessDialog(post);
  }

  void _showJoinSuccessDialog(CommunityPost post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tham gia thành công!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn đã đăng ký tham gia kèo "${post.title}". Vui lòng có mặt đúng giờ!',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 14),
            Text(
              'Hotline liên hệ trưởng nhóm / ban tổ chức:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Text(
                    '0909 123 456',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    if (AuthStore.instance.isGuest) {
      AuthGuardSheet.show(context, actionName: 'đăng kèo thể thao');
      return;
    }

    final titleController = TextEditingController();
    final venueController = TextEditingController();
    final timeController = TextEditingController();
    final feeController = TextEditingController();
    final noteController = TextEditingController();
    String selectedSport = 'badminton';
    String selectedDistrict = 'Bình Thạnh';
    int requiredPlayers = 4;
    String? attachedImageUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.cardBorder, width: 1.5),
              left: BorderSide(color: AppColors.cardBorder, width: 1.5),
              right: BorderSide(color: AppColors.cardBorder, width: 1.5),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Đăng bài tuyển người chơi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(modalContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Môn thể thao',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (type, label) in [
                        ('badminton', '🏸 Cầu lông'),
                        ('pickleball', '🏓 Pickleball'),
                        ('football', '⚽ Bóng đá'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label,
                                style: const TextStyle(fontSize: 12)),
                            selected: selectedSport == type,
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.2),
                            onSelected: (selected) {
                              if (selected)
                                setModalState(() => selectedSport = type);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                CommunityImageAttachmentPicker(
                  sportType: selectedSport,
                  selectedImageUrl: attachedImageUrl,
                  onImageChanged: (url) {
                    setModalState(() => attachedImageUrl = url);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Tiêu đề kèo đấu',
                    hintText: 'VD: Tuyển 2 chân đánh đôi tối nay...',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: venueController,
                  decoration: InputDecoration(
                    labelText: 'Tên sân / Địa chỉ',
                    hintText: 'VD: CLB Bình Thạnh Sport...',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedDistrict,
                  dropdownColor: AppColors.surface,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Quận / Khu vực',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    'Bình Thạnh',
                    'Thủ Đức',
                    'Quận 7',
                    'Quận 1',
                    'Tân Bình'
                  ]
                      .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null)
                      setModalState(() => selectedDistrict = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    labelText: 'Thời gian',
                    hintText: 'VD: 19:00 - 21:00',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: requiredPlayers,
                  dropdownColor: AppColors.surface,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Tổng số người',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [2, 4, 6, 8, 10, 12, 14]
                      .map((n) => DropdownMenuItem(
                          value: n,
                          child: Text('$n người',
                              style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => requiredPlayers = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Chi phí (đ/người)',
                    hintText: 'VD: 40000',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú thêm',
                    hintText: 'VD: Trình độ cơ bản - giao lưu vui vẻ...',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final profile = UserProfileStore.instance.profile;
                      final newPost = CommunityPost(
                        id: 'post_${DateTime.now().millisecondsSinceEpoch}',
                        authorId: profile.userId,
                        title: titleController.text.trim().isEmpty
                            ? 'Kèo giao lưu thể thao'
                            : titleController.text.trim(),
                        authorName: profile.fullName,
                        authorAvatar: profile.fullName.isNotEmpty
                            ? profile.fullName[0]
                            : 'QA',
                        sportType: selectedSport,
                        district: selectedDistrict,
                        skillLevel: 'Mọi trình độ',
                        venueName: venueController.text.trim().isEmpty
                            ? 'CLB Thể Thao'
                            : venueController.text.trim(),
                        scheduledTime: timeController.text.trim().isEmpty
                            ? '19:00 - 21:00 Ngày mai'
                            : timeController.text.trim(),
                        requiredPlayers: requiredPlayers,
                        currentPlayers: 1,
                        shareFee: double.tryParse(
                                feeController.text.replaceAll('.', '')) ??
                            40000,
                        note: noteController.text.trim().isEmpty
                            ? 'Kèo giao lưu vui vẻ, chào đón mọi người!'
                            : noteController.text.trim(),
                        isJoined: true,
                        requiresApproval: true,
                        imageUrl: attachedImageUrl,
                      );
                      setState(() {
                        _communityPosts.insert(0, newPost);
                      });
                      CommunityFeedStore.instance.addPost(newPost);
                      Navigator.of(modalContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                '🎉 Đã đăng kèo tuyển thành viên thành công!')),
                      );
                    },
                    child: const Text('Đăng bài tuyển người',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              key: const Key('mode_tab_community'),
              onTap: () => setState(() => _hubMode = 'community'),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: _hubMode == 'community'
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(
                    '🔥 Kèo tuyển thành viên',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _hubMode == 'community'
                          ? Colors.black
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              key: const Key('mode_tab_ai'),
              onTap: () => setState(() => _hubMode = 'ai'),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color:
                      _hubMode == 'ai' ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(
                    '✨ Gợi ý đối thủ AI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _hubMode == 'ai'
                          ? Colors.black
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopePill(
      String scope, String label, String key, int myPostsCount) {
    final isSelected = _postScope == scope;
    return GestureDetector(
      key: Key(key),
      onTap: () => setState(() => _postScope = scope),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (scope == 'my_posts'
                  ? AppColors.accent.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.15))
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (scope == 'my_posts' ? AppColors.accent : AppColors.primary)
                : AppColors.cardBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (scope == 'my_posts' ? AppColors.accent : AppColors.primary)
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _showApprovalBottomSheet(BuildContext context, CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) => Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.cardBorder, width: 1.5),
              left: BorderSide(color: AppColors.cardBorder, width: 1.5),
              right: BorderSide(color: AppColors.cardBorder, width: 1.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Duyệt người tham gia (${post.pendingCount})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(modalContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...post.pendingRequests
                  .where((r) => r.status == 'pending')
                  .map((req) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                AppColors.secondary.withValues(alpha: 0.2),
                            child: Text(
                              req.userName.isNotEmpty ? req.userName[0] : '?',
                              style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(req.userName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                Text(req.userPhone,
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              req.skillLevel,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: Key('reject_${req.id}'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.error),
                                foregroundColor: AppColors.error,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                CommunityFeedStore.instance
                                    .rejectJoinRequest(post.id, req.id);
                                Navigator.of(modalContext).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Đã từ chối yêu cầu của ${req.userName}.')),
                                );
                              },
                              icon: const Icon(Icons.close_rounded, size: 14),
                              label: const Text('Từ chối',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              key: Key('approve_${req.id}'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                CommunityFeedStore.instance
                                    .approveJoinRequest(post.id, req.id);
                                Navigator.of(modalContext).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Đã chấp nhận ${req.userName} vào kèo!')),
                                );
                              },
                              icon: const Icon(Icons.check_rounded, size: 14),
                              label: const Text('Đồng ý',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              if (post.pendingCount == 0)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Không có yêu cầu nào đang chờ duyệt.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityPostCard(CommunityPost post) {
    final progress = post.requiredPlayers > 0
        ? (post.currentPlayers / post.requiredPlayers).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: post.isJoined
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  post.authorAvatar,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '📍 ${post.district} • ${post.skillLevel}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _sportLabel(post.sportType),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              key: Key('post_hero_image_${post.id}'),
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: Image.network(
                  post.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 160,
                      width: double.infinity,
                      color: AppColors.cardBorder.withValues(alpha: 0.2),
                      child: Center(
                        child: Icon(Icons.image_outlined,
                            size: 36, color: AppColors.primary),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    width: double.infinity,
                    color: AppColors.cardBorder.withValues(alpha: 0.2),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_tennis_rounded,
                              size: 36,
                              color: AppColors.primary.withValues(alpha: 0.7)),
                          const SizedBox(height: 6),
                          Text(
                            'Hình ảnh thể thao',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            post.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.stadium_rounded,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  post.venueName,
                  style:
                      TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  post.scheduledTime,
                  style:
                      TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Đã có ${post.currentPlayers}/${post.requiredPlayers} người - ${post.remainingSlots > 0 ? "🔥 Còn thiếu ${post.remainingSlots} slot" : "Đã đủ người"}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: post.remainingSlots > 0
                            ? AppColors.warning
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_formatCurrency(post.shareFee)}/người',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    post.isFull ? AppColors.primary : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          if (post.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppColors.cardBorder.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      post.note,
                      style: TextStyle(
                          fontSize: 10.5, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Host tools OR join button + Social like button
          Builder(builder: (ctx) {
            final currentUserId = UserProfileStore.instance.profile.userId;
            final isHost = post.authorId == currentUserId;

            final likeButton = InkWell(
              key: Key('post_like_button_${post.id}'),
              borderRadius: BorderRadius.circular(20),
              onTap: () => CommunityFeedStore.instance.toggleLike(post.id),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: post.isLiked
                      ? Colors.redAccent.withValues(alpha: 0.12)
                      : AppColors.background.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: post.isLiked
                        ? Colors.redAccent.withValues(alpha: 0.3)
                        : AppColors.cardBorder.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: post.isLiked
                          ? Colors.redAccent
                          : AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${post.likesCount}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: post.isLiked
                            ? Colors.redAccent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );

            if (isHost) {
              // Host view: badge + review/close buttons
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      likeButton,
                      // Host badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('👑', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 4),
                            Text('Kèo của bạn',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (post.pendingCount > 0) ...[
                        Expanded(
                          child: FilledButton.icon(
                            key: Key('review_requests_${post.id}'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () =>
                                _showApprovalBottomSheet(context, post),
                            icon: const Icon(Icons.group_rounded, size: 14),
                            label: Text('Duyệt yêu cầu (${post.pendingCount})',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (!post.isClosed)
                        Expanded(
                          child: OutlinedButton.icon(
                            key: Key('close_post_${post.id}'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.cardBorder),
                              foregroundColor: AppColors.textSecondary,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              CommunityFeedStore.instance.closePost(post.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('🔒 Đã đóng kèo thành công!')),
                              );
                            },
                            icon: const Icon(Icons.lock_rounded, size: 13),
                            label: const Text('Đóng kèo',
                                style: TextStyle(fontSize: 11)),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('🔒 Đã chốt kèo',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 11)),
                        ),
                    ],
                  ),
                ],
              );
            }

            // Non-host view: show join action based on state
            Widget actionWidget;
            if (post.isClosed || post.isFull) {
              actionWidget = Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: const Text('🔒 Đã chốt kèo',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey)),
              );
            } else if (post.hasPendingRequest(currentUserId)) {
              actionWidget = Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.35)),
                ),
                child: const Text('⏳ Đang chờ duyệt',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.accent)),
              );
            } else if (post.hasJoined(currentUserId)) {
              actionWidget = Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: AppColors.primary),
                    SizedBox(width: 5),
                    Text('Đã tham gia ✓',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.primary)),
                  ],
                ),
              );
            } else if (post.requiresApproval) {
              actionWidget = FilledButton.icon(
                key: Key('request_join_${post.id}'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
                onPressed: () {
                  if (AuthStore.instance.isGuest) {
                    AuthGuardSheet.show(context,
                        actionName: 'tham gia kèo đấu');
                    return;
                  }
                  CommunityFeedStore.instance.sendJoinRequest(
                      post.id, UserProfileStore.instance.profile);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('📩 Đã gửi yêu cầu tham gia đến chủ kèo!')),
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 14),
                label: const Text('Gửi yêu cầu',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              );
            } else {
              actionWidget = FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
                onPressed: () => _joinPost(post),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
                label: const Text('Tham gia ngay',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                likeButton,
                actionWidget,
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAiMatchmaker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero AI Banner with Cyber Gradient
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Trợ lý Matchmaker AI',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Phân tích hồ sơ trình độ, môn thể thao yêu thích và vị trí của bạn để tìm bạn đấu cân tài cân sức nhất.',
                style:
                    TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.textPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isLoading ? null : _runAiMatchmaking,
                child: _isLoading
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      )
                    : Text(
                        '✨ Phân tích đối thủ phù hợp',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section Title
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Kèo đấu đề xuất cho bạn',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_recommendations.isEmpty && !_isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.all(36),
              child: Column(
                children: [
                  Icon(Icons.sports_tennis_rounded,
                      size: 54, color: AppColors.cardBorder),
                  SizedBox(height: 12),
                  Text(
                    'Bấm nút phía trên để AI tìm đối thủ phù hợp nhất cho bạn',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

        ..._recommendations.map((rec) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: rec.matchScore >= 80
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: rec.matchScore >= 80
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : AppColors.warning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '🎯 ${rec.matchScore}% Match',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: rec.matchScore >= 80
                                ? AppColors.primary
                                : AppColors.warning,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppColors.secondary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          rec.compatibilityLevel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    rec.matchReason,
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Đã gửi lời mời tham gia kèo đấu!')),
                        );
                      },
                      child: const Text('Gửi lời mời',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = UserProfileStore.instance.profile.userId;
    final filteredPosts = _communityPosts.where((post) {
      final matchSport =
          _selectedSport == 'all' || post.sportType == _selectedSport;
      final matchDistrict =
          _selectedDistrict == 'all' || post.district == _selectedDistrict;
      final matchScope = _postScope == 'all' || post.authorId == currentUserId;
      return matchSport && matchDistrict && matchScope;
    }).toList();
    final myPostsCount =
        _communityPosts.where((p) => p.authorId == currentUserId).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _hubMode == 'community'
              ? 'Cộng Đồng Thể Thao'
              : 'Ghép Kèo Thông Minh AI',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        actions: [
          if (_hubMode == 'community')
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                key: const Key('create_post_header_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showCreatePostDialog(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('+ Đăng kèo',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
        children: [
          _buildModeSelector(),
          const SizedBox(height: 4),
          if (_hubMode == 'community') ...[
            // Filter chips: Sport
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (sportKey, sportLabel) in [
                    ('all', 'Tất cả môn'),
                    ('badminton', '🏸 Cầu lông'),
                    ('pickleball', '🏓 Pickleball'),
                    ('football', '⚽ Bóng đá'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        label: Text(sportLabel),
                        selected: _selectedSport == sportKey,
                        onSelected: (selected) {
                          setState(() =>
                              _selectedSport = selected ? sportKey : 'all');
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedSport == sportKey
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedSport == sportKey
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                        side: BorderSide(
                          color: _selectedSport == sportKey
                              ? AppColors.primary
                              : AppColors.cardBorder,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Scope filter pills: all vs my posts
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildScopePill(
                      'all', '🔥 Tất cả kèo', 'filter_all_posts', myPostsCount),
                  const SizedBox(width: 8),
                  _buildScopePill('my_posts', '👑 Kèo của tôi ($myPostsCount)',
                      'filter_my_posts', myPostsCount),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Section Header

            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kèo tuyển thành viên (${filteredPosts.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Empty state
            if (filteredPosts.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 48, color: AppColors.cardBorder),
                    SizedBox(height: 12),
                    Text(
                      'Chưa có kèo nào phù hợp bộ lọc',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),

            // Post Cards
            for (final post in filteredPosts) _buildCommunityPostCard(post),
          ] else ...[
            _buildAiMatchmaker(),
          ],
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 3: VÉ CỦA TÔI (OFFLINE PASS)
// -------------------------------------------------------------
typedef MyTicketsScreen = TicketsScreen;

class TicketsScreen extends StatefulWidget {
  final List<TicketModel>? tickets;
  final VoidCallback? onNavigateToCommunity;
  final Function(CommunityPost)? onPostCreated;

  const TicketsScreen({
    super.key,
    this.tickets,
    this.onNavigateToCommunity,
    this.onPostCreated,
  });

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  Widget _buildSportBadge(String sportType) {
    switch (sportType.toLowerCase()) {
      case 'football':
      case 'bóng đá':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: Colors.lightBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.lightBlue.withValues(alpha: 0.4)),
          ),
          child: const Text(
            '⚽ BÓNG ĐÁ',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Colors.lightBlue,
            ),
          ),
        );
      case 'pickleball':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: const Text(
            '🏓 PICKLEBALL',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: AppColors.warning,
            ),
          ),
        );
      case 'badminton':
      case 'cầu lông':
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          child: Text(
            '🏸 CẦU LÔNG',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        );
    }
  }

  String _formatCurrency(double amount) {
    final str = amount.toInt().toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '$formatted đ';
  }

  void _navigateToCommunity() {
    if (widget.onNavigateToCommunity != null) {
      widget.onNavigateToCommunity!();
    } else {
      MainNavigationController.switchToTab?.call(1);
    }
  }

  void _openRecruitDialogForTicket(TicketModel ticket) {
    if (AuthStore.instance.isGuest) {
      AuthGuardSheet.show(context, actionName: 'tuyển người chơi');
      return;
    }

    final titleController = TextEditingController(
      text: 'Cần tìm bạn chơi cùng tại ${ticket.venueName}',
    );
    final venueController = TextEditingController(text: ticket.venueName);
    final timeController = TextEditingController(text: ticket.timeSlot);
    final feeController = TextEditingController(text: '40000');
    final noteController = TextEditingController(
      text:
          'Đã có sân tại ${ticket.venueName}, mời bạn cùng tham gia giao lưu!',
    );
    String selectedSport = ticket.sportType;
    String selectedDistrict = ticket.district;
    int requiredPlayers = 2;
    String? attachedImageUrl = ticket.venueImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (modalContext, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.cardBorder, width: 1.5),
              left: BorderSide(color: AppColors.cardBorder, width: 1.5),
              right: BorderSide(color: AppColors.cardBorder, width: 1.5),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Đăng bài tuyển người chơi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(modalContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Môn thể thao',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (type, label) in [
                        ('badminton', '🏸 Cầu lông'),
                        ('pickleball', '🏓 Pickleball'),
                        ('football', '⚽ Bóng đá'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label,
                                style: const TextStyle(fontSize: 12)),
                            selected: selectedSport == type,
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.2),
                            onSelected: (selected) {
                              if (selected)
                                setModalState(() => selectedSport = type);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                CommunityImageAttachmentPicker(
                  sportType: selectedSport,
                  selectedImageUrl: attachedImageUrl,
                  onImageChanged: (url) {
                    setModalState(() => attachedImageUrl = url);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Tiêu đề bài đăng',
                    hintText: 'VD: Cần tìm bạn chơi cùng...',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: venueController,
                  decoration: InputDecoration(
                    labelText: 'Tên sân / Địa chỉ',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedDistrict,
                  dropdownColor: AppColors.surface,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Quận / Khu vực',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    'Bình Thạnh',
                    'Thủ Đức',
                    'Quận 7',
                    'Quận 1',
                    'Tân Bình'
                  ]
                      .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null)
                      setModalState(() => selectedDistrict = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    labelText: 'Thời gian',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: requiredPlayers,
                  dropdownColor: AppColors.surface,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Số người cần tuyển',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [1, 2, 3, 4, 5, 6, 8]
                      .map((n) => DropdownMenuItem(
                          value: n,
                          child: Text('$n người',
                              style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => requiredPlayers = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Chi phí chia sẻ (đ/người)',
                    hintText: 'VD: 40000',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú thêm',
                    hintText: 'VD: Tìm bạn chơi cùng giao lưu vui vẻ...',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final newPost = CommunityPost(
                        id: 'post_${DateTime.now().millisecondsSinceEpoch}',
                        title: titleController.text.trim().isEmpty
                            ? 'Cần tìm bạn chơi cùng tại ${ticket.venueName}'
                            : titleController.text.trim(),
                        authorName: 'Tôi (Bạn)',
                        authorAvatar: 'ME',
                        sportType: selectedSport,
                        district: selectedDistrict,
                        skillLevel: 'Mọi trình độ',
                        venueName: venueController.text.trim().isEmpty
                            ? ticket.venueName
                            : venueController.text.trim(),
                        scheduledTime: timeController.text.trim().isEmpty
                            ? ticket.timeSlot
                            : timeController.text.trim(),
                        requiredPlayers: requiredPlayers + 1,
                        currentPlayers: 1,
                        shareFee: double.tryParse(feeController.text
                                .replaceAll('.', '')
                                .trim()) ??
                            40000,
                        note: noteController.text.trim().isEmpty
                            ? 'Đã có sân tại ${ticket.venueName}, mời bạn cùng tham gia giao lưu!'
                            : noteController.text.trim(),
                        isJoined: true,
                        imageUrl: attachedImageUrl,
                      );
                      CommunityFeedStore.instance.addPost(newPost);
                      widget.onPostCreated?.call(newPost);
                      Navigator.of(modalContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Đã đăng bài tuyển thành viên lên Cộng đồng!'),
                          action: SnackBarAction(
                            key: const Key('snackbar_action_community'),
                            label: 'Xem ngay',
                            textColor: AppColors.primary,
                            onPressed: _navigateToCommunity,
                          ),
                        ),
                      );
                    },
                    child: const Text('Đăng bài ngay',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, TicketModel ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ticket Top Section
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'SPORTHUB PASS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  color: AppColors.secondary,
                                ),
                              ),
                              _buildSportBadge(ticket.sportType),
                              if (ticket.bookingId.startsWith('BK-FIXED'))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.purple.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.purpleAccent
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.all_inclusive_rounded,
                                          color: Colors.purpleAccent, size: 10),
                                      SizedBox(width: 3),
                                      Text(
                                        'LỊCH CỐ ĐỊNH',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purpleAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticket.venueName.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        ticket.status == 'paid' ? '✅ ĐÃ THANH TOÁN' : 'ĐÃ ĐẶT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.bookingId.startsWith('BK-FIXED')
                                ? 'Lịch cố định'
                                : 'Ngày thi đấu',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10),
                          ),
                          const SizedBox(height: 2),
                          Text(ticket.matchDate,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.bookingId.startsWith('BK-FIXED')
                                ? 'Khung giờ cố định'
                                : 'Giờ đá / đánh',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticket.bookingId.startsWith('BK-FIXED')
                                ? '${ticket.startTime} - ${ticket.endTime} (Sân cố định)'
                                : '${ticket.startTime} - ${ticket.endTime} (Sân ${ticket.courtNumber})',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Số tiền',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10)),
                          const SizedBox(height: 2),
                          Text(
                            _formatCurrency(ticket.totalPrice),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Ticket Divider with Cutout Notches
          Row(
            children: [
              Container(
                width: 10,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final dashCount = (constraints.maxWidth / 10).floor();
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        dashCount,
                        (_) => Container(
                          width: 5,
                          height: 1.5,
                          color: AppColors.cardBorder,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: 10,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
            ],
          ),

          // Ticket Bottom Section (QR + ID + Recruit Button)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Column(
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.qr_code_2_rounded,
                            size: 52, color: Colors.black87),
                        const SizedBox(height: 1),
                        Text(
                          'Mã vé: ${ticket.bookingId}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.storage_rounded,
                        size: 11, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Lưu trữ cục bộ SQLite - Quét offline không cần mạng',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: Key('recruit_ticket_${ticket.id}'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.6)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    icon: Icon(Icons.group_add_rounded,
                        size: 16, color: AppColors.primary),
                    label: Text(
                      '📢 Tuyển thêm người chơi',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                    onPressed: () => _openRecruitDialogForTicket(ticket),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: AuthStore.instance.stateNotifier,
      builder: (context, authState, _) {
        if (authState.isGuest) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Vé Đã Đặt (Offline Pass)',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 40,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Yêu cầu đăng nhập',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tính năng lưu vé QR và xuất trình offline chỉ dành cho thành viên đã đăng nhập. Vui lòng đăng nhập để xem các vé đã đặt của bạn.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        key: const Key('tickets_guest_login_button'),
                        onPressed: () => AuthStore.instance.logout(),
                        icon: Icon(Icons.login_rounded,
                            color: AppColors.onPrimary, size: 20),
                        label: Text(
                          '⚡ Đăng nhập để xem vé',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ValueListenableBuilder<List<TicketModel>>(
          valueListenable: TicketStore.instance.ticketsNotifier,
          builder: (context, storeTickets, _) {
            final tickets = widget.tickets ?? storeTickets;
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Vé Đã Đặt (Offline Pass)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                children: [
                  // Offline Banner
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.offline_pin_rounded,
                            color: AppColors.secondary, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vé được lưu trong CSDL SQLite cục bộ, xuất trình không cần 4G/WiFi.',
                            style: TextStyle(
                                color: AppColors.textPrimary, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Render Tickets
                  for (final ticket in tickets) _buildTicketCard(context, ticket),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// -------------------------------------------------------------
// TAB 4: HỒ SƠ CÁ NHÂN & THỂ THAO
// -------------------------------------------------------------
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const List<String> _sports = ['Pickleball', 'Cầu lông', 'Bóng đá'];
  static const List<String> _skillLevels = ['Cơ bản', 'Trung bình', 'Nâng cao'];
  static const List<String> _districts = [
    'Bình Thạnh',
    'Quận 1',
    'Thủ Đức',
    'Quận 7',
    'Tân Bình',
  ];
  static const List<String> _timeSlots = [
    'Buổi tối (18:00 - 21:00)',
    'Buổi sáng (06:00 - 09:00)',
    'Buổi chiều (15:00 - 18:00)',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late String _selectedSport;
  late String _selectedSkill;
  late String _selectedDistrict;
  late String _selectedTime;

  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    final profile = UserProfileStore.instance.profile;
    _currentUserId = profile.userId;
    _nameController = TextEditingController(text: profile.fullName);
    _phoneController = TextEditingController(text: profile.phone);
    _initValues(profile);
    UserProfileStore.instance.profileNotifier.addListener(_onProfileChanged);
  }

  void _initValues(UserProfile profile) {
    _currentUserId = profile.userId;
    _selectedSport = _normalizeSport(profile.preferredSport);
    _selectedSkill = _normalizeSkill(profile.skillLevel);
    _selectedDistrict = _districts.contains(profile.district)
        ? profile.district
        : _districts.first;
    _selectedTime = _timeSlots.contains(profile.playTimePreference)
        ? profile.playTimePreference
        : _timeSlots.first;
  }

  void _onProfileChanged() {
    if (!mounted) return;
    final profile = UserProfileStore.instance.profile;
    if (_currentUserId != profile.userId) {
      _nameController.text = profile.fullName;
      _phoneController.text = profile.phone;
    } else {
      if (!_nameController.text.contains(profile.fullName)) {
        _nameController.text = profile.fullName;
      }
      if (!_phoneController.text.contains(profile.phone)) {
        _phoneController.text = profile.phone;
      }
    }
    setState(() {
      _initValues(profile);
    });
  }

  @override
  void dispose() {
    UserProfileStore.instance.profileNotifier.removeListener(_onProfileChanged);
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizeSport(String sport) {
    final s = sport.toLowerCase();
    if (s.contains('pickleball')) return 'Pickleball';
    if (s.contains('cầu lông') || s.contains('badminton')) return 'Cầu lông';
    if (s.contains('bóng đá') ||
        s.contains('football') ||
        s.contains('soccer')) {
      return 'Bóng đá';
    }
    return _sports.first;
  }

  String _normalizeSkill(String skill) {
    final s = skill.toLowerCase();
    if (s.contains('cơ bản') || s.contains('beginner')) return 'Cơ bản';
    if (s.contains('trung bình') || s.contains('intermediate')) {
      return 'Trung bình';
    }
    if (s.contains('nâng cao') || s.contains('advanced')) return 'Nâng cao';
    return 'Trung bình';
  }

  String _getInitials(String name) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'U';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    UserProfileStore.instance.updateProfile(
      fullName: name.isNotEmpty ? name : null,
      phone: phone.isNotEmpty ? phone : null,
      preferredSport: _selectedSport,
      skillLevel: _selectedSkill,
      district: _selectedDistrict,
      playTimePreference: _selectedTime,
    );
    final updated = UserProfileStore.instance.profile;
    _nameController.text = updated.fullName;
    _phoneController.text = updated.phone;
    ChatbotService.instance.updateContext(
      ChatbotService.instance.currentContext?.copyWith(
            userName: updated.fullName,
            preferredSport: _selectedSport,
          ) ??
          ChatContext(
            userName: updated.fullName,
            preferredSport: _selectedSport,
          ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã cập nhật hồ sơ thành công!',
          style: TextStyle(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xác nhận đăng xuất',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            key: const Key('confirm_logout_button'),
            onPressed: () {
              Navigator.of(ctx).pop();
              AuthStore.instance.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  void _openQuickSwitcher() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đổi tài khoản nhanh',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Chọn tài khoản demo bên dưới để chuyển đổi ngay:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...SeedData.demoUsers.map((user) {
                final isCurrent =
                    AuthStore.instance.currentUser?.userId == user.userId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: isCurrent
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isCurrent
                            ? AppColors.primary
                            : AppColors.cardBorder,
                        width: isCurrent ? 1.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          _getInitials(user.fullName),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        user.fullName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        '${user.phone} • ${user.preferredSport.toUpperCase()} (${user.skillLevel})',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isCurrent
                          ? Icon(Icons.check_circle_rounded,
                              color: AppColors.primary)
                          : Icon(Icons.arrow_forward_ios_rounded,
                              color: AppColors.textSecondary, size: 14),
                      onTap: () {
                        AuthStore.instance.loginWithDemo(user);
                        UserProfileStore.instance.profileNotifier.value = user;
                        _nameController.text = user.fullName;
                        _phoneController.text = user.phone;
                        ChatbotService.instance.updateContext(
                          ChatbotService.instance.currentContext?.copyWith(
                                userName: user.fullName,
                                preferredSport: user.preferredSport,
                              ) ??
                              ChatContext(
                                userName: user.fullName,
                                preferredSport: user.preferredSport,
                              ),
                        );
                        if (user.userId == 'user_owner_01') {
                          VenueOwnerStore.instance.toggleOwnerMode(true);
                        }
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  },
);
}

  Widget _buildGuestHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                  border: Border.all(color: AppColors.cardBorder, width: 2),
                ),
                child: const Center(
                  child: Text(
                    '👤',
                    style: TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khách vãng lai',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chế độ xem trải nghiệm',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        '⚡ Khách vãng lai',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Đăng nhập để đặt sân, tìm đồng đội, quản lý vé offline và lưu thông tin cá nhân của bạn.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              key: const Key('guest_profile_login_button'),
              onPressed: () => AuthStore.instance.logout(),
              icon: Icon(Icons.login_rounded,
                  color: AppColors.onPrimary, size: 20),
              label: Text(
                '⚡ Đăng nhập / Đăng ký ngay',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              key: const Key('profile_quick_switch_button'),
              onPressed: _openQuickSwitcher,
              icon: Icon(Icons.swap_horiz_rounded,
                  color: AppColors.primary, size: 18),
              label: Text(
                '🔄 Chọn tài khoản Demo để thử nghiệm',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeStore.instance.themeModeNotifier,
              builder: (context, _, __) {
                final isDark = ThemeStore.instance.isDarkMode;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
                    key: const Key('profile_theme_toggle'),
                    value: isDark,
                    onChanged: (_) => ThemeStore.instance.toggleTheme(),
                    activeTrackColor: AppColors.primary,
                  ),
                  onTap: () => ThemeStore.instance.toggleTheme(),
                );
              },
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  key: const Key('profile_quick_switch_button'),
                  onPressed: _openQuickSwitcher,
                  icon: Icon(Icons.swap_horiz_rounded,
                      size: 18, color: AppColors.primary),
                  label: Text(
                    '🔄 Đổi tài khoản',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  key: const Key('profile_logout_button'),
                  onPressed: _showLogoutDialog,
                  icon: const Icon(Icons.logout_rounded,
                      size: 18, color: AppColors.error),
                  label: const Text(
                    '🚪 Đăng xuất',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPartnerOwnerBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.warning, Color(0xFFF97316)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_rounded,
                        size: 13, color: Colors.black),
                    SizedBox(width: 4),
                    Text(
                      'SportHub Partner',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dành cho Chủ Sân (SportHub Partner)',
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
          const SizedBox(height: 8),
          Text(
            'Quản lý lịch sân, soát vé check-in và doanh thu thời gian thực',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              key: const Key('switch_to_owner_mode_button'),
              onPressed: () => VenueOwnerStore.instance.toggleOwnerMode(true),
              icon:
                  const Icon(Icons.bolt_rounded, color: Colors.black, size: 18),
              label: const Text(
                '⚡ Chuyển sang Chế độ Chủ Sân',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Hồ sơ cá nhân',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ValueListenableBuilder<AuthState>(
        valueListenable: AuthStore.instance.stateNotifier,
        builder: (context, authState, _) {
          if (authState.isGuest) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              child: Column(
                children: [
                  _buildGuestHeaderCard(),
                  const SizedBox(height: 14),
                  _buildPartnerOwnerBanner(),
                ],
              ),
            );
          }

          return ValueListenableBuilder<UserProfile>(
            valueListenable: UserProfileStore.instance.profileNotifier,
            builder: (context, profile, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(profile),
                    const SizedBox(height: 14),
                    _buildReputationStats(profile),
                    const SizedBox(height: 14),
                    _buildAccountActions(),
                    const SizedBox(height: 14),
                    _buildPartnerOwnerBanner(),
                    const SizedBox(height: 20),
                    Text(
                      'Thông tin cá nhân & Thể thao',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildProfileForm(),
                    const SizedBox(height: 20),
                    _buildActivitySection(profile),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(UserProfile profile) {
    final initials = _getInitials(profile.fullName);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.cardBorder, width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  profile.phone,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final String vipLabel;
                    final Color vipColor;
                    if (profile.matchesPlayed >= 15) {
                      vipLabel = '⭐ Thành viên VIP';
                      vipColor = const Color(0xFFFFD700);
                    } else if (profile.matchesPlayed >= 10) {
                      vipLabel = '🥇 Thành viên Vàng';
                      vipColor = const Color(0xFFFFA500);
                    } else {
                      vipLabel = '🌱 Thành viên Mới';
                      vipColor = Colors.green;
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: vipColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: vipColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        vipLabel,
                        style: TextStyle(
                          color: vipColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReputationStats(UserProfile profile) {
    return Row(
      children: [
        _buildStatCard(
          '${profile.reputationRating.toStringAsFixed(1)} ⭐',
          'Đánh giá uy tín',
          Icons.star_rounded,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          '${profile.matchesPlayed} Trận',
          'Đã chơi',
          Icons.sports_score_rounded,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          '${profile.onTimeRate}%',
          'Đúng giờ',
          Icons.access_time_rounded,
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Họ và tên',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            key: const Key('profile_input_fullname'),
            controller: _nameController,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Nhập họ và tên',
              hintStyle:
                  TextStyle(color: AppColors.textSecondary, fontSize: 14),
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              prefixIcon: Icon(Icons.person_outline_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Số điện thoại',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            key: const Key('profile_input_phone'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Nhập số điện thoại',
              hintStyle:
                  TextStyle(color: AppColors.textSecondary, fontSize: 14),
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              prefixIcon: Icon(Icons.phone_outlined,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Môn thể thao yêu thích',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _sports.map((sport) {
              final isSelected = _selectedSport == sport;
              return ChoiceChip(
                label: Text(
                  sport,
                  style: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.background,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedSport = sport);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Trình độ kỹ năng',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _skillLevels.map((lvl) {
              final isSelected = _selectedSkill == lvl;
              return ChoiceChip(
                label: Text(
                  lvl,
                  style: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.secondary,
                backgroundColor: AppColors.background,
                side: BorderSide(
                  color:
                      isSelected ? AppColors.secondary : AppColors.cardBorder,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedSkill = lvl);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Khu vực / Quận sinh sống',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedDistrict,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              prefixIcon: Icon(Icons.location_on_outlined,
                  color: AppColors.textSecondary, size: 20),
            ),
            items: _districts.map((d) {
              return DropdownMenuItem<String>(
                value: d,
                child: Text(d),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedDistrict = val);
              }
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Khung giờ chơi ưu tiên',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedTime,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              prefixIcon: Icon(Icons.schedule_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
            items: _timeSlots.map((t) {
              return DropdownMenuItem<String>(
                value: t,
                child: Text(t),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedTime = val);
              }
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              key: const Key('profile_save_button'),
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                '💾 Lưu thông tin',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quản lý hoạt động',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<List<CommunityPost>>(
          valueListenable: CommunityFeedStore.instance.postsNotifier,
          builder: (context, posts, _) {
            final myPosts = posts
                .where((p) =>
                    p.authorId == profile.userId ||
                    p.authorName == profile.fullName)
                .toList();
            final pendingCount =
                myPosts.fold<int>(0, (sum, p) => sum + p.pendingCount);

            return _buildActivityCard(
              title: 'Kèo tuyển của tôi',
              subtitle:
                  '${myPosts.length} bài đăng tuyển • $pendingCount yêu cầu chờ duyệt',
              icon: Icons.groups_rounded,
              iconColor: AppColors.secondary,
              onTap: () => MainNavigationController.switchToTab?.call(1),
            );
          },
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<List<TicketModel>>(
          valueListenable: TicketStore.instance.ticketsNotifier,
          builder: (context, tickets, _) {
            final validTickets =
                tickets.where((t) => t.isValid && !t.isExpired).length;
            return _buildActivityCard(
              title: 'Vé đã đặt',
              subtitle: '$validTickets vé khả dụng • Vé QR offline',
              icon: Icons.confirmation_number_rounded,
              iconColor: AppColors.primary,
              onTap: () => MainNavigationController.switchToTab?.call(2),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
