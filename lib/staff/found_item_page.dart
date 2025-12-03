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
  List<String> _altTypes = [];
  String? _aiColor;
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
    fillColor: Colors.white.withOpacity(.9),
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
      _altTypes = [];
      _aiColor = null;
      _typeCtrl.clear();
      _colorCtrl.clear();
    });

    await _runAI();
  }

  Future<void> _runAI() async {
    if (_image == null) return;
    setState(() => _busy = true);

    try {
      final bytes = await _image!.readAsBytes();
      final res = await _ai.suggest(bytes);

      final allLabels = res
          .map((e) => (e['label'] ?? '').toString())
          .where((x) => x.isNotEmpty)
          .toList();

      String? detectedColor;
      for (final e in res) {
        if (e['color'] is String) {
          detectedColor = e['color'] as String;
          break;
        }
      }

      setState(() {
        if (allLabels.isNotEmpty && _typeCtrl.text.trim().isEmpty) {
          _typeCtrl.text = allLabels.first;
        }
        _altTypes =
        allLabels.length > 1 ? allLabels.skip(1).take(2).toList() : [];

        _aiColor = detectedColor;
        if (detectedColor != null && _colorCtrl.text.trim().isEmpty) {
          _colorCtrl.text = detectedColor;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final locale = Localizations.localeOf(context);

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.translate('pleaseAddPhoto', locale.languageCode))),
      );
      return;
    }

    if (_typeCtrl.text.trim().isEmpty ||
        _colorCtrl.text.trim().isEmpty ||
        _foundLocCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.translate('typeColorLocationRequired', locale.languageCode))),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      final imageUrl = await _service.uploadImage(_image!);

      final doc = await FirebaseFirestore.instance.collection('foundItems').add({
        'title': _typeCtrl.text.trim(),
        'type': _typeCtrl.text.trim(),
        'color': _colorCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? '-' : _descCtrl.text.trim(),
        'foundLocation': _foundLocCtrl.text.trim(),
        'storageLocation': _storageLocCtrl.text.trim().isEmpty ? '-' : _storageLocCtrl.text.trim(),
        'reportLocation': _foundLocCtrl.text.trim(),
        'imagePath': imageUrl,
        'status': AppLocalizations.translate('underReview', locale.languageCode),
        'date': _format(_foundAt, locale.languageCode),
        'createdAt': _format(DateTime.now(), locale.languageCode),
        'updatedAt': _format(DateTime.now(), locale.languageCode),
        'foundAt': Timestamp.fromDate(_foundAt),
        'itemCategory': 'found',
        'aiSuggestions': _altTypes,
        'aiColor': _aiColor,
      });

      await doc.update({'id': doc.id});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.translate('savedSuccessfully', locale.languageCode)),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.translate('saveFailed', locale.languageCode)}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _format(DateTime dt, String lang) {
    final h = dt.hour.toString();
    final m = dt.minute.toString().padLeft(2, '0');

    if (lang == 'ar') {
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inDays == 0) {
        return 'اليوم - $h:$m';
      } else if (diff.inDays == 1) {
        return 'أمس - $h:$m';
      }
      return '${dt.day}/${dt.month}/${dt.year} - $h:$m';
    }

    return '${dt.year}-${dt.month}-${dt.day} • $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            AppLocalizations.translate('registerFoundItem', locale.languageCode),
            style: const TextStyle(color: Colors.black87),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _image != null ? _runAI : null,
              tooltip: AppLocalizations.translate('rerunAI', locale.languageCode),
            )
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
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                        image: _image != null
                            ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _image == null
                          ? Center(
                        child: Text(AppLocalizations.translate('noImageSelected', locale.languageCode)),
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_camera),
                          label: Text(AppLocalizations.translate('camera', locale.languageCode)),
                          onPressed: () => _pick(true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo),
                          label: Text(AppLocalizations.translate('gallery', locale.languageCode)),
                          onPressed: () => _pick(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_altTypes.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.translate('suggestedTypes', locale.languageCode),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Wrap(
                          spacing: 8,
                          children: _altTypes
                              .map((t) => ActionChip(
                            label: Text(t),
                            onPressed: () => _typeCtrl.text = t,
                          ))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),

                  if (_aiColor != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.translate('suggestedColor', locale.languageCode),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Wrap(
                          children: [
                            ActionChip(
                              label: Text(_aiColor!),
                              onPressed: () => _colorCtrl.text = _aiColor!,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),

                  TextField(
                    controller: _typeCtrl,
                    decoration: _dec(AppLocalizations.translate('itemType', locale.languageCode)),
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _colorCtrl,
                    decoration: _dec(AppLocalizations.translate('color', locale.languageCode)),
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: _dec(AppLocalizations.translate('description', locale.languageCode)),
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _foundLocCtrl,
                    decoration: _dec(AppLocalizations.translate('foundLocation', locale.languageCode)),
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _storageLocCtrl,
                    decoration: _dec(AppLocalizations.translate('storageLocation', locale.languageCode)),
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      '${AppLocalizations.translate('foundTime', locale.languageCode)}: ${_format(_foundAt, locale.languageCode)}',
                    ),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _foundAt,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (d == null) return;

                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_foundAt),
                      );
                      if (t == null) return;

                      setState(() {
                        _foundAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: mainGreen),
                      onPressed: _busy ? null : _save,
                      child: Text(
                        AppLocalizations.translate('save', locale.languageCode),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
