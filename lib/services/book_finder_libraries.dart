import 'dart:convert' show json;
import 'package:flutter/material.dart' show debugPrint;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

final String _baseUrl = dotenv.env['KOHA_SVC_URL'] ?? '';

/// Service for fetching the libraries participating in the Book Finder service
class BookFinderLibraries {
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

  /// Fetches the set of library codes that participate in the Book Finder service
  ///
  /// Returns a `Set<String>` containing the library codes.
  ///
  /// Returns an empty set in case of an error
  static Future<Set<String>> getBookFinderLibrariesSet() async {
    final dio = _createDio();

    try {
      final response = await dio.get('/book_finder_libraries');
      List<dynamic> decodedJson = json.decode(response.data);

      return decodedJson.map((item) => item['library_code'] as String).toSet();
    } on DioException catch (e) {
      // Log the error for debugging
      debugPrint('DioException in getBookFinderLibrariesSet: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');
      debugPrint('Status code: ${e.response?.statusCode}');
      return {};
    } catch (e) {
      debugPrint('Unexpected error in getBookFinderLibrariesSet: $e');
      return {};
    } finally {
      dio.close();
    }
  }
}
