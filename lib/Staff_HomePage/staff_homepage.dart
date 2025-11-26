import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../staff/found_item_page.dart';
import '../welcomePage/welcome_screen.dart';
import '../staff/search_reports_page.dart';
import '../staff/report_details_page.dart';
import '../l10n/app_localizations_helper.dart';
import '../main.dart';

class StaffHomePage extends StatelessWidget {
  const StaffHomePage({super.key});

  final Color mainGreen = const Color(0xFF243E36);
  final Color borderBrown = const Color(0xFF272525);

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
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
        .collection('lostItems')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots(),
      builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
        child: Text(AppLocalizations.translate('error', currentLocale.languageCode)),
        );
      }

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      final latestReports = snapshot.data?.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'status': data['status'] ?? '',
        'date': data['date'] ?? '',
        'type': data['type'] ?? '',
        'color': data['color'] ?? '',
        'description': data['description'] ?? '',
        'reportLocation': data['reportLocation'] ?? '',
        'foundLocation': data['foundLocation'] ?? '',
        'createdAt': data['createdAt'] ?? '',
        'updatedAt': data['updatedAt'] ?? '',
        'imagePath': data['imagePath'] ?? '',
        };
      }).toList() ?? [];

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: mainGreen,
          foregroundColor: Colors.white,
          title: Text(
            AppLocalizations.translate('staffHome', currentLocale.languageCode),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () => _showLanguageDialog(context),
              icon: const Icon(Icons.language),
              tooltip: AppLocalizations.translate('language', currentLocale.languageCode),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.logout),
              tooltip: AppLocalizations.translate('logout', currentLocale.languageCode),
            ),
          ],
        ),
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
            Container(color: Colors.white.withOpacity(0.25)),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          color: mainGreen,
                          icon: Icons.link,
                          label: AppLocalizations.translate('matchReport', currentLocale.languageCode),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FoundItemPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          color: borderBrown,
                          icon: Icons.search,
                          label: AppLocalizations.translate('searchReports', currentLocale.languageCode),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                const SearchReportsPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    AppLocalizations.translate('latestReports', currentLocale.languageCode),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: latestReports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final report = latestReports[index];
                      return _ReportListTile(
                        id: report['id'] as String,
                        title: report['title'] as String,
                        status: report['status'] as String,
                        date: report['date'] as String,
                        mainColor: mainGreen,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportDetailsPage(
                                report: report,
                                mainGreen: mainGreen,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.90),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black26,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportListTile extends StatelessWidget {
  final String id;
  final String title;
  final String status;
  final String date;
  final Color mainColor;
  final VoidCallback onTap;

  const _ReportListTile({
    required this.id,
    required this.title,
    required this.status,
    required this.date,
    required this.mainColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppLocalizations.translate('reportNumber', currentLocale.languageCode)}: $id',
              style: TextStyle(
                fontSize: 16,
                color: mainColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text('${AppLocalizations.translate('lostItem', currentLocale.languageCode)}: $title'),
            const SizedBox(height: 6),
            Text('${AppLocalizations.translate('status', currentLocale.languageCode)}: $status'),
            const SizedBox(height: 6),
            Text(
              '${AppLocalizations.translate('date', currentLocale.languageCode)}: $date',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
