// lib/AI_services/ai_suggester.dart
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class AISuggester {
  Interpreter? _interpreter;
  List<String> _labels = [];

  static const String _modelAsset  = 'assets/models/model.tflite';
  static const String _labelsAsset = 'assets/models/labels.txt';
  static const int _inputWidth = 224;
  static const int _inputHeight = 224;
  static const bool _expectsFloat = true;

  /// نربط بعض ImageNet labels بأنواع مفقودات تناسب الحرم
  /// (هنا نفلتر الـ church / traffic light وأصحابهم 🤚)
  static const Map<String, String> _labelToLostType = {
    'wallet': 'محفظة',
    'backpack': 'حقيبة ظهر',
    'handbag': 'حقيبة يد',
    'purse': 'حقيبة صغيرة',
    'cellular telephone': 'جوال',
    'laptop': 'لابتوب',
    'notebook': 'دفتر',
    'book jacket': 'كتاب',
    'sunglass': 'نظارة شمسية',
    'sunglasses': 'نظارة شمسية',
    'digital watch': 'ساعة',
    'analog clock': 'ساعة',
    'watch': 'ساعة',
  };

  Future<void> _ensureLoaded() async {
    if (_interpreter != null && _labels.isNotEmpty) return;

    _interpreter = await Interpreter.fromAsset(_modelAsset);

    final txt = await rootBundle.loadString(_labelsAsset);
    _labels = txt
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// ترجع:
  /// [
  ///   { 'label': 'محفظة', 'score': 0.82, 'index': 123, 'color': 'أسود' },
  ///   { 'label': 'حقيبة ظهر', ... },
  ///   ...
  /// ]
  Future<List<Map<String, dynamic>>> suggest(Uint8List imageBytes) async {
    await _ensureLoaded();
    final interpreter = _interpreter!;
    final outputT = interpreter.getOutputTensors().first;

    // تجهيز الـ input
    final input = _preprocess(
      imageBytes,
      width: _inputWidth,
      height: _inputHeight,
      asFloat: _expectsFloat,
    );

    final outputType = outputT.type;
    final numClasses = outputT.shape.last;

    dynamic outputBuffer;
    if (outputType == TensorType.float32) {
      outputBuffer = List.filled(numClasses, 0.0).reshape([1, numClasses]);
    } else if (outputType == TensorType.uint8) {
      outputBuffer = List.filled(numClasses, 0).reshape([1, numClasses]);
    } else {
      throw Exception('Unsupported output tensor type: $outputType');
    }

    // تشغيل المودل
    interpreter.run(input, outputBuffer);

    // تحويل الـ output إلى قائمة احتمالات
    List<double> probs;
    if (outputType == TensorType.float32) {
      probs = (outputBuffer as List).first.cast<double>();
    } else {
      probs = ((outputBuffer as List).first.cast<int>())
          .map((v) => v / 255.0)
          .toList();
    }

    // ترتيب الكلاسات من الأعلى احتمالاً
    final idx = List.generate(probs.length, (i) => i)
      ..sort((a, b) => probs[b].compareTo(probs[a]));

    // raw list من المودل قبل الفلترة
    final rawList = [
      for (final i in idx)
        {
          'label': (i < _labels.length) ? _labels[i] : 'class_$i',
          'score': probs[i],
          'index': i,
        }
    ];

    // فلترة + mapping إلى "أنواع مفقودات" مفهومة
    final mapped = _mapToLostTypes(rawList);

    // لو لقينا انواع مناسبة نستخدمها، غير كذا نرجع أول 3 raw كـ fallback
    final finalList = mapped.isNotEmpty ? mapped : rawList.take(3).toList();

    // تقدير اللون من الصورة نفسها
    final colorName = _estimateColorName(imageBytes);
    if (colorName != null && finalList.isNotEmpty) {
      final first = finalList.first;
      finalList[0] = {
        ...first,
        'color': colorName, // هنا يتقرأ في FoundItemPage كـ aiColor
      };
    }

    return finalList;
  }

  /// نحول ImageNet labels إلى أنواع مفقودات (محفظة، جوال، ...).
  List<Map<String, dynamic>> _mapToLostTypes(
      List<Map<String, dynamic>> raw,
      ) {
    final result = <Map<String, dynamic>>[];
    final used = <String>{};

    for (final m in raw) {
      final rawLabel = (m['label'] as String).toLowerCase();
      final score = (m['score'] as double?) ?? 0.0;

      // Threshold بسيط عشان ما ناخذ احتمالات ضعيفة
      if (score < 0.15) continue;

      String? mapped;
      _labelToLostType.forEach((k, v) {
        if (rawLabel.contains(k)) {
          mapped = v;
        }
      });

      if (mapped != null && !used.contains(mapped)) {
        used.add(mapped!);
        result.add({
          'label': mapped,
          'score': score,
          'index': m['index'],
        });
      }
    }

    return result;
  }

  /// نحسب لون تقريبي للصورة (أسود، أبيض، رمادي، أحمر، أزرق...).
  String? _estimateColorName(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    int sumR = 0, sumG = 0, sumB = 0;
    int samples = 0;

    // نأخذ عينة كل 4 بيكسلات تقريباً عشان الأداء
    for (var y = 0; y < image.height; y += 4) {
      for (var x = 0; x < image.width; x += 4) {
        final p = image.getPixel(x, y);
        sumR += img.getRed(p);
        sumG += img.getGreen(p);
        sumB += img.getBlue(p);
        samples++;
      }
    }

    if (samples == 0) return null;

    final r = sumR / samples;
    final g = sumG / samples;
    final b = sumB / samples;

    final brightness = (r + g + b) / 3.0;
    final maxC = math.max(r, math.max(g, b));
    final minC = math.min(r, math.min(g, b));
    final delta = maxC - minC;

    // ألوان أساسية (داكن/فاتح/رمادي)
    if (brightness < 40) return 'أسود';
    if (brightness > 215) return 'أبيض';
    if (delta < 20) return 'رمادي';

    // حساب Hue تقريبي
    double hue;
    if (maxC == r) {
      hue = 60.0 * ((g - b) / delta % 6);
    } else if (maxC == g) {
      hue = 60.0 * ((b - r) / delta + 2);
    } else {
      hue = 60.0 * ((r - g) / delta + 4);
    }
    if (hue < 0) hue += 360.0;

    if (hue < 20 || hue >= 340) return 'أحمر';
    if (hue < 50) return 'برتقالي';
    if (hue < 70) return 'أصفر';
    if (hue < 170) return 'أخضر';
    if (hue < 210) return 'سماوي';
    if (hue < 260) return 'أزرق';
    if (hue < 300) return 'بنفسجي';
    return 'بني';
  }

  List _preprocess(
      Uint8List bytes, {
        required int width,
        required int height,
        required bool asFloat,
      }) {
    final original = img.decodeImage(bytes);
    if (original == null) throw Exception('Could not decode image');
    final resized = img.copyResize(original, width: width, height: height);

    if (asFloat) {
      final input = List.generate(
        1,
            (_) => List.generate(
          height,
              (_) => List.generate(
            width,
                (_) => List.filled(3, 0.0),
          ),
        ),
      );

      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final p = resized.getPixel(x, y);
          input[0][y][x][0] = img.getRed(p) / 255.0;
          input[0][y][x][1] = img.getGreen(p) / 255.0;
          input[0][y][x][2] = img.getBlue(p) / 255.0;
        }
      }
      return input;
    } else {
      final input = List.generate(
        1,
            (_) => List.generate(
          height,
              (_) => List.generate(
            width,
                (_) => List.filled(3, 0),
          ),
        ),
      );

      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final p = resized.getPixel(x, y);
          input[0][y][x][0] = img.getRed(p);
          input[0][y][x][1] = img.getGreen(p);
          input[0][y][x][2] = img.getBlue(p);
        }
      }
      return input;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
