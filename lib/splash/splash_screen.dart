import 'package:flutter/material.dart';
import 'package:wadiah_app/WelcomePage/welcome_screen.dart'; 
import '../HomePage/HomePage.dart';
import '../staff/staff_login_screen.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  void _checkUserStatus() async { 
    // انتظار عرض الشاشة الترحيبية
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    try {
      // التأكد من تهيئة Firebase
      await _authService.ensureInitialized();
      
      if (_authService.isLoggedIn) { 
        String? userType = await _authService.getUserType();
        
        if (userType == 'staff') { 
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StaffLoginScreen()),
          );
        } else { 
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } catch (e) {
      print('Error checking user status: $e');
      // في حالة الخطأ، انتقل لصفحة الترحيب
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    }
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
            colors: [Color(0xFF798884), Color(0xFF837D70)],//0xFF243E36
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo.png', width: 180),
                  const SizedBox(height: 24),
                  const Text(
                    'وديعة.. ما استودع محفوظ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF333333),
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
