import 'package:flutter/material.dart';
import '../main.dart';

class UIFeedback {
  static void snack(
      String message, {
        Color? color,
        Duration duration = const Duration(seconds: 3),
      }) {
    rootMessengerKey.currentState?.hideCurrentSnackBar();
    rootMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: duration,
      ),
    );
  }
}
