import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations_helper.dart';

class PreviousReportsPage extends StatelessWidget {
  const PreviousReportsPage({super.key});

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
          elevation: 0,
          centerTitle: true,
          title: Text(
            AppLocalizations.translate(
                'previousReports', currentLocale.languageCode),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('lostItems')
              .where('itemCategory', isEqualTo: 'lost')
              .where('userId', isEqualTo: 'current_user_id')
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
                child: Text(
                  AppLocalizations.translate(
                      'noPreviousReports', currentLocale.languageCode),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black38,
                  ),
                ),
              );
            }

            final allDocs = snapshot.data!.docs;
            final closedDocs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = (data['status'] ?? '').toString();
              return status.contains('مغلق') || status.contains('Closed');
            }).toList();

            if (closedDocs.isEmpty) {
              return Center(
                child: Text(
                  AppLocalizations.translate(
                      'noPreviousReports', currentLocale.languageCode),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black38,
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: closedDocs.length,
                itemBuilder: (context, index) {
                  final data =
                  closedDocs[index].data() as Map<String, dynamic>;
                  final reportId =
                  (data['id'] ?? closedDocs[index].id).toString();
                  final title = (data['title'] ?? '').toString();
                  final status = (data['status'] ?? '').toString();
                  final date = (data['date'] ?? '').toString();
                  final imagePath = (data['imagePath'] ?? '').toString();

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
                                    borderRadius: BorderRadius.circular(8),
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
                                '${AppLocalizations.translate('reportNumber', currentLocale.languageCode)}: ${reportId.substring(0, reportId.length > 8 ? 8 : reportId.length)}',
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
    );
  }
}
