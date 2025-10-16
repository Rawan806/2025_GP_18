import 'package:flutter/material.dart';
import 'package:wadiah_app/LostForm/LostForm.dart';
import 'package:wadiah_app/signin/signin_screen.dart';
import 'package:wadiah_app/Visitor_Profile/visitor_profile.dart';
import 'package:wadiah_app/TrackReports/track_reports.dart';
import 'package:wadiah_app/PreviousReports/previous_reports.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color mainGreen = Color(0xFF243E36);
    const Color beigeColor = Color(0xFFC3BFB0); // لون الخلفية الجديد

    return Scaffold(
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
                      'وديعة',
                      style: TextStyle(
                        color: mainGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              ListTile(
                leading: Icon(Icons.person, color: mainGreen),
                title: const Text('الحساب'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VisitorProfile()),
                    );
                  },
              ),

              
              ListTile(
                leading: Icon(Icons.article_outlined, color: mainGreen),
                title: const Text('البلاغات السابقة'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PreviousReportsPage()),
                    );
                  },
              ),

              ListTile(
                leading: Icon(Icons.chat_bubble_outline, color: mainGreen),
                title: const Text('تواصل معنا'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const Divider(),

              ListTile(
                leading: Icon(Icons.logout, color: mainGreen),
                title: const Text('تسجيل خروج'),
                onTap: () {
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
            const Text(
              'حيث تُصان الودائع وتُرد الأمانات.',
              style: TextStyle(fontSize: 20, color: mainGreen),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainGreen,
                  foregroundColor: Colors.white,
                  // side: const BorderSide(color: Colors.white, width: 1.2),
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
                child: const Text(
                  'الإبلاغ عن مفقود',
                  style: TextStyle(fontSize: 20),
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
                  // side: const BorderSide(color: Colors.white, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  elevation: 3,
                ),
                onPressed: () {Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrackReportScreen()),
                  );
                  },
                child: const Text('متابعة البلاغات', style: TextStyle(fontSize: 20)),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
