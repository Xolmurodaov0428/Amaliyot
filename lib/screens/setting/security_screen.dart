import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/api_config.dart';
import '../widgets/setting/setting_appbar.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _pinEnabled = false;
  bool _biometricEnabled = false;

  static const String _pinKey = 'app_lock_pin';
  static const String _pinEnabledKey = 'pin_enabled';
  static const String _biometricKey = 'biometric_enabled';

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      _pinEnabled = prefs.getBool(_pinEnabledKey) ?? false;
      _biometricEnabled = prefs.getBool(_biometricKey) ?? false;
    });
  }

  Future<void> _setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    await prefs.setBool(_pinEnabledKey, true);

    if (!mounted) return;
    setState(() => _pinEnabled = true);

    _showSnack("PIN muvaffaqiyatli yoqildi", Colors.green);
  }

  Future<void> _removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setBool(_pinEnabledKey, false);
    await prefs.setBool(_biometricKey, false);

    if (!mounted) return;
    setState(() {
      _pinEnabled = false;
      _biometricEnabled = false;
    });

    _showSnack("PIN o'chirildi", Colors.orange);
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value == true && !_pinEnabled) {
      _showSnack('Avval PIN yoqing', Colors.red);
      return;
    }

    if (value == true) {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        _showSnack('Bu qurilmada biometrik kirish mavjud emas', Colors.red);
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Biometrik kirishni yoqish uchun tasdiqlang',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!authenticated) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, value);

    if (!mounted) return;
    setState(() => _biometricEnabled = value);

    _showSnack(
      value ? "Biometrik kirish yoqildi" : "Biometrik kirish o'chirildi",
      value ? Colors.green : Colors.orange,
    );
  }

  Future<void> _changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      _showSnack('Yangi parol va tasdiqlash mos emas', Colors.red);
      return;
    }

    if (newPassword.length < 6) {
      _showSnack("Yangi parol kamida 6 ta belgidan iborat bo'lsin", Colors.red);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        _showSnack('Token topilmadi. Qayta login qiling', Colors.red);
        return;
      }

      final res = await http.post(
        ApiConfig.uri('change-password'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        }),
      );

      final body = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnack("Parol muvaffaqiyatli o'zgartirildi", Colors.green);
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack(
          body['message']?.toString() ?? "Parolni o'zgartirishda xato",
          Colors.red,
        );
      }
    } catch (e) {
      _showSnack('Xato: $e', Colors.red);
    } finally {
    }
  }

  void _showChangePasswordSheet() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _BottomSheetCard(
          title: "Parolni o'zgartirish",
          child: Column(
            children: [
              _PasswordField(controller: oldCtrl, label: 'Eski parol'),
              const SizedBox(height: 12),
              _PasswordField(controller: newCtrl, label: 'Yangi parol'),
              const SizedBox(height: 12),
              _PasswordField(controller: confirmCtrl, label: 'Tasdiqlash'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    final old = oldCtrl.text.trim();
                    final newP = newCtrl.text.trim();
                    final conf = confirmCtrl.text.trim();
                    Navigator.pop(context);
                    _changePassword(
                      oldPassword: old,
                      newPassword: newP,
                      confirmPassword: conf,
                    );
                  },
                  child: const Text('Saqlash'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  void _showPinSheet() {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _BottomSheetCard(
          title: "4 xonali PIN o'rnatish",
          child: Column(
            children: [
              _PinField(controller: pinCtrl, label: 'PIN'),
              const SizedBox(height: 12),
              _PinField(controller: confirmCtrl, label: 'PIN tasdiqlash'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    final pin = pinCtrl.text.trim();
                    final confirm = confirmCtrl.text.trim();

                    if (pin.length != 4 || confirm.length != 4) {
                      _showSnack("PIN 4 xonali bo'lishi kerak", Colors.red);
                      return;
                    }

                    if (pin != confirm) {
                      _showSnack('PIN mos emas', Colors.red);
                      return;
                    }

                    Navigator.pop(context);
                    _setPin(pin);
                  },
                  child: const Text('PIN yoqish'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnack(String text, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const CustomAppBar(title: 'Xavfsizlik'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SecurityCard(
                    icon: Icons.lock_reset_rounded,
                    iconBg: const Color(0xFFE0F2FE),
                    iconColor: const Color(0xFF0284C7),
                    title: "Parolni o'zgartirish",
                    subtitle: 'Eski parol orqali yangi parol yarating',
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _showChangePasswordSheet,
                  ),
                  const SizedBox(height: 12),

                  _SecurityCard(
                    icon: Icons.pin_rounded,
                    iconBg: const Color(0xFFEDE9FE),
                    iconColor: const Color(0xFF7C3AED),
                    title: 'PIN kod',
                    subtitle: _pinEnabled
                        ? 'Ilova PIN bilan himoyalangan'
                        : "Ilova ochilganda 4 xonali PIN so'ralsin",
                    trailing: Switch(
                      value: _pinEnabled,
                      onChanged: (value) {
                        if (value) {
                          _showPinSheet();
                        } else {
                          _removePin();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  _SecurityCard(
                    icon: Icons.fingerprint_rounded,
                    iconBg: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF16A34A),
                    title: 'Biometrik kirish',
                    subtitle: 'Barmoq izi yoki FaceID orqali kirish',
                    trailing: Switch(
                      value: _biometricEnabled,
                      onChanged: _toggleBiometric,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _SecurityCard(
                    icon: Icons.info_outline_rounded,
                    iconBg: const Color(0xFFFFF7ED),
                    iconColor: const Color(0xFFF97316),
                    title: 'Xavfsizlik eslatmasi',
                    subtitle:
                    'Parolni hech kimga bermang. Umumiy qurilmada “Eslab qolish”ni yoqmang.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SecurityCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSheetCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _BottomSheetCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;

  const _PasswordField({
    required this.controller,
    required this.label,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: widget.label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        suffixIcon: IconButton(
          onPressed: () => setState(() => obscure = !obscure),
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _PinField({
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: 4,
      obscureText: true,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}