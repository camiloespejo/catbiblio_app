import 'dart:convert' show json;
import 'dart:collection' show HashMap;
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

final String _baseUrl = dotenv.env['KOHA_SVC_URL'] ?? '';

class HomeLibraries {
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

  static Future<HashMap<String, String>> getHomeLibrariesHashMap() async {
    final dio = _createDio();

    try {
      final response = await dio.get('/home_libraries');
      List<dynamic> decodedJson = json.decode(response.data);

      return decodedJson.fold<HashMap<String, String>>(
        HashMap<String, String>(),
        (map, item) {
          map[item['library_code'] as String] = item['library_name'] as String;
          return map;
        },
      );
    } on DioException catch (e) {
      // _log('Response data: ${e.response?.data}');
      // _log('Status code: ${e.response?.statusCode}');
      _log('DioException in getBookFinderLibrariesSet: ${e.message}');
      return HashMap<String, String>();
    } catch (e) {
      _log('Unexpected error in getBookFinderLibrariesSet: $e');
      return HashMap<String, String>();
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
