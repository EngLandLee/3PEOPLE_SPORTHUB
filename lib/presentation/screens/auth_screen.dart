import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/email_otp_service.dart';
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
  bool _isSubmittingRegister = false;

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

  bool _isLoggingIn = false;

  Future<void> _handleLogin() async {
    if (_isLoggingIn) return;
    final identifier = _loginPhoneController.text.trim();
    final password = _loginPasswordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() {
        _loginError = 'Vui lòng nhập số điện thoại/email và mật khẩu.';
      });
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _loginError = null;
    });

    try {
      final result = await AuthStore.instance.loginAsync(identifier, password);
      if (!mounted) return;
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    if (_isSubmittingRegister) return;

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

    setState(() {
      _isSubmittingRegister = true;
      _registerError = null;
    });

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

    final result = await AuthStore.instance.stageRegistration(
      profile: profile,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      _isSubmittingRegister = false;
    });

    if (!result.success) {
      setState(() {
        _registerError = result.errorMessage;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Không thể gửi mã OTP.'),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      setState(() {
        _registerError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Đã gửi mã OTP đến $email. Vui lòng kiểm tra hộp thư!'),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
        ),
      );
      _showOtpModal(context, email, phone);
    }
  }

  void _showOtpModal(BuildContext context, String email, String phone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return _OtpModalSheet(
          email: email,
          phone: phone,
          onAuthSuccess: widget.onAuthSuccess,
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return _ForgotPasswordSheet(
          initialIdentifier: _loginPhoneController.text.trim(),
          onPasswordResetSuccess: (identifier, newPassword) {
            setState(() {
              _loginPhoneController.text = identifier;
              _loginPasswordController.text = newPassword;
              _loginError = null;
            });
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
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: AppColors.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Nền tảng Thể thao Đẳng cấp',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
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
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const Key('forgot_password_button'),
            onPressed: _showForgotPasswordDialog,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Quên mật khẩu?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

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
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text(
            'Đăng nhập ngay ➔',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
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
          onPressed: _isSubmittingRegister ? null : _handleRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: _isSubmittingRegister
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Text(
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
    final keyStr = roleLabel == 'Chủ sân'
        ? 'quick_login_chusan'
        : roleLabel == 'Super Admin'
            ? 'quick_login_admin'
            : 'quick_login_customer';
    return InkWell(
      key: Key(keyStr),
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

class _OtpModalSheet extends StatefulWidget {
  final String email;
  final String phone;
  final VoidCallback? onAuthSuccess;

  const _OtpModalSheet({
    required this.email,
    required this.phone,
    this.onAuthSuccess,
  });

  @override
  State<_OtpModalSheet> createState() => _OtpModalSheetState();
}

class _OtpModalSheetState extends State<_OtpModalSheet> {
  final TextEditingController _otpController = TextEditingController();
  String? _otpError;
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = EmailOtpService.instance.secondsUntilResend > 0
        ? EmailOtpService.instance.secondsUntilResend
        : 60;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0 || _isResending) return;
    setState(() {
      _isResending = true;
      _otpError = null;
    });

    final res = await AuthStore.instance.resendOtp();
    if (!mounted) return;

    setState(() {
      _isResending = false;
      if (res.success) {
        _secondsRemaining = 60;
        _startTimer();
      } else {
        _otpError = res.errorMessage;
      }
    });

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã gửi lại mã OTP mới đến ${widget.email}.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  bool _isConfirming = false;

  void _handleConfirm() {
    if (_isConfirming) return;
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _otpError = 'Vui lòng nhập mã OTP 6 số.';
      });
      return;
    }
    setState(() {
      _isConfirming = true;
      _otpError = null;
    });

    final res = AuthStore.instance.verifyOtp(code);
    setState(() {
      _isConfirming = false;
    });

    if (res.success) {
      Navigator.of(context).pop();
      widget.onAuthSuccess?.call();
    } else {
      setState(() {
        _otpError = res.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 6),
          Text(
            'Mã OTP 6 số đã được gửi đến hộp thư Gmail:\n${widget.email}\nVui lòng kiểm tra Hộp thư đến (Inbox) hoặc Thư rác (Spam).',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // OTP input field
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TextField(
              key: const Key('otp_input_field'),
              controller: _otpController,
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
          if (_otpError != null) ...[
            const SizedBox(height: 6),
            Text(
              _otpError!,
              key: const Key('otp_error_text'),
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),

          // Open Gmail button
          OutlinedButton.icon(
            key: const Key('otp_open_gmail_button'),
            onPressed: () {
              EmailOtpService.instance.openGmailInbox();
            },
            icon: Icon(Icons.open_in_new_rounded,
                color: AppColors.textPrimary, size: 16),
            label: Text(
              'Mở hộp thư Gmail',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.cardBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 6),

          // Resend OTP Button with cooldown & loading spinner
          Center(
            child: _isResending
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton.icon(
                    key: const Key('otp_resend_button'),
                    onPressed: _secondsRemaining == 0 ? _handleResend : null,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 15,
                      color: _secondsRemaining == 0
                          ? AppColors.primary
                          : AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    label: Text(
                      _secondsRemaining > 0
                          ? 'Gửi lại mã sau ${_secondsRemaining}s'
                          : 'Gửi lại mã OTP qua Gmail',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _secondsRemaining == 0
                            ? AppColors.primary
                            : AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 6),

          // Confirm button
          ElevatedButton(
            key: const Key('otp_confirm_button'),
            onPressed: _isConfirming ? null : _handleConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isConfirming
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : const Text(
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
  }
}

class _ForgotPasswordSheet extends StatefulWidget {
  final String initialIdentifier;
  final void Function(String identifier, String newPassword)
      onPasswordResetSuccess;

  const _ForgotPasswordSheet({
    required this.initialIdentifier,
    required this.onPasswordResetSuccess,
  });

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _identifierController;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorText;
  String? _targetEmail;

  @override
  void initState() {
    super.initState();
    _identifierController =
        TextEditingController(text: widget.initialIdentifier);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetOtp() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      setState(() {
        _errorText = 'Vui lòng nhập email hoặc số điện thoại đã đăng ký.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final result = await AuthStore.instance.requestPasswordReset(identifier);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success) {
        _otpSent = true;
        _targetEmail = result.user?.email ?? identifier;
      } else {
        _errorText = result.errorMessage;
      }
    });
  }

  void _handleConfirmReset() {
    final otp = _otpController.text.trim();
    final newPass = _newPasswordController.text;

    final result = AuthStore.instance.resetPasswordWithOtp(
      otp: otp,
      newPassword: newPass,
    );

    if (!result.success) {
      setState(() {
        _errorText = result.errorMessage;
      });
      return;
    }

    final identifier = _identifierController.text.trim();
    Navigator.of(context).pop();
    widget.onPasswordResetSuccess(identifier, newPass);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Đặt lại mật khẩu mới thành công! Bạn có thể đăng nhập ngay.',
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _otpSent ? 'Đặt Lại Mật Khẩu Mới' : 'Khôi Phục Mật Khẩu Qua OTP',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _otpSent
                ? 'Đã gửi mã OTP 6 chữ số tới $_targetEmail. Vui lòng nhập mã OTP và mật khẩu mới.'
                : 'Nhập số điện thoại hoặc email đã đăng ký để nhận mã xác thực OTP 6 chữ số.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          if (!_otpSent) ...[
            TextField(
              key: const Key('forgot_identifier_input'),
              controller: _identifierController,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Email hoặc Số điện thoại',
                hintText: 'nguyenvanan@gmail.com hoặc 0909123456',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ] else ...[
            TextField(
              key: const Key('forgot_otp_input'),
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
              decoration: InputDecoration(
                counterText: '',
                labelText: 'Mã OTP 6 chữ số',
                hintText: '123456',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('forgot_new_password_input'),
              controller: _newPasswordController,
              obscureText: true,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới (tối thiểu 6 ký tự)',
                hintText: 'Nhập mật khẩu mới',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              key: const Key('forgot_error_text'),
              style: const TextStyle(color: AppColors.error, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 14),
          ElevatedButton(
            key: Key(_otpSent ? 'forgot_confirm_button' : 'forgot_send_otp_button'),
            onPressed: _isLoading
                ? null
                : (_otpSent ? _handleConfirmReset : _handleSendResetOtp),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _otpSent ? 'Xác nhận đổi mật khẩu' : 'Gửi mã OTP khôi phục',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
