import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_main_screen.dart';
import 'services/admin_api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const CadionAdminApp(),
  );
}

class CadionAdminApp extends StatelessWidget {
  const CadionAdminApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadion Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.darkTheme,
      home: const AdminSessionGate(),
    );
  }
}

class AdminSessionGate extends StatefulWidget {
  const AdminSessionGate({
    super.key,
  });

  @override
  State<AdminSessionGate> createState() =>
      _AdminSessionGateState();
}

class _AdminSessionGateState
    extends State<AdminSessionGate> {
  final AdminApiService _apiService =
  AdminApiService();

  bool _isChecking = true;
  String? _adminId;

  @override
  void initState() {
    super.initState();

    _checkSession();
  }

  Future<void> _checkSession() async {
    final bool hasSession =
    await _apiService.hasSavedSession();

    if (!hasSession) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isChecking = false;
        _adminId = null;
      });

      return;
    }

    final Map<String, dynamic> result =
    await _apiService.checkAdmin();

    if (!mounted) {
      return;
    }

    if (result['success'] != true) {
      await _apiService.logout();

      if (!mounted) {
        return;
      }

      setState(() {
        _isChecking = false;
        _adminId = null;
      });

      return;
    }

    final dynamic adminValue =
    result['admin'];

    String? adminId;

    if (adminValue is Map) {
      final Map<String, dynamic> admin =
      Map<String, dynamic>.from(
        adminValue,
      );

      adminId =
          admin['id']?.toString();
    }

    adminId ??=
    await _apiService.getSavedAdminId();

    if (!mounted) {
      return;
    }

    setState(() {
      _isChecking = false;
      _adminId = adminId;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (
    _adminId == null ||
        _adminId!.trim().isEmpty
    ) {
      return const AdminLoginScreen();
    }

    return AdminMainScreen(
      adminId: _adminId!,
    );
  }
}
