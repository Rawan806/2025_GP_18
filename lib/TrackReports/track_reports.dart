import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations_helper.dart';

class TrackReportScreen extends StatelessWidget {
  const TrackReportScreen({super.key});

  final Color mainGreen = const Color(0xFF243E36);
  final Color beigeColor = const Color(0xFFC3BFB0);

  Color _getStatusColor(String status) {
    if (status.contains('قيد المراجعة') || status.contains('Under Review')) {
      return Colors.orange;
    } else if (status.contains('جاري البحث') || status.contains('Searching')) {
      return Colors.blue;
    } else if (status.contains('جاهز للاستلام') ||
        status.contains('Ready for Pickup')) {
      return Colors.green;
    } else if (status.contains('مغلق') || status.contains('Closed')) {
      return Colors.grey;
    }
    return Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: beigeColor,
        appBar: AppBar(
          backgroundColor: mainGreen,
          centerTitle: true,
          title: Text(
            AppLocalizations.translate(
                'trackMyReports', currentLocale.languageCode),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('lostItems')
                    .where('itemCategory', isEqualTo: 'lost')
                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? 'current_user_id')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: mainGreen),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        isArabic
                            ? 'حدث خطأ في تحميل البيانات'
                            : 'Error loading data',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            isArabic
                                ? 'لا توجد بلاغات حالياً'
                                : 'No reports yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final allDocs = snapshot.data!.docs;
                  final activeDocs = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = (data['status'] ?? '').toString();
                    return !(status.contains('مغلق') ||
                        status.contains('Closed'));
                  }).toList();

                  if (activeDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            isArabic
                                ? 'لا توجد بلاغات حالياً'
                                : 'No active reports',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.builder(
                      itemCount: activeDocs.length,
                      itemBuilder: (context, index) {
                        final data =
                        activeDocs[index].data() as Map<String, dynamic>;

                        final reportId =
                        (data['id'] ?? activeDocs[index].id).toString();
                        final title = (data['title'] ?? '').toString();
                        final status = (data['status'] ?? '').toString();
                        final date = (data['date'] ?? '').toString();
                        final imagePath = (data['imagePath'] ?? '').toString();
                        final pinCode = (data['pinCode'] ?? '').toString();
                        final doc_num = (data['doc_num'] ?? '').toString();

                        return Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 12),
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
                          child: Row(
                            children: [
                              if (imagePath.isNotEmpty)
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
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                        ),
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
                                    Icons.inventory_2,
                                    color: mainGreen,
                                    size: 30,
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${AppLocalizations.translate('reportNumber', currentLocale.languageCode)}: $doc_num',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: mainGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${AppLocalizations.translate('lostItem', currentLocale.languageCode)}: $title',
                                      style: const TextStyle(fontSize: 15),
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
                                    if (pinCode.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'PIN: $pinCode',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.brown[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                    if (date.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        date,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9D8C3),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.translate(
                          'duaaMessage', currentLocale.languageCode),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppLocalizations.translate(
                          'duaaText', currentLocale.languageCode),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: mainGreen,
                        height: 1.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
