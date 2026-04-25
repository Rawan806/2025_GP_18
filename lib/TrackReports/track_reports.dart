import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations_helper.dart';
import '../MatchReview/MatchReviewScreen.dart';
import '../HandoverPin/HandoverPinScreen.dart';

class TrackReportScreen extends StatelessWidget {
  const TrackReportScreen({super.key});

  final Color mainGreen = const Color(0xFF243E36);
  final Color beigeColor = const Color(0xFFC3BFB0);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.orange;
      case 'possible_match':
        return Colors.blue;
      case 'waiting_for_staff_review':
        return Colors.deepPurple;
      case 'approved_by_staff':
        return Colors.teal;
      case 'ready_to_handover':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.black87;
    }
  }

  bool _isCancelledStatus(String status) => status == 'cancelled';
  bool _isClosedStatus(String status) => status == 'completed';
  bool _canUserCancel(String status) => status == 'submitted';

  String _getLocalizedStatus(String status, String languageCode) {
    switch (status) {
      case 'submitted':
        return languageCode == 'ar' ? 'تم رفع البلاغ' : 'Submitted';
      case 'possible_match':
        return languageCode == 'ar'
            ? 'تم العثور على تطابق محتمل'
            : 'Possible Match';
      case 'waiting_for_staff_review':
        return languageCode == 'ar'
            ? 'بانتظار مراجعة الموظف'
            : 'Waiting for Staff Review';
      case 'approved_by_staff':
        return languageCode == 'ar'
            ? 'تمت الموافقة من الموظف'
            : 'Approved by Staff';
      case 'ready_to_handover':
        return languageCode == 'ar' ? 'جاهز للتسليم' : 'Ready for Handover';
      case 'completed':
        return languageCode == 'ar' ? 'مكتمل' : 'Completed';
      case 'cancelled':
        return languageCode == 'ar' ? 'ملغي' : 'Cancelled';
      default:
        return status;
    }
  }

  Future<void> _cancelReport({
    required BuildContext context,
    required String docId,
    required String languageCode,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('lostItems')
          .doc(docId)
          .update({
            'status': 'cancelled',
            'cancelledBy': 'user',
            'cancelledAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            languageCode == 'ar'
                ? 'تم إلغاء البلاغ بنجاح'
                : 'Report cancelled successfully',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
      );
    }
  }

  Future<void> _showCancelDialog({
    required BuildContext context,
    required String docId,
    required String languageCode,
  }) async {
    final isArabic = languageCode == 'ar';

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(isArabic ? 'تأكيد الإلغاء' : 'Confirm Cancellation'),
            content: Text(
              isArabic
                  ? 'هل أنت متأكد من إلغاء هذا البلاغ؟'
                  : 'Are you sure you want to cancel this report?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(isArabic ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(isArabic ? 'نعم' : 'Yes'),
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      await _cancelReport(
        context: context,
        docId: docId,
        languageCode: languageCode,
      );
    }
  }

  void _openMatchReview(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MatchReviewScreen(lostReportId: docId, lostReportData: data),
      ),
    );
  }

  void _openHandoverPin(BuildContext context, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HandoverPinScreen(lostReportData: data),
      ),
    );
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
              'trackMyReports',
              currentLocale.languageCode,
            ),
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
                    .where(
                      'userId',
                      isEqualTo:
                          FirebaseAuth.instance.currentUser?.uid ??
                          'current_user_id',
                    )
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
                          const Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey,
                          ),
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
                    return !_isClosedStatus(status) &&
                        !_isCancelledStatus(status);
                  }).toList();

                  if (activeDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isArabic
                                ? 'لا توجد بلاغات نشطة'
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
                        final doc = activeDocs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final title = (data['title'] ?? '').toString();
                        final rawStatus = (data['status'] ?? '').toString();
                        final status = _getLocalizedStatus(
                          rawStatus,
                          currentLocale.languageCode,
                        );
                        final date = (data['date'] ?? '').toString();
                        final imagePath = (data['imagePath'] ?? '').toString();
                        final pinCode =
                        (data['handoverPin'] ?? data['pinCode'] ?? '').toString();                        final docNum = (data['doc_num'] ?? '').toString();

                        final canCancel = _canUserCancel(rawStatus);

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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                      '${AppLocalizations.translate('reportNumber', currentLocale.languageCode)}: $docNum',
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
                                        color: _getStatusColor(rawStatus),
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
                                    if (pinCode.isNotEmpty &&
                                        rawStatus == 'ready_to_handover') ...[
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
                                    const SizedBox(height: 10),

                                    if (rawStatus == 'possible_match')
                                      Align(
                                        alignment: isArabic
                                            ? Alignment.centerLeft
                                            : Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: () => _openMatchReview(
                                            context,
                                            doc.id,
                                            data,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: mainGreen,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: Text(
                                            isArabic
                                                ? 'مراجعة التطابق'
                                                : 'Review Match',
                                          ),
                                        ),
                                      ),

                                    if (rawStatus == 'ready_to_handover')
                                      Align(
                                        alignment: isArabic
                                            ? Alignment.centerLeft
                                            : Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _openHandoverPin(context, data),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: Text(
                                            isArabic ? 'عرض PIN' : 'View PIN',
                                          ),
                                        ),
                                      ),

                                    if (canCancel)
                                      Align(
                                        alignment: isArabic
                                            ? Alignment.centerLeft
                                            : Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () => _showCancelDialog(
                                            context: context,
                                            docId: doc.id,
                                            languageCode:
                                                currentLocale.languageCode,
                                          ),
                                          icon: const Icon(
                                            Icons.cancel,
                                            color: Colors.redAccent,
                                          ),
                                          label: Text(
                                            isArabic
                                                ? 'إلغاء البلاغ'
                                                : 'Cancel Report',
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
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
                        'duaaMessage',
                        currentLocale.languageCode,
                      ),
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
                        'duaaText',
                        currentLocale.languageCode,
                      ),
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
