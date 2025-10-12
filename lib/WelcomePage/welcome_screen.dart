import 'package:flutter/material.dart';
import '../signin/signin_screen.dart';
import '../staff/staff_login_screen.dart'; // later

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _buttonsFade;

  late final Animation<Offset> _logoSlide;
  late final Animation<Offset> _titleSlide;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<Offset> _buttonsSlide;

  final Color mainGreen = const Color(0xFF243E36);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    );
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.45, curve: Curves.easeOut),
    );
    _subtitleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
    );
    _buttonsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(_logoFade);
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(_titleFade);
    _subtitleSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(_subtitleFade);
    _buttonsSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(_buttonsFade);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _fadeSlide(Animation<double> fade, Animation<Offset> slide, Widget child) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // اللوقو
                _fadeSlide(
                  _logoFade,
                  _logoSlide,
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 350,
                    ),
                  ),
                ),

                // العنوان
                _fadeSlide(
                  _titleFade,
                  _titleSlide,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'وديعة ترحب بك!',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: mainGreen,
                        letterSpacing: 1.2,
                        shadows: const [
                          //Shadow(
                          //   blurRadius: 8,
                          //   color: Colors.black26,
                          //   offset: Offset(2, 2),
                          //,
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // النص الفرعي
                _fadeSlide(
                  _subtitleFade,
                  _subtitleSlide,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'اختر حسابك للمتابعة',
                      style: TextStyle(
                        fontSize: 27,
                        color: mainGreen,
                        fontWeight: FontWeight.w500,
                        shadows: const [
                          // Shadow(
                          //   blurRadius: 5,
                          //   color: Colors.black26,
                          //   offset: Offset(1, 1),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // الأزرار
                _fadeSlide(
                  _buttonsFade,
                  _buttonsSlide,
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SigninScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainGreen,
                          minimumSize: const Size(240, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'زائر',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(builder: (context) => const StaffLoginScreen()),
                          // );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainGreen,
                          minimumSize: const Size(240, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'موظف',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
