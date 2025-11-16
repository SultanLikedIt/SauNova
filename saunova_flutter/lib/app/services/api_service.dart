import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:saunova/log/app_logger.dart';

typedef ApiData = Future<Map<String, dynamic>?>;

class ApiService {
  static final String _apiBaseUrl = dotenv.env['API_URL']!;
  static String get wsBaseUrl =>
      _apiBaseUrl.replaceFirst(RegExp(r'^http', caseSensitive: false), 'ws');

  static late final Dio _dio;
  static late final FirebaseAuth _auth;

  static void init() {
    _auth = FirebaseAuth.instance;
    _dio = Dio(
      BaseOptions(
        baseUrl: _apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final user = _auth.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  static Future<void> startSession(temperature, humidity, sessionLength) async {
    try {
      final response = await _dio.post(
        '/sauna/start_session',
        data: {
          'temperature': temperature,
          'humidity': humidity,
          'session_length': sessionLength,
        },
      );
      AppLogger.info('Session started: ${response.data}');
    } on DioException catch (e) {
      AppLogger.error(
        'Start session failed: ${e.response?.statusCode ?? 'Unknown'}',
      );
    }
  }

  static ApiData stopSession() async {
    try {
      final response = await _dio.post('/sauna/end_session');
      return response.data;
    } on DioException catch (e) {
      AppLogger.error(
        'Stop session failed: ${e.response?.statusCode ?? 'Unknown'}',
      );
      return null;
    }
  }

  static ApiData login() async {
    try {
      final response = await _dio.get('/auth/login');
      return response.data;
    } on DioException catch (e) {
      AppLogger.error(
        'Login failed: ${e.response?.statusMessage ?? 'Unknown'}',
      );
      return null;
    }
  }

  static ApiData signUp(String email, String? image) async {
    try {
      final response = await _dio.post(
        '/auth/signup',
        data: {'email': email, 'image': image},
      );
      return response.data;
    } on DioException catch (e) {
      AppLogger.error('Sign Up failed: ${e.response?.statusCode ?? 'Unknown'}');
      return null;
    }
  }

  static ApiData finishSetup(
    String gender,
    int height,
    int weight,
    int age,
    List<String> goals,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/finish-setup',
        data: {
          'gender': gender,
          'height': height,
          'weight': weight,
          'age': age,
          'goals': goals,
        },
      );
      return response.data;
    } on DioException catch (e) {
      AppLogger.error(
        'Finish setup failed: ${e.response?.statusCode ?? 'Unknown'}',
      );
      return null;
    }
  }

  static Future<bool> setProfileImage(String? imageUrl) async {
    try {
      final path = '/image/profile';
      final response = imageUrl != null
          ? _dio.post(path, data: {'image_url': imageUrl})
          : _dio.delete(path);
      await response;
      return true;
    } on DioException catch (e) {
      AppLogger.error(
        'Set profile image failed: ${e.response?.statusCode ?? 'Unknown'}',
      );
      return false;
    }
  }

  /// Health check endpoint
  static Future<bool> ping() async {
    try {
      final response = await _dio.get('/ping');
      return response.data['status'] == 'ok';
    } on DioException {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getSaunaRecommendations() async {
    try {
      final response = await _dio.get('/sauna/recommendations');
      return response.data;
    } on DioException catch (e) {
      final errorText =
          e.response?.data?.toString() ?? e.message ?? 'Unknown error';
      AppLogger.error(
        'Get recommendations failed: ${e.response?.statusCode ?? 'Unknown'} - $errorText',
      );
    }
    return null;
  }

  /// Ask a question to the chatbot (non-streaming)
  ///
  /// [question] - The question to ask
  /// [sessionId] - Chat session ID
  /// Returns response with answer, sources, session_id, chat_history
  static Future<Map<String, dynamic>> askQuestion(String question) async {
    try {
      final response = await _dio.post(
        '/chat/ask',
        data: {'question': question},
      );
      AppLogger.info('Ask question response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      String errorMessage =
          'Ask question failed: ${e.response?.statusCode ?? 'Unknown'}';

      if (e.response?.data != null) {
        try {
          final errorData = e.response!.data;
          if (errorData is Map && errorData['detail'] != null) {
            errorMessage = errorData['detail'].toString();
          } else {
            errorMessage = errorData.toString();
          }
        } catch (_) {
          // Ignore parsing errors
        }
      }

      final error = Exception(errorMessage);
      throw error;
    }
  }
}
