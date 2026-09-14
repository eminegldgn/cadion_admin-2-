import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/admin_api_service.dart';
import 'admin_main_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({
    super.key,
  });

  @override
  State<AdminLoginScreen> createState() =>
      _AdminLoginScreenState();
}

class _AdminLoginScreenState
    extends State<AdminLoginScreen> {
  final TextEditingController _adminIdController =
  TextEditingController(
    text: 'admin_test_cihazi',
  );

  final TextEditingController _passwordController =
  TextEditingController();

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _adminIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) {
      return;
    }

    final bool isValid =
        _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final String adminId =
    _adminIdController.text.trim();

    final String password =
        _passwordController.text;

    final AdminApiService apiService =
    AdminApiService();

    final Map<String, dynamic> result =
    await apiService.login(
      adminId: adminId,
      password: password,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (result['success'] != true) {
      _showMessage(
        result['error']?.toString() ??
            'Admin girişi yapılamadı.',
        success: false,
      );

      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return AdminMainScreen(
            adminId: adminId,
          );
        },
      ),
    );
  }

  void _showMessage(
      String message, {
        required bool success,
      }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: success
                  ? AdminColors.success
                  : AdminColors.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildLogo(),

                    const SizedBox(height: 26),

                    const Text(
                      'Cadion Admin',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AdminColors.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Yönetim paneline güvenli giriş yapın',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AdminColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 34),

                    _buildLoginCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            AdminColors.primary,
            AdminColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AdminColors.primary.withValues(
              alpha: 0.25,
            ),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Icon(
        Icons.admin_panel_settings_rounded,
        color: Colors.white,
        size: 48,
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AdminColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Girişi',
            style: TextStyle(
              color: AdminColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Admin ID ve şifrenizi girin.',
            style: TextStyle(
              color: AdminColors.textSecondary,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 22),

          TextFormField(
            controller: _adminIdController,
            enabled: !_isLoading,
            textInputAction: TextInputAction.next,
            validator: (String? value) {
              final String adminId =
                  value?.trim() ?? '';

              if (adminId.isEmpty) {
                return 'Admin ID alanı boş bırakılamaz.';
              }

              if (adminId.length < 3) {
                return 'Geçerli bir Admin ID girin.';
              }

              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Admin ID',
              hintText: 'admin_test_cihazi',
              prefixIcon: Icon(
                Icons.person_outline_rounded,
              ),
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            enabled: !_isLoading,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              _login();
            },
            validator: (String? value) {
              final String password =
                  value ?? '';

              if (password.isEmpty) {
                return 'Şifre alanı boş bırakılamaz.';
              }

              if (password.length < 6) {
                return 'Şifre en az 6 karakter olmalıdır.';
              }

              return null;
            },
            decoration: InputDecoration(
              labelText: 'Şifre',
              hintText: 'Şifrenizi girin',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
              ),
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Şifreyi göster'
                    : 'Şifreyi gizle',
                onPressed: _isLoading
                    ? null
                    : () {
                  setState(() {
                    _obscurePassword =
                    !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed:
              _isLoading ? null : _login,
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(
                Icons.login_rounded,
              ),
              label: Text(
                _isLoading
                    ? 'Giriş yapılıyor...'
                    : 'Giriş Yap',
              ),
            ),
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AdminColors.success.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AdminColors.success.withValues(
                  alpha: 0.18,
                ),
              ),
            ),
            child: const Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: AdminColors.success,
                  size: 19,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Giriş bilgileriniz JWT ile doğrulanır ve oturum anahtarı güvenli şekilde cihazda saklanır.',
                    style: TextStyle(
                      color: AdminColors.textSecondary,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}