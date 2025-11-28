import 'dart:convert' show json;
import 'dart:async' show TimeoutException;
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import 'package:catbiblio_app/models/library.dart';

final String _baseUrl = dotenv.env['KOHA_SVC_URL'] ?? '';

/// Service for fetching libraries from a Koha-based service
class LibrariesService {
  static Dio _createDio() {
    Dio dio = Dio();

    dio.options = BaseOptions(
      baseUrl: _baseUrl,
      responseType: ResponseType.plain,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json;encoding=UTF-8'},
    );

    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
        retryEvaluator: (error, _) {
          return error.type == DioExceptionType.receiveTimeout;
        },
      ),
    );

    return dio;
  }

  /// Fetches the list of libraries from a Koha-based service
  ///
  /// Returns a `List<Library>` containing all available libraries.
  ///
  /// Returns an empty list if no libraries are found or in case of an error
  static Future<List<Library>> getLibraries() async {
    final dio = _createDio();

    try {
      final response = await dio.get('/libraries');

      final List<dynamic> librariesJson = json.decode(response.data);

      return librariesJson
          .map((json) => Library.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _log('DioException in getLibraries: ${e.message}');
      // _log('Response data: ${e.response?.data}');
      // _log('Status code: ${e.response?.statusCode}');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
            throw TimeoutException('Timeout error: Check your internet connection');
      }

      // Handle specific error types
      switch (e.type) {
        case DioExceptionType.badResponse:
          _log('Server error: ${e.response?.statusCode}');
          break;
        case DioExceptionType.cancel:
          _log('Request cancelled');
          break;
        case DioExceptionType.unknown:
          _log('Unknown error: ${e.message}');
          break;
        default:
          _log('Dio error: $e');
      }

      // Return an empty list in case any error
      return [];
    } catch (e) {
      _log('Unexpected error in getLibraries: $e');
      return [];
    } finally {
      dio.close();
    }
  }
}

void _log(String? message) {
  if (kDebugMode) {
    debugPrint('libraries service log: $message');
  }
}
