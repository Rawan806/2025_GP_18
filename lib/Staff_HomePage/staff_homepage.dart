import 'package:flutter/material.dart';


class StaffHomePage extends StatelessWidget {
  const StaffHomePage({super.key});

  final Color mainGreen = const Color(0xFF243E36);
  final Color borderBrown = const Color(0xFF272525);

  @override
  Widget build(BuildContext context) {
    const totalReports = 24;
    const pendingReports = 5;
    const matchedReports = 7;
    const closedReports = 12;

    final latestReports = [
      {
        'id': '#R-1024',
        'title': 'ساعة يد فضية',
        'status': 'قيد المراجعة',
        'date': 'اليوم - 12:30 م',
      },
      {
        'id': '#R-1023',
        'title': 'محفظة جلد بنية',
        'status': 'مطابقة مبدئية',
        'date': 'أمس - 4:10 م',
      },
      {
        'id': '#R-1022',
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
            'واجهة الموظف',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () {
                // TODO: ربط تسجيل الخروج لاحقًا
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

                  // Quick Actions
                  const Text(
                    'الإجراءات السريعة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          color: mainGreen,
                          icon: Icons.add_box_outlined,
                          label: 'تسجيل لقطة جديدة',
                          onTap: () {
                            // TODO: الانتقال لصفحة "New Found Item"
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
                            // TODO: الانتقال لصفحة "Search Reports"
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Dashboard Cards
                  const Text(
                    'لوحة التقارير',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DashboardCard(
                          title: 'إجمالي البلاغات',
                          value: totalReports.toString(),
                          icon: Icons.list_alt,
                          color: mainGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DashboardCard(
                          title: 'قيد المتابعة',
                          value: pendingReports.toString(),
                          icon: Icons.hourglass_bottom,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DashboardCard(
                          title: 'بلاغات مطابقة',
                          value: matchedReports.toString(),
                          icon: Icons.link,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DashboardCard(
                          title: 'بلاغات مغلقة',
                          value: closedReports.toString(),
                          icon: Icons.check_circle,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Latest Reports
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
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
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

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black12,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.65), width: 1.2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            color: Colors.black12,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: mainColor.withOpacity(0.5),
          width: 0.9,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              id,
              style: TextStyle(
                fontSize: 11,
                color: mainColor.withOpacity(0.95),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: mainColor,
            ),
          ),
        ],
      ),
    );
  }
}
