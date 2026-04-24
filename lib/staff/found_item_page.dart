import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../AI_services/ai_suggester.dart';
import '../AI_services/found_item_service.dart';
import '../l10n/app_localizations_helper.dart';
import 'search_match_items_page.dart';

class FoundItemPage extends StatefulWidget {
  const FoundItemPage({super.key});

  @override
  State<FoundItemPage> createState() => _FoundItemPageState();
}

class _FoundItemPageState extends State<FoundItemPage> {
  final Color mainGreen = const Color(0xFF243E36);
  final Color borderBrown = const Color(0xFF272525);
  final Color beigeColor = const Color(0xFFC3BFB0);
  final Color chipGrey = const Color(0xFF3E3C3C);

  final _typeCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _foundLocCtrl = TextEditingController();
  final _storageLocCtrl = TextEditingController();

  final _otherElectronicsBrandCtrl = TextEditingController();
  final _bagBrandCtrl = TextEditingController();
  final _watchBrandCtrl = TextEditingController();
  final _glassesBrandCtrl = TextEditingController();

  DateTime _foundAt = DateTime.now();
  String? _autoCategory;
  String? _autoSubtype;

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
    _otherElectronicsBrandCtrl.dispose();
    _bagBrandCtrl.dispose();
    _watchBrandCtrl.dispose();
    _glassesBrandCtrl.dispose();
    _ai.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderBrown, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderBrown, width: 2),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderBrown),
    ),
    labelStyle: TextStyle(color: borderBrown.withOpacity(0.9)),
  );

  List<String> _yesNoOptions() => ['نعم', 'لا'];
  List<String> _bagSizes() => ['صغيرة', 'متوسطة', 'كبيرة'];
  List<String> _documentTypes() => ['بطاقة', 'جواز سفر', 'رخصة', 'مستند'];
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

  String _normalizedType() => _typeCtrl.text.trim().toLowerCase();

  bool _isElectronicsType() {
    final t = _normalizedType();
    return t.contains('جوال') ||
        t.contains('phone') ||
        t.contains('iphone') ||
        t.contains('mobile') ||
        t.contains('لابتوب') ||
        t.contains('laptop') ||
        t.contains('سماعات') ||
        t.contains('ear') ||
        t.contains('head') ||
        t.contains('jbl') ||
        t.contains('sony');
  }

  bool _isBagType() {
    final t = _normalizedType();
    return t.contains('محفظة') ||
        t.contains('wallet') ||
        t.contains('شنطة') ||
        t.contains('bag') ||
        t.contains('backpack') ||
        t.contains('حقيبة');
  }

  bool _isDocumentMainType() {
    final t = _normalizedType();
    return t.contains('بطاقة') ||
        t.contains('card') ||
        t.contains('جواز') ||
        t.contains('passport') ||
        t.contains('رخصة') ||
        t.contains('license') ||
        t.contains('مستند') ||
        t.contains('document');
  }

  bool _isJewelryLikeType() {
    final t = _normalizedType();
    return t.contains('خاتم') ||
        t.contains('ring') ||
        t.contains('سوار') ||
        t.contains('bracelet') ||
        t.contains('سلسلة') ||
        t.contains('necklace') ||
        t.contains('ساعة') ||
        t.contains('watch') ||
        t.contains('نظارة') ||
        t.contains('glasses') ||
        t.contains('sunglass');
  }

  bool get _isWatchSubtype => _autoSubtype == 'ساعة';
  bool get _isGlassesSubtype => _autoSubtype == 'نظارة';
  bool get _isRegularJewelrySubtype =>
      _autoSubtype == 'خاتم' ||
          _autoSubtype == 'سوار' ||
          _autoSubtype == 'سلسلة';

  String _mapTypeToCategory(String type, String languageCode) {
    final t = type.trim().toLowerCase();

    if (t.contains('جوال') ||
        t.contains('phone') ||
        t.contains('iphone') ||
        t.contains('mobile') ||
        t.contains('لابتوب') ||
        t.contains('laptop') ||
        t.contains('سماعات') ||
        t.contains('ear') ||
        t.contains('head')) {
      return AppLocalizations.translate('electronics', languageCode);
    }

    if (t.contains('محفظة') ||
        t.contains('wallet') ||
        t.contains('شنطة') ||
        t.contains('bag') ||
        t.contains('backpack') ||
        t.contains('حقيبة')) {
      return AppLocalizations.translate('bags', languageCode);
    }

    if (t.contains('بطاقة') ||
        t.contains('card') ||
        t.contains('جواز') ||
        t.contains('passport') ||
        t.contains('رخصة') ||
        t.contains('license') ||
        t.contains('مستند') ||
        t.contains('document')) {
      return AppLocalizations.translate('documentsCards', languageCode);
    }

    if (t.contains('خاتم') ||
        t.contains('ring') ||
        t.contains('سوار') ||
        t.contains('bracelet') ||
        t.contains('سلسلة') ||
        t.contains('necklace') ||
        t.contains('ساعة') ||
        t.contains('watch') ||
        t.contains('نظارة') ||
        t.contains('glasses') ||
        t.contains('sunglass')) {
      return AppLocalizations.translate('jewelry', languageCode);
    }

    return AppLocalizations.translate('other', languageCode);
  }

  String _mapTypeToSubtype(String type) {
    final t = type.trim().toLowerCase();

    if (t.contains('watch') || t.contains('ساعة')) return 'ساعة';
    if (t.contains('glasses') || t.contains('sunglass') || t.contains('نظارة')) {
      return 'نظارة';
    }
    if (t.contains('ring') || t.contains('خاتم')) return 'خاتم';
    if (t.contains('bracelet') || t.contains('سوار')) return 'سوار';
    if (t.contains('necklace') || t.contains('سلسلة')) return 'سلسلة';

    return '';
  }

  void _resetDynamicFields() {
    _selectedElectronicsBrand = null;
    _otherElectronicsBrandCtrl.clear();
    _bagBrandCtrl.clear();
    _watchBrandCtrl.clear();
    _glassesBrandCtrl.clear();

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
      _autoCategory = null;
      _autoSubtype = null;
      _resetDynamicFields();
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

      final lang = Localizations.localeOf(context).languageCode;

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

        _autoCategory = _mapTypeToCategory(_typeCtrl.text, lang);
        _autoSubtype = _mapTypeToSubtype(_typeCtrl.text);
        _resetDynamicFields();
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

  String _resolvedBrand() {
    if (_isElectronicsType()) {
      if (_selectedElectronicsBrand == 'أخرى') {
        return _otherElectronicsBrandCtrl.text.trim().toLowerCase();
      }
      return (_selectedElectronicsBrand ?? '').trim().toLowerCase();
    }

    if (_isBagType()) {
      return _bagBrandCtrl.text.trim().toLowerCase();
    }

    if (_isJewelryLikeType() && _isWatchSubtype) {
      return _watchBrandCtrl.text.trim().toLowerCase();
    }

    if (_isJewelryLikeType() && _isGlassesSubtype) {
      return _glassesBrandCtrl.text.trim().toLowerCase();
    }

    return '';
  }

  Future<void> _save() async {
    final locale = Localizations.localeOf(context);

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate('pleaseAddPhoto', locale.languageCode),
          ),
        ),
      );
      return;
    }

    if (_typeCtrl.text.trim().isEmpty ||
        _colorCtrl.text.trim().isEmpty ||
        _foundLocCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate(
              'typeColorLocationRequired',
              locale.languageCode,
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      final imageUrl = await _service.uploadImage(_image!);
      final brand = _resolvedBrand();

      final docId = await _service.saveFoundItem(
        type: _typeCtrl.text.trim(),
        color: _colorCtrl.text.trim(),
        description:
        _descCtrl.text.trim().isEmpty ? '-' : _descCtrl.text.trim(),
        foundLocation: _foundLocCtrl.text.trim(),
        foundAt: _foundAt,
        storageLocation: _storageLocCtrl.text.trim().isEmpty
            ? '-'
            : _storageLocCtrl.text.trim(),
        imageUrl: imageUrl,
        aiTypes: _altTypes,
        aiColor: _aiColor,
      );

      await FirebaseFirestore.instance.collection('foundItems').doc(docId).update({
        'title': _typeCtrl.text.trim(),
        'type': _typeCtrl.text.trim(),
        'category': _autoCategory ?? _typeCtrl.text.trim(),
        'subtype': _autoSubtype ?? '',
        'color': _colorCtrl.text.trim(),

        'description':
        _descCtrl.text.trim().isEmpty ? '-' : _descCtrl.text.trim(),
        'foundLocation': _foundLocCtrl.text.trim(),
        'storageLocation': _storageLocCtrl.text.trim().isEmpty
            ? '-'
            : _storageLocCtrl.text.trim(),
        'reportLocation': _foundLocCtrl.text.trim(),

        'imagePath': imageUrl,
        'imageUrl': imageUrl,

        'status': AppLocalizations.translate(
          'stored',
          locale.languageCode,
        ),

        'date': _format(_foundAt, locale.languageCode),
        'foundAt': Timestamp.fromDate(_foundAt),

        'itemCategory': 'found',
        'aiSuggestions': _altTypes,
        'aiTypes': _altTypes,
        'aiColor': _aiColor ?? '',

        'brand': brand,
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
          'subtype': _autoSubtype ?? '',
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

        'docId': docId,
        'id': docId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.translate(
              'savedSuccessfully',
              locale.languageCode,
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SearchMatchItemsPage(
            initialCreatedDoc: {
              'firebaseDocId': docId,
              'id': docId,
              'doc_num': '',
              'collection': 'foundItems',
              '_key': 'found:$docId',
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.translate('saveFailed', locale.languageCode)}: $e',
          ),
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

      if (diff.inDays == 0) return 'اليوم - $h:$m';
      if (diff.inDays == 1) return 'أمس - $h:$m';

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
        backgroundColor: beigeColor,
        appBar: AppBar(
          backgroundColor: mainGreen,
          title: Text(
            AppLocalizations.translate(
              'registerFoundItem',
              locale.languageCode,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _image != null ? _runAI : null,
              tooltip: AppLocalizations.translate(
                'rerunAI',
                locale.languageCode,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: mainGreen, width: 2),
                      image: _image != null
                          ? DecorationImage(
                        image: FileImage(_image!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: _image == null
                        ? Center(
                      child: Text(
                        AppLocalizations.translate(
                          'noImageSelected',
                          locale.languageCode,
                        ),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: mainGreen),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: Icon(Icons.photo_camera, color: mainGreen),
                          label: Text(
                            AppLocalizations.translate(
                              'camera',
                              locale.languageCode,
                            ),
                            style: TextStyle(color: mainGreen),
                          ),
                          onPressed: () => _pick(true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: mainGreen),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: Icon(Icons.photo, color: mainGreen),
                          label: Text(
                            AppLocalizations.translate(
                              'gallery',
                              locale.languageCode,
                            ),
                            style: TextStyle(color: mainGreen),
                          ),
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
                          AppLocalizations.translate(
                            'suggestedTypes',
                            locale.languageCode,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: _altTypes
                              .map(
                                (t) => ActionChip(
                              backgroundColor: chipGrey,
                              label: Text(
                                t,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              onPressed: () {
                                setState(() {
                                  _typeCtrl.text = t;
                                  _autoCategory = _mapTypeToCategory(
                                    t,
                                    locale.languageCode,
                                  );
                                  _autoSubtype = _mapTypeToSubtype(t);
                                  _resetDynamicFields();
                                });
                              },
                            ),
                          )
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
                          AppLocalizations.translate(
                            'suggestedColor',
                            locale.languageCode,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          children: [
                            ActionChip(
                              backgroundColor: chipGrey,
                              label: Text(
                                _aiColor!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              onPressed: () {
                                setState(() {
                                  _colorCtrl.text = _aiColor!;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),

                  TextField(
                    controller: _typeCtrl,
                    decoration: _dec(
                      AppLocalizations.translate(
                        'itemType',
                        locale.languageCode,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _autoCategory =
                            _mapTypeToCategory(value, locale.languageCode);
                        _autoSubtype = _mapTypeToSubtype(value);
                        _resetDynamicFields();
                      });
                    },
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 12),

                  if (_autoCategory != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderBrown),
                      ),
                      child: Text(
                        'الفئة: $_autoCategory',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: _colorCtrl,
                    decoration: _dec(
                      AppLocalizations.translate(
                        'color',
                        locale.languageCode,
                      ),
                    ),
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 12),

                  if (_isElectronicsType()) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedElectronicsBrand,
                      decoration: _dec('العلامة التجارية'),
                      items: _electronicsBrands()
                          .map(
                            (b) => DropdownMenuItem<String>(
                          value: b,
                          child: Text(b),
                        ),
                      )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedElectronicsBrand = val;
                          if (val != 'أخرى') {
                            _otherElectronicsBrandCtrl.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    if (_selectedElectronicsBrand == 'أخرى') ...[
                      TextField(
                        controller: _otherElectronicsBrandCtrl,
                        decoration: _dec('يرجى إدخال العلامة التجارية'),
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      ),
                      const SizedBox(height: 12),
                    ],

                    DropdownButtonFormField<String>(
                      value: _screenBroken,
                      decoration: _dec('هل يوجد كسر في الشاشة؟'),
                      items: _yesNoOptions()
                          .map(
                            (v) => DropdownMenuItem<String>(
                          value: v,
                          child: Text(v),
                        ),
                      )
                          .toList(),
                      onChanged: (val) => setState(() => _screenBroken = val),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _coverColor,
                      decoration: _dec('لون الغلاف'),
                      items: _coverColors()
                          .map(
                            (c) => DropdownMenuItem<String>(
                          value: c,
                          child: Text(c),
                        ),
                      )
                          .toList(),
                      onChanged: (val) => setState(() => _coverColor = val),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_isBagType()) ...[
                    TextField(
                      controller: _bagBrandCtrl,
                      decoration: _dec('العلامة التجارية'),
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _hasCards,
                      decoration: _dec('هل تحتوي بطاقات؟'),
                      items: _yesNoOptions()
                          .map(
                            (v) => DropdownMenuItem<String>(
                          value: v,
                          child: Text(v),
                        ),
                      )
                          .toList(),
                      onChanged: (val) => setState(() => _hasCards = val),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _bagSize,
                      decoration: _dec('حجم الغرض'),
                      items: _bagSizes()
                          .map(
                            (v) => DropdownMenuItem<String>(
                          value: v,
                          child: Text(v),
                        ),
                      )
                          .toList(),
                      onChanged: (val) => setState(() => _bagSize = val),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_isDocumentMainType()) ...[
                    DropdownButtonFormField<String>(
                      value: _documentType,
                      decoration: _dec('نوع المستند'),
                      items: _documentTypes()
                          .map(
                            (v) => DropdownMenuItem<String>(
                          value: v,
                          child: Text(v),
                        ),
                      )
                          .toList(),
                      onChanged: (val) => setState(() => _documentType = val),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _hasCover,
                      decoration: _dec('هل يوجد غلاف؟'),
                      items: _yesNoOptions()
                          .map(
                            (v) => DropdownMenuItem<String>(
                          value: v,
                          child: Text(v),
                        ),
                      )
                          .toList(),
                      onChanged: (val) => setState(() => _hasCover = val),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _coverDocumentColor,
                      decoration: _dec('لون الغلاف'),
                      items: _getColors()
                          .map(
                            (v) => DropdownMenuItem<String>(
                          value: v,
                          child: Text(v),
                        ),
                      )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _coverDocumentColor = val),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_isJewelryLikeType()) ...[
                    if (_isRegularJewelrySubtype) ...[
                      DropdownButtonFormField<String>(
                        value: _jewelryMaterial,
                        decoration: _dec('مادة الغرض'),
                        items: _jewelryMaterials()
                            .map(
                              (v) => DropdownMenuItem<String>(
                            value: v,
                            child: Text(v),
                          ),
                        )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _jewelryMaterial = val),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _hasStone,
                        decoration: _dec('هل تحتوي فص؟'),
                        items: _yesNoOptions()
                            .map(
                              (v) => DropdownMenuItem<String>(
                            value: v,
                            child: Text(v),
                          ),
                        )
                            .toList(),
                        onChanged: (val) => setState(() => _hasStone = val),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (_isWatchSubtype) ...[
                      TextField(
                        controller: _watchBrandCtrl,
                        decoration: _dec('العلامة التجارية'),
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _watchType,
                        decoration: _dec('نوع الساعة'),
                        items: _watchTypes()
                            .map(
                              (v) => DropdownMenuItem<String>(
                            value: v,
                            child: Text(v),
                          ),
                        )
                            .toList(),
                        onChanged: (val) => setState(() => _watchType = val),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _watchBandType,
                        decoration: _dec('نوع السوار'),
                        items: _watchBandTypes()
                            .map(
                              (v) => DropdownMenuItem<String>(
                            value: v,
                            child: Text(v),
                          ),
                        )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _watchBandType = val),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _watchScreenBroken,
                        decoration: _dec('هل الشاشة مكسورة؟'),
                        items: _yesNoOptions()
                            .map(
                              (v) => DropdownMenuItem<String>(
                            value: v,
                            child: Text(v),
                          ),
                        )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _watchScreenBroken = val),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _watchShape,
                        decoration: _dec('شكل الساعة'),
                        items: _watchShapes()
                            .map(
                              (v) => DropdownMenuItem<String>(
                            value: v,
                            child: Text(v),
                          ),
                        )
                            .toList(),
                        onChanged: (val) => setState(() => _watchShape = val),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _watchFaceColor,
                        decoration: _dec('لون المينا'),
                        items: _getColors()
                            .map(
                              (v) => DropdownMenuItem<String>(
                            value: v,
                            child: Text(v),
                          ),
                        )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _watchFaceColor = val),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (_isGlassesSubtype) ...[
                      TextField(
                        controller: _glassesBrandCtrl,
                        decoration: _dec('العلامة التجارية'),
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _glassesType,
                        decoration: _dec('نوع النظارة'),
                        items: _glassesTypes()
                            .map(
                              (v) => DropdownMenuItem<String>(
                            value: v,
                            child: Text(v),
                          ),
                        )
                            .toList(),
                        onChanged: (val) => setState(() => _glassesType = val),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _glassesFrameColor,
                        decoration: _dec('لون الإطار'),
                        items: _getColors()
                            .map(
                              (v) => DropdownMenuItem<String>(
                            value: v,
                            child: Text(v),
                          ),
                        )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _glassesFrameColor = val),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],

                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: _dec(
                      AppLocalizations.translate(
                        'description',
                        locale.languageCode,
                      ),
                    ),
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _foundLocCtrl,
                    decoration: _dec(
                      AppLocalizations.translate(
                        'foundLocation',
                        locale.languageCode,
                      ),
                    ),
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _storageLocCtrl,
                    decoration: _dec(
                      AppLocalizations.translate(
                        'storageLocation',
                        locale.languageCode,
                      ),
                    ),
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderBrown),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: Icon(Icons.schedule, color: mainGreen),
                    label: Text(
                      '${AppLocalizations.translate('foundTime', locale.languageCode)}: ${_format(_foundAt, locale.languageCode)}',
                      style: TextStyle(color: mainGreen),
                    ),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _foundAt,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );

                      if (d == null) return;

                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_foundAt),
                      );

                      if (t == null) return;

                      setState(() {
                        _foundAt = DateTime(
                          d.year,
                          d.month,
                          d.day,
                          t.hour,
                          t.minute,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _busy ? null : _save,
                    child: Text(
                      AppLocalizations.translate(
                        'save',
                        locale.languageCode,
                      ),
                      style: const TextStyle(fontSize: 18),
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