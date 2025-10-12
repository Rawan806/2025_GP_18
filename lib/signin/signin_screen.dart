import 'package:flutter/material.dart';
import 'package:wadiah_app/HomePage/HomePage.dart';
import '../signup/signup_screen.dart';
import '../welcomePage/welcome_screen.dart'; // عدّلي المسار إذا اختلف

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // ألوان الثيم حقتنا
  final Color mainGreen = const Color(0xFF243E36);
  final Color borderBrown = const Color(0xFF272525);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تعبئة البريد الإلكتروني وكلمة المرور'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: borderBrown.withOpacity(0.85)),
    filled: true,
    fillColor: Colors.transparent, // بدون تعبئة مصمتة
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          Container(
            color: Colors.white24.withOpacity(0.25),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: IconButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    );
                  },
                  icon: Directionality(
                    textDirection: TextDirection.rtl, // يضمن اتجاه السهم لليمين
                    child: const Icon(Icons.arrow_back, size: 22, color: Colors.black87),
                  ),
                  tooltip: 'رجوع',
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  const Text(
                    'تسجيل الدخول',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 24),

                  TextField(
                    controller: emailController,
                    decoration: _dec('البريد الإلكتروني', Icons.email),
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _dec('كلمة المرور', Icons.lock),
                    textAlign: TextAlign.right,
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _handleLogin,
                    child: const Text(
                      'دخول',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () {
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

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
