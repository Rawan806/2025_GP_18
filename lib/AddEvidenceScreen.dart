import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddEvidenceScreen extends StatefulWidget {
  final String lostReportId;
  final Map<String, dynamic> lostReportData;

  const AddEvidenceScreen({
    super.key,
    required this.lostReportId,
    required this.lostReportData,
  });

  @override
  State<AddEvidenceScreen> createState() => _AddEvidenceScreenState();
}

class _AddEvidenceScreenState extends State<AddEvidenceScreen> {
  static const Color mainGreen = Color(0xFF243E36);
  static const Color beigeColor = Color(0xFFC3BFB0);
  static const Color borderBrown = Color(0xFF272525);

  final TextEditingController evidenceDescriptionController =
      TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController specialMarksController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _selectedEvidenceImage;
  bool _isSubmitting = false;

  InputDecoration _inputDeco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      suffixIcon: icon != null ? Icon(icon, color: mainGreen) : null,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderBrown, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: borderBrown, width: 2),
      ),
      border: OutlineInputBorder(borderSide: BorderSide(color: borderBrown)),
    );
  }

  Future<void> _pickEvidenceImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedEvidenceImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadEvidenceImage(File image) async {
    try {
      final fileName =
          'evidence_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading evidence image: $e');
      return null;
    }
  }

  Future<void> _submitEvidence() async {
    final currentLocale = Localizations.localeOf(context);

    if (evidenceDescriptionController.text.trim().isEmpty &&
        _selectedEvidenceImage == null &&
        brandController.text.trim().isEmpty &&
        specialMarksController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentLocale.languageCode == 'ar'
                ? 'أضيفي على الأقل صورة أو وصفًا أو علامة مميزة'
                : 'Please add at least an image, description, or special mark',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? evidenceImageUrl;

      if (_selectedEvidenceImage != null) {
        evidenceImageUrl = await _uploadEvidenceImage(_selectedEvidenceImage!);
      }

      await FirebaseFirestore.instance
          .collection('lostItems')
          .doc(widget.lostReportId)
          .update({
            'evidenceImagePath': evidenceImageUrl ?? '',
            'evidenceDescription': evidenceDescriptionController.text.trim(),
            'evidenceBrand': brandController.text.trim(),
            'evidenceSpecialMarks': specialMarksController.text.trim(),
            'status': 'waiting_for_staff_review',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentLocale.languageCode == 'ar'
                ? 'تم إرسال الأدلة بنجاح'
                : 'Evidence submitted successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    evidenceDescriptionController.dispose();
    brandController.dispose();
    specialMarksController.dispose();
    super.dispose();
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
            isArabic ? 'إضافة أدلة' : 'Add Evidence',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isArabic
                    ? 'أضيفي صورة أو وصفًا أدق أو علامات مميزة لمساعدة الموظف على التحقق.'
                    : 'Add an image, a more detailed description, or special marks to help staff verify ownership.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              if (_selectedEvidenceImage != null) ...[
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: mainGreen, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _selectedEvidenceImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              OutlinedButton.icon(
                onPressed: _pickEvidenceImage,
                icon: Icon(
                  _selectedEvidenceImage == null ? Icons.upload : Icons.edit,
                  color: mainGreen,
                ),
                label: Text(
                  isArabic ? 'إرفاق صورة' : 'Attach Image',
                  style: TextStyle(color: mainGreen),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: mainGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: evidenceDescriptionController,
                maxLines: 4,
                decoration: _inputDeco(
                  isArabic ? 'وصف إضافي' : 'Additional Description',
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: brandController,
                decoration: _inputDeco(isArabic ? 'العلامة التجارية' : 'Brand'),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: specialMarksController,
                maxLines: 3,
                decoration: _inputDeco(
                  isArabic ? 'علامات مميزة' : 'Special Marks',
                ),
              ),
              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitEvidence,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isArabic ? 'إرسال الأدلة' : 'Submit Evidence',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
