import 'dart:convert' show json;
import 'package:flutter/material.dart' show debugPrint;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import 'package:catbiblio_app/models/book_location.dart';

final String _baseUrl = dotenv.env['KOHA_SVC_URL'] ?? '';

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
      debugPrint('DioException in getBookLocation: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');
      debugPrint('Status code: ${e.response?.statusCode}');

      // Handle specific error types
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          debugPrint('Timeout error: Check network connection');
          break;
        case DioExceptionType.badResponse:
          debugPrint('Server error: ${e.response?.statusCode}');
          break;
        case DioExceptionType.cancel:
          debugPrint('Request cancelled');
          break;
        case DioExceptionType.unknown:
          debugPrint('Unknown error: ${e.message}');
          break;
        default:
          debugPrint('Dio error: $e');
      }

      return BookLocation(level: '', room: '');
    } catch (e) {
      debugPrint('Unexpected error in getBookLocation: $e');
      return BookLocation(level: '', room: '');
    } finally {
      dio.close();
    }
  }
}
