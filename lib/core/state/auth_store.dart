import 'package:flutter/foundation.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/entities/user_profile.dart';
import '../services/chatbot_service.dart';
import 'notification_store.dart';
import 'ticket_store.dart';
import 'venue_owner_store.dart';
import '../utils/seed_data.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  final UserProfile? user;

  const AuthResult.success([this.user])
      : success = true,
        errorMessage = null;

  const AuthResult.failure(this.errorMessage)
      : success = false,
        user = null;
}

class AuthStore {
  AuthStore._internal() {
    reset();
  }

  static final AuthStore instance = AuthStore._internal();

  late final ValueNotifier<AuthState> stateNotifier = ValueNotifier<AuthState>(
    const AuthState.unauthenticated(),
  );

  final Map<String, String> _credentials = {};
  final Map<String, UserProfile> _registeredUsers = {};

  UserProfile? _pendingProfile;
  String? _pendingPassword;
  String? _pendingOtp;

  AuthState get state => stateNotifier.value;
  UserProfile? get currentUser => state.user;
  bool get isGuest => state.isGuest;
  bool get hasPendingOtp => _pendingProfile != null;
  UserProfile? get pendingProfile => _pendingProfile;
  String? get pendingOtp => _pendingOtp;

  String _normalizePhone(String phone) =>
      phone.replaceAll(RegExp(r'\s+'), '').trim();

  void _clearUserScopedData({UserProfile? user, bool isNewUser = false}) {
    if (isNewUser && user != null) {
      TicketStore.instance.clearAll();
      NotificationStore.instance.loadForUser(user, isNewUser: true);
    } else if (user != null) {
      if (user.userId == 'user_demo_01') {
        TicketStore.instance.reset();
      } else {
        TicketStore.instance.clearAll();
      }
      NotificationStore.instance.loadForUser(user, isNewUser: false);
    } else {
      TicketStore.instance.clearAll();
      NotificationStore.instance.loadForUser(null);
    }
    ChatbotService.instance.resetMessages();
  }

  void reset({bool clearRegistered = false}) {
    final savedRegisteredUsers = Map<String, UserProfile>.from(_registeredUsers);
    final savedCredentials = Map<String, String>.from(_credentials);

    _credentials.clear();
    _registeredUsers.clear();

    for (final demo in SeedData.demoUsers) {
      final normalized = _normalizePhone(demo.phone);
      _registeredUsers[normalized] = demo;
      _credentials[normalized] = '123456';
    }

    if (!clearRegistered) {
      for (final entry in savedRegisteredUsers.entries) {
        if (!_registeredUsers.containsKey(entry.key)) {
          _registeredUsers[entry.key] = entry.value;
          _credentials[entry.key] = savedCredentials[entry.key] ?? '123456';
        }
      }
    }

    _pendingProfile = null;
    _pendingPassword = null;
    _pendingOtp = null;

    stateNotifier.value = const AuthState.unauthenticated();
    _clearUserScopedData(user: null);
  }

  AuthResult login(String identifier, String password) {
    final trimmed = identifier.trim();
    final normalized = _normalizePhone(trimmed);
    final lower = trimmed.toLowerCase();

    UserProfile? user = _registeredUsers[normalized];
    if (user == null) {
      for (final u in _registeredUsers.values) {
        if (u.email.toLowerCase() == lower && lower.isNotEmpty) {
          user = u;
          break;
        }
      }
    }

    if (user == null && lower.isNotEmpty) {
      for (final u in _registeredUsers.values) {
        final emailPrefix = u.email.split('@').first.toLowerCase();
        if (u.userId.toLowerCase() == lower ||
            emailPrefix == lower ||
            (lower == 'admin' && (u.email == 'admin@sporthub.vn' || u.role == 'admin')) ||
            (lower == 'partner' && (u.email == 'partner@taodan.vn' || u.role == 'partner')) ||
            (lower == 'chusan' && (u.email.contains('chusan') || u.role == 'partner'))) {
          user = u;
          break;
        }
      }
    }

    if (user == null) {
      return const AuthResult.failure(
        'Số điện thoại hoặc Email chưa được đăng ký trong hệ thống.',
      );
    }

    final key = _normalizePhone(user.phone);
    final storedPass = _credentials[key];
    final isDemo = SeedData.demoUsers.any(
      (d) => _normalizePhone(d.phone) == key || d.email.toLowerCase() == user!.email.toLowerCase(),
    );
    final isValidPass = storedPass == password ||
        (isDemo && (password == '123456' || password == 'password123' || password == 'admin' || password == 'admin123'));

    if (!isValidPass) {
      return const AuthResult.failure(
        'Mật khẩu không chính xác. Vui lòng thử lại.',
      );
    }

    stateNotifier.value = AuthState.authenticated(user);
    _clearUserScopedData(user: user, isNewUser: false);

    if (user.isOwner) {
      VenueOwnerStore.instance.toggleOwnerMode(true);
    } else {
      VenueOwnerStore.instance.toggleOwnerMode(false);
    }

    return AuthResult.success(user);
  }

  AuthResult stageRegistration({
    required UserProfile profile,
    required String password,
    String? otp,
  }) {
    if (password.length < 6) {
      return const AuthResult.failure(
        'Mật khẩu phải chứa ít nhất 6 ký tự.',
      );
    }

    _pendingProfile = profile;
    _pendingPassword = password;
    _pendingOtp = otp ?? '123456';
    return const AuthResult.success();
  }

  AuthResult verifyOtp(String code) {
    if (_pendingProfile == null || _pendingPassword == null) {
      return const AuthResult.failure(
        'Không có thông tin đăng ký đang chờ xác thực OTP.',
      );
    }

    final trimmed = code.trim();
    final isValid = trimmed == _pendingOtp ||
        trimmed == '123456' ||
        RegExp(r'^\d{6}$').hasMatch(trimmed);

    if (!isValid) {
      return const AuthResult.failure(
        'Mã OTP không hợp lệ. Vui lòng nhập đúng 6 chữ số.',
      );
    }

    final profile = _pendingProfile!;
    final normalized = _normalizePhone(profile.phone);

    _registeredUsers[normalized] = profile;
    _credentials[normalized] = _pendingPassword!;

    _pendingProfile = null;
    _pendingPassword = null;
    _pendingOtp = null;

    stateNotifier.value = AuthState.authenticated(profile);
    _clearUserScopedData(user: profile, isNewUser: true);

    if (profile.isOwner) {
      VenueOwnerStore.instance.toggleOwnerMode(true);
    } else {
      VenueOwnerStore.instance.toggleOwnerMode(false);
    }

    return AuthResult.success(profile);
  }

  void loginWithDemo(UserProfile demoUser) {
    final normalized = _normalizePhone(demoUser.phone);
    _registeredUsers[normalized] = demoUser;
    stateNotifier.value = AuthState.authenticated(demoUser);
    _clearUserScopedData(user: demoUser, isNewUser: false);
  }

  void continueAsGuest() {
    _pendingProfile = null;
    _pendingPassword = null;
    stateNotifier.value = const AuthState.guest();
    _clearUserScopedData(user: null);
  }

  void logout() {
    _pendingProfile = null;
    _pendingPassword = null;
    _pendingOtp = null;
    VenueOwnerStore.instance.toggleOwnerMode(false);
    stateNotifier.value = const AuthState.unauthenticated();
    _clearUserScopedData(user: null);
  }

  void updateCurrentUser(UserProfile updated) {
    final normalized = _normalizePhone(updated.phone);
    _registeredUsers[normalized] = updated;
    if (state.isAuthenticated) {
      stateNotifier.value = AuthState.authenticated(updated);
    }
  }
}
