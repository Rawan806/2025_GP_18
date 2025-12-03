import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations_helper.dart';

class ReportDetailsPage extends StatefulWidget {
  final Map<String, dynamic> report;
  final Color mainGreen;

  const ReportDetailsPage({
    super.key,
    required this.report,
    required this.mainGreen,
  });

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  String _selectedStatus = '';
  final TextEditingController _notesController = TextEditingController();
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final currentDescription = (widget.report['description'] ?? '').toString();
    _descriptionController = TextEditingController(text: currentDescription);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges(Locale currentLocale) async {
    try {
      // ناخذ docId من الماب لو موجود، أو نرجع لـ id
      final rawDocId = widget.report['docId'] ?? widget.report['id'];
      final docId = rawDocId?.toString();

      if (docId == null || docId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLocale.languageCode == 'ar'
                  ? 'تعذّر العثور على رقم البلاغ في النظام.'
                  : 'Could not find the report document ID.',
            ),
          ),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('lostItems')
          .doc(docId)
          .update({
        'status': _selectedStatus,
        'description': _descriptionController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentLocale.languageCode == 'ar'
                ? 'تم حفظ التغييرات بنجاح.'
                : 'Changes saved successfully.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentLocale.languageCode == 'ar'
                ? 'حدث خطأ أثناء حفظ التغييرات.'
                : 'Error while saving changes.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmPickup(Locale currentLocale) async {
    try {
      // نفس منطق docId هنا
      final rawDocId = widget.report['docId'] ?? widget.report['id'];
      final docId = rawDocId?.toString();

      if (docId == null || docId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLocale.languageCode == 'ar'
                  ? 'تعذّر العثور على رقم البلاغ في النظام.'
                  : 'Could not find the report document ID.',
            ),
          ),
        );
        return;
      }

      final readyText = AppLocalizations.translate(
        'readyForPickup',
        currentLocale.languageCode,
      );

      await FirebaseFirestore.instance
          .collection('lostItems')
          .doc(docId)
          .update({
        'status': readyText,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _selectedStatus = readyText;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentLocale.languageCode == 'ar'
                ? 'تم تحديث الحالة إلى جاهز للاستلام.'
                : 'Status updated to Ready for Pickup.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentLocale.languageCode == 'ar'
                ? 'حدث خطأ أثناء تحديث الحالة.'
                : 'Error while updating status.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';
    final report = widget.report;

    if (_selectedStatus.isEmpty) {
      _selectedStatus = (report['status'] as String?) ??
          AppLocalizations.translate(
            'underReview',
            currentLocale.languageCode,
          );
    }

    final statuses = [
      AppLocalizations.translate('underReview', currentLocale.languageCode),
      AppLocalizations.translate(
          'preliminaryMatch', currentLocale.languageCode),
      AppLocalizations.translate('readyForPickup', currentLocale.languageCode),
      AppLocalizations.translate('closed', currentLocale.languageCode),
    ];

    final String id = report['id']?.toString() ?? '';
    final String title = report['title']?.toString() ?? '';
    final String type = report['type']?.toString() ?? '-';
    final String color = report['color']?.toString() ?? '-';
    final String description = report['description']?.toString() ?? '-';
    final String reportLocation = report['reportLocation']?.toString() ?? '-';
    final String foundLocation = report['foundLocation']?.toString() ?? '-';
    final String createdAt = report['createdAt']?.toString() ?? '-';
    final String updatedAt = report['updatedAt']?.toString() ?? '-';
    final String pinCode = report['pinCode']?.toString() ?? '';
    final String reporterName = report['reporterName']?.toString() ?? '-';
    final String reporterPhone =
        report['reporterPhone']?.toString() ??
            report['reporterNumber']?.toString() ??
            '-';
    final String? imagePath = report['imagePath'] as String?;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: widget.mainGreen,
          foregroundColor: Colors.white,
          title: Text(
            '${AppLocalizations.translate('reportDetailsTitle', currentLocale.languageCode)} #$id',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (imagePath != null && imagePath.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imagePath,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 180,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey.shade100,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),
                              color: Colors.grey.shade100,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: widget.mainGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${AppLocalizations.translate('reportNumber', currentLocale.languageCode)}: $id',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),

                        const SizedBox(height: 16),

                        _InfoRow(
                          label: currentLocale.languageCode == 'ar'
                              ? 'اسم المبلِّغ'
                              : 'Reporter Name',
                          value: reporterName,
                        ),
                        _InfoRow(
                          label: currentLocale.languageCode == 'ar'
                              ? 'رقم المبلِّغ'
                              : 'Reporter Phone',
                          value: reporterPhone,
                        ),
                        _InfoRow(
                          label: AppLocalizations.translate(
                              'type', currentLocale.languageCode),
                          value: type,
                        ),
                        _InfoRow(
                          label: AppLocalizations.translate(
                              'color', currentLocale.languageCode),
                          value: color,
                        ),
                        _InfoRow(
                          label: AppLocalizations.translate(
                              'reportLocation', currentLocale.languageCode),
                          value: reportLocation,
                        ),
                        _InfoRow(
                          label: AppLocalizations.translate(
                              'foundLocation', currentLocale.languageCode),
                          value: foundLocation,
                        ),
                        _InfoRow(
                          label: AppLocalizations.translate(
                              'createdAt', currentLocale.languageCode),
                          value: createdAt,
                        ),
                        _InfoRow(
                          label: AppLocalizations.translate(
                              'updatedAt', currentLocale.languageCode),
                          value: updatedAt,
                        ),
                        _InfoRow(
                          label: 'PIN',
                          value: pinCode.isNotEmpty ? pinCode : '-',
                        ),

                        const SizedBox(height: 16),

                        Text(
                          AppLocalizations.translate(
                              'description', currentLocale.languageCode),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          textAlign:
                          isArabic ? TextAlign.right : TextAlign.left,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          AppLocalizations.translate(
                              'reportStatus', currentLocale.languageCode),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: statuses
                              .map(
                                (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            ),
                          )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedStatus = value;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.mainGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _saveChanges(currentLocale),
                          icon: const Icon(Icons.save),
                          label: Text(
                            AppLocalizations.translate(
                              'saveChanges',
                              currentLocale.languageCode,
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          AppLocalizations.translate(
                            'staffNotesInternal',
                            currentLocale.languageCode,
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 4,
                          textAlign:
                          isArabic ? TextAlign.right : TextAlign.left,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.translate(
                              'writeNotesPlaceholder',
                              currentLocale.languageCode,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              // مكان حفظ الملاحظات داخليًا (لو حابة نربطه بفايرستور نقدر نكتبه)
                            },
                            icon: const Icon(Icons.save_outlined),
                            label: Text(
                              AppLocalizations.translate(
                                'saveNotes',
                                currentLocale.languageCode,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Container(
                        //   padding: const EdgeInsets.all(12),
                        //   decoration: BoxDecoration(
                        //     color: Colors.white,
                        //     borderRadius: BorderRadius.circular(12),
                        //     border:
                        //     Border.all(color: Colors.grey.shade300),
                        //   ),
                        //   child: Column(
                        //     crossAxisAlignment: CrossAxisAlignment.start,
                        //     children: [
                        //       const Text(
                        //         'مطابقات مقترحة بواسطة الذكاء الاصطناعي (قريبًا)',
                        //         style: TextStyle(
                        //           fontSize: 15,
                        //           fontWeight: FontWeight.w600,
                        //         ),
                        //       ),
                        //       const SizedBox(height: 8),
                        //       Text(
                        //         'سيظهر هنا في المستقبل عناصر يُعتقد أنها تطابق هذا البلاغ، مع أزرار قبول / رفض.',
                        //         style: TextStyle(
                        //           fontSize: 13,
                        //           color: Colors.grey.shade800,
                        //         ),
                        //       ),
                        //       const SizedBox(height: 8),
                        //       Wrap(
                        //         spacing: 10,
                        //         children: [
                        //           OutlinedButton.icon(
                        //             onPressed: null,
                        //             icon: const Icon(Icons.check),
                        //             label: const Text('قبول المطابقة'),
                        //           ),
                        //           OutlinedButton.icon(
                        //             onPressed: null,
                        //             icon: const Icon(Icons.close),
                        //             label: const Text('رفض المطابقة'),
                        //           ),
                        //         ],
                        //       ),
                        //     ],
                        //   ),
                        // ),

                        const SizedBox(height: 16),

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: widget.mainGreen,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: widget.mainGreen),
                            ),
                          ),
                          onPressed: () => _confirmPickup(currentLocale),
                          icon: const Icon(Icons.verified_user_outlined),
                          label: Text(
                            AppLocalizations.translate(
                              'confirmDeliveryWithPin',
                              currentLocale.languageCode,
                            ),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
