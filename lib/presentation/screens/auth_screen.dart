import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/auth_store.dart';
import '../../domain/entities/user_profile.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const AuthScreen({
    super.key,
    this.onAuthSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoginTab = true;

  // Login Controllers
  final TextEditingController _loginPhoneController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();
  bool _obscureLoginPassword = true;
  String? _loginError;

  // Register Controllers
  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPhoneController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  bool _obscureRegPassword = true;
  String _selectedRole = 'player';
  String _selectedSport = 'pickleball';
  String? _registerError;

  @override
  void dispose() {
    _loginPhoneController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final identifier = _loginPhoneController.text.trim();
    final password = _loginPasswordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() {
        _loginError = 'Vui lòng nhập số điện thoại/email và mật khẩu.';
      });
      return;
    }

    final result = AuthStore.instance.login(identifier, password);
    if (!result.success) {
      setState(() {
        _loginError = result.errorMessage ?? 'Đăng nhập không thành công.';
      });
    } else {
      setState(() {
        _loginError = null;
      });
      widget.onAuthSuccess?.call();
    }
  }

  void _handleRegister() {
    final name = _regNameController.text.trim();
    final email = _regEmailController.text.trim();
    final phone = _regPhoneController.text.trim();
    final password = _regPasswordController.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      setState(() {
        _registerError =
            'Vui lòng điền đầy đủ họ tên, email, SĐT và mật khẩu.';
      });
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _registerError =
            'Vui lòng nhập địa chỉ email hợp lệ (ví dụ: yourname@gmail.com).';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _registerError = 'Mật khẩu phải chứa ít nhất 6 ký tự.';
      });
      return;
    }

    final profile = UserProfile(
      userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
      fullName: name,
      email: email,
      phone: phone,
      role: _selectedRole,
      preferredSport: _selectedSport,
      skillLevel: 'Beginner',
      district: 'Bình Thạnh',
      playTimePreference: 'Buổi tối (18:00 - 21:00)',
      matchesPlayed: 0,
      reputationRating: 5.0,
      onTimeRate: 100,
    );

    final result = AuthStore.instance.stageRegistration(
      profile: profile,
      password: password,
      otp: '123456',
    );

    if (!result.success) {
      setState(() {
        _registerError = result.errorMessage;
      });
    } else {
      setState(() {
        _registerError = null;
      });
      _showOtpModal(context, email, phone);
    }
  }

  void _showOtpModal(BuildContext context, String email, String phone) {
    final TextEditingController otpController = TextEditingController();
    String? otpError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 20,
                right: 20,
                top: 14,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Xác thực mã OTP qua Gmail',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mã OTP 6 số đã được gửi đến hộp thư Gmail:\n$email\n(Mã xác nhận thử nghiệm: 123456)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: TextField(
                      key: const Key('otp_input_field'),
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: AppColors.primary,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        hintText: '000000',
                        hintStyle: TextStyle(
                          fontSize: 22,
                          letterSpacing: 8,
                          color: Colors.white24,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (otpError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      otpError!,
                      key: const Key('otp_error_text'),
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const Key('otp_autofill_button'),
                    onPressed: () {
                      setSheetState(() {
                        otpController.text = '123456';
                        otpError = null;
                      });
                    },
                    icon: const Icon(Icons.bolt,
                        color: AppColors.accent, size: 16),
                    label: const Text(
                      'Tự động điền 123456',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    key: const Key('otp_confirm_button'),
                    onPressed: () {
                      final code = otpController.text.trim();
                      final res = AuthStore.instance.verifyOtp(code);
                      if (res.success) {
                        Navigator.of(modalContext).pop();
                        widget.onAuthSuccess?.call();
                      } else {
                        setSheetState(() {
                          otpError = res.errorMessage;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Xác nhận & Hoàn tất',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildSegmentedTabBar(),
              const SizedBox(height: 14),
              if (_isLoginTab)
                _buildLoginSection()
              else
                _buildRegisterSection(),
              const SizedBox(height: 10),
              _buildGuestModeButton(),
              if (_isLoginTab) _buildAccountHints(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.sports_tennis_rounded,
              size: 26,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'SportHub',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Nền tảng Thể thao Đẳng cấp',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedTabBar() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              key: const Key('auth_tab_login'),
              onTap: () {
                setState(() {
                  _isLoginTab = true;
                  _loginError = null;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _isLoginTab
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  border: _isLoginTab
                      ? Border.all(color: AppColors.primary, width: 1.2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '⚡ Đăng nhập',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          _isLoginTab ? FontWeight.bold : FontWeight.w500,
                      color: _isLoginTab
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              key: const Key('auth_tab_register'),
              onTap: () {
                setState(() {
                  _isLoginTab = false;
                  _registerError = null;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: !_isLoginTab
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  border: !_isLoginTab
                      ? Border.all(color: AppColors.primary, width: 1.2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '✨ Đăng ký mới',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          !_isLoginTab ? FontWeight.bold : FontWeight.w500,
                      color: !_isLoginTab
                          ? AppColors.primary
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

  Widget _buildLoginSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone / Email input
        _buildTextField(
          key: const Key('login_phone_input'),
          controller: _loginPhoneController,
          label: 'Số điện thoại hoặc Email',
          hintText: 'admin@sporthub.vn, partner@taodan.vn hoặc SĐT',
          icon: Icons.person_pin_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),

        // Password input
        _buildTextField(
          key: const Key('login_password_input'),
          controller: _loginPasswordController,
          label: 'Mật khẩu',
          hintText: 'Nhập mật khẩu (mặc định: 123456)',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscureLoginPassword,
          suffixIcon: IconButton(
            key: const Key('toggle_password_visibility'),
            icon: Icon(
              _obscureLoginPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textSecondary,
              size: 18,
            ),
            onPressed: () {
              setState(() {
                _obscureLoginPassword = !_obscureLoginPassword;
              });
            },
          ),
        ),
        const SizedBox(height: 8),

        // Error text
        if (_loginError != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _loginError!,
                    key: const Key('login_error_text'),
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],

        // Submit button
        ElevatedButton(
          key: const Key('login_submit_button'),
          onPressed: _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text(
            'Đăng nhập ngay ➔',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildRegisterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Role Selector: Player vs Partner (Court Owner)
        Text(
          'Loại tài khoản đăng ký:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                key: const Key('register_role_player'),
                onTap: () {
                  setState(() {
                    _selectedRole = 'player';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: _selectedRole == 'player'
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedRole == 'player'
                          ? AppColors.primary
                          : AppColors.cardBorder,
                      width: _selectedRole == 'player' ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: _selectedRole == 'player'
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Khách hàng',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedRole == 'player'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedRole == 'player'
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                key: const Key('register_role_partner'),
                onTap: () {
                  setState(() {
                    _selectedRole = 'partner';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: _selectedRole == 'partner'
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedRole == 'partner'
                          ? AppColors.accent
                          : AppColors.cardBorder,
                      width: _selectedRole == 'partner' ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.store_rounded,
                        size: 16,
                        color: _selectedRole == 'partner'
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Chủ cụm sân',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedRole == 'partner'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedRole == 'partner'
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Name
        _buildTextField(
          key: const Key('register_name_input'),
          controller: _regNameController,
          label: 'Họ và tên',
          hintText: 'Nhập họ và tên của bạn',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 8),

        // Gmail Email
        _buildTextField(
          key: const Key('register_email_input'),
          controller: _regEmailController,
          label: 'Email Gmail nhận OTP',
          hintText: 'vidu@gmail.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),

        // Phone
        _buildTextField(
          key: const Key('register_phone_input'),
          controller: _regPhoneController,
          label: 'Số điện thoại',
          hintText: 'Nhập số điện thoại liên hệ',
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 8),

        // Password
        _buildTextField(
          key: const Key('register_password_input'),
          controller: _regPasswordController,
          label: 'Mật khẩu',
          hintText: 'Tối thiểu 6 ký tự',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscureRegPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureRegPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textSecondary,
              size: 18,
            ),
            onPressed: () {
              setState(() {
                _obscureRegPassword = !_obscureRegPassword;
              });
            },
          ),
        ),
        const SizedBox(height: 8),

        // Sport selector chips (for Player)
        if (_selectedRole == 'player') ...[
          Text(
            'Môn thể thao ưa thích:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            key: const Key('register_sport_chips'),
            child: Row(
              children: [
                _buildSportChip('pickleball', '🏓 Pickleball'),
                const SizedBox(width: 6),
                _buildSportChip('badminton', '🏸 Cầu lông'),
                const SizedBox(width: 6),
                _buildSportChip('football', '⚽ Bóng đá'),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Register error text
        if (_registerError != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _registerError!,
                    key: const Key('register_error_text'),
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],

        // Submit register
        ElevatedButton(
          key: const Key('register_submit_button'),
          onPressed: _handleRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text(
            'Nhận mã OTP qua Gmail ➔',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSportChip(String sportKey, String label) {
    final isSelected = _selectedSport == sportKey;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSport = sportKey;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: TextField(
            key: key,
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestModeButton() {
    return Center(
      child: TextButton(
        key: const Key('continue_as_guest_button'),
        onPressed: () {
          AuthStore.instance.continueAsGuest();
          widget.onAuthSuccess?.call();
        },
        child: Text(
          'Bỏ qua, khám phá với tư cách Khách ➔',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountHints() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
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
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tài khoản hệ thống (Mật khẩu: 123456)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildAccountHintItem(
            roleLabel: 'Super Admin',
            identifier: 'admin@sporthub.vn',
            color: AppColors.secondary,
          ),
          const SizedBox(height: 4),
          _buildAccountHintItem(
            roleLabel: 'Chủ sân',
            identifier: 'partner@taodan.vn',
            color: AppColors.accent,
          ),
          const SizedBox(height: 4),
          _buildAccountHintItem(
            roleLabel: 'Khách hàng',
            identifier: 'nguyenvanan@gmail.com',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountHintItem({
    required String roleLabel,
    required String identifier,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _loginPhoneController.text = identifier;
          _loginPasswordController.text = '123456';
          _loginError = null;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                roleLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                identifier,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Điền nhanh',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
