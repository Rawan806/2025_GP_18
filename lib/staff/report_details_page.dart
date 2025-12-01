import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';
    final report = widget.report;
    
    if (_selectedStatus.isEmpty) {
      _selectedStatus = widget.report['status'] as String? ?? AppLocalizations.translate('underReview', currentLocale.languageCode);
    }
    
    final _statuses = [
      AppLocalizations.translate('pending', currentLocale.languageCode),
      AppLocalizations.translate('underReview', currentLocale.languageCode),
      AppLocalizations.translate('matched', currentLocale.languageCode),
      AppLocalizations.translate('closed', currentLocale.languageCode),
    ];

    final String id = report['id'] ?? '';
    final String title = report['title'] ?? '';
    final String type = report['type'] ?? '-';
    final String color = report['color'] ?? '-';
    final String description = report['description'] ?? '-';
    final String reportLocation = report['reportLocation'] ?? '-';
    final String foundLocation = report['foundLocation'] ?? '-';
    final String createdAt = report['createdAt'] ?? '-';
    final String updatedAt = report['updatedAt'] ?? '-';
    final String? imagePath = report['imagePath'] as String?;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: widget.mainGreen,
          foregroundColor: Colors.white,
          title: Text(
            '${AppLocalizations.translate('reportDetailsTitle', currentLocale.languageCode)} #$id',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // نفس خلفية الهوم بيج
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
                  // كارد أساسي
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
                        // صورة العنصر
                        if (imagePath != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              imagePath,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
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

                        _InfoRow(label: AppLocalizations.translate('type', currentLocale.languageCode), value: type),
                        _InfoRow(label: AppLocalizations.translate('color', currentLocale.languageCode), value: color),
                        _InfoRow(label: AppLocalizations.translate('reportLocation', currentLocale.languageCode), value: reportLocation),
                        _InfoRow(label: AppLocalizations.translate('foundLocation', currentLocale.languageCode), value: foundLocation),
                        _InfoRow(label: AppLocalizations.translate('createdAt', currentLocale.languageCode), value: createdAt),
                        _InfoRow(label: AppLocalizations.translate('updatedAt', currentLocale.languageCode), value: updatedAt),

                        const SizedBox(height: 16),

                        Text(
                          AppLocalizations.translate('description', currentLocale.languageCode),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 14),
                        ),

                        const SizedBox(height: 20),

                        // الحالة
                        Text(
                          AppLocalizations.translate('reportStatus', currentLocale.languageCode),
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
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _statuses
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
                            // TODO: اربطي هنا بالتحديث في قاعدة البيانات
                          },
                        ),

                        const SizedBox(height: 20),

                        // زر طلب أدلة إضافية
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.mainGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            // TODO: افتحي شاشة/دايلوج لطلب أدلة إضافية من المبلّغ
                          },
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(
                            AppLocalizations.translate('requestAdditionalEvidence', currentLocale.languageCode),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ملاحظات الموظف
                        Text(
                          AppLocalizations.translate('staffNotesInternal', currentLocale.languageCode),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 4,
                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.translate('writeNotesPlaceholder', currentLocale.languageCode),
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
                              // TODO: حفظ الملاحظات في Firestore مثلاً
                            },
                            icon: const Icon(Icons.save_outlined),
                            label: Text(AppLocalizations.translate('saveNotes', currentLocale.languageCode)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // (Future) AI matches
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'مطابقات مقترحة بواسطة الذكاء الاصطناعي (قريبًا)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'سيظهر هنا في المستقبل قائمة بعناصر مفقودة/معثور عليها '
                                    'يعتقد النموذج أنها تطابق هذا البلاغ، مع أزرار قبول / رفض.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(Icons.check),
                                    label: const Text('قبول المطابقة'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(Icons.close),
                                    label: const Text('رفض المطابقة'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // (Future) تأكيد التسليم بالـ PIN
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
                          onPressed: () {
                            // TODO: مستقبلاً افتحي شاشة إدخال PIN لتأكيد التسليم
                          },
                          icon: const Icon(Icons.verified_user_outlined),
                          label: Text(
                            AppLocalizations.translate('confirmDeliveryWithPin', currentLocale.languageCode),
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
