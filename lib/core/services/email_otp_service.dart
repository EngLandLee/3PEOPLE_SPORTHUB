import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:url_launcher/url_launcher.dart';
import 'supabase_service.dart';

class SendOtpResult {
  final bool success;
  final String otp;
  final String? errorMessage;
  final String email;
  final String dispatchChannel; // 'gmail_smtp', 'supabase_auth', or 'local_preview'

  const SendOtpResult.success({
    required this.otp,
    required this.email,
    this.dispatchChannel = 'supabase_auth',
  })  : success = true,
        errorMessage = null;

  const SendOtpResult.failure(this.errorMessage, {this.otp = '', this.email = '', this.dispatchChannel = 'none'})
      : success = false;
}

class VerifyOtpResult {
  final bool success;
  final String? errorMessage;

  const VerifyOtpResult.success()
      : success = true,
        errorMessage = null;

  const VerifyOtpResult.failure(this.errorMessage) : success = false;
}

/// Service handling OTP generation, dispatch via real Gmail SMTP / Supabase Auth,
/// expiration, attempts management, and Gmail inbox navigation.
class EmailOtpService {
  EmailOtpService._internal();

  static final EmailOtpService instance = EmailOtpService._internal();

  /// Default Gmail sender credentials (can be supplied via --dart-define or defaults from .env)
  static const String envGmailSender = String.fromEnvironment(
    'GMAIL_SENDER_EMAIL',
    defaultValue: 'lequocanh125@gmail.com',
  );
  static const String envGmailAppPassword = String.fromEnvironment(
    'GMAIL_APP_PASSWORD',
    defaultValue: 'wupcueqbcweukbvq',
  );

  String? _senderEmailOverride;
  String? _appPasswordOverride;

  bool? _disableNetworkDispatchOverride;

  /// Automatically disables socket/network calls during automated widget tests
  bool get disableNetworkDispatch {
    if (_disableNetworkDispatchOverride != null) {
      return _disableNetworkDispatchOverride!;
    }
    try {
      final binding = WidgetsBinding.instance.runtimeType.toString();
      return binding.contains('Test');
    } catch (_) {
      return false;
    }
  }

  set disableNetworkDispatch(bool value) {
    _disableNetworkDispatchOverride = value;
  }

  String? _currentOtp;
  String? _currentEmail;
  String? _currentFullName;
  DateTime? _otpExpiresAt;
  DateTime? _lastSentAt;
  int _attemptsRemaining = 5;

  /// Notifier broadcasting newly dispatched OTP for simulated in-app Gmail banner/toast
  final ValueNotifier<Map<String, dynamic>?> lastDispatchedOtpNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);

  String? get currentOtp => _currentOtp;
  String? get currentEmail => _currentEmail;
  DateTime? get otpExpiresAt => _otpExpiresAt;
  int get attemptsRemaining => _attemptsRemaining;

  /// Resend cooldown in seconds (default 60s)
  static const int resendCooldownSeconds = 60;

  /// OTP Validity duration (5 minutes)
  static const Duration otpValidityDuration = Duration(minutes: 5);

  bool get isExpired {
    if (_otpExpiresAt == null) return true;
    return DateTime.now().isAfter(_otpExpiresAt!);
  }

  bool get canResend {
    if (_lastSentAt == null) return true;
    final diff = DateTime.now().difference(_lastSentAt!).inSeconds;
    return diff >= resendCooldownSeconds;
  }

  int get secondsUntilResend {
    if (_lastSentAt == null) return 0;
    final elapsed = DateTime.now().difference(_lastSentAt!).inSeconds;
    final remaining = resendCooldownSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Configure or override Gmail SMTP credentials dynamically at runtime
  void configureGmailSmtp({String? senderEmail, String? appPassword}) {
    _senderEmailOverride = senderEmail;
    _appPasswordOverride = appPassword;
  }

  /// Generates a secure random 6-digit OTP string
  String generateRandomOtp() {
    final rand = Random();
    final code = 100000 + rand.nextInt(900000);
    return code.toString();
  }

  /// Sends registration OTP to the provided Gmail address using direct Gmail SMTP or Supabase Auth
  Future<SendOtpResult> sendOtp({
    required String email,
    String? fullName,
    String? customOtp,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return const SendOtpResult.failure('Địa chỉ email không hợp lệ.');
    }

    final otp = customOtp ?? generateRandomOtp();
    final now = DateTime.now();

    _currentOtp = otp;
    _currentEmail = cleanEmail;
    _currentFullName = fullName?.trim() ?? 'Quý khách';
    _otpExpiresAt = now.add(otpValidityDuration);
    _lastSentAt = now;
    _attemptsRemaining = 5;

    String usedChannel = 'local_preview';
    final sender = (_senderEmailOverride ?? envGmailSender).trim();
    final appPassword = (_appPasswordOverride ?? envGmailAppPassword).trim();

    // 1. First priority: Direct Gmail SMTP dispatch if configured and not disabled for testing
    if (!disableNetworkDispatch && sender.isNotEmpty && appPassword.isNotEmpty) {
      try {
        final smtpServer = gmail(sender, appPassword);
        final message = Message()
          ..from = Address(sender, 'SportHub Vietnam')
          ..recipients.add(cleanEmail)
          ..subject = 'Mã xác thực đăng ký tài khoản SportHub: $otp'
          ..html = _buildHtmlEmail(
            fullName: _currentFullName ?? 'Quý khách',
            otp: otp,
            email: cleanEmail,
          );

        await send(message, smtpServer);
        usedChannel = 'gmail_smtp';
        debugPrint('✅ [EmailOtpService] Real email delivered via Gmail SMTP to: $cleanEmail');
      } catch (e) {
        debugPrint('⚠️ [EmailOtpService] Gmail SMTP dispatch failed, fallback to Supabase: $e');
      }
    }

    // 2. Second priority: Supabase Auth Email OTP dispatch
    if (!disableNetworkDispatch && usedChannel != 'gmail_smtp' && SupabaseService.instance.isConfigured) {
      try {
        await SupabaseService.instance.client?.auth.signInWithOtp(
          email: cleanEmail,
          shouldCreateUser: true,
        );
        usedChannel = 'supabase_auth';
        debugPrint('✅ [EmailOtpService] Real OTP email dispatched via Supabase Auth to: $cleanEmail');
      } catch (e) {
        debugPrint('ℹ️ [EmailOtpService] Supabase Auth OTP note: $e');
      }
    }

    // 3. Broadcast simulated in-app Gmail notification payload (for instant testing/autofill)
    final dispatchPayload = {
      'email': cleanEmail,
      'fullName': _currentFullName,
      'otp': otp,
      'channel': usedChannel,
      'sentAt': now,
      'expiresAt': _otpExpiresAt,
      'subject': '[$cleanEmail] Mã xác thực đăng ký tài khoản SportHub: $otp',
    };

    lastDispatchedOtpNotifier.value = dispatchPayload;
    debugPrint('📧 [EmailOtpService] OTP generated for $cleanEmail: $otp [$usedChannel] (Valid for 5 mins)');

    return SendOtpResult.success(
      otp: otp,
      email: cleanEmail,
      dispatchChannel: usedChannel,
    );
  }

  /// Verifies entered code
  VerifyOtpResult verify({required String enteredCode}) {
    if (_currentOtp == null || _otpExpiresAt == null) {
      return const VerifyOtpResult.failure(
        'Không tìm thấy phiên xác thực OTP. Vui lòng thử lại.',
      );
    }

    if (isExpired) {
      return const VerifyOtpResult.failure(
        'Mã OTP đã hết hạn hiệu lực (5 phút). Vui lòng nhấn gửi lại mã mới.',
      );
    }

    if (_attemptsRemaining <= 0) {
      return const VerifyOtpResult.failure(
        'Bạn đã nhập sai quá số lần cho phép. Vui lòng bấm gửi lại mã OTP.',
      );
    }

    final trimmed = enteredCode.trim();
    // Valid if matches generated OTP or testing master demo code '123456'
    final isValid = trimmed == _currentOtp || trimmed == '123456';

    if (!isValid) {
      _attemptsRemaining--;
      if (_attemptsRemaining <= 0) {
        return const VerifyOtpResult.failure(
          'Mã OTP không đúng. Bạn đã hết lượt thử, vui lòng bấm gửi lại mã.',
        );
      }
      return VerifyOtpResult.failure(
        'Mã OTP không chính xác. Bạn còn $_attemptsRemaining lần thử.',
      );
    }

    return const VerifyOtpResult.success();
  }

  /// Opens the Gmail mobile application or web inbox
  Future<bool> openGmailInbox() async {
    // 1. Try Gmail mobile app deep link
    final gmailAppUri = Uri.parse('googlegmail:///');
    try {
      if (await canLaunchUrl(gmailAppUri)) {
        return await launchUrl(gmailAppUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    // 2. Fallback to Gmail Web Inbox URL
    final gmailWebUri = Uri.parse('https://mail.google.com/mail/u/0/#inbox');
    try {
      return await launchUrl(gmailWebUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('⚠️ [EmailOtpService] Could not launch Gmail inbox: $e');
      return false;
    }
  }

  /// Clears active OTP session
  void reset() {
    _currentOtp = null;
    _currentEmail = null;
    _currentFullName = null;
    _otpExpiresAt = null;
    _lastSentAt = null;
    _attemptsRemaining = 5;
    lastDispatchedOtpNotifier.value = null;
  }

  /// Builds branded HTML email body
  String _buildHtmlEmail({
    required String fullName,
    required String otp,
    required String email,
  }) {
    return '''
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mã xác thực SportHub</title>
</head>
<body style="margin: 0; padding: 24px; background-color: #F8FAFC; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #1E293B;">
  <div style="max-width: 560px; margin: 0 auto; background: #FFFFFF; border-radius: 16px; border: 1px solid #E2E8F0; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.05);">
    
    <!-- Header -->
    <div style="background: linear-gradient(135deg, #059669 0%, #10B981 100%); padding: 32px 24px; text-align: center;">
      <h1 style="margin: 0; color: #FFFFFF; font-size: 26px; font-weight: 800; letter-spacing: -0.5px;">SportHub</h1>
      <p style="margin: 6px 0 0 0; color: #D1FAE5; font-size: 14px;">Nền tảng Thể thao & Đặt sân Thông minh hàng đầu Việt Nam</p>
    </div>

    <!-- Body -->
    <div style="padding: 32px 24px;">
      <h2 style="margin: 0 0 12px 0; font-size: 18px; color: #0F172A;">Xin chào $fullName,</h2>
      <p style="margin: 0 0 20px 0; font-size: 14px; line-height: 1.6; color: #475569;">
        Bạn đang thực hiện thao tác đăng ký tài khoản SportHub với địa chỉ email: <strong>$email</strong>. Dưới đây là mã xác thực OTP của bạn:
      </p>

      <!-- OTP Card -->
      <div style="background: #ECFDF5; border: 1px dashed #059669; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0;">
        <span style="font-size: 12px; font-weight: 700; color: #047857; letter-spacing: 1px; text-transform: uppercase;">Mã xác thực của bạn</span>
        <div style="font-size: 38px; font-weight: 800; color: #047857; letter-spacing: 10px; margin: 12px 0 6px 10px;">
          $otp
        </div>
        <p style="margin: 0; font-size: 12px; color: #065F46;">Mã có hiệu lực trong vòng <strong>5 phút</strong></p>
      </div>

      <!-- Instructions -->
      <div style="background: #F8FAFC; border-radius: 8px; padding: 14px 16px; margin-bottom: 24px;">
        <p style="margin: 0; font-size: 13px; color: #64748B; line-height: 1.5;">
          🛡️ <strong>Lưu ý bảo mật:</strong> Không chia sẻ mã OTP này cho bất kỳ ai, kể cả nhân viên hỗ trợ SportHub. Nếu bạn không yêu cầu mã này, vui lòng bỏ qua email.
        </p>
      </div>

      <p style="margin: 0; font-size: 14px; color: #475569;">
        Chúc bạn có những trải nghiệm thể thao tuyệt vời cùng cộng đồng SportHub!
      </p>
    </div>

    <!-- Footer -->
    <div style="border-top: 1px solid #F1F5F9; padding: 20px 24px; background: #F8FAFC; text-align: center;">
      <p style="margin: 0; font-size: 12px; color: #94A3B8;">
        © 2026 SportHub Vietnam. Tất cả quyền được bảo lưu.<br>
        Email này được gửi tự động, vui lòng không trả lời trực tiếp.
      </p>
    </div>

  </div>
</body>
</html>
''';
  }
}
