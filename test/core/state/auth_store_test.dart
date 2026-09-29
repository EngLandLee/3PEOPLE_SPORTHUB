import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/core/utils/seed_data.dart';
import 'package:sporthub/domain/entities/user_profile.dart';
import 'package:sporthub/main.dart';

void main() {
  late AuthStore authStore;

  setUp(() {
    authStore = AuthStore.instance;
    authStore.reset();
  });

  test('initial state is authenticated with default demo user for backward compatibility', () {
    expect(authStore.state.isAuthenticated, isTrue);
    expect(authStore.currentUser?.userId, equals('user_demo_01'));
    expect(authStore.isGuest, isFalse);
    expect(authStore.state.isLoggedIn, isTrue);
  });

  test('logout sets state to unauthenticated', () {
    authStore.logout();
    expect(authStore.state.isAuthenticated, isFalse);
    expect(authStore.currentUser, isNull);
    expect(authStore.isGuest, isFalse);
    expect(authStore.state.isLoggedIn, isFalse);
  });

  test('continueAsGuest sets state to guest', () {
    authStore.continueAsGuest();
    expect(authStore.state.isAuthenticated, isFalse);
    expect(authStore.currentUser, isNull);
    expect(authStore.isGuest, isTrue);
    expect(authStore.state.isLoggedIn, isFalse);
  });

  test('loginWithDemo switches active user', () {
    final minh = SeedData.demoUsers.firstWhere((u) => u.userId == 'user_demo_02');
    authStore.loginWithDemo(minh);
    expect(authStore.state.isAuthenticated, isTrue);
    expect(authStore.currentUser?.userId, equals('user_demo_02'));
    expect(authStore.currentUser?.fullName, equals('Lê Minh'));
  });

  test('login with valid credentials succeeds', () {
    authStore.logout();
    final result = authStore.login('0909 123 456', '123456');
    expect(result.success, isTrue);
    expect(authStore.state.isAuthenticated, isTrue);
  });

  test('login with valid credentials accepting password123 succeeds', () {
    authStore.logout();
    final result = authStore.login('0909 123 456', 'password123');
    expect(result.success, isTrue);
    expect(authStore.state.isAuthenticated, isTrue);
  });

  test('login with normalized phone (without spaces) succeeds', () {
    authStore.logout();
    final result = authStore.login('0909123456', '123456');
    expect(result.success, isTrue);
    expect(authStore.state.isAuthenticated, isTrue);
  });

  test('login with invalid credentials fails with message', () {
    authStore.logout();
    final result = authStore.login('0909 123 456', 'wrongpass');
    expect(result.success, isFalse);
    expect(result.errorMessage, isNotNull);
    expect(authStore.state.isAuthenticated, isFalse);
  });

  test('login with unregistered phone fails with message', () {
    authStore.logout();
    final result = authStore.login('0999 999 999', '123456');
    expect(result.success, isFalse);
    expect(result.errorMessage, isNotNull);
    expect(authStore.state.isAuthenticated, isFalse);
  });

  test('register stages pending profile and verifyOtp completes registration', () {
    authStore.logout();
    const newProfile = UserProfile(
      userId: 'user_new_01',
      fullName: 'Phạm Hoàng',
      phone: '0933 111 222',
      preferredSport: 'football',
      skillLevel: 'Cơ bản',
      district: 'Quận 1',
      playTimePreference: 'Tối',
    );

    final regResult = authStore.stageRegistration(profile: newProfile, password: 'password123');
    expect(regResult.success, isTrue);
    expect(authStore.hasPendingOtp, isTrue);

    final otpResult = authStore.verifyOtp('123456');
    expect(otpResult.success, isTrue);
    expect(authStore.state.isAuthenticated, isTrue);
    expect(authStore.currentUser?.phone, equals('0933 111 222'));
    expect(authStore.currentUser?.matchesPlayed, equals(0));
    expect(authStore.currentUser?.reputationRating, equals(5.0));
    expect(authStore.currentUser?.onTimeRate, equals(100));
    expect(authStore.hasPendingOtp, isFalse);
  });

  test('verifyOtp with invalid OTP fails', () {
    authStore.logout();
    const newProfile = UserProfile(
      userId: 'user_new_02',
      fullName: 'Hoàng Long',
      phone: '0944 333 222',
      preferredSport: 'badminton',
      skillLevel: 'Trung bình',
      district: 'Bình Thạnh',
      playTimePreference: 'Sáng',
    );
    authStore.stageRegistration(profile: newProfile, password: 'password123');

    final otpResult = authStore.verifyOtp('123'); // not 6 digits
    expect(otpResult.success, isFalse);
    expect(otpResult.errorMessage, isNotNull);
    expect(authStore.state.isAuthenticated, isFalse);
  });

  test('verifyOtp without pending registration fails', () {
    authStore.logout();
    final otpResult = authStore.verifyOtp('123456');
    expect(otpResult.success, isFalse);
    expect(otpResult.errorMessage, isNotNull);
  });

  test('UserProfileStore synchronizes with AuthStore', () {
    final minh = SeedData.demoUsers.firstWhere((u) => u.userId == 'user_demo_02');
    authStore.loginWithDemo(minh);
    expect(UserProfileStore.instance.profile.userId, equals('user_demo_02'));
    expect(UserProfileStore.instance.profile.fullName, equals('Lê Minh'));

    authStore.logout();
    // In logout/guest mode, UserProfileStore provides default profile fallback
    expect(UserProfileStore.instance.profile.userId, equals('user_demo_01'));
  });
}
