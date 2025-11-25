import 'dart:convert' show json;
import 'package:flutter/material.dart' show debugPrint;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

final String _baseUrl = dotenv.env['KOHA_SVC_URL'] ?? '';

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

  static Future<List<BookSelection>> getBookSelections() async {
    final dio = _createDio();

    try {
      final response = await dio.get('/book_selections');
      List<dynamic> decodedJson = json.decode(response.data);

      return decodedJson.map((item) => BookSelection.fromJson(item)).toList();
    } on DioException catch (e) {
      // Log the error for debugging
      debugPrint('DioException in getBookSelections: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');
      debugPrint('Status code: ${e.response?.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Unexpected error in getBookSelections: $e');
      return [];
    } finally {
      dio.close();
    }
  }
}
