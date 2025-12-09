// lib/AI_services/ai_suggester.dart
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class AISuggester {
  Interpreter? _interpreter;
  List<String> _labels = [];

  static const String _modelAsset = 'assets/models/model.tflite';
  static const String _labelsAsset = 'assets/models/labels.txt';
  static const int _inputWidth = 224;
  static const int _inputHeight = 224;
  static const bool _expectsFloat = true;



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

  /// نربط بعض ImageNet labels بأنواع مفقودات تناسب الحرم
  static const Map<String, String> _labelToLostType = {
    'wallet': 'wallet / محفظة',
    'backpack': 'backpack / حقيبة ظهر',
    'handbag': 'handbag / حقيبة يد',
    'purse': 'purse / حقيبة صغيرة',
    'cellular telephone': 'cellphone / جوال',
    'laptop': 'laptop / لابتوب',
    'notebook': 'notebook / دفتر',
    'book jacket': 'book / كتاب',
    'sunglass': 'sunglasses / نظارة شمسية',
    'sunglasses': 'sunglasses / نظارة شمسية',
    'digital watch': 'watch / ساعة',
    'analog clock': 'watch / ساعة',
    'watch': 'watch / ساعة',
  };



  /// ترجع:
  /// [
  ///   { 'label': 'محفظة', 'score': 0.82, 'index': 123, 'color': 'أسود' },
  ///   { 'label': 'حقيبة ظهر', ... },
  ///   ...
  /// ]
  // didnt workkk ^

  Future<List<Map<String, dynamic>>> suggest(Uint8List imageBytes) async {
    await _ensureLoaded();
    final interpreter = _interpreter!;
    final outputT = interpreter.getOutputTensors().first;

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

    // لو لقينا أنواع مناسبة نستخدمها، غير كذا نرجع أول 3 raw كـ fallback
    final finalList = mapped.isNotEmpty ? mapped : rawList.take(3).toList();

    // تقدير اللون من الصورة نفسها
    final colorName = _estimateColorName(imageBytes);
    if (colorName != null && finalList.isNotEmpty) {
      final first = finalList.first;
      finalList[0] = {
        ...first,
        'color': colorName, // يتقرأ في FoundItemPage كـ aiColor
      };
    }

    return finalList;
  }

  /// نحول ImageNet labels إلى أنواع مفقودات (محفظة، جوال، وغيره).
  List<Map<String, dynamic>> _mapToLostTypes(
      List<Map<String, dynamic>> raw,
      ) {
    final result = <Map<String, dynamic>>[];
    final used = <String>{};

    for (final m in raw) {
      final rawLabel = (m['label'] as String).toLowerCase();
      final score = (m['score'] as double?) ?? 0.0;

      // Threshold
      // to add more accuracy and eliminate options with low probability
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


  String? _estimateColorName(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    // i took the center pixeles
    // after multiple attempts I found out these numbers are the best so far
    final int startX = (image.width * 0.30).round();
    final int endX   = (image.width * 0.70).round();
    final int startY = (image.height * 0.20).round();
    final int endY   = (image.height * 0.80).round();

    double sumR = 0, sumG = 0, sumB = 0;
    double sumW = 0;

    // a sample every 2 pixels this is what the LLM suggested as a big support
    for (var y = startY; y < endY; y += 2) {
      for (var x = startX; x < endX; x += 2) {
        final p = image.getPixel(x, y);
        final r = img.getRed(p).toDouble();
        final g = img.getGreen(p).toDouble();
        final b = img.getBlue(p).toDouble();

        final brightness = (r + g + b) / 3.0;

        // the darker pixels are the weight they gain
        // cuz most object will be darker than the background
        final weight = 1.0 + (255.0 - brightness) / 255.0;

        sumR += r * weight;
        sumG += g * weight;
        sumB += b * weight;
        sumW += weight;
      }
    }

    if (sumW == 0) return null;

    final double r = sumR / sumW;
    final double g = sumG / sumW;
    final double b = sumB / sumW;

    final double brightness = (r + g + b) / 3.0;
    final double maxC = math.max(r, math.max(g, b));
    final double minC = math.min(r, math.min(g, b));
    final double delta = maxC - minC;

    // ألوان أساسية (داكن/فاتح)
    if (brightness < 40) return 'black / أسود';
    if (brightness > 230) return 'white / أبيض';

    // it should've been grey but the pixels are confusing for our human eyes
    // so i decided to write black
    if (delta < 10) return 'black / أسود';

    // حساب Hue تقريبي
    double hue;
    if (maxC == r) {
      hue = 60.0 * (((g - b) / delta) % 6);
    } else if (maxC == g) {
      hue = 60.0 * ((b - r) / delta + 2);
    } else {
      hue = 60.0 * ((r - g) / delta + 4);
    }
    if (hue < 0) hue += 360.0;

    if (hue < 20 || hue >= 340) return 'red / أحمر';
    if (hue < 50) return 'orange / برتقالي';
    if (hue < 70) return 'yellow / أصفر';
    if (hue < 170) return 'green / أخضر';
    if (hue < 200) return 'skyblue / سماوي';
    if (hue < 240) return 'blue / أزرق';
    if (hue < 300) return 'purple / بنفسجي';
    return 'brown / بني';
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
