import 'dart:io';
import 'package:flutter/services.dart';

class NativeShare {
  static const platform = MethodChannel('com.example.grocery_bot/share');

  static Future<void> shareText(String text) async {
    if (Platform.isAndroid) {
      try {
        await platform.invokeMethod('shareText', {'text': text});
      } on PlatformException catch (e) {
        print("Failed to share text: ${e.message}");
      }
    } else {
      print("Sharing not supported on this platform.");
    }
  }
}
