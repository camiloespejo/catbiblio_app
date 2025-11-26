import 'dart:convert' show json;
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:xml/xml.dart' as xml; // DEPRECATED as SRU is not longer used
import 'package:collection/collection.dart'; // DEPRECATED as SRU is not longer used

import 'package:catbiblio_app/models/query_params.dart';
import 'package:catbiblio_app/models/book_preview.dart';
import 'package:catbiblio_app/models/search_result.dart';

final String _baseUrl = dotenv.env['KOHA_SVC_URL'] ?? '';

/// Service for searching books from a Koha-based service
class SearchService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      responseType: ResponseType.plain,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/xml'},
    ),
  );

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

  /// Searches for books based on the provided query parameters.
  ///
  /// Parameters:
  /// - [params]: An instance of [QueryParams] containing the search criteria.
  ///
  /// Returns a [SearchResult] containing a `List<BookPreview>` and the total [int] of records found,
  /// or throws a exception if the request fails.
  ///
  /// Examples:
  /// - Title search: http://baseUrl/cgi-bin/koha/svc/new_search?title=dune&branch=USBI-X
  ///   - searchBooks(QueryParams(library: 'USBI-X', searchBy: 'title', searchQuery: 'dune'))
  /// - Author search: http://baseUrl/cgi-bin/koha/svc/new_search?author=frank+herbert
  ///   - searchBooks(QueryParams(library: 'USBI-X', searchBy: 'author', searchQuery: 'frank herbert'))
  /// - Subject search: http://baseUrl/cgi-bin/koha/svc/new_search?subject=ciencia+ficcion&branch=USBI-V
  ///   - searchBooks(QueryParams(library: 'USBI-V', searchBy: 'subject', searchQuery: 'ciencia ficcion'))
  static Future<SearchResult> searchBooks(QueryParams params) async {
    final dio = _createDio();
    final queryParameters = buildQueryParameters(params);

    if (params.searchQuery.isEmpty) {
      _log('Empty search query provided');
      return SearchResult(books: [], totalRecords: 0);
    }

    try {
      final response = await dio.get(
        '/new_search',
        queryParameters: queryParameters,
      );

      final List<BookPreview> results = json
          .decode(response.data)
          .map<BookPreview>(
            (json) => BookPreview.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      return SearchResult(
        books: results,
        totalRecords: results.isNotEmpty ? results.first.totalRecords : 0,
      );
    } on DioException catch (e) {
      _log('DioException caught: ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      _log('Unexpected error in searchBooks: $e');
      throw ParseException("Unexpected error: $e");
    } finally {
      dio.close();
    }
  }

  /// Builds query parameters for the search request based on [QueryParams].
  ///
  /// Returns a map of query parameters to be used in the search request.
  ///
  /// Throws a [ParseException] if there is an error building the parameters.
  static Map<String, dynamic> buildQueryParameters(QueryParams params) {
    late Map<String, dynamic> queryParameters;

    try {
      queryParameters =
          <String, dynamic>{
            'q': params.searchBy == 'general' ? params.searchQuery : null,
            'title': params.searchBy == 'title' ? params.searchQuery : null,
            'author': params.searchBy == 'author' ? params.searchQuery : null,
            'subject': params.searchBy == 'subject' ? params.searchQuery : null,
            'isbn': params.searchBy == 'isbn' ? params.searchQuery : null,
            'issn': params.searchBy == 'issn' ? params.searchQuery : null,
            'branch': params.library != 'all' ? params.library : null,
            'item_type': params.itemType != 'all' ? params.itemType : null,
            'offset': params.startRecord > 0 ? params.startRecord : null,
          }..removeWhere(
            (key, value) =>
                value == null ||
                (value is String && value.isEmpty) ||
                (value is int && value <= 1),
          );

      return queryParameters;
    } catch (e) {
      _log("Error building query parameters: $e");
      throw ParseException("Error building query parameters: $e");
    }
  }

  /// --- DEPRECATED ---
  /// MARC and SRU namespaces
  static const String _marcNamespace = "http://www.loc.gov/MARC21/slim";
  static const String _sruNamespace = "http://www.loc.gov/zing/srw/";

  /// --- DEPRECATED ---
  /// MARC field tags
  static const String _titleTag = "245";
  static const String _authorTag = "100";
  static const String _biblioNumberTag = "999";
  static const String _publishingDetailsTag = "260";

  /// --- DEPRECATED ---
  ///
  /// Searches for books based on the provided [QueryParams].
  ///
  /// Returns a [SearchResult] containing a `List<BookPreview>` and the total [int] of records found,
  /// or throws a [SruException] if the request fails.
  ///
  /// Examples:
  /// - Title search: http://baseUrl/cgi-bin/koha/svc/search?title=dune&branch=USBI-X
  ///   - searchBooks(QueryParams(library: 'USBI-X', searchBy: 'title', searchQuery: 'dune'))
  /// - Author search: http://baseUrl/cgi-bin/koha/svc/search?author=frank+herbert
  ///   - searchBooks(QueryParams(library: 'USBI-X', searchBy: 'author', searchQuery: 'frank herbert'))
  /// - Subject search: http://baseUrl/cgi-bin/koha/svc/search?subject=ciencia+ficcion&branch=USBI-V
  ///   - searchBooks(QueryParams(library: 'USBI-V', searchBy: 'subject', searchQuery: 'ciencia ficcion'))
  static Future<SearchResult> sruSearchBooks(QueryParams params) async {
    final queryParameters = buildQueryParameters(params);

    try {
      final response = await _dio.get(
        '/sru_search',
        queryParameters: queryParameters,
      );

      return _parseXmlResponse(response.data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ParseException("Unexpected error: $e");
    }
  }

  /// --- DEPRECATED ---
  ///
  /// Parses the XML response and extracts total records and book previews
  static SearchResult _parseXmlResponse(String xmlData) {
    try {
      final document = xml.XmlDocument.parse(xmlData);

      final totalRecords = _extractTotalRecords(document);
      final books = _extractBooks(document);

      return SearchResult(books: books, totalRecords: totalRecords);
    } catch (e) {
      throw ParseException("Error parsing SRU response: $e");
    }
  }

  /// --- DEPRECATED ---
  ///
  /// Extracts the total number of records from the XML response
  static int _extractTotalRecords(xml.XmlDocument document) {
    final numberOfRecords = document
        .findAllElements("numberOfRecords", namespace: _sruNamespace)
        .firstOrNull
        ?.innerText;

    return int.tryParse(numberOfRecords ?? '0') ?? 0;
  }

  /// --- DEPRECATED ---
  ///
  /// Extracts all books from the XML document
  static List<BookPreview> _extractBooks(xml.XmlDocument document) {
    final records = document.findAllElements(
      "recordData",
      namespace: _sruNamespace,
    );

    return records
        .map(_parseBookRecord)
        .whereType<BookPreview>() // Filter out failed parses
        .toList();
  }

  /// --- DEPRECATED ---
  ///
  /// Parses a single book record from the XML
  static BookPreview? _parseBookRecord(xml.XmlElement recordData) {
    try {
      final record = recordData
          .findElements("record", namespace: _marcNamespace)
          .firstOrNull;

      if (record == null) {
        debugPrint("Warning: No MARC record found in recordData");
        return null;
      }

      final dataFieldHelper = _DataFieldHelper(record);

      final title = _extractTitle(dataFieldHelper);
      final author = _extractAuthor(dataFieldHelper);
      final biblioNumber = _extractBiblioNumber(dataFieldHelper);
      final publishingDetails = _extractPublishingDetails(dataFieldHelper);
      final locatedInLibraries = _countCoincidences(dataFieldHelper);

      //if (title.trim().isEmpty) return null;

      return BookPreview(
        title: title,
        author: author,
        coverUrl: '',
        biblioNumber: biblioNumber,
        publishingDetails: publishingDetails,
        locatedInLibraries: locatedInLibraries,
        totalRecords: 0,
        isbn: '',
        normalizedIsbn: '',
      );
    } catch (e) {
      debugPrint("Error parsing book record: ${e.toString()}");
      return null;
    }
  }

  /// --- DEPRECATED ---
  ///
  /// Extracts the title from MARC field 245
  static String _extractTitle(_DataFieldHelper helper) {
    final titleParts = [
      helper.getSubfield(_titleTag, 'a'), // Title
      helper.getSubfield(_titleTag, 'b'), // Remainder of title
      helper.getSubfield(_titleTag, 'c'), // Statement of responsibility
    ].where((part) => part != null && part.isNotEmpty).toList();

    return titleParts.join(' ').trim();
  }

  /// --- DEPRECATED ---
  ///
  /// Extracts the author from MARC field 100
  static String _extractAuthor(_DataFieldHelper helper) {
    return helper.getSubfield(_authorTag, 'a') ?? '';
  }

  /// --- DEPRECATED ---
  ///
  /// Extracts the bibliographic number from MARC field 999 (local use)
  static String _extractBiblioNumber(_DataFieldHelper helper) {
    return helper.getSubfield(_biblioNumberTag, 'c')?.trim() ?? '';
  }

  /// --- DEPRECATED ---
  ///
  static int _countCoincidences(_DataFieldHelper helper) {
    return helper._datafieldTagCoincidences('952');
  }

  /// --- DEPRECATED ---
  ///
  /// Extracts publishing details from MARC field 260
  static String _extractPublishingDetails(_DataFieldHelper helper) {
    final publishingParts = [
      helper.getSubfield(_publishingDetailsTag, 'a'), // Place of publication
      helper.getSubfield(_publishingDetailsTag, 'b'), // Publisher
      helper.getSubfield(_publishingDetailsTag, 'c'), // Date of publication
    ].where((part) => part != null && part.isNotEmpty).toList();

    return publishingParts.join(' ');
  }

  /// Handles Dio exceptions and providing meaningful error messages
  static SruException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        _log('Connection timeout: Check your internet connection');
        return const NetworkException(
          "Connection timeout - please check your internet connection",
        );
      case DioExceptionType.receiveTimeout:
        _log('Receive timeout: Check network connection');
        return const NetworkException(
          "Request timeout - the server took too long to respond",
        );
      case DioExceptionType.badResponse:
        _log(
          'Bad response from server: ${e.response?.statusCode} - ${e.response?.statusMessage}',
        );
        final statusCode = e.response?.statusCode;
        final statusMessage = e.response?.statusMessage;
        return ApiException(
          "Server error: $statusCode - $statusMessage",
          statusCode: statusCode,
        );
      case DioExceptionType.connectionError:
        _log('Connection error: Unable to reach the server');
        return const NetworkException(
          "Connection error - unable to reach the server",
        );
      case DioExceptionType.cancel:
        _log('Request was cancelled');
        return const NetworkException("Request was cancelled");
      default:
        _log('Network error: ${e.message}');
        return NetworkException("Network error: ${e.message}");
    }
  }
}

void _log(String? message) {
  if (kDebugMode) {
    debugPrint('search service log: $message');
  }
}

/// --- DEPRECATED ---
sealed class SruException implements Exception {
  final String message;
  const SruException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends SruException {
  const NetworkException(super.message);
}

class ParseException extends SruException {
  const ParseException(super.message);
}

class ApiException extends SruException {
  final int? statusCode;
  const ApiException(super.message, {this.statusCode});
}

/// --- DEPRECATED ---
///
/// Helper class to simplify datafield and subfield extraction
/// This encapsulates the repetitive XML navigation logic
class _DataFieldHelper {
  final xml.XmlElement record;
  final Map<String, xml.XmlElement?> _dataFieldCache = {};

  _DataFieldHelper(this.record);

  /// Gets a datafield by tag, with caching for performance
  xml.XmlElement? _getDataField(String tag) {
    if (!_dataFieldCache.containsKey(tag)) {
      _dataFieldCache[tag] = record
          .findElements("datafield", namespace: SearchService._marcNamespace)
          .firstWhereOrNull((df) => df.getAttribute("tag") == tag);
    }
    return _dataFieldCache[tag];
  }

  /// Gets a subfield value by datafield tag and subfield code
  String? getSubfield(String datafieldTag, String subfieldCode) {
    final dataField = _getDataField(datafieldTag);
    if (dataField == null) return null;

    return dataField
        .findElements("subfield", namespace: SearchService._marcNamespace)
        .firstWhereOrNull((sf) => sf.getAttribute("code") == subfieldCode)
        ?.innerText
        .trim();
  }

  int _datafieldTagCoincidences(String tag) {
    Set libraries = {};

    final datafields952 = record
        .findElements("datafield", namespace: SearchService._marcNamespace)
        .where((element) => element.getAttribute("tag") == tag);

    for (var df in datafields952) {
      var libraryName = df
          .findElements("subfield", namespace: SearchService._marcNamespace)
          .firstWhereOrNull((sf) => sf.getAttribute("code") == 'a')
          ?.innerText
          .trim();

      if (libraryName != null && libraryName.isNotEmpty) {
        libraries.add(libraryName);
      }
    }

    return libraries.length;
  }
}
