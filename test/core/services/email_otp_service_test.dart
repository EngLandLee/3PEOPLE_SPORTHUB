import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/services/email_otp_service.dart';

void main() {
  late EmailOtpService otpService;

  setUp(() {
    otpService = EmailOtpService.instance;
    otpService.reset();
    otpService.disableNetworkDispatch = true;
  });

  test('default Gmail SMTP credentials are configured', () {
    expect(EmailOtpService.envGmailSender, equals('lequocanh125@gmail.com'));
    expect(EmailOtpService.envGmailAppPassword, equals('wupcueqbcweukbvq'));
  });

  test('generateRandomOtp returns valid 6-digit numeric string', () {
    final code = otpService.generateRandomOtp();
    expect(code.length, equals(6));
    expect(RegExp(r'^\d{6}$').hasMatch(code), isTrue);
  });

  test('sendOtp with invalid email fails', () async {
    final result = await otpService.sendOtp(email: 'invalid-email');
    expect(result.success, isFalse);
    expect(result.errorMessage, isNotNull);
  });

  test('sendOtp generates dynamic OTP and broadcasts notification payload', () async {
    final result = await otpService.sendOtp(
      email: 'testuser@gmail.com',
      fullName: 'Nguyễn Văn Test',
    );

    expect(result.success, isTrue);
    expect(result.otp.length, equals(6));
    expect(otpService.currentOtp, equals(result.otp));
    expect(otpService.currentEmail, equals('testuser@gmail.com'));
    expect(otpService.isExpired, isFalse);
    expect(otpService.attemptsRemaining, equals(5));

    final payload = otpService.lastDispatchedOtpNotifier.value;
    expect(payload, isNotNull);
    expect(payload?['otp'], equals(result.otp));
    expect(payload?['email'], equals('testuser@gmail.com'));
    expect(payload?['subject'], contains(result.otp));
  });

  test('verify with matching OTP succeeds', () async {
    final sendResult = await otpService.sendOtp(
      email: 'testuser@gmail.com',
      customOtp: '849201',
    );
    expect(sendResult.success, isTrue);

    final verifyResult = otpService.verify(enteredCode: '849201');
    expect(verifyResult.success, isTrue);
    expect(verifyResult.errorMessage, isNull);
  });

  test('verify with master demo code 123456 succeeds', () async {
    await otpService.sendOtp(
      email: 'testuser@gmail.com',
      customOtp: '998877',
    );

    final verifyResult = otpService.verify(enteredCode: '123456');
    expect(verifyResult.success, isTrue);
  });

  test('verify with wrong code decrements attempts and fails', () async {
    await otpService.sendOtp(
      email: 'testuser@gmail.com',
      customOtp: '849201',
    );

    final wrong1 = otpService.verify(enteredCode: '111111');
    expect(wrong1.success, isFalse);
    expect(wrong1.errorMessage, contains('4 lần thử'));
    expect(otpService.attemptsRemaining, equals(4));

    // Exhaust attempts
    otpService.verify(enteredCode: '111111');
    otpService.verify(enteredCode: '111111');
    otpService.verify(enteredCode: '111111');
    final lastWrong = otpService.verify(enteredCode: '111111');
    expect(lastWrong.success, isFalse);
    expect(lastWrong.errorMessage, contains('hết lượt'));
  });

  test('canResend reflects 60-second cooldown', () async {
    expect(otpService.canResend, isTrue);

    await otpService.sendOtp(email: 'testuser@gmail.com');
    expect(otpService.canResend, isFalse);
    expect(otpService.secondsUntilResend, inInclusiveRange(58, 60));
  });

  test('reset clears active OTP and state', () async {
    await otpService.sendOtp(email: 'testuser@gmail.com');
    expect(otpService.currentOtp, isNotNull);

    otpService.reset();
    expect(otpService.currentOtp, isNull);
    expect(otpService.currentEmail, isNull);
    expect(otpService.otpExpiresAt, isNull);
    expect(otpService.lastDispatchedOtpNotifier.value, isNull);
  });
}
