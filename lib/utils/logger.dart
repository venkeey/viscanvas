import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class Logger {
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  static void debug(String message, [String? tag]) {
    _log(LogLevel.debug, message, tag);
  }

  static void info(String message, [String? tag]) {
    _log(LogLevel.info, message, tag);
  }

  static void warning(String message, [String? tag]) {
    _log(LogLevel.warning, message, tag);
  }

  static void error(String message, [String? tag]) {
    _log(LogLevel.error, message, tag);
  }

  static void _log(LogLevel level, String message, [String? tag]) {
    if (level.index < _minLevel.index) return;

    final prefix = tag != null ? '[$tag]' : '';
    final levelStr = level.name.toUpperCase();
    final timestamp = DateTime.now().toIso8601String().substring(11, 23); // HH:MM:SS.mmm

    final formattedMessage = '[$timestamp] $levelStr$prefix $message';

    // Use debugPrint for better console formatting in Flutter
    debugPrint(formattedMessage);
  }
}

// Convenience functions for common tags
class CanvasLogger {
  static void documentBlock(String message) => Logger.debug(message, 'DocumentBlock');
  static void canvasService(String message) => Logger.debug(message, 'CanvasService');
  static void canvasScreen(String message) => Logger.debug(message, 'CanvasScreen');
  static void documentEditor(String message) => Logger.debug(message, 'DocumentEditor');
}