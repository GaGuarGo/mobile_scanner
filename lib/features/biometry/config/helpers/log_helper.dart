import 'package:flutter/material.dart';

class LogHelper {
  static const _reset = '\x1B[0m';

  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _blue = '\x1B[34m';
  static const _magenta = '\x1B[35m';

  static void info(String message) {
    debugPrint('$_blue[INFO] $message$_reset');
  }

  static void success(String message) {
    debugPrint('$_green[SUCCESS] $message$_reset');
  }

  static void warning(String message) {
    debugPrint('$_yellow[WARNING] $message$_reset');
  }

  static void error(String message) {
    debugPrint('$_red[ERROR] $message$_reset');
  }

  static void debug(String message) {
    debugPrint('$_magenta[DEBUG] $message$_reset');
  }

  static void custom(String label, String message, String colorCode) {
    debugPrint('$colorCode[$label] $message$_reset');
  }
}
