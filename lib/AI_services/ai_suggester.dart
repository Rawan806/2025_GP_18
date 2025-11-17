import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class AISuggester {
  // Singleton
  static final AISuggester _instance = AISuggester._internal();
  factory AISuggester() => _instance;
  AISuggester._internal();

  Interpreter? _interpreter;
  List<String> _labels = [];

  static const String _modelAsset  = 'assets/models/model.tflite';
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

  Future<List<Map<String, dynamic>>> suggest(Uint8List imageBytes) async {
    await _ensureLoaded();
    final interpreter = _interpreter!;
    final inputT  = interpreter.getInputTensors().first;
    final outputT = interpreter.getOutputTensors().first;

    // تحضير تنسور
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

    List<double> probs;
    if (outputType == TensorType.float32) {
      probs = (outputBuffer as List).first.cast<double>();
    } else {
      probs = ((outputBuffer as List).first.cast<int>())
          .map((v) => v / 255.0)
          .toList();
    }

    // ترتيب النتائج من الأعلى للأقل
    final idx = List.generate(probs.length, (i) => i)
      ..sort((a, b) => probs[b].compareTo(probs[a]));

    // حساب اللون من الصورة ///////////
    final colorName = _estimateDominantColorName(imageBytes);

    final List<Map<String, dynamic>> filtered = [];
    for (final i in idx) {
      final label = (i < _labels.length) ? _labels[i] : 'class_$i';
      final score = probs[i];

      //  احتمالات ضعيفة جدًا نتجاهلها
      if (score < 0.15) continue;

      if (_isReasonableLabel(label)) {
        filtered.add({
          'label': label,
          'score': score,
          'index': i,
          'color': colorName,
        });
      }
    }

    if (filtered.isNotEmpty) {
      return filtered;
    }

    final fallback = <Map<String, dynamic>>[];
    for (final i in idx.take(3)) {
      final label = (i < _labels.length) ? _labels[i] : 'class_$i';
      fallback.add({
        'label': label,
        'score': probs[i],
        'index': i,
        'color': colorName,
      });
    }
    return fallback;
  }

  List _preprocess(
      Uint8List bytes, {
        required int width,
        required int height,
        required bool asFloat,
      }) {
    final original = img.decodeImage(bytes);
    if (original == null) throw Exception('Could not decode image');

    final resized = img.copyResize(
      original,
      width: width,
      height: height,
    );

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

  bool _isReasonableLabel(String label) {
    final l = label.toLowerCase();

    const keywords = [
      'wallet',
      'purse',
      'bag',
      'handbag',
      'backpack',
      'briefcase',
      'card',
      'id',
      'watch',
      'ring',
      'necklace',
      'earring',
      'key',
      'keys',
      'cellular telephone',
      'mobile',
      'phone',
      'laptop',
      'notebook',
      'umbrella',
      'sunglass',
      'sunglasses',
      'glasses',
      'spectacles',
      'credit card',
    ];

    for (final k in keywords) {
      if (l.contains(k)) return true;
    }
    return false;
  }

  /// يحسب لون تقريبي من الصورة////
  String? _estimateDominantColorName(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    final resized = img.copyResize(image, width: 64, height: 64);
    final w = resized.width;
    final h = resized.height;

    int totalR = 0, totalG = 0, totalB = 0;
    final count = w * h;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = resized.getPixel(x, y);
        totalR += img.getRed(p);
        totalG += img.getGreen(p);
        totalB += img.getBlue(p);
      }
    }

    final r = (totalR / count).round();
    final g = (totalG / count).round();
    final b = (totalB / count).round();

    return _mapRgbToName(r, g, b);
  }

  String _mapRgbToName(int r, int g, int b) {
    final brightness = (r + g + b) / 3.0;

    if (brightness > 230) return 'white';
    if (brightness < 40) return 'black';

    if (r > g + 30 && r > b + 30) {
      if (r > 180 && g > 160 && b < 120) return 'gold';
      return 'red';
    }
    if (g > r + 30 && g > b + 30) return 'green';
    if (b > r + 30 && b > g + 30) return 'blue';

    if ((r - b).abs() < 20 && r > 150 && b > 150) return 'purple';
    if (r > 160 && g > 160 && b < 80) return 'yellow';

    return 'grey';
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
