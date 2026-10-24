import 'package:flutter/foundation.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/entities/user_profile.dart';
import '../services/chatbot_service.dart';
import 'ticket_store.dart';
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
    AuthState.authenticated(SeedData.demoUsers.first),
  );

  final Map<String, String> _credentials = {};
  final Map<String, UserProfile> _registeredUsers = {};

  UserProfile? _pendingProfile;
  String? _pendingPassword;

  AuthState get state => stateNotifier.value;
  UserProfile? get currentUser => state.user;
  bool get isGuest => state.isGuest;
  bool get hasPendingOtp => _pendingProfile != null;
  UserProfile? get pendingProfile => _pendingProfile;

  String _normalizePhone(String phone) =>
      phone.replaceAll(RegExp(r'\s+'), '').trim();

  void _clearUserScopedData() {
    // TicketStore is currently local-only and has no server-backed owner
    // filter. Reset it on identity changes so the next user cannot inherit
    // the previous user's tickets or payment context.
    TicketStore.instance.reset();
    ChatbotService.instance.resetMessages();
  }

  void reset() {
    _credentials.clear();
    _registeredUsers.clear();

    for (final demo in SeedData.demoUsers) {
      final normalized = _normalizePhone(demo.phone);
      _registeredUsers[normalized] = demo;
      _credentials[normalized] = '123456';
    }

    _pendingProfile = null;
    _pendingPassword = null;

    final defaultDemo = SeedData.demoUsers.first;
    stateNotifier.value = AuthState.authenticated(defaultDemo);
  }

  AuthResult login(String phone, String password) {
    final normalized = _normalizePhone(phone);
    final user = _registeredUsers[normalized];

    if (user == null) {
      return const AuthResult.failure(
        'Số điện thoại chưa được đăng ký trong hệ thống.',
      );
    }

    final storedPass = _credentials[normalized];
    final isDemo = SeedData.demoUsers.any(
      (d) => _normalizePhone(d.phone) == normalized,
    );
    final isValidPass = storedPass == password ||
        (isDemo && (password == '123456' || password == 'password123'));

    if (!isValidPass) {
      return const AuthResult.failure(
        'Mật khẩu không chính xác. Vui lòng thử lại.',
      );
    }

    stateNotifier.value = AuthState.authenticated(user);
    _clearUserScopedData();
    return AuthResult.success(user);
  }

  AuthResult stageRegistration({
    required UserProfile profile,
    required String password,
  }) {
    if (password.length < 6) {
      return const AuthResult.failure(
        'Mật khẩu phải chứa ít nhất 6 ký tự.',
      );
    }

    _pendingProfile = profile;
    _pendingPassword = password;
    return const AuthResult.success();
  }

  AuthResult verifyOtp(String code) {
    if (_pendingProfile == null || _pendingPassword == null) {
      return const AuthResult.failure(
        'Không có thông tin đăng ký đang chờ xác thực OTP.',
      );
    }

    final trimmed = code.trim();
    final isValid = trimmed == '123456' || RegExp(r'^\d{6}$').hasMatch(trimmed);

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

    stateNotifier.value = AuthState.authenticated(profile);
    _clearUserScopedData();
    return AuthResult.success(profile);
  }

  void loginWithDemo(UserProfile demoUser) {
    final normalized = _normalizePhone(demoUser.phone);
    _registeredUsers[normalized] = demoUser;
    stateNotifier.value = AuthState.authenticated(demoUser);
    _clearUserScopedData();
  }

  void continueAsGuest() {
    _pendingProfile = null;
    _pendingPassword = null;
    stateNotifier.value = AuthState.guest();
    _clearUserScopedData();
  }

  void logout() {
    _pendingProfile = null;
    _pendingPassword = null;
    stateNotifier.value = AuthState.unauthenticated();
    _clearUserScopedData();
  }

  void updateCurrentUser(UserProfile updated) {
    final normalized = _normalizePhone(updated.phone);
    _registeredUsers[normalized] = updated;
    if (state.isAuthenticated) {
      stateNotifier.value = AuthState.authenticated(updated);
    }
  }
}
