import 'dart:convert' show json;
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import 'package:catbiblio_app/models/book_location.dart';

final String _baseUrl = dotenv.env['KOHA_SVC_URL'] ?? '';

/// Service for fetching book locations from a Koha-based service
class LocationsService {
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

  /// Fetches the book location based on LCC, collection, and library code from a Koha-based service
  ///
  /// Parameters:
  /// - [lcc]: The Library of Congress Classification code of the book.
  /// - [collection]: The collection to which the book belongs.
  /// - [libraryCode]: The code of the library where the book is located.
  ///
  /// Returns a `BookLocation` object containing the level and room information.
  ///
  /// Returns an empty `BookLocation` (level and room as empty strings) in case of an error.
  static Future<BookLocation> getBookLocation(
    String lcc,
    String collection,
    String libraryCode,
  ) async {
    final dio = _createDio();

    try {
      final response = await dio.get(
        '/locations',
        queryParameters: {
          'lcc': lcc,
          'coleccion': collection,
          'homebranch': libraryCode,
        },
      );

      BookLocation bookLocation = BookLocation.fromJson(
        json.decode(response.data),
      );
      return bookLocation;
    } on DioException catch (e) {
      // Log the error for debugging
      _log('DioException in getBookLocation: ${e.message}');
      // _log('Response data: ${e.response?.data}');
      // _log('Status code: ${e.response?.statusCode}');

      // Handle specific error types
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          _log('Timeout error: Check network connection');
          break;
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

      return BookLocation(level: '', room: '');
    } catch (e) {
      _log('Unexpected error in getBookLocation: $e');
      return BookLocation(level: '', room: '');
    } finally {
      dio.close();
    }
  }
}

void _log(String? message) {
  if (kDebugMode) {
    debugPrint('locations service log: $message');
  }
}
