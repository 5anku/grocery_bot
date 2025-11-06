// lib/native_share.dart
import 'dart:io';
import 'package:flutter/services.dart';

class NativeShare {
  static const platform = MethodChannel('com.sanku.mygrocerylist/share');

  static Future shareText(String text) async {
    if (Platform.isAndroid) {
      try {
        await platform.invokeMethod('shareText', {'text': text});
      } on PlatformException catch (e) {
        // Optionally log
        // print("Failed to share text: ${e.message}");
      }
    } else {
      // print("Sharing not supported on this platform.");
    }
  }
}
