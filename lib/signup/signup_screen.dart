import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← لأجل inputFormatters
import '../signin/signin_screen.dart';
import '../HomePage/HomePage.dart';
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

  final Color mainGreen = const Color(0xFF255E4B);

  @override
  void initState() {
    super.initState();
    // نجعل التطبيق يرسم خلف أشرطة النظام (status/navigation) ونخليها شفافة
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

  void _handleSignUp() {
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إنشاء الحساب بنجاح')),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration _dec(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      body: Container(
        constraints: const BoxConstraints.expand(), // ← يمـلأ الشاشة كلها
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
            opacity: 1.0,
          ),
        ),
        child: SafeArea(
          top: true,  // ← نحمي من الأعلى
          bottom: false, // ← نخلي الخلفية تمتدّ تحت شريط النظام
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
                    onPressed: _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('إنشاء حساب',
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
      ),
    );
  }
}
