import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
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

  List<String> _getCategories(String languageCode) {
    return [
      AppLocalizations.translate('electronics', languageCode),
      AppLocalizations.translate('jewelry', languageCode),
      AppLocalizations.translate('bags', languageCode),
      AppLocalizations.translate('documentsCards', languageCode),
      AppLocalizations.translate('other', languageCode),
    ];
  }

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

  @override
  void dispose() {
    dateController.dispose();
    itemNameController.dispose();
    descriptionController.dispose();
    otherCategoryController.dispose();
    super.dispose();
  }

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
            AppLocalizations.translate('reportForm', currentLocale.languageCode),
            style: const TextStyle(
              color: Colors.white,         //خليته ابيض اوضح
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
                decoration: _inputDeco(AppLocalizations.translate('lostDateTime', currentLocale.languageCode), icon: Icons.calendar_today),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppLocalizations.translate('pleaseSelectDateTime', currentLocale.languageCode)
                    : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: itemNameController,
                decoration: _inputDeco(AppLocalizations.translate('lostItemName', currentLocale.languageCode)),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppLocalizations.translate('pleaseEnterItemName', currentLocale.languageCode)
                    : null,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _inputDeco(AppLocalizations.translate('category', currentLocale.languageCode)),
                items: categories
                    .map((c) => DropdownMenuItem<String>(
                  value: c,
                  child: Text(c),
                ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
                    if (_selectedCategory != AppLocalizations.translate('other', currentLocale.languageCode)) {
                      otherCategoryController.clear();
                    }
                  });
                },
                validator: (v) =>
                (v == null || v.isEmpty) ? AppLocalizations.translate('pleaseSelectCategory', currentLocale.languageCode) : null,
              ),
              const SizedBox(height: 15),

              if (_selectedCategory == AppLocalizations.translate('other', currentLocale.languageCode)) ...[
                TextFormField(
                  controller: otherCategoryController,
                  decoration: _inputDeco(AppLocalizations.translate('otherCategory', currentLocale.languageCode)),
                  validator: (v) => (_selectedCategory == AppLocalizations.translate('other', currentLocale.languageCode) &&
                      (v == null || v.trim().isEmpty))
                      ? AppLocalizations.translate('pleaseSpecifyCategory', currentLocale.languageCode)
                      : null,
                ),
                const SizedBox(height: 15),
              ],

              OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.upload, color: mainGreen),
                label: Text(AppLocalizations.translate('attachPhotos', currentLocale.languageCode), style: TextStyle(color: mainGreen)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: mainGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                AppLocalizations.translate('photoNote', currentLocale.languageCode),
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
                decoration: _inputDeco(AppLocalizations.translate('additionalDescription', currentLocale.languageCode)),
              ),
              const SizedBox(height: 25),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  final valid = _formKey.currentState?.validate() ?? false;
                  if (!valid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.translate('fillAllFields', currentLocale.languageCode))),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.translate('reportSubmitted', currentLocale.languageCode)),
                      duration: const Duration(seconds: 1),
                    ),
                  );

                  Future.delayed(const Duration(seconds: 1), () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                          (route) => false,
                    );
                  });
                },
                child: Text(AppLocalizations.translate('submitReport', currentLocale.languageCode), style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
