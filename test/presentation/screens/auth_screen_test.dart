import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/state/auth_store.dart';
import 'package:sporthub/presentation/screens/auth_screen.dart';

void main() {
  setUp(() {
    AuthStore.instance.reset();
    AuthStore.instance.logout();
  });

  testWidgets('AuthScreen displays login tab and allows quick demo login', (tester) async {
    bool callbackFired = false;
    await tester.pumpWidget(MaterialApp(
      home: AuthScreen(onAuthSuccess: () => callbackFired = true),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth_tab_login')), findsOneWidget);
    expect(find.byKey(const Key('login_phone_input')), findsOneWidget);
    expect(find.byKey(const Key('quick_login_user_demo_01')), findsOneWidget);

    // Tap quick login An
    await tester.tap(find.byKey(const Key('quick_login_user_demo_01')));
    await tester.pumpAndSettle();

    expect(AuthStore.instance.state.isAuthenticated, isTrue);
    expect(AuthStore.instance.currentUser?.fullName, equals('Nguyễn Văn An'));
    expect(callbackFired, isTrue);
  });

  testWidgets('AuthScreen allows quick demo login for Minh and Linh', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quick_login_user_demo_02')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('quick_login_user_demo_02')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick_login_user_demo_02')));
    await tester.pumpAndSettle();

    expect(AuthStore.instance.state.isAuthenticated, isTrue);
    expect(AuthStore.instance.currentUser?.fullName, equals('Lê Minh'));

    // Switch to Linh
    await tester.ensureVisible(find.byKey(const Key('quick_login_user_demo_03')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick_login_user_demo_03')));
    await tester.pumpAndSettle();

    expect(AuthStore.instance.currentUser?.fullName, equals('Trần Thuỳ Linh'));
  });

  testWidgets('AuthScreen performs manual login with credentials and handles error', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pumpAndSettle();

    // Try empty login
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login_error_text')), findsOneWidget);

    // Try invalid login
    await tester.enterText(find.byKey(const Key('login_phone_input')), '0900000000');
    await tester.enterText(find.byKey(const Key('login_password_input')), 'wrongpass');
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_error_text')), findsOneWidget);
    expect(AuthStore.instance.state.isAuthenticated, isFalse);

    // Enter correct credentials for An
    await tester.enterText(find.byKey(const Key('login_phone_input')), '0909 123 456');
    await tester.enterText(find.byKey(const Key('login_password_input')), '123456');
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_error_text')), findsNothing);
    expect(AuthStore.instance.state.isAuthenticated, isTrue);
    expect(AuthStore.instance.currentUser?.fullName, equals('Nguyễn Văn An'));
  });

  testWidgets('AuthScreen toggles password visibility', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pumpAndSettle();

    final toggleBtn = find.byKey(const Key('toggle_password_visibility'));
    expect(toggleBtn, findsOneWidget);

    // Password field should initially be obscured
    TextField pwField = tester.widget(find.byKey(const Key('login_password_input')));
    expect(pwField.obscureText, isTrue);

    // Tap toggle
    await tester.tap(toggleBtn);
    await tester.pumpAndSettle();

    pwField = tester.widget(find.byKey(const Key('login_password_input')));
    expect(pwField.obscureText, isFalse);
  });

  testWidgets('AuthScreen validates register fields before staging', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.pumpAndSettle();

    // Switch to Register tab
    await tester.tap(find.byKey(const Key('auth_tab_register')));
    await tester.pumpAndSettle();

    // Empty tap
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('register_error_text')), findsOneWidget);

    // Password too short (< 6 chars)
    await tester.enterText(find.byKey(const Key('register_name_input')), 'Lê Hoàng');
    await tester.enterText(find.byKey(const Key('register_phone_input')), '0912345678');
    await tester.enterText(find.byKey(const Key('register_password_input')), '123');
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('register_error_text')), findsOneWidget);
  });

  testWidgets('AuthScreen allows switching to register tab, entering info and verifying OTP', (tester) async {
    bool callbackFired = false;
    await tester.pumpWidget(MaterialApp(
      home: AuthScreen(onAuthSuccess: () => callbackFired = true),
    ));
    await tester.pumpAndSettle();

    // Switch to Register tab
    await tester.tap(find.byKey(const Key('auth_tab_register')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('register_name_input')), findsOneWidget);
    expect(find.byKey(const Key('register_sport_chips')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('register_name_input')), 'Trần Nam');
    await tester.enterText(find.byKey(const Key('register_phone_input')), '0988 777 666');
    await tester.enterText(find.byKey(const Key('register_password_input')), '123456');
    await tester.pumpAndSettle();

    // Tap continue to OTP
    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();

    // OTP bottom sheet should appear
    expect(find.byKey(const Key('otp_input_field')), findsOneWidget);

    // Try invalid OTP code
    await tester.enterText(find.byKey(const Key('otp_input_field')), '000');
    await tester.tap(find.byKey(const Key('otp_confirm_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('otp_error_text')), findsOneWidget);

    // Auto-fill OTP
    await tester.tap(find.byKey(const Key('otp_autofill_button')));
    await tester.pumpAndSettle();

    // Confirm OTP
    await tester.tap(find.byKey(const Key('otp_confirm_button')));
    await tester.pumpAndSettle();

    expect(AuthStore.instance.state.isAuthenticated, isTrue);
    expect(AuthStore.instance.currentUser?.fullName, equals('Trần Nam'));
    expect(AuthStore.instance.currentUser?.matchesPlayed, equals(0));
    expect(AuthStore.instance.currentUser?.reputationRating, equals(5.0));
    expect(AuthStore.instance.currentUser?.onTimeRate, equals(100));
    expect(callbackFired, isTrue);
  });

  testWidgets('AuthScreen allows continuing as guest', (tester) async {
    bool callbackFired = false;
    await tester.pumpWidget(MaterialApp(
      home: AuthScreen(onAuthSuccess: () => callbackFired = true),
    ));
    await tester.pumpAndSettle();

    final guestBtn = find.byKey(const Key('continue_as_guest_button'));
    expect(guestBtn, findsOneWidget);
    await tester.tap(guestBtn);
    await tester.pumpAndSettle();

    expect(AuthStore.instance.isGuest, isTrue);
    expect(callbackFired, isTrue);
  });
}
