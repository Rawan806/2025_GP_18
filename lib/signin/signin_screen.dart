import 'package:flutter/material.dart';
import 'package:wadiah_app/HomePage/HomePage.dart';
import '../signup/signup_screen.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // اللون الأساسي لتطبيق وديعة
  final Color mainGreen = const Color(0xFF255E4B);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // اللوقو
              Image.asset('assets/logo.png', width: 120),

              const SizedBox(height: 20),

              // عنوان الصفحة
              const Text(
                'تسجيل الدخول كزائر',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 30),

              // حقل البريد الإلكتروني
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                ),
                textAlign: TextAlign.right,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 15),

              // حقل كلمة المرور
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
                textAlign: TextAlign.right,
              ),

              const SizedBox(height: 20),

              // زر تسجيل الدخول
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // توجيه المستخدم إلى الصفحة الرئيسية بعد تسجيل الدخول
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                },
                child: const Text(
                  'دخول',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 10),

              // زر إنشاء حساب جديد
              TextButton(
                onPressed: () {
                  // ✅ هنا نربط صفحة إنشاء الحساب
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
                child: Text(
                  'ليس لديك حساب؟ سجل الآن',
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
    );
  }
}

