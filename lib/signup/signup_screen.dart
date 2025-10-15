import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // لأجل inputFormatters
import 'package:firebase_auth/firebase_auth.dart';
import '../signin/signin_screen.dart';
import '../HomePage/HomePage.dart';
import '../services/auth_service.dart';
//i added background here
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  final Color mainGreen = const Color(0xFF243E36);
  final Color borderBrown = const Color(0xFF272525);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    // تحقق بسيط
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  void _handleSignUp() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    //  التحقق من تعبئة كل الحقول
    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة جميع الحقول المطلوبة')),
      );
      return;
    }

    //  تحقق من الإيميل
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال بريد إلكتروني صحيح')),
      );
      return;
    }

    // تحقق من رقم الجوال يكون 10 أرقام
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الجوال يجب أن يكون 10 أرقام')),
      );
      return;
    }

    // 8 أحرف على الاقل
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب أن تكون كلمة المرور 8 أحرف على الأقل')),
      );
      return;
    }

    //  تطابق كلمة المرور
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة المرور وتأكيدها غير متطابقتين')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // إنشاء حساب جديد باستخدام Firebase Auth
      await _authService.createUserWithEmailAndPassword(
        email, 
        password, 
        name, 
        phone, 
        'visitor' // نوع المستخدم كزائر
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء الحساب بنجاح'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // الانتقال للصفحة الرئيسية
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'كلمة المرور ضعيفة جداً';
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
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ غير متوقع: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration _dec(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: borderBrown.withOpacity(0.85)),
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderBrown.withOpacity(0.7), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderBrown.withOpacity(0.7), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderBrown, width: 1.6),
      ),
      labelStyle: TextStyle(color: borderBrown.withOpacity(0.85)),
    );

    //////////////////////////////////////////////

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            constraints: const BoxConstraints.expand(), // يمـلا الشاشة كلها
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
                opacity: 1.0,
              ),
            ),
          ),
          Container(
            color: Colors.white24.withOpacity(0.25),
          ),
          SafeArea(
            top: true,
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
///////////////////////////////////////////////////////////////////////////
                  TextField(
                    controller: nameController,
                    decoration: _dec('الاسم الكامل', Icons.person),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: emailController,
                    decoration: _dec('البريد الإلكتروني', Icons.email),
                    textDirection: TextDirection.rtl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: phoneController,
                    decoration: _dec('رقم الجوال', Icons.phone),
                    textDirection: TextDirection.rtl,
                    keyboardType: TextInputType.phone,
                    inputFormatters:  [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // كلمة المرور
                  TextField(
                    controller: passwordController,
                    decoration: _dec('كلمة المرور', Icons.lock),
                    obscureText: true,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 15),

                  // تأكيد كلمة المرور
                  TextField(
                    controller: confirmPasswordController,
                    decoration: _dec('تأكيد كلمة المرور', Icons.lock_outline),
                    obscureText: true,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 30),

                  // إنشاء حساب فعليا
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('إنشاء حساب',
                              style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // تسجيل الدخول
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SigninScreen()),
                      );
                    },
                    child: Text(
                      'لديك حساب بالفعل؟ تسجيل الدخول',
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
        ],
      ),
    );
  }
}
