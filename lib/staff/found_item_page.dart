// lib/staff/found_item_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../AI_services/ai_suggester.dart';
import '../AI_services/found_item_service.dart';

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
  List<String> _typeChips = []; // بدائل فقط
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
      borderSide:
      BorderSide(color: borderBrown.withOpacity(0.7), width: 1.2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
      BorderSide(color: borderBrown.withOpacity(0.7), width: 1.2),
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

      // the labels
      final suggestions = res
          .map((m) => (m['label'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();

      // catch the color
      String? aiColor;
      for (final m in res) {
        if (m['color'] is String) {
          aiColor = m['color'] as String;
          break;
        }
      }

      // new method
      setState(() {
        // 1) أفضل اقتراح يروح مباشرة في حقل الـ type لو كان الحقل فاضي
        if (suggestions.isNotEmpty && _typeCtrl.text.trim().isEmpty) {
          _typeCtrl.text = suggestions.first;
        }

        // 2) البدائل: أولهم تم استخدامه بالفعل، فنبدأ من الثاني، وبحد أقصى 2
        if (suggestions.length > 1) {
          _typeChips = suggestions.skip(1).take(2).toList();
        } else {
          _typeChips = [];
        }

        // 3) اللون: تعبية الحقل لو فاضي + chip واحدة
        _colorSuggest = aiColor;
        if (aiColor != null && _colorCtrl.text.trim().isEmpty) {
          _colorCtrl.text = aiColor;
        }
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
    if (_image == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please add a photo')));
      return;
    }
    if (_typeCtrl.text.trim().isEmpty ||
        _colorCtrl.text.trim().isEmpty ||
        _foundLocCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Type/Color/Location are required')));
      return;
    }

    setState(() => _busy = true);
    try {
      final url = await _service.uploadImage(_image!);
      await _service.saveFoundItem(
        type: _typeCtrl.text.trim(),
        color: _colorCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        foundLocation: _foundLocCtrl.text.trim(),
        foundAt: _foundAt,
        storageLocation: _storageLocCtrl.text.trim(),
        imageUrl: url,
        aiTypes: _typeChips,
        aiColor: _colorSuggest,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Saved successfully'),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Save failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Register Found Item',
            style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _image != null ? _runAI : null,
            tooltip: 'Re-run AI',
          ),
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
                          ? DecorationImage(
                        image: FileImage(_image!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: _image == null
                        ? const Center(child: Text('No image selected'))
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Camera'),
                        onPressed: () => _pick(true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo),
                        label: const Text('Gallery'),
                        onPressed: () => _pick(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_typeChips.isNotEmpty) ...[
                  const Text(
                    'Suggested types (alternatives):',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Wrap(
                    spacing: 8,
                    children: _typeChips
                        .map(
                          (t) => ActionChip(
                        label: Text(t),
                        onPressed: () => _typeCtrl.text = t,
                      ),
                    )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                ],

                if (_colorSuggest != null) ...[
                  const Text(
                    'Suggested color:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Wrap(
                    children: [
                      ActionChip(
                        label: Text(_colorSuggest!),
                        onPressed: () => _colorCtrl.text = _colorSuggest!,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                TextField(
                  controller: _typeCtrl,
                  decoration:
                  _dec('Item type (e.g., wallet, phone, backpack)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _colorCtrl,
                  decoration: _dec('Color'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descCtrl,
                  decoration:
                  _dec('Description / distinctive marks'),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _foundLocCtrl,
                  decoration: _dec('Found location (area/desk)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _storageLocCtrl,
                  decoration:
                  _dec('Storage location (office shelf/bin)'),
                ),
                const SizedBox(height: 10),

                OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: Text('Found time: ${_foundAt.toLocal()}'),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _foundAt,
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 30)),
                      lastDate:
                      DateTime.now().add(const Duration(days: 1)),
                    );
                    if (d == null) return;
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_foundAt),
                    );
                    if (t == null) return;
                    setState(
                          () => _foundAt = DateTime(
                        d.year,
                        d.month,
                        d.day,
                        t.hour,
                        t.minute,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainGreen,
                    ),
                    onPressed: _busy ? null : _save,
                    child: const Text(
                      'Save',
                      style:
                      TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
