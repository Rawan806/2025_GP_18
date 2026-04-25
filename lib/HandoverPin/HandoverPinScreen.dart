import 'package:flutter/material.dart';

class HandoverPinScreen extends StatelessWidget {
  final Map<String, dynamic> lostReportData;

  const HandoverPinScreen({super.key, required this.lostReportData});

  static const Color mainGreen = Color(0xFF243E36);
  static const Color beigeColor = Color(0xFFC3BFB0);

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';

    final String pinCode =
    (lostReportData['handoverPin'] ?? lostReportData['pinCode'] ?? '')
        .toString();

    final String foundImage =
    (lostReportData['matchedFoundImagePath'] ?? '').toString();

    final String foundLocation =
    (lostReportData['matchedFoundLocation'] ??
        lostReportData['foundLocation'] ??
        'Lost & Found Office')
        .toString();

    final String foundTitle =
    (lostReportData['matchedFoundTitle'] ??
        lostReportData['matchedFoundType'] ??
        '')
        .toString();

    final String status = (lostReportData['status'] ?? '').toString();

    final bool isReadyForHandover = status == 'ready_to_handover';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: beigeColor,
        appBar: AppBar(
          backgroundColor: mainGreen,
          centerTitle: true,
          title: Text(
            isArabic ? 'رمز التسليم' : 'Handover PIN',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
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
              children: [
                Icon(
                  isReadyForHandover
                      ? Icons.verified_user
                      : Icons.hourglass_top,
                  color: isReadyForHandover ? mainGreen : Colors.orange,
                  size: 44,
                ),
                const SizedBox(height: 10),

                Text(
                  isReadyForHandover
                      ? (isArabic
                      ? 'تمت الموافقة على التسليم'
                      : 'Approved for Handover')
                      : (isArabic
                      ? 'لم يتم تجهيز التسليم بعد'
                      : 'Handover is not ready yet'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: mainGreen,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                if (foundImage.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      foundImage,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _imagePlaceholder();
                      },
                    ),
                  )
                else
                  _imagePlaceholder(),

                const SizedBox(height: 18),

                if (foundTitle.isNotEmpty)
                  _InfoRow(
                    label: isArabic ? 'العنصر' : 'Item',
                    value: foundTitle,
                  ),

                _InfoRow(
                  label: isArabic ? 'مكان الاستلام' : 'Pickup Location',
                  value: foundLocation.isEmpty
                      ? 'Lost & Found Office'
                      : foundLocation,
                ),

                const SizedBox(height: 24),

                Text(
                  isArabic ? 'رمز التسليم الخاص بك' : 'Your Handover PIN',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: isReadyForHandover ? mainGreen : Colors.grey,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    pinCode.isEmpty ? '------' : pinCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  isArabic
                      ? 'يرجى زيارة مكتب المفقودات وإظهار هذا الرمز للموظف عند الاستلام.'
                      : 'Please visit the Lost & Found Office and show this PIN to the staff during handover.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  isArabic
                      ? 'ملاحظة: لا تشاركي هذا الرمز إلا مع موظف المفقودات.'
                      : 'Note: Do not share this PIN except with Lost & Found staff.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
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
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

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
                color: HandoverPinScreen.mainGreen,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value.isEmpty ? '-' : value),
          ),
        ],
      ),
    );
  }
}