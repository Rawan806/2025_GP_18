import 'package:flutter/material.dart';
import 'package:wadiah_app/LostForm/LostForm.dart';
import 'package:wadiah_app/services/auth_service.dart';
import 'package:wadiah_app/signin/signin_screen.dart';
import 'package:wadiah_app/Visitor_Profile/visitor_profile.dart';
import 'package:wadiah_app/TrackReports/track_reports.dart';
import 'package:wadiah_app/PreviousReports/previous_reports.dart';
import '../l10n/app_localizations_helper.dart';
import '../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  void _showLanguageDialog(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.translate('language', currentLocale.languageCode)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text('🇸🇦'),
                title: Text(AppLocalizations.translate('arabic', currentLocale.languageCode)),
                onTap: () {
                  MyApp.of(context).setLocale(const Locale('ar'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇺🇸'),
                title: Text(AppLocalizations.translate('english', currentLocale.languageCode)),
                onTap: () {
                  MyApp.of(context).setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color mainGreen = Color(0xFF243E36);
    const Color beigeColor = Color(0xFFC3BFB0); // لون الخلفية الجديد
    
    // الحصول على اللغة الحالية
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: mainGreen,
          elevation: 0,
          centerTitle: true,
        ),

        // السايد بار
        drawer: Drawer(
          backgroundColor: beigeColor, // بيج
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color(0xFFAAA38C), //little different seems cool
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/logo.png', width: 72, height: 72),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.translate('appTitle', currentLocale.languageCode),
                        style: const TextStyle(
                          color: mainGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.person, color: mainGreen),
                  title: Text(AppLocalizations.translate('account', currentLocale.languageCode)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VisitorProfile()),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.article_outlined, color: mainGreen),
                  title: Text(AppLocalizations.translate('previousReports', currentLocale.languageCode)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PreviousReportsPage()),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline, color: mainGreen),
                  title: Text(AppLocalizations.translate('contactUs', currentLocale.languageCode)),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),

                // خيار تغيير اللغة
                ListTile(
                  leading: const Icon(Icons.language, color: mainGreen),
                  title: Text(AppLocalizations.translate('language', currentLocale.languageCode)),
                  trailing: Icon(
                    isArabic ? Icons.keyboard_arrow_left : Icons.keyboard_arrow_right,
                    color: mainGreen,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showLanguageDialog(context);
                  },
                ),

                const Divider(),

                ListTile(
                  leading: const Icon(Icons.logout, color: mainGreen),
                  title: Text(AppLocalizations.translate('logout', currentLocale.languageCode)),
                  onTap: () {
                    AuthService().signOut();
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const SigninScreen()),
                      (_) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        backgroundColor: beigeColor, //الصفحة بيج
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Image.asset('assets/logo.png', width: 150, height: 150),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.translate('tagline', currentLocale.languageCode),
                style: const TextStyle(fontSize: 20, color: mainGreen),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    elevation: 3,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LostForm()),
                    );
                  },
                  child: Text(
                    AppLocalizations.translate('reportLost', currentLocale.languageCode),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    elevation: 3,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TrackReportScreen()),
                    );
                  },
                  child: Text(
                    AppLocalizations.translate('trackReports', currentLocale.languageCode),
                    style: const TextStyle(fontSize: 20),
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