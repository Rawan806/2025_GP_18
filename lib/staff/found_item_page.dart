// lib/staff/found_item_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../AI_services/ai_suggester.dart';
import '../AI_services/found_item_service.dart';
import '../l10n/app_localizations_helper.dart';

class FoundItemPage extends StatefulWidget {
  const FoundItemPage({super.key});
  @override
  State<FoundItemPage> createState() => _FoundItemPageState();
}

class _FoundItemPageState extends State<FoundItemPage> {
  final Color mainGreen = const Color(0xFF243E36);
  final Color borderBrown = const Color(0xFF272525);

  final _typeCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _foundLocCtrl = TextEditingController();
  final _storageLocCtrl = TextEditingController();
  DateTime _foundAt = DateTime.now();

  final _ai = AISuggester();
  final _service = FoundItemService();
  final _picker = ImagePicker();

  File? _image;
  List<String> _typeChips = [];
  String? _colorSuggest;
  bool _busy = false;

  @override
  void dispose() {
    _typeCtrl.dispose();
    _colorCtrl.dispose();
    _descCtrl.dispose();
    _foundLocCtrl.dispose();
    _storageLocCtrl.dispose();
    _ai.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white.withOpacity(.88),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderBrown.withOpacity(0.7), width: 1.2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderBrown.withOpacity(0.7), width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderBrown, width: 1.6),
    ),
    labelStyle: TextStyle(color: borderBrown.withOpacity(0.85)),
  );

  Future<void> _pick(bool camera) async {
    final x = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() {
      _image = File(x.path);
      _typeChips = [];
      _colorSuggest = null;
    });
    await _runAI();
  }

  Future<void> _runAI() async {
    if (_image == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await _image!.readAsBytes();
      final res = await _ai.suggest(bytes);

      final suggestions = res
          .map((m) => (m['label'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();

      String? aiColor;
      for (final m in res) {
        if (m['color'] is String) {
          aiColor = m['color'] as String;
          break;
        }
      }

      setState(() {
        _typeChips =
        suggestions.length > 3 ? suggestions.take(3).toList() : suggestions;
        _colorSuggest = aiColor;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('AI error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final currentLocale = Localizations.localeOf(context);
    
    // التحقق من وجود الصورة
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.translate('pleaseAddPhoto', currentLocale.languageCode)))
      );
      return;
    }
    
    // التحقق من الحقول الأساسية
    if (_typeCtrl.text.trim().isEmpty ||
        _colorCtrl.text.trim().isEmpty ||
        _foundLocCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.translate('typeColorLocationRequired', currentLocale.languageCode)))
      );
      return;
    }
    
    // التحقق من أن الـ AI قد تم تشغيله (الأنواع المقترحة موجودة)
    if (_typeChips.isEmpty && _colorSuggest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for AI analysis to complete'))
      );
      return;
    }

    setState(() => _busy = true);
    
    try {
      // رفع الصورة إلى Firebase Storage
      final imageUrl = await _service.uploadImage(_image!);
      
      // إنشاء مستند جديد في Firestore
      final docRef = await FirebaseFirestore.instance.collection('foundItems').add({
        'title': _typeCtrl.text.trim(),
        'type': _typeCtrl.text.trim(),
        'color': _colorCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? 'No description provided' : _descCtrl.text.trim(),
        'foundLocation': _foundLocCtrl.text.trim(),
        'reportLocation': _foundLocCtrl.text.trim(), // نفس موقع العثور
        'storageLocation': _storageLocCtrl.text.trim().isEmpty ? 'Not specified' : _storageLocCtrl.text.trim(),
        'imagePath': imageUrl,
        'status': AppLocalizations.translate('underReview', currentLocale.languageCode),
        'date': _formatDateTime(_foundAt),
        'createdAt': _formatDateTime(DateTime.now()),
        'updatedAt': _formatDateTime(DateTime.now()),
        'foundAt': Timestamp.fromDate(_foundAt),
        'itemCategory': 'found', // للتمييز بين المفقودات والموجودات
      });
      
      // تحديث المستند بالـ ID الخاص به
      await docRef.update({'id': docRef.id});

      if (!mounted) return;
      final locale = Localizations.localeOf(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.translate('savedSuccessfully', locale.languageCode)), 
          backgroundColor: Colors.green
        ),
      );
      Navigator.pop(context);
      
    } catch (e) {
      if (!mounted) return;
      final locale = Localizations.localeOf(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.translate('saveFailed', locale.languageCode)}: $e'), 
          backgroundColor: Colors.red
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  
  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inDays == 0) {
      return 'اليوم - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'أمس - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(AppLocalizations.translate('registerFoundItem', currentLocale.languageCode), style: const TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _image != null ? _runAI : null, tooltip: AppLocalizations.translate('rerunAI', currentLocale.languageCode)),
          ],
      ),
      body: Stack(
        children: [
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 16/9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                      image: _image != null ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover) : null,
                    ),
                    child: _image == null ? Center(child: Text(AppLocalizations.translate('noImageSelected', currentLocale.languageCode))) : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.photo_camera), label: Text(AppLocalizations.translate('camera', currentLocale.languageCode)), onPressed: () => _pick(true))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.photo), label: Text(AppLocalizations.translate('gallery', currentLocale.languageCode)), onPressed: () => _pick(false))),
                  ],
                ),
                const SizedBox(height: 12),

                if (_typeChips.isNotEmpty) ...[
                  Text(AppLocalizations.translate('suggestedTypes', currentLocale.languageCode), style: const TextStyle(fontWeight: FontWeight.w600)),
                  Wrap(
                    spacing: 8,
                    children: _typeChips.map((t) => ActionChip(label: Text(t), onPressed: () => _typeCtrl.text = t)).toList(),
                  ),
                  const SizedBox(height: 8),
                ],

                if (_colorSuggest != null) ...[
                  Text(AppLocalizations.translate('suggestedColor', currentLocale.languageCode), style: const TextStyle(fontWeight: FontWeight.w600)),
                  Wrap(children: [ActionChip(label: Text(_colorSuggest!), onPressed: () => _colorCtrl.text = _colorSuggest!)],),
                  const SizedBox(height: 8),
                ],

                TextField(controller: _typeCtrl, decoration: _dec(AppLocalizations.translate('itemType', currentLocale.languageCode)), textAlign: isArabic ? TextAlign.right : TextAlign.left),
                const SizedBox(height: 10),
                TextField(controller: _colorCtrl, decoration: _dec(AppLocalizations.translate('color', currentLocale.languageCode)), textAlign: isArabic ? TextAlign.right : TextAlign.left),
                const SizedBox(height: 10),
                TextField(controller: _descCtrl, decoration: _dec(AppLocalizations.translate('description', currentLocale.languageCode)), maxLines: 3, textAlign: isArabic ? TextAlign.right : TextAlign.left),
                const SizedBox(height: 10),
                TextField(controller: _foundLocCtrl, decoration: _dec(AppLocalizations.translate('foundLocation', currentLocale.languageCode)), textAlign: isArabic ? TextAlign.right : TextAlign.left),
                const SizedBox(height: 10),
                TextField(controller: _storageLocCtrl, decoration: _dec(AppLocalizations.translate('storageLocation', currentLocale.languageCode)), textAlign: isArabic ? TextAlign.right : TextAlign.left),
                const SizedBox(height: 10),

                OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: Text('${AppLocalizations.translate('foundTime', currentLocale.languageCode)}: ${_foundAt.toLocal()}'),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _foundAt,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (d == null) return;
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_foundAt));
                    if (t == null) return;
                    setState(() => _foundAt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                  },
                ),

                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: mainGreen),
                    onPressed: _busy ? null : _save,
                    child: Text(AppLocalizations.translate('save', currentLocale.languageCode), style: const TextStyle(color: Colors.white, fontSize: 16)),
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
