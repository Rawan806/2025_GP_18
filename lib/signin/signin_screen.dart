import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wadiah_app/main.dart' show rootMessengerKey;

import 'package:wadiah_app/HomePage/HomePage.dart';
import '../signup/signup_screen.dart';
import '../welcomePage/welcome_screen.dart';
import '../staff/staff_login_screen.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations_helper.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  // ألوان الثيم
  final Color mainGreen = const Color(0xFF243E36);
  final Color borderBrown = const Color(0xFF272525);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _snack(String text, {Color? color}) {
    // ✅ لا نستخدم ScaffoldMessenger.of(context) هنا عشان ما ينهار بعد إغلاق الديالوج
    rootMessengerKey.currentState?.hideCurrentSnackBar();
    rootMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ✅ Forgot Password Dialog + Send reset email (stable)
  Future<void> _showForgotPasswordDialog() async {
    final lang = Localizations.localeOf(context).languageCode;

    String email = emailController.text.trim();
    bool sending = false;

    await showDialog(
      context: context,
      barrierDismissible: !sending,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setLocalState) {
            Future<void> sendReset() async {
              final trimmed = email.trim();

              if (trimmed.isEmpty) {
                _snack(AppLocalizations.translate('enterEmail', lang),
                    color: Colors.red);
                return;
              }

              if (sending) return;
              setLocalState(() => sending = true);

              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: trimmed);

                if (Navigator.canPop(dialogCtx)) {
                  Navigator.of(dialogCtx).pop();
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _snack(AppLocalizations.translate('resetEmailSent', lang),
                      color: Colors.green);
                });
              } on FirebaseAuthException catch (e) {
                final msg =
                    'Reset failed (${e.code}): ${e.message ?? "no message"}';
                _snack(msg, color: Colors.red);
              } catch (e) {
                _snack('Reset failed (unknown): $e', color: Colors.red);
              } finally {
                if (dialogCtx.mounted) setLocalState(() => sending = false);
              }
            }

            return AlertDialog(
              title: Text(AppLocalizations.translate('forgotPassword', lang)),
              content: TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppLocalizations.translate('email', lang),
                ),
                controller: null, // ✅ no controller
                onChanged: (v) => email = v,
              ),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => Navigator.of(dialogCtx).pop(),
                  child: Text(AppLocalizations.translate('cancel', lang)),
                ),
                ElevatedButton(
                  onPressed: sending ? null : sendReset,
                  child: sending
                      ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(AppLocalizations.translate('send', lang)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleLogin() async {
    final lang = Localizations.localeOf(context).languageCode;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _snack(
        AppLocalizations.translate('fillEmailPassword', lang),
        color: Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailAndPassword(email, password);
      String? userType = await _authService.getUserType();

      if (!mounted) return;

      if (userType == 'staff') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StaffLoginScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = AppLocalizations.translate('userNotFound', lang);
          break;
        case 'wrong-password':
          message = AppLocalizations.translate('wrongPassword', lang);
          break;
        case 'invalid-email':
          message = AppLocalizations.translate('invalidEmail', lang);
          break;
        case 'user-disabled':
          message = AppLocalizations.translate('userDisabled', lang);
          break;
        default:
          message =
          '${AppLocalizations.translate('loginError', lang)}: ${e.message ?? e.code}';
      }

      _snack(message, color: Colors.red);
    } catch (e) {
      _snack(
        '${AppLocalizations.translate('unexpectedError', lang)}: $e',
        color: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: borderBrown.withOpacity(0.85)),
    filled: true,
    fillColor: Colors.white.withOpacity(0.9),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
      BorderSide(color: borderBrown.withOpacity(0.8), width: 1.4),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
      BorderSide(color: borderBrown.withOpacity(0.7), width: 1.4),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderBrown, width: 1.8),
    ),
    labelStyle: TextStyle(
      color: borderBrown.withOpacity(0.85),
      fontWeight: FontWeight.w500,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // الخلفية
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background.jpg'),
                  fit: BoxFit.cover,
                  opacity: 1.0,
                ),
              ),
            ),
            Container(color: Colors.white24.withOpacity(0.25)),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WelcomeScreen()),
                      );
                    },
                    icon: Directionality(
                      textDirection: TextDirection.rtl,
                      child: const Icon(Icons.arrow_back,
                          size: 22, color: Colors.black87),
                    ),
                    tooltip: 'رجوع',
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.translate(
                          'signIn', currentLocale.languageCode),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: emailController,
                      decoration: _dec(
                        AppLocalizations.translate(
                            'email', currentLocale.languageCode),
                        Icons.email,
                      ),
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: _dec(
                        AppLocalizations.translate(
                            'password', currentLocale.languageCode),
                        Icons.lock,
                      ),
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    ),

                    // نسيت كلمة المرور
                    Align(
                      alignment:
                      isArabic ? Alignment.centerLeft : Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: Text(
                          AppLocalizations.translate(
                              'forgotPassword', currentLocale.languageCode),
                          style: TextStyle(
                            color: mainGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        AppLocalizations.translate(
                            'login', currentLocale.languageCode),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        AppLocalizations.translate(
                            'noAccount', currentLocale.languageCode),
                        style: TextStyle(
                          color: mainGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
