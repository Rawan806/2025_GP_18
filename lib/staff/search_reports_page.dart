import 'package:flutter/material.dart';
import '../Staff_HomePage/staff_homepage.dart';

class SearchReportsPage extends StatefulWidget {
  const SearchReportsPage({super.key});

  @override
  State<SearchReportsPage> createState() => _SearchReportsPageState();
}

class _SearchReportsPageState extends State<SearchReportsPage> {
  final Color mainGreen = const Color(0xFF243E36);
  final Color beigeColor = const Color(0xFFC3BFB0);

  final TextEditingController _searchController = TextEditingController();
  String selectedStatus = 'كل الحالات';

  final List<Map<String, dynamic>> allReports = [
    {'id': '1023', 'title': 'ساعة يد فضية', 'status': 'قيد المراجعة'},
    {'id': '1024', 'title': 'محفظة جلد بنية', 'status': 'مطابقة مبدئية'},
    {'id': '1025', 'title': 'حقيبة ظهر سوداء', 'status': 'مغلقة'},
  ];

  List<Map<String, dynamic>> get filteredReports {
    final query = _searchController.text.trim();

    return allReports.where((report) {
      final matchesSearch = query.isEmpty ||
          report['id'].toString().contains(query) ||
          report['title'].toString().contains(query);

      final matchesStatus =
          selectedStatus == 'كل الحالات' || report['status'] == selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: beigeColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'البحث في البلاغات',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),

          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, 
            color: Colors.black87, size: 22),

            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaffHomePage(),
                ),
              );
            },
          ),

          actions: const [],
        ),

        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو رقم البلاغ',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "الحالة",
                  labelStyle: const TextStyle(color: Colors.black87),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  'كل الحالات',
                  'قيد المراجعة',
                  'مطابقة مبدئية',
                  'مغلقة',
                ].map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selectedStatus = value);
                },
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: filteredReports.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد نتائج مطابقة.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredReports.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final report = filteredReports[index];
                          return _ReportCard(
                            mainGreen: mainGreen,
                            report: report,
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StaffHomePage(),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Color mainGreen;
  final Map<String, dynamic> report;
  final VoidCallback onTap;

  const _ReportCard({
    super.key,
    required this.mainGreen,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final id = report['id'];
    final title = report['title'];
    final status = report['status'];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
              'رقم البلاغ: $id',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: mainGreen,
              ),
            ),
            const SizedBox(height: 6),
            Text('العنصر: $title'),
            const SizedBox(height: 6),
            Text('الحالة: $status'),
          ],
        ),
      ),
    );
  }
}
