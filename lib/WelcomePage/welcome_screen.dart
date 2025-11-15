import 'package:flutter/material.dart';
import '../signin/signin_screen.dart';
import '../staff/found_item_page.dart';
import '../l10n/app_localizations_helper.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _titleFade;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _buttonsFade;

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

    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _subtitleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
    );
    _buttonsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );

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
      child: SlideTransition(position: slide, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          children: [
            // الخلفية فقط
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background.jpg'),
                  fit: BoxFit.cover,
                  opacity: 1.0,
                ),
              ),
            ),
            // طبقة خفيفة لتنعيم الخلفية
            Container(color: Colors.white.withOpacity(0.25)),

            // المحتوى بالنصوص فقط
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // العنوان الرئيسي
                  _fadeSlide(
                    _titleFade,
                    _titleSlide,
                    Text(
                      '${AppLocalizations.translate('welcome', currentLocale.languageCode)} ${AppLocalizations.translate('appTitle', currentLocale.languageCode)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: mainGreen,
                        letterSpacing: 1.2,
                        shadows: const [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black26,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // النص الفرعي
                  _fadeSlide(
                    _subtitleFade,
                    _subtitleSlide,
                    Text(
                      'فضلًا اختر نوع المستخدم',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: mainGreen.withOpacity(0.95),
                        shadows: const [
                          Shadow(
                            blurRadius: 6,
                            color: Colors.black26,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

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
                          child: Text(
                            AppLocalizations.translate('visitor', currentLocale.languageCode),
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FoundItemPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainGreen,
                            minimumSize: const Size(240, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.translate('staff', currentLocale.languageCode),
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
<<<<<<< Updated upstream
                ],
              ),
=======
                ),

                const SizedBox(height: 16),

                // النص الفرعي
                _fadeSlide(
                  _subtitleFade,
                  _subtitleSlide,
                  Text(
                    'فضلًا اختر نوع المستخدم',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: mainGreen.withOpacity(0.95),
                      shadows: const [
                        Shadow(
                          blurRadius: 6,
                          color: Colors.black26,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 50),

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
                        child: Text(
                          AppLocalizations.translate('visitor', currentLocale.languageCode),
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                           context,
                           MaterialPageRoute(builder: (context) => const StaffLoginScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainGreen,
                          minimumSize: const Size(240, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.translate('staff', currentLocale.languageCode),
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
>>>>>>> Stashed changes
            ),
          ],
        ),
      ),
    );
  }
}
