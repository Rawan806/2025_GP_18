import 'package:flutter/material.dart';
import '../staff/found_item_page.dart';
import '../welcomePage/welcome_screen.dart';
import '../staff/search_reports_page.dart'; 

class StaffHomePage extends StatelessWidget {
  const StaffHomePage({super.key});

  final Color mainGreen = const Color(0xFF243E36);
  final Color borderBrown = const Color(0xFF272525);

  @override
  Widget build(BuildContext context) {
    final latestReports = [
      {
        'id': '1023',
        'title': 'ساعة يد فضية',
        'status': 'قيد المراجعة',
        'date': 'اليوم - 12:30 م',
      },
      {
        'id': '1024',
        'title': 'محفظة جلد بنية',
        'status': 'مطابقة مبدئية',
        'date': 'أمس - 4:10 م',
      },
      {
        'id': '1025',
        'title': 'حقيبة ظهر سوداء',
        'status': 'مغلقة',
        'date': 'أمس - 10:05 ص',
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: mainGreen,
          foregroundColor: Colors.white,
          title: const Text(
            'الرئيسية - الموظف',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
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
              tooltip: 'تسجيل الخروج',
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
                          label: 'مطابقة بلاغ',
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
                          label: 'بحث في البلاغات',
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

                  // أحدث البلاغات
                  const Text(
                    'أحدث البلاغات',
                    style: TextStyle(
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

  const _ReportListTile({
    required this.id,
    required this.title,
    required this.status,
    required this.date,
    required this.mainColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // نفس TrackReportScreen
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
          // رقم البلاغ
          Text(
            'رقم البلاغ: $id',
            style: TextStyle(
              fontSize: 16,
              color: mainColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          // العنصر المفقود
          Text('العنصر المفقود: $title'),
          const SizedBox(height: 6),

          // الحالة
          Text('الحالة: $status'),
          const SizedBox(height: 6),

          // التاريخ
          Text(
            'التاريخ: $date',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
