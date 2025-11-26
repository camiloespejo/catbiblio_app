import 'dart:convert' show json;
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

final String _baseUrl = dotenv.env['KOHA_SVC_URL'] ?? '';

/// Service for fetching the books selections/new acquisitions from the service
class BookSelection {
  final String biblionumber;
  final String name;

  BookSelection({required this.biblionumber, required this.name});

  factory BookSelection.fromJson(Map<String, dynamic> json) {
    return BookSelection(
      biblionumber: json['biblionumber'] as String,
      name: json['book_name'] as String,
    );
  }
}

class BookSelectionsService {
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

  /// Fetches the list of book selections/new acquisitions from the service
  ///
  /// Returns a `List<BookSelection>` containing the book selections.
  ///
  /// Returns an empty list in case of an error
  static Future<List<BookSelection>> getBookSelections() async {
    final dio = _createDio();

    try {
      final response = await dio.get('/book_selections');
      List<dynamic> decodedJson = json.decode(response.data);

      return decodedJson.map((item) => BookSelection.fromJson(item)).toList();
    } on DioException catch (e) {
      _log('DioException in getBookSelections: ${e.message}');
      // _log('Response data: ${e.response?.data}');
      // _log('Status code: ${e.response?.statusCode}');
      return [];
    } catch (e) {
      _log('Unexpected error in getBookSelections: $e');
      return [];
    } finally {
      dio.close();
    }
  }
}

void _log(String? message) {
  if (kDebugMode) {
    debugPrint('book_selections service log: $message');
  }
}
