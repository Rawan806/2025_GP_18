import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
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

  final TextEditingController specialMarksController = TextEditingController();

  final TextEditingController otherElectronicsBrandController =
  TextEditingController();
  final TextEditingController bagBrandController = TextEditingController();
  final TextEditingController watchBrandController = TextEditingController();
  final TextEditingController glassesBrandController = TextEditingController();

  DateTime? selectedDate;
  String? _selectedCategory;
  String? _selectedColor;

  String? _selectedJewelrySubtype;

  String? _selectedElectronicsBrand;
  String? _screenBroken;
  String? _coverColor;

  String? _hasCards;
  String? _bagSize;

  String? _documentType;
  String? _hasCover;
  String? _coverDocumentColor;

  String? _jewelryMaterial;
  String? _hasStone;

  String? _watchType;
  String? _watchBandType;
  String? _watchScreenBroken;
  String? _watchShape;
  String? _watchFaceColor;

  String? _glassesType;
  String? _glassesFrameColor;

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  bool _isUploading = false;

  static const String baseUrl = 'http://10.0.2.2:8000';

  List<String> _getCategories(String languageCode) {
    return [
      AppLocalizations.translate('electronics', languageCode),
      AppLocalizations.translate('jewelry', languageCode),
      AppLocalizations.translate('bags', languageCode),
      AppLocalizations.translate('documentsCards', languageCode),
      AppLocalizations.translate('other', languageCode),
    ];
  }

  List<String> _getColors() {
    return [
      'أحمر',
      'برتقالي',
      'أصفر',
      'أخضر',
      'سماوي',
      'أزرق',
      'بنفسجي',
      'بني',
      'أسود',
      'أبيض',
    ];
  }

  List<String> _coverColors() => ['لا يوجد', ..._getColors()];

  bool _isElectronics(String languageCode) =>
      _selectedCategory == AppLocalizations.translate('electronics', languageCode);

  bool _isBags(String languageCode) =>
      _selectedCategory == AppLocalizations.translate('bags', languageCode);

  bool _isDocuments(String languageCode) =>
      _selectedCategory == AppLocalizations.translate('documentsCards', languageCode);

  bool _isJewelry(String languageCode) =>
      _selectedCategory == AppLocalizations.translate('jewelry', languageCode);

  List<String> _yesNoOptions() => ['نعم', 'لا'];
  List<String> _bagSizes() => ['صغيرة', 'متوسطة', 'كبيرة'];
  List<String> _documentTypes() => ['بطاقة', 'جواز سفر', 'رخصة', 'مستند'];
  List<String> _jewelrySubtypes() => ['خاتم', 'سوار', 'سلسلة', 'ساعة', 'نظارة'];
  List<String> _jewelryMaterials() => ['ذهب', 'فضة', 'غير ذلك'];
  List<String> _watchTypes() => ['ذكية', 'عادية'];
  List<String> _watchBandTypes() => ['معدني', 'جلد', 'سيليكون'];
  List<String> _watchShapes() => ['دائرية', 'مربعة'];
  List<String> _glassesTypes() => ['شمسية', 'طبية'];

  List<String> _electronicsBrands() => [
    'Apple',
    'Samsung',
    'Huawei',
    'Xiaomi',
    'Oppo',
    'Realme',
    'Nokia',
    'HP',
    'Dell',
    'Lenovo',
    'Asus',
    'Acer',
    'Sony',
    'JBL',
    'أخرى',
  ];

  bool get _isWatchSubtype => _selectedJewelrySubtype == 'ساعة';
  bool get _isGlassesSubtype => _selectedJewelrySubtype == 'نظارة';
  bool get _isRegularJewelrySubtype =>
      _selectedJewelrySubtype == 'خاتم' ||
          _selectedJewelrySubtype == 'سوار' ||
          _selectedJewelrySubtype == 'سلسلة';

  void _resetDynamicFields() {
    _selectedJewelrySubtype = null;
    _selectedElectronicsBrand = null;

    otherElectronicsBrandController.clear();
    bagBrandController.clear();
    watchBrandController.clear();
    glassesBrandController.clear();

    _screenBroken = null;
    _coverColor = null;
    _hasCards = null;
    _bagSize = null;
    _documentType = null;
    _hasCover = null;
    _coverDocumentColor = null;
    _jewelryMaterial = null;
    _hasStone = null;
    _watchType = null;
    _watchBandType = null;
    _watchScreenBroken = null;
    _watchShape = null;
    _watchFaceColor = null;
    _glassesType = null;
    _glassesFrameColor = null;
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
      border: OutlineInputBorder(borderSide: BorderSide(color: borderBrown)),
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

  String _generatePinCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final now = DateTime.now();
    final chosen = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (chosen.isAfter(now)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate(
              'pleaseSelectValidPastDateTime',
              Localizations.localeOf(context).languageCode,
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      selectedDate = chosen;
      dateController.text =
          intl.DateFormat('yyyy-MM-dd – HH:mm').format(selectedDate!);
    });
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

  Future<String?> _uploadImageToFirebase(File image) async {
    try {
      final fileName = 'lost_items/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      final snapshot = await storageRef.putFile(image);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _triggerIndexing({
    required String docId,
    required String collection,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/index-item'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'docId': docId,
        'collection': collection,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Indexing failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> _searchMatches({
    required String docId,
    required String collection,
    int topK = 5,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'docId': docId,
        'collection': collection,
        'top_k': topK,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Search failed: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid search response');
    }

    return decoded;
  }

  bool _hasGoodMatch(List<Map<String, dynamic>> matches) {
    if (matches.isEmpty) return false;
    final label = (matches.first['match_label'] ?? '').toString();
    return label == 'strong_match' || label == 'potential_match';
  }

  String _resolvedBrand(String languageCode) {
    if (_isElectronics(languageCode)) {
      if (_selectedElectronicsBrand == 'أخرى') {
        return otherElectronicsBrandController.text.trim().toLowerCase();
      }
      return (_selectedElectronicsBrand ?? '').trim().toLowerCase();
    }

    if (_isBags(languageCode)) {
      return bagBrandController.text.trim().toLowerCase();
    }

    if (_isJewelry(languageCode) && _isWatchSubtype) {
      return watchBrandController.text.trim().toLowerCase();
    }

    if (_isJewelry(languageCode) && _isGlassesSubtype) {
      return glassesBrandController.text.trim().toLowerCase();
    }

    return '';
  }

  String _resolvedSubtype(String languageCode) {
    if (_isJewelry(languageCode)) return _selectedJewelrySubtype ?? '';
    return '';
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

    if (selectedDate!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate(
              'pleaseSelectValidPastDateTime',
              currentLocale.languageCode,
            ),
          ),
        ),
      );
      return;
    }

    if (_selectedColor == null || _selectedColor!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار اللون')),
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

      final finalCategory =
      _selectedCategory ==
          AppLocalizations.translate('other', currentLocale.languageCode)
          ? otherCategoryController.text.trim()
          : _selectedCategory!;

      final now = DateTime.now();
      final pinCode = _generatePinCode();
      final brand = _resolvedBrand(currentLocale.languageCode);
      final subtype = _resolvedSubtype(currentLocale.languageCode);
      final specialMarks = specialMarksController.text.trim();

      final docRef =
      await FirebaseFirestore.instance.collection('lostItems').add({
        'title': itemNameController.text.trim(),
        'type': finalCategory,
        'category': finalCategory,
        'subtype': subtype,
        'color': _selectedColor ?? '',

        'brand': brand,
        'specialMarks': specialMarks,

        'description': descriptionController.text.trim().isEmpty
            ? 'No description provided'
            : descriptionController.text.trim(),

        'reportLocation': 'User Report',
        'foundLocation': 'User Report',

        'imagePath': imageUrl ?? '',
        'imageUrl': imageUrl ?? '',

        'status': 'submitted',
        'date': _formatDateTime(selectedDate!),
        'lostDate': Timestamp.fromDate(selectedDate!),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),

        'doc_num': DateTime.now().millisecondsSinceEpoch.toString(),
        'itemCategory': 'lost',
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'current_user_id',
        'pinCode': pinCode,

        'screenBroken': _screenBroken ?? '',
        'coverColor': _coverColor ?? '',
        'hasCards': _hasCards ?? '',
        'bagSize': _bagSize ?? '',
        'documentType': _documentType ?? '',
        'hasCover': _hasCover ?? '',
        'coverDocumentColor': _coverDocumentColor ?? '',
        'jewelryMaterial': _jewelryMaterial ?? '',
        'hasStone': _hasStone ?? '',
        'watchType': _watchType ?? '',
        'watchBandType': _watchBandType ?? '',
        'watchScreenBroken': _watchScreenBroken ?? '',
        'watchShape': _watchShape ?? '',
        'watchFaceColor': _watchFaceColor ?? '',
        'glassesType': _glassesType ?? '',
        'glassesFrameColor': _glassesFrameColor ?? '',

        'dynamicAttributes': {
          'brand': brand,
          'subtype': subtype,
          'specialMarks': specialMarks,
          'screenBroken': _screenBroken ?? '',
          'coverColor': _coverColor ?? '',
          'hasCards': _hasCards ?? '',
          'bagSize': _bagSize ?? '',
          'documentType': _documentType ?? '',
          'hasCover': _hasCover ?? '',
          'coverDocumentColor': _coverDocumentColor ?? '',
          'jewelryMaterial': _jewelryMaterial ?? '',
          'hasStone': _hasStone ?? '',
          'watchType': _watchType ?? '',
          'watchBandType': _watchBandType ?? '',
          'watchScreenBroken': _watchScreenBroken ?? '',
          'watchShape': _watchShape ?? '',
          'watchFaceColor': _watchFaceColor ?? '',
          'glassesType': _glassesType ?? '',
          'glassesFrameColor': _glassesFrameColor ?? '',
        },

        'matchedFoundItemId': null,
        'matchedFoundImagePath': '',
        'matchedFoundTitle': '',
        'matchedFoundType': '',
        'matchedFoundColor': '',
        'matchedFoundLocation': '',
        'matchedFoundSimilarity': null,

        'evidenceImagePath': '',
        'evidenceDescription': '',

        'aiSuggestions': [],
        'aiColor': '',

        'topMatches': [],
        'potentialMatchesCount': 0,
        'candidatePoolSize': 0,
        'searchedIn': '',
        'topScore': null,
        'avgTop5Score': null,
        'searchTimeMs': null,
        'searchError': '',

        'docId': '',
        'id': '',
        'isIndexed': false,
        'indexStatus': 'pending',
        'indexError': '',
      });

      await docRef.update({
        'id': docRef.id,
        'docId': docRef.id,
      });

      try {
        await _triggerIndexing(
          docId: docRef.id,
          collection: 'lostItems',
        );
      } catch (e) {
        await docRef.update({
          'isIndexed': false,
          'indexStatus': 'failed',
          'indexError': e.toString(),
        });
        debugPrint('Indexing error: $e');
      }

      try {
        final searchResponse = await _searchMatches(
          docId: docRef.id,
          collection: 'lostItems',
        );

        final rawResults =
        (searchResponse['results'] as List<dynamic>? ?? []);

        final List<Map<String, dynamic>> topMatches = rawResults.map((e) {
          final item = Map<String, dynamic>.from(e as Map);
          return {
            'docId': item['docId'] ?? '',
            'collection': item['collection'] ?? '',
            'imageUrl': item['imageUrl'] ?? '',
            'similarity': item['similarity'] ?? 0.0,
            'match_label': item['match_label'] ?? '',
            'type': item['type'] ?? '',
            'color': item['color'] ?? '',
            'location': item['location'] ?? '',
            'status': item['status'] ?? '',
          };
        }).toList();

        final hasGoodMatch = _hasGoodMatch(topMatches);
        final Map<String, dynamic>? bestMatch =
        topMatches.isNotEmpty ? topMatches.first : null;

        await docRef.update({
          'topMatches': topMatches,
          'potentialMatchesCount':
          searchResponse['potential_matches_count'] ?? 0,
          'candidatePoolSize': searchResponse['candidate_pool_size'] ?? 0,
          'searchedIn': searchResponse['searched_in'] ?? 'foundItems',
          'topScore': searchResponse['top_score'],
          'avgTop5Score': searchResponse['avg_top5_score'],
          'searchTimeMs': searchResponse['search_time_ms'],
          'searchError': '',

          'matchedFoundItemId':
          hasGoodMatch && bestMatch != null ? bestMatch['docId'] : null,
          'matchedFoundImagePath':
          hasGoodMatch && bestMatch != null
              ? (bestMatch['imageUrl'] ?? '')
              : '',
          'matchedFoundTitle':
          hasGoodMatch && bestMatch != null
              ? (bestMatch['type'] ?? '')
              : '',
          'matchedFoundType':
          hasGoodMatch && bestMatch != null
              ? (bestMatch['type'] ?? '')
              : '',
          'matchedFoundColor':
          hasGoodMatch && bestMatch != null
              ? (bestMatch['color'] ?? '')
              : '',
          'matchedFoundLocation':
          hasGoodMatch && bestMatch != null
              ? (bestMatch['location'] ?? '')
              : '',
          'matchedFoundSimilarity':
          hasGoodMatch && bestMatch != null
              ? bestMatch['similarity']
              : null,

          'status': hasGoodMatch ? 'possible_match' : 'submitted',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        await docRef.update({
          'topMatches': [],
          'potentialMatchesCount': 0,
          'candidatePoolSize': 0,
          'searchedIn': 'foundItems',
          'topScore': null,
          'avgTop5Score': null,
          'searchTimeMs': null,
          'searchError': e.toString(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

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
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    dateController.dispose();
    itemNameController.dispose();
    descriptionController.dispose();
    otherCategoryController.dispose();
    specialMarksController.dispose();
    otherElectronicsBrandController.dispose();
    bagBrandController.dispose();
    watchBrandController.dispose();
    glassesBrandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';
    final categories = _getCategories(currentLocale.languageCode);
    final colors = _getColors();

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: beigeColor,
        appBar: AppBar(
          backgroundColor: mainGreen,
          title: Text(
            AppLocalizations.translate('reportForm', currentLocale.languageCode),
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
                      .map((c) => DropdownMenuItem<String>(
                    value: c,
                    child: Text(c),
                  ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val;
                      _resetDynamicFields();
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

                DropdownButtonFormField<String>(
                  value: _selectedColor,
                  decoration: _inputDeco('لون الغرض'),
                  items: colors
                      .map((color) => DropdownMenuItem<String>(
                    value: color,
                    child: Text(color),
                  ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedColor = val),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? 'يرجى اختيار اللون' : null,
                ),
                const SizedBox(height: 15),

                if (_isElectronics(currentLocale.languageCode)) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedElectronicsBrand,
                    decoration: _inputDeco('العلامة التجارية'),
                    items: _electronicsBrands()
                        .map((b) => DropdownMenuItem<String>(
                      value: b,
                      child: Text(b),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedElectronicsBrand = val;
                        if (val != 'أخرى') {
                          otherElectronicsBrandController.clear();
                        }
                      });
                    },
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'يرجى اختيار العلامة التجارية'
                        : null,
                  ),
                  const SizedBox(height: 15),

                  if (_selectedElectronicsBrand == 'أخرى') ...[
                    TextFormField(
                      controller: otherElectronicsBrandController,
                      decoration: _inputDeco('يرجى إدخال العلامة التجارية'),
                      validator: (v) {
                        if (_selectedElectronicsBrand == 'أخرى' &&
                            (v == null || v.trim().isEmpty)) {
                          return 'يرجى إدخال العلامة التجارية';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                  ],

                  DropdownButtonFormField<String>(
                    value: _screenBroken,
                    decoration: _inputDeco('هل يوجد كسر في الشاشة؟'),
                    items: _yesNoOptions()
                        .map((v) => DropdownMenuItem<String>(
                      value: v,
                      child: Text(v),
                    ))
                        .toList(),
                    onChanged: (val) => setState(() => _screenBroken = val),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'يرجى تحديد حالة الشاشة'
                        : null,
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: _coverColor,
                    decoration: _inputDeco('لون الغلاف'),
                    items: _coverColors()
                        .map((c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(c),
                    ))
                        .toList(),
                    onChanged: (val) => setState(() => _coverColor = val),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'يرجى اختيار لون الغلاف'
                        : null,
                  ),
                  const SizedBox(height: 15),
                ],

                if (_isBags(currentLocale.languageCode)) ...[
                  TextFormField(
                    controller: bagBrandController,
                    decoration: _inputDeco('العلامة التجارية'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'يرجى إدخال العلامة التجارية'
                        : null,
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: _hasCards,
                    decoration: _inputDeco('هل تحتوي بطاقات؟'),
                    items: _yesNoOptions()
                        .map((v) => DropdownMenuItem<String>(
                      value: v,
                      child: Text(v),
                    ))
                        .toList(),
                    onChanged: (val) => setState(() => _hasCards = val),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'يرجى تحديد ما إذا كان الغرض يحتوي بطاقات'
                        : null,
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: _bagSize,
                    decoration: _inputDeco('حجم الغرض'),
                    items: _bagSizes()
                        .map((v) => DropdownMenuItem<String>(
                      value: v,
                      child: Text(v),
                    ))
                        .toList(),
                    onChanged: (val) => setState(() => _bagSize = val),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'يرجى اختيار حجم الغرض'
                        : null,
                  ),
                  const SizedBox(height: 15),
                ],

                if (_isDocuments(currentLocale.languageCode)) ...[
                  DropdownButtonFormField<String>(
                    value: _documentType,
                    decoration: _inputDeco('نوع المستند'),
                    items: _documentTypes()
                        .map((v) => DropdownMenuItem<String>(
                      value: v,
                      child: Text(v),
                    ))
                        .toList(),
                    onChanged: (val) => setState(() => _documentType = val),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'يرجى اختيار نوع المستند'
                        : null,
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: _hasCover,
                    decoration: _inputDeco('هل يوجد غلاف؟'),
                    items: _yesNoOptions()
                        .map((v) => DropdownMenuItem<String>(
                      value: v,
                      child: Text(v),
                    ))
                        .toList(),
                    onChanged: (val) => setState(() => _hasCover = val),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'يرجى تحديد وجود الغلاف'
                        : null,
                  ),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    value: _coverDocumentColor,
                    decoration: _inputDeco('لون الغلاف'),
                    items: _getColors()
                        .map((v) => DropdownMenuItem<String>(
                      value: v,
                      child: Text(v),
                    ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _coverDocumentColor = val),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'يرجى اختيار لون الغلاف'
                        : null,
                  ),
                  const SizedBox(height: 15),
                ],

                if (_isJewelry(currentLocale.languageCode)) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedJewelrySubtype,
                    decoration: _inputDeco('نوع الغرض'),
                    items: _jewelrySubtypes()
                        .map((v) => DropdownMenuItem<String>(
                      value: v,
                      child: Text(v),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedJewelrySubtype = val;
                        _jewelryMaterial = null;
                        _hasStone = null;
                        _watchType = null;
                        _watchBandType = null;
                        _watchScreenBroken = null;
                        _watchShape = null;
                        _watchFaceColor = null;
                        watchBrandController.clear();
                        _glassesType = null;
                        _glassesFrameColor = null;
                        glassesBrandController.clear();
                      });
                    },
                    validator: (v) =>
                    (v == null || v.isEmpty) ? 'يرجى اختيار نوع الغرض' : null,
                  ),
                  const SizedBox(height: 15),

                  if (_isRegularJewelrySubtype) ...[
                    DropdownButtonFormField<String>(
                      value: _jewelryMaterial,
                      decoration: _inputDeco('مادة الغرض'),
                      items: _jewelryMaterials()
                          .map((v) => DropdownMenuItem<String>(
                        value: v,
                        child: Text(v),
                      ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _jewelryMaterial = val),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'يرجى اختيار مادة الغرض'
                          : null,
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: _hasStone,
                      decoration: _inputDeco('هل تحتوي فص؟'),
                      items: _yesNoOptions()
                          .map((v) => DropdownMenuItem<String>(
                        value: v,
                        child: Text(v),
                      ))
                          .toList(),
                      onChanged: (val) => setState(() => _hasStone = val),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'يرجى تحديد وجود فص' : null,
                    ),
                    const SizedBox(height: 15),
                  ],

                  if (_isWatchSubtype) ...[
                    TextFormField(
                      controller: watchBrandController,
                      decoration: _inputDeco('العلامة التجارية'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'يرجى إدخال العلامة التجارية'
                          : null,
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: _watchType,
                      decoration: _inputDeco('نوع الساعة'),
                      items: _watchTypes()
                          .map((v) => DropdownMenuItem<String>(
                        value: v,
                        child: Text(v),
                      ))
                          .toList(),
                      onChanged: (val) => setState(() => _watchType = val),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'يرجى اختيار نوع الساعة' : null,
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: _watchBandType,
                      decoration: _inputDeco('نوع السوار'),
                      items: _watchBandTypes()
                          .map((v) => DropdownMenuItem<String>(
                        value: v,
                        child: Text(v),
                      ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _watchBandType = val),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'يرجى اختيار نوع السوار' : null,
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: _watchScreenBroken,
                      decoration: _inputDeco('هل الشاشة مكسورة؟'),
                      items: _yesNoOptions()
                          .map((v) => DropdownMenuItem<String>(
                        value: v,
                        child: Text(v),
                      ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _watchScreenBroken = val),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'يرجى تحديد حالة الشاشة' : null,
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: _watchShape,
                      decoration: _inputDeco('شكل الساعة'),
                      items: _watchShapes()
                          .map((v) => DropdownMenuItem<String>(
                        value: v,
                        child: Text(v),
                      ))
                          .toList(),
                      onChanged: (val) => setState(() => _watchShape = val),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'يرجى اختيار شكل الساعة' : null,
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: _watchFaceColor,
                      decoration: _inputDeco('لون المينا'),
                      items: _getColors()
                          .map((v) => DropdownMenuItem<String>(
                        value: v,
                        child: Text(v),
                      ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _watchFaceColor = val),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'يرجى اختيار لون المينا' : null,
                    ),
                    const SizedBox(height: 15),
                  ],

                  if (_isGlassesSubtype) ...[
                    TextFormField(
                      controller: glassesBrandController,
                      decoration: _inputDeco('العلامة التجارية'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'يرجى إدخال العلامة التجارية'
                          : null,
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: _glassesType,
                      decoration: _inputDeco('نوع النظارة'),
                      items: _glassesTypes()
                          .map((v) => DropdownMenuItem<String>(
                        value: v,
                        child: Text(v),
                      ))
                          .toList(),
                      onChanged: (val) => setState(() => _glassesType = val),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'يرجى اختيار نوع النظارة' : null,
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: _glassesFrameColor,
                      decoration: _inputDeco('لون الإطار'),
                      items: _getColors()
                          .map((v) => DropdownMenuItem<String>(
                        value: v,
                        child: Text(v),
                      ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _glassesFrameColor = val),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'يرجى اختيار لون الإطار' : null,
                    ),
                    const SizedBox(height: 15),
                  ],
                ],

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
                    validator: (v) => (_selectedCategory ==
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

                TextFormField(
                  controller: specialMarksController,
                  maxLines: 2,
                  decoration: _inputDeco('علامات مميزة / تفاصيل خاصة'),
                ),
                const SizedBox(height: 15),

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