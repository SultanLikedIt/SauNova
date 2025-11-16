import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger();

  static void info(dynamic message) {
    _logger.i(message);
  }

  static void warning(String message) {
    _logger.w(message);
  }

  static void error(String message) {
    _logger.e(message);
  }

  static void debug(String message) {
    _logger.d(message);
  }
}
