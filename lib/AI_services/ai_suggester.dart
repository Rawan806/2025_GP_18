// lib/AI_services/ai_suggester.dart
import 'dart:typed_data';
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

  Future<void> _ensureLoaded() async {
    if (_interpreter != null && _labels.isNotEmpty) return;
    _interpreter = await Interpreter.fromAsset(_modelAsset);

    final txt = await rootBundle.loadString(_labelsAsset);
    _labels = txt.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<List<Map<String, dynamic>>> suggest(Uint8List imageBytes) async {
    await _ensureLoaded();
    final interpreter = _interpreter!;
    final inputT  = interpreter.getInputTensors().first;
    final outputT = interpreter.getOutputTensors().first;

    final input = _preprocess(imageBytes,
        width: _inputWidth, height: _inputHeight, asFloat: _expectsFloat);

    final outputType = outputT.type;        // TensorType
    final numClasses = outputT.shape.last;

    dynamic outputBuffer;
    if (outputType == TensorType.float32) {
      outputBuffer = List.filled(numClasses, 0.0).reshape([1, numClasses]);
    } else if (outputType == TensorType.uint8) {
      outputBuffer = List.filled(numClasses, 0).reshape([1, numClasses]);
    } else {
      throw Exception('Unsupported output tensor type: $outputType');
    }

    interpreter.run(input, outputBuffer);

    List<double> probs;
    if (outputType == TensorType.float32) {
      probs = (outputBuffer as List).first.cast<double>();
    } else {
      probs = ((outputBuffer as List).first.cast<int>()).map((v) => v / 255.0).toList();
    }

    final idx = List.generate(probs.length, (i) => i)..sort((a,b)=>probs[b].compareTo(probs[a]));
    return [
      for (final i in idx)
        {
          'label': (i < _labels.length) ? _labels[i] : 'class_$i',
          'score': probs[i],
          'index': i,
        }
    ];
  }

  List _preprocess(Uint8List bytes,
      {required int width, required int height, required bool asFloat}) {
    final original = img.decodeImage(bytes);
    if (original == null) throw Exception('Could not decode image');
    final resized = img.copyResize(original, width: width, height: height);

    if (asFloat) {
      final input = List.generate(
          1, (_) => List.generate(height, (_) => List.generate(width, (_) => List.filled(3, 0.0))));
      for (var y=0; y<height; y++) {
        for (var x=0; x<width; x++) {
          final p = resized.getPixel(x, y);
          input[0][y][x][0] = img.getRed(p)   / 255.0;
          input[0][y][x][1] = img.getGreen(p) / 255.0;
          input[0][y][x][2] = img.getBlue(p)  / 255.0;
        }
      }
      return input;
    } else {
      final input = List.generate(
          1, (_) => List.generate(height, (_) => List.generate(width, (_) => List.filled(3, 0))));
      for (var y=0; y<height; y++) {
        for (var x=0; x<width; x++) {
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
