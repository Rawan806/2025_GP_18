import 'package:flutter/material.dart';
import '../signin/signin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SigninScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.50, -0.00),
            end: Alignment(0.50, 1.00),
            colors: [
              Color(0xFFB5D4CB), // الفاتح العلوي
              Color(0xFF5E6E6A), // الغامق السفلي
            ],
          ),
        ),
        child: Stack(
          children: [
            // المحتوى الرئيسي (الشعار + النص)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo.png', width: 180),
                  const SizedBox(height: 24),
                  const Text(
                    // غيّري النص لو تبين صيغتك: ' وديعة.. ما استٌودع محفوظ'
                    'وديعة.. ما استودع محفوظ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF2A353A),
                      fontSize: 20,
                      fontFamily: 'Noto Sans Arabic',
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

        
          ],
        ),
      ),
    );
  }
}

