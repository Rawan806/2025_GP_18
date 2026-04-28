import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations_helper.dart';
import 'AddEvidenceScreen.dart';

class MatchReviewScreen extends StatelessWidget {
  final String lostReportId;
  final Map<String, dynamic> lostReportData;

  const MatchReviewScreen({
    super.key,
    required this.lostReportId,
    required this.lostReportData,
  });

  static const Color mainGreen = Color(0xFF243E36);
  static const Color beigeColor = Color(0xFFC3BFB0);

  Future<void> _rejectMatch(BuildContext context) async {
    final currentLocale = Localizations.localeOf(context);

    try {
      await FirebaseFirestore.instance
          .collection('lostItems')
          .doc(lostReportId)
          .update({
            'status': 'submitted',
            'matchedFoundItemId': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentLocale.languageCode == 'ar'
                ? 'تم رفض التطابق'
                : 'Match rejected',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _goToEvidenceScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEvidenceScreen(
          lostReportId: lostReportId,
          lostReportData: lostReportData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';

    final String foundImage = (lostReportData['matchedFoundImagePath'] ?? '')
        .toString();
    final String foundTitle = (lostReportData['matchedFoundTitle'] ?? '')
        .toString();
    final String foundType = (lostReportData['matchedFoundType'] ?? '')
        .toString();
    final String foundColor = (lostReportData['matchedFoundColor'] ?? '')
        .toString();
    final String foundLocation = (lostReportData['matchedFoundLocation'] ?? '')
        .toString();
    final String similarity = (lostReportData['matchedSimilarity'] ?? '')
        .toString();

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: beigeColor,
        appBar: AppBar(
          backgroundColor: mainGreen,
          centerTitle: true,
          title: Text(
            isArabic ? 'مراجعة التطابق' : 'Match Review',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                      isArabic
                          ? 'العنصر المحتمل العثور عليه'
                          : 'Possible Found Item',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: mainGreen,
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (foundImage.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          foundImage,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 220,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    _InfoRow(
                      label: isArabic ? 'الاسم' : 'Title',
                      value: foundTitle.isEmpty ? '-' : foundTitle,
                    ),
                    _InfoRow(
                      label: isArabic ? 'النوع' : 'Type',
                      value: foundType.isEmpty ? '-' : foundType,
                    ),
                    _InfoRow(
                      label: isArabic ? 'اللون' : 'Color',
                      value: foundColor.isEmpty ? '-' : foundColor,
                    ),
                    _InfoRow(
                      label: isArabic ? 'الموقع' : 'Location',
                      value: foundLocation.isEmpty ? '-' : foundLocation,
                    ),
                    _InfoRow(
                      label: isArabic ? 'نسبة التشابه' : 'Similarity',
                      value: similarity.isEmpty ? '-' : similarity,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _goToEvidenceScreen(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isArabic ? 'هذا الغرض قد يكون لي' : 'This may be mine',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _rejectMatch(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isArabic ? 'ليس غرضي' : 'Not mine',
                    style: const TextStyle(fontSize: 16),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: MatchReviewScreen.mainGreen,
              ),
            ),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}
