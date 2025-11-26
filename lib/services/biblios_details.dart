import 'dart:async' show TimeoutException;
import 'dart:convert' show json;
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import 'package:catbiblio_app/models/biblios_details.dart';

final String _baseUrl = dotenv.env['KOHA_SVC_URL'] ?? '';

/// Service for fetching detailed relevant bibliographic information from a Koha-based service
class BibliosDetailsService {
  static const String marcInJson = 'json';
  static const String marcInXml = 'xml';
  static const String plainText = 'text';

  static Dio _createDio({ResponseType responseType = ResponseType.json}) {
    Dio dio = Dio();

    dio.options = BaseOptions(
      baseUrl: _baseUrl,
      responseType: responseType,
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

  /// Fetches detailed bibliographic information for a given biblionumber
  /// from a Koha-based service.
  ///
  /// Parameters:
  /// - [biblioNumber]: The biblionumber of the title to fetch details for.
  ///
  /// Returns a [BibliosDetails] object containing various bibliographic fields.
  ///
  /// If the biblionumber is invalid (<= 0), returns an empty [BibliosDetails] object.
  /// In case of an error during the request or parsing, returns a [BibliosDetails] object with empty fields.
  ///
  /// Example: http://{{baseUrl}}/cgi-bin/koha/svc/biblios_details2?biblionumber=123&format=json
  static Future<BibliosDetails> getBibliosDetails(int biblioNumber) async {
    if (biblioNumber <= 0) {
      return BibliosDetails(title: '', author: '');
    }

    final dio = _createDio();

    try {
      _log('Requesting biblio $biblioNumber from ${dio.options.baseUrl}');

      final response = await dio.get(
        '/biblios_details',
        queryParameters: {'biblionumber': biblioNumber, 'format': marcInJson},
      );

      final Map<String, dynamic> bibliosJson = response.data is String
          ? json.decode(response.data)
          : response.data;
      final List<dynamic> titleFields = bibliosJson['fields'];

      return BibliosDetails(
        title:
            '${getSubfieldData(titleFields, '245', 'a') ?? ''} ${getSubfieldData(titleFields, '245', 'b') ?? ''} ${getSubfieldData(titleFields, '245', 'c') ?? ''}'
                .trim(),
        author: getSubfieldData(titleFields, '100', 'a') ?? '',
        isbn: getSubfieldData(titleFields, '020', 'a') ?? '',
        language: getSubfieldData(titleFields, '041', 'a') ?? '',
        originalLanguage: getSubfieldData(titleFields, '041', 'h') ?? '',
        subject: getSubfieldData(titleFields, '650', 'a') ?? '',
        collaborators: getSubfieldData(titleFields, '700', 'a') ?? '',
        summary: getSubfieldData(titleFields, '520', 'a') ?? '',
        cdd:
            '${getSubfieldData(titleFields, '082', 'a') ?? ''} ${getSubfieldData(titleFields, '082', 'b') ?? ''} ${getSubfieldData(titleFields, '082', '2') ?? ''}'
                .trim(),
        loc:
            '${getSubfieldData(titleFields, '050', 'a') ?? ''} ${getSubfieldData(titleFields, '050', 'b') ?? ''}'
                .trim(),
        editor:
            '${getSubfieldData(titleFields, '260', 'a') ?? ''} ${getSubfieldData(titleFields, '260', 'b') ?? ''} ${getSubfieldData(titleFields, '260', 'c') ?? ''} ${getSubfieldData(titleFields, '264', 'a') ?? ''} ${getSubfieldData(titleFields, '264', 'b') ?? ''} ${getSubfieldData(titleFields, '264', 'c') ?? ''}'
                .trim(),
        edition: getSubfieldData(titleFields, '250', 'a') ?? '',
        description:
            '${getSubfieldData(titleFields, '300', 'a') ?? ''} ${getSubfieldData(titleFields, '300', 'b') ?? ''} ${getSubfieldData(titleFields, '300', 'c') ?? ''}'
                .trim(),
        otherClassification: getSubfieldData(titleFields, '084', 'a') ?? '',
        lawClassification:
            '${getSubfieldData(titleFields, '099', 'a') ?? ''} ${getSubfieldData(titleFields, '099', 'b') ?? ''} ${getSubfieldData(titleFields, '099', 'c') ?? ''}'
                .trim(),
      );
    } on DioException catch (e) {
      _log('DioException in getBibliosDetails: ${e.message}');
      // _log('Response headers: ${e.response?.headers}');
      // _log('Status code: ${e.response?.statusCode}');
      // Handle specific error types
      if (e.response?.statusCode == 404) {
        // _log(
        //   'BibliosDetails not found (404) for biblionumber $biblioNumber',
        // );
        return BibliosDetails(title: '', author: '');
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw TimeoutException('Request to $_baseUrl timed out');
      }

      switch (e.type) {
        case DioExceptionType.badResponse:
          _log('Server error: ${e.response?.statusCode}');
          break;
        default:
          _log('Dio error: $e');
      }

      rethrow;
      //return BibliosDetails(title: 'Error', author: 'Error');
    } catch (e) {
      // Handle JSON parsing or other errors
      _log('Unexpected error in getBibliosDetails: $e');
      return BibliosDetails(title: '', author: '');
    } finally {
      dio.close();
    }
  }

  /// Fetches the MARC record in plain text format for a given biblionumber
  /// from a Koha-based service.
  ///
  /// Parameters:
  /// - [biblioNumber]: The biblionumber of the title to fetch the MARC record for.
  ///
  /// Returns the MARC record as a plain text [String].
  ///
  /// If the biblionumber is invalid (<= 0), returns null.
  ///
  /// In case of an error during the request, returns null.
  static Future<String?> getBibliosMarcPlainText(int biblioNumber) async {
    if (biblioNumber <= 0) {
      return null;
    }

    final dio = _createDio(responseType: ResponseType.plain);

    try {
      // Example of how to make the request
      final response = await dio.get(
        '/biblios_details',
        queryParameters: {'biblionumber': biblioNumber, 'format': plainText},
      );

      // Return the plain text MARC record
      return response.data as String;
    } on DioException catch (e) {
      // Handle specific error types
      if (e.response?.statusCode == 404) {
        // _log(
        //   'BibliosDetails not found (404) for biblionumber $biblioNumber',
        // );
        // Return an empty string for not found items
        return null;
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw TimeoutException('Request to $_baseUrl timed out');
      }

      switch (e.type) {
        case DioExceptionType.badResponse:
          _log('Server error: ${e.response?.statusCode}');
          break;
        default:
          _log('Dio error: $e');
      }

      rethrow;
    } catch (e) {
      _log('Unexpected error in getBibliosMarcPlainText: $e');
      return null;
    } finally {
      dio.close();
    }
  }

  /// Helper function to find all values for a given tag and subfield in a MARC record formatted in JSON,
  /// concatenating said values with a pipe '|' if multiple are found.
  ///
  /// Parameters:
  /// - [fields]: The list of fields from the MARC record in JSON format.
  /// - [tag]: The MARC tag to search for (e.g., '020').
  /// - [subfieldCode]: The subfield code to search for within the specified tag (e.g., 'a').
  ///
  /// Returns a concatenated [String] of all found subfield values separated by ' | '.
  ///
  /// Returns null if no matching subfields are found.
  static String? getSubfieldData(
    List<dynamic> fields,
    String tag,
    String subfieldCode,
  ) {
    // 1. Find ALL maps that contain the main tag (e.g., {"020": {...}}).
    // We use 'where' instead of 'firstWhere' to get all occurrences.
    final fieldContainers = fields.where(
      (element) => (element as Map).containsKey(tag),
    );

    // If no fields with that tag exist, stop here.
    if (fieldContainers.isEmpty) {
      return null;
    }

    // A list to hold the data from each found subfield.
    final List<String> results = [];

    // 2. Loop through each of the found field containers.
    for (final fieldContainer in fieldContainers) {
      // 3. Get the value associated with the tag (e.g., the map with "ind1", "subfields").
      final tagData = fieldContainer[tag];

      // 4. Check if the tag's data is a Map and contains the "subfields" key.
      if (tagData is Map && tagData.containsKey('subfields')) {
        // 5. Get the list of subfields.
        final List<dynamic> subfieldsList = tagData['subfields'];

        // 6. Search the list to find the first map containing our subfieldCode.
        // (It's rare for the same subfield code to repeat within a single field).
        final subfieldMap = subfieldsList.firstWhere(
          (subfield) => (subfield as Map).containsKey(subfieldCode),
          orElse: () => null,
        );

        // 7. If we found a matching subfield, add its value to our results list.
        if (subfieldMap != null) {
          final value = subfieldMap[subfieldCode];
          if (value is String) {
            results.add(value);
          }
        }
      }
    }

    // 8. After checking all fields, process the collected results.
    if (results.isEmpty) {
      _log(
        'No matching subfields found for tag $tag and subfield $subfieldCode',
      );
      // If we looped through everything but found no matching subfields.
      return null;
    } else {
      // Join all found values with a " | " and return the final string.
      return results.join(' | ');
    }
  }
}

void _log(String? message) {
  if (kDebugMode) {
    debugPrint('biblios_details service log: $message');
  }
}
