import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Staff_HomePage/staff_homepage.dart';
import '../l10n/app_localizations_helper.dart';

class SearchReportsPage extends StatefulWidget {
  const SearchReportsPage({super.key});

  @override
  State<SearchReportsPage> createState() => _SearchReportsPageState();
}

class _SearchReportsPageState extends State<SearchReportsPage> {
  final Color mainGreen = const Color(0xFF243E36);
  final Color beigeColor = const Color(0xFFC3BFB0);
  final TextEditingController _searchController = TextEditingController();
  late String selectedStatus = "";

  Stream<QuerySnapshot> _getReportsStream() {
    Query query = FirebaseFirestore.instance
        .collection('lostItems')
        .orderBy('createdAt', descending: true);
    return query.snapshots();
  }

  String _getEnglishStatus(String status) {
    if (status.contains('قيد المراجعة') || status.contains('Under Review')) {
      return 'Under Review';
    } else if (status.contains('مطابقة مبدئية') || status.contains('Preliminary Match')) {
      return 'Preliminary Match';
    } else if (status.contains('جاهز للاستلام') || status.contains('Ready for Pickup')) {
      return 'Ready for Pickup';
    } else if (status.contains('مغلق') || status.contains('Closed')) {
      return 'Closed';
    }
    return status;
  }

  List<Map<String, dynamic>> _filterReports(
      List<DocumentSnapshot> docs,
      BuildContext context,
      ) {
    final currentLocale = Localizations.localeOf(context);
    final allStatusesText = AppLocalizations.translate('allStatuses', currentLocale.languageCode);
    final searchQuery = _searchController.text.trim().toLowerCase();

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final id = (data['id'] ?? doc.id).toString();
      final doc_num = (data['doc_num'] ?? '').toString();
      final title = (data['title'] ?? '').toString().toLowerCase();
      final status = (data['status'] ?? '').toString();

      final matchesSearch = searchQuery.isEmpty ||
          id.contains(searchQuery) ||
          title.contains(searchQuery) ||
          (data['category'] ?? '').toString().toLowerCase().contains(searchQuery) ||
          (data['description'] ?? '').toString().toLowerCase().contains(searchQuery);

      final matchesStatus = selectedStatus.isEmpty ||
          selectedStatus == allStatusesText ||
          _getEnglishStatus(selectedStatus) == _getEnglishStatus(status);

      return matchesSearch && matchesStatus;
    }).map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': data['id'] ?? doc.id,
        'title': data['title'] ?? '',
        'status': data['status'] ?? '',
        'category': data['category'] ?? '',
        'description': data['description'] ?? '',
        'imagePath': data['imagePath'] ?? '',
        'date': data['date'] ?? '',
        'itemCategory': data['itemCategory'] ?? '',
        'doc_num': data['doc_num'] ?? '',
        'userId': data['userId'] ?? '',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';

    if (selectedStatus.isEmpty) {
      selectedStatus = AppLocalizations.translate('allStatuses', currentLocale.languageCode);
    }

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: beigeColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            AppLocalizations.translate('searchReports', currentLocale.languageCode),
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 22),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaffHomePage(),
                ),
              );
            },
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                decoration: InputDecoration(
                  hintText: AppLocalizations.translate('searchByNameOrNumber', currentLocale.languageCode),
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
                  labelText: AppLocalizations.translate('status', currentLocale.languageCode),
                  labelStyle: const TextStyle(color: Colors.black87),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  AppLocalizations.translate('allStatuses', currentLocale.languageCode),
                  AppLocalizations.translate('underReview', currentLocale.languageCode),
                  AppLocalizations.translate('preliminaryMatch', currentLocale.languageCode),
                  AppLocalizations.translate('readyForPickup', currentLocale.languageCode),
                  AppLocalizations.translate('closed', currentLocale.languageCode),
                ].map((s) {
                  return DropdownMenuItem<String>(value: s, child: Text(s));
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selectedStatus = value);
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getReportsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: mainGreen));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        isArabic ? 'حدث خطأ في تحميل البيانات' : 'Error loading data',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            isArabic ? 'لا توجد بلاغات' : 'No reports found',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredList = _filterReports(snapshot.data!.docs, context);

                  if (filteredList.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          AppLocalizations.translate('noMatchingResults', currentLocale.languageCode),
                          style: const TextStyle(color: Colors.black54, fontSize: 16),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView.separated(
                      itemCount: filteredList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final report = filteredList[index];
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
                  );
                },
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
    required this.mainGreen,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final id = report['id'].toString();
    final title = report['title'].toString();
    final status = report['status'].toString();
    final category = report['category'].toString();
    final imagePath = report['imagePath'].toString();
    final date = report['date'].toString();
    final itemCategory = report['itemCategory'].toString();
    final doc_num = report['doc_num'].toString();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            if (imagePath.isNotEmpty && imagePath != 'null')
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imagePath,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                    );
                  },
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: mainGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  itemCategory == 'found' ? Icons.check_circle : Icons.search,
                  color: mainGreen,
                  size: 30,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          // '${AppLocalizations.translate('reportNumber', currentLocale.languageCode)}: ${id.substring(0, id.length > 8 ? 8 : id.length)}',
                          '${AppLocalizations.translate('reportNumber', currentLocale.languageCode)}: ${doc_num}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: mainGreen,
                          ),
                        ),
                      ),
                      if (itemCategory == 'found')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                          child: Text(
                            currentLocale.languageCode == 'ar' ? 'موجود' : 'Found',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${AppLocalizations.translate('item', currentLocale.languageCode)}: $title',
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (category.isNotEmpty && category != 'null')
                    Text(
                      '${AppLocalizations.translate('category', currentLocale.languageCode)}: $category',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppLocalizations.translate('status', currentLocale.languageCode)}: $status',
                    style: TextStyle(
                      fontSize: 13,
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (date.isNotEmpty && date != 'null') ...[
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('قيد المراجعة') || status.contains('Under Review')) {
      return Colors.orange;
    } else if (status.contains('مطابقة مبدئية') || status.contains('Preliminary Match')) {
      return Colors.blue;
    } else if (status.contains('جاهز للاستلام') || status.contains('Ready for Pickup')) {
      return Colors.green;
    } else if (status.contains('مغلق') || status.contains('Closed')) {
      return Colors.grey;
    }
    return Colors.black87;
  }
}
