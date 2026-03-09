import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../signin/signin_screen.dart';
import '../HomePage/HomePage.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations_helper.dart';
import '../otp_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;

  // رقم جوال بصيغة E.164: +9665xxxxxxxx
  String _phoneE164 = '';
  final PhoneNumber _initialNumber = PhoneNumber(isoCode: 'SA');

  final Color mainGreen = const Color(0xFF243E36);
  final Color borderBrown = const Color(0xFF272525);

  @override
  void initState() {
    super.initState();

    passwordController.addListener(_revalidateForm);
    confirmPasswordController.addListener(_revalidateForm);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  void _revalidateForm() {
    final form = _formKey.currentState;
    if (form != null) form.validate();
  }

  @override
  void dispose() {
    passwordController.removeListener(_revalidateForm);
    confirmPasswordController.removeListener(_revalidateForm);

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  // ---------- Validators ----------
  String? _validateName(String? v, String lang) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return AppLocalizations.translate('fillAllFields', lang);
    if (value.length < 2) return 'الاسم قصير جدًا';
    return null;
  }

  String? _validateEmail(String? v, String lang) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return AppLocalizations.translate('fillAllFields', lang);
    if (!_isValidEmail(value)) return AppLocalizations.translate('invalidEmail', lang);
    return null;
  }

  String? _validatePhone(String lang) {
    // يعتمد على intl_phone_number_input في إخراج E.164
    if (_phoneE164.trim().isEmpty) {
      return AppLocalizations.translate('fillAllFields', lang);
    }
    // لو تبين تشيك إضافي:
    if (!_phoneE164.startsWith('+')) {
      return 'رقم الجوال غير صحيح';
    }
    return null;
  }

  String? _validatePassword(String? v, String lang) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return AppLocalizations.translate('fillAllFields', lang);
    if (value.length < 8) return AppLocalizations.translate('passwordLength', lang);
    return null;
  }

  String? _validateConfirmPassword(String? v, String lang) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return AppLocalizations.translate('fillAllFields', lang);
    if (value != passwordController.text.trim()) {
      return AppLocalizations.translate('passwordMismatch', lang);
    }
    return null;
  }

  // ---------- Main SignUp Flow ----------
  Future<void> _handleSignUp() async {
    final currentLocale = Localizations.localeOf(context);
    final lang = currentLocale.languageCode;

    FocusScope.of(context).unfocus();

    final ok = _formKey.currentState?.validate() ?? false;
    final phoneError = _validatePhone(lang);
    if (!ok || phoneError != null) {
      // لو فشل رقم الجوال، نطلع SnackBar سريع (والـUI already يبين errors تحت الحقول)
      if (phoneError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(phoneError)),
        );
      }
      return;
    }

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phone = _phoneE164.trim();

    setState(() => _isLoading = true);

    try {
      // 1) إنشاء حساب الإيميل/باسورد أولًا
      await _authService.createUserWithEmailAndPassword(
        email,
        password,
        name,
        phone,
        'visitor',
      );

      if (!mounted) return;

      // 2) أرسل SMS وانتقل لصفحة OTP
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phoneE164: phone,
            name: name,
            email: email,
            userType: 'visitor',
            onVerifiedNavigateToHome: true,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'كلمة المرور ضعيفة جدًا';
          break;
        case 'email-already-in-use':
          message = 'البريد الإلكتروني مستخدم من قبل';
          break;
        case 'invalid-email':
          message = 'البريد الإلكتروني غير صحيح';
          break;
        default:
          message = 'خطأ في إنشاء الحساب: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ غير متوقع: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final lang = currentLocale.languageCode;
    final isArabic = lang == 'ar';

    InputDecoration dec(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: borderBrown.withOpacity(0.85)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderBrown.withOpacity(0.8), width: 1.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderBrown.withOpacity(0.7), width: 1.4),
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

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            AppLocalizations.translate('signUp', lang),
            style: const TextStyle(color: Colors.black87),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Container(
              constraints: const BoxConstraints.expand(),
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
              top: true,
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      // الاسم
                      TextFormField(
                        controller: nameController,
                        decoration: dec(AppLocalizations.translate('fullName', lang), Icons.person),
                        validator: (v) => _validateName(v, lang),
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      ),
                      const SizedBox(height: 15),

                      // الايميل
                      TextFormField(
                        controller: emailController,
                        decoration: dec(AppLocalizations.translate('email', lang), Icons.email),
                        validator: (v) => _validateEmail(v, lang),
                        keyboardType: TextInputType.emailAddress,
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      ),
                      const SizedBox(height: 15),

                      // الجوال الدولي
                      InternationalPhoneNumberInput(
                        onInputChanged: (PhoneNumber number) {
                          setState(() {
                            _phoneE164 = number.phoneNumber ?? '';
                          });
                        },
                        selectorConfig: const SelectorConfig(
                          selectorType: PhoneInputSelectorType.DROPDOWN,
                          showFlags: true,
                          useEmoji: true,
                        ),
                        ignoreBlank: false,
                        autoValidateMode: AutovalidateMode.onUserInteraction,
                        initialValue: _initialNumber,
                        textFieldController: phoneController,
                        formatInput: true,
                        inputDecoration: dec(AppLocalizations.translate('phoneNumber', lang), Icons.phone),
                        keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                      ),
                      const SizedBox(height: 15),

                      // الباسورد
                      TextFormField(
                        controller: passwordController,
                        decoration: dec(AppLocalizations.translate('password', lang), Icons.lock),
                        validator: (v) => _validatePassword(v, lang),
                        obscureText: true,
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      ),
                      const SizedBox(height: 15),

                      // تأكيد
                      TextFormField(
                        controller: confirmPasswordController,
                        decoration: dec(AppLocalizations.translate('confirmPassword', lang), Icons.lock_outline),
                        validator: (v) => _validateConfirmPassword(v, lang),
                        obscureText: true,
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : Text(
                            AppLocalizations.translate('createAccount', lang),
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SigninScreen()),
                          );
                        },
                        child: Text(
                          AppLocalizations.translate('hasAccount', lang),
                          style: TextStyle(
                            color: mainGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
