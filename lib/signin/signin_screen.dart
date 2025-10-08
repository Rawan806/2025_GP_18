import 'package:flutter/material.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      body: Padding(
        padding: const EdgeInsets.all(24.0),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            Image.asset('assets/logo.png', width:120),
            const SizedBox(height: 20),

            const Text(
              'تسجيل الدخول',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),


            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 15),


            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.right,
            ),


           ElevatedButton(
            onPressed: () {
              print('تسجيل الدخول بالإيميل: ${emailController.text}');
            },
            child: const Text('دخول'),
          ),


          TextButton(
            onPressed: () {
              print('انتقل إلى صفحة إنشاء حساب');
            },
            child: const Text('ليس لديك حساب؟ سجل الآن'),
          ),




          ],
        ),
      ),
    );
  }
}
