import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StaffHandoverScreen extends StatefulWidget {
  final Map<String, dynamic> lostReportData;

  const StaffHandoverScreen({
    super.key,
    required this.lostReportData,
  });

  @override
  State<StaffHandoverScreen> createState() => _StaffHandoverScreenState();
}

class _StaffHandoverScreenState extends State<StaffHandoverScreen> {
  static const Color mainGreen = Color(0xFF243E36);
  static const Color beigeColor = Color(0xFFC3BFB0);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool disclaimerAccepted = false;
  bool isLoading = false;
  bool formSubmitted = false;

  @override
  void initState() {
    super.initState();
    formSubmitted = widget.lostReportData['handoverFormSubmitted'] == true;
  }

  @override
  void dispose() {
    nameController.dispose();
    idController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  String _t(String ar, String en) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? ar : en;
  }

  String _getImageUrl() {
    final possibleKeys = [
      'matchedFoundImagePath',
      'matchedFoundImageUrl',
      'matchedImageUrl',
      'imagePath',
      'imageUrl',
      'photoUrl',
    ];

    for (final key in possibleKeys) {
      final value = (widget.lostReportData[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }

    return '';
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: mainGreen),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: mainGreen, width: 2),
      ),
    );
  }

  Future<void> submitForm() async {
    if (nameController.text.trim().isEmpty ||
        idController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      _snack(
        _t('يرجى تعبئة جميع البيانات', 'Please fill all fields'),
        Colors.orange,
      );
      return;
    }

    if (!disclaimerAccepted) {
      _snack(
        _t('يرجى قبول التعهد', 'Please accept the disclaimer'),
        Colors.orange,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final docId = (widget.lostReportData['docId'] ?? '').toString();

      if (docId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('lostItems').doc(docId).update({
          'handoverFormSubmitted': true,
          'handoverFormSubmittedAt': FieldValue.serverTimestamp(),
          'recipientName': nameController.text.trim(),
          'recipientId': idController.text.trim(),
          'recipientPhone': phoneController.text.trim(),
          'disclaimerAccepted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        formSubmitted = true;
        widget.lostReportData['handoverFormSubmitted'] = true;
      });

      _snack(
        _t(
          'تم إرسال النموذج، يمكنك الآن عرض رمز التسليم',
          'Form submitted. You can now view your PIN',
        ),
        Colors.green,
      );
    } catch (e) {
      _snack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final title = (widget.lostReportData['title'] ??
            widget.lostReportData['type'] ??
            widget.lostReportData['itemName'] ??
            '')
        .toString();

    final pin = (widget.lostReportData['pinCode'] ??
            widget.lostReportData['handoverPin'] ??
            '')
        .toString();

    final image = _getImageUrl();

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: beigeColor,
        appBar: AppBar(
          backgroundColor: mainGreen,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(_t('نموذج التسليم', 'Handover Form')),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _t('العنصر جاهز للاستلام', 'Item Ready for Handover'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: mainGreen,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (image.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            image,
                            height: 190,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          ),
                        )
                      else
                        _placeholder(),

                      const SizedBox(height: 16),

                      if (title.isNotEmpty)
                        Text(
                          '${_t('العنصر', 'Item')}: $title',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                      const SizedBox(height: 20),

                      if (formSubmitted) ...[
                        Text(
                          _t('رمز التسليم الخاص بك', 'Your Handover PIN'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: mainGreen,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            pin.isEmpty ? '------' : pin,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              letterSpacing: 4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _t(
                            'يرجى إظهار هذا الرمز للموظف عند الاستلام.',
                            'Please show this PIN to the staff during handover.',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            _t(
                              'يرجى تعبئة نموذج التسليم أولاً، وبعد الإرسال سيظهر لك رمز التسليم.',
                              'Please fill the handover form first. After submission, your PIN will appear.',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.orange[900],
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        Text(
                          _t('بيانات المستلم', 'Recipient Information'),
                          style: const TextStyle(
                            color: mainGreen,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: nameController,
                          decoration: _dec(
                            _t('الاسم الكامل', 'Full Name'),
                            Icons.person,
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: idController,
                          keyboardType: TextInputType.number,
                          decoration: _dec(
                            _t('رقم الهوية / الإقامة', 'National ID / Iqama'),
                            Icons.badge,
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _dec(
                            _t('رقم الجوال', 'Phone Number'),
                            Icons.phone,
                          ),
                        ),

                        const SizedBox(height: 14),

                        CheckboxListTile(
                          value: disclaimerAccepted,
                          onChanged: (value) {
                            setState(() => disclaimerAccepted = value ?? false);
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            _t(
                              'أقر بأنني سأحضر رمز التسليم وأثبت ملكيتي للعنصر عند الاستلام.',
                              'I confirm that I will present the PIN and prove ownership during handover.',
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        ElevatedButton.icon(
                          onPressed: submitForm,
                          icon: const Icon(Icons.send),
                          label: Text(_t('إرسال النموذج', 'Submit Form')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image_not_supported, size: 48),
    );
  }
}