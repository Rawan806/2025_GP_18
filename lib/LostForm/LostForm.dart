import 'dart:io';
import 'dart:math'; //  لتوليد PIN عشوائي
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:wadiah_app/HomePage/HomePage.dart';
import '../l10n/app_localizations_helper.dart';

class LostForm extends StatefulWidget {
  const LostForm({super.key});

  @override
  State<LostForm> createState() => _LostFormState();
}

class _LostFormState extends State<LostForm> {
  final Color mainGreen = const Color(0xFF243E36);
  final Color beigeColor = const Color(0xFFC3BFB0);
  final Color borderBrown = const Color(0xFF272525);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController dateController = TextEditingController();
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController otherCategoryController = TextEditingController();

  DateTime? selectedDate;
  String? _selectedCategory;

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  bool _isUploading = false;

  // =============== Helpers ==================

  List<String> _getCategories(String languageCode) {
    return [
      AppLocalizations.translate('electronics', languageCode),
      AppLocalizations.translate('jewelry', languageCode),
      AppLocalizations.translate('bags', languageCode),
      AppLocalizations.translate('documentsCards', languageCode),
      AppLocalizations.translate('other', languageCode),
    ];
  }

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
      border: OutlineInputBorder(
        borderSide: BorderSide(color: borderBrown),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      return "اليوم - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } else if (diff.inDays == 1) {
      return "أمس - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } else {
      return "${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    }
  }

  //   PIN  من 6 أرقام
  String _generatePinCode() {
    final random = Random();
    final int value = 100000 + random.nextInt(900000); // من 100000 إلى 999999
    return value.toString();
  }

  // ================== Pickers ==============

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ar'),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          dateController.text =
              intl.DateFormat('yyyy-MM-dd – HH:mm').format(selectedDate!);
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // ============ Firebase Logic ==================

  Future<String?> _uploadImageToFirebase(File image) async {
    try {
      final String fileName =
          'lost_items/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef =
      FirebaseStorage.instance.ref().child(fileName);

      final UploadTask uploadTask = storageRef.putFile(image);
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    final currentLocale = Localizations.localeOf(context);
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate(
              'fillAllFields',
              currentLocale.languageCode,
            ),
          ),
        ),
      );
      return;
    }

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate(
              'pleaseSelectDateTime',
              currentLocale.languageCode,
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        imageUrl = await _uploadImageToFirebase(_selectedImage!);
        if (imageUrl == null) {
          throw Exception("Failed to upload image");
        }
      }

      final String finalCategory =
      _selectedCategory ==
          AppLocalizations.translate(
            'other',
            currentLocale.languageCode,
          )
          ? otherCategoryController.text.trim()
          : _selectedCategory!;

      final now = DateTime.now();

      //  توليد PIN
      final String pinCode = _generatePinCode();

      final docRef = await FirebaseFirestore.instance
          .collection('lostItems')
          .add({
        'title': itemNameController.text.trim(),
        'type': finalCategory,
        'category': finalCategory,
        'description': descriptionController.text.trim().isEmpty
            ? 'No description provided'
            : descriptionController.text.trim(),
        'reportLocation': 'User Report',
        'foundLocation': '',
        'imagePath': imageUrl ?? '',
        'status': 'قيد المراجعة',
        'date': _formatDateTime(selectedDate!),
        'lostDate': Timestamp.fromDate(selectedDate!),
        'createdAt': _formatDateTime(now),
        'updatedAt': _formatDateTime(now),
        'doc_num': DateTime.now().millisecondsSinceEpoch.toString(),
        'itemCategory': 'lost',
        'userId':  FirebaseAuth.instance.currentUser?.uid ?? 'current_user_id',
        'pinCode': pinCode,          //  PIN
      });

      // حفظ الـ id داخل الدوكيومنت نفسه
      await docRef.update({'id': docRef.id});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.translate('reportSubmitted', currentLocale.languageCode)}\nPIN: $pinCode',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  // ================== Lifecycle =============

  @override
  void dispose() {
    dateController.dispose();
    itemNameController.dispose();
    descriptionController.dispose();
    otherCategoryController.dispose();
    super.dispose();
  }

  // ================== UI ==================

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';
    final categories = _getCategories(currentLocale.languageCode);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: beigeColor,
        appBar: AppBar(
          backgroundColor: mainGreen,
          title: Text(
            AppLocalizations.translate(
              'reportForm',
              currentLocale.languageCode,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: dateController,
                  readOnly: true,
                  onTap: _pickDateTime,
                  decoration: _inputDeco(
                    AppLocalizations.translate(
                      'lostDateTime',
                      currentLocale.languageCode,
                    ),
                    icon: Icons.calendar_today,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppLocalizations.translate(
                    'pleaseSelectDateTime',
                    currentLocale.languageCode,
                  )
                      : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: itemNameController,
                  decoration: _inputDeco(
                    AppLocalizations.translate(
                      'lostItemName',
                      currentLocale.languageCode,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppLocalizations.translate(
                    'pleaseEnterItemName',
                    currentLocale.languageCode,
                  )
                      : null,
                ),
                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: _inputDeco(
                    AppLocalizations.translate(
                      'category',
                      currentLocale.languageCode,
                    ),
                  ),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(c),
                    ),
                  )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val;
                      if (_selectedCategory !=
                          AppLocalizations.translate(
                            'other',
                            currentLocale.languageCode,
                          )) {
                        otherCategoryController.clear();
                      }
                    });
                  },
                  validator: (v) => (v == null || v.isEmpty)
                      ? AppLocalizations.translate(
                    'pleaseSelectCategory',
                    currentLocale.languageCode,
                  )
                      : null,
                ),
                const SizedBox(height: 15),

                if (_selectedCategory ==
                    AppLocalizations.translate(
                      'other',
                      currentLocale.languageCode,
                    )) ...[
                  TextFormField(
                    controller: otherCategoryController,
                    decoration: _inputDeco(
                      AppLocalizations.translate(
                        'otherCategory',
                        currentLocale.languageCode,
                      ),
                    ),
                    validator: (v) =>
                    (_selectedCategory ==
                        AppLocalizations.translate(
                          'other',
                          currentLocale.languageCode,
                        ) &&
                        (v == null || v.trim().isEmpty))
                        ? AppLocalizations.translate(
                      'pleaseSpecifyCategory',
                      currentLocale.languageCode,
                    )
                        : null,
                  ),
                  const SizedBox(height: 15),
                ],

                if (_selectedImage != null) ...[
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: mainGreen, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(
                    _selectedImage == null ? Icons.upload : Icons.edit,
                    color: mainGreen,
                  ),
                  label: Text(
                    AppLocalizations.translate(
                      'attachPhotos',
                      currentLocale.languageCode,
                    ),
                    style: TextStyle(color: mainGreen),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: mainGreen),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  AppLocalizations.translate(
                    'photoNote',
                    currentLocale.languageCode,
                  ),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: _inputDeco(
                    AppLocalizations.translate(
                      'additionalDescription',
                      currentLocale.languageCode,
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isUploading ? null : _submitForm,
                  child: _isUploading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    AppLocalizations.translate(
                      'submitReport',
                      currentLocale.languageCode,
                    ),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
