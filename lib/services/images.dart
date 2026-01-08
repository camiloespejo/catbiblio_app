import 'package:flutter/material.dart' show Image, BoxFit;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

final String _baseUrl =
    dotenv.env['KOHA_BASE_URL'] ?? 'https://catbiblio.uv.mx';

const String _openLibraryBaseUrl = 'https://covers.openlibrary.org';

/// Represents a fetched thumbnail together with its source.
class ThumbnailResult {
  /// The fetched image widget.
  final Image image;

  /// The source of the image (e.g., 'local' or 'openlibrary').
  final String source;
  ThumbnailResult(this.image, this.source);
}

/// Service for fetching book images from local Koha instance and OpenLibrary
class ImageService {
  static Dio _createDio() {
    Dio dio = Dio();

    dio.options = BaseOptions(
      baseUrl: '',
      responseType: ResponseType.bytes,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
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

  // Source marker to indicate where the thumbnail was fetched from.
  static const String sourceLocal = 'local';
  static const String sourceOpenLibrary = 'openlibrary';

  /// Fetches a book thumbnail, trying local source first, then OpenLibrary.
  ///
  /// Parameters:
  /// - [biblionumber]: The biblionumber to fetch the thumbnail from the local Koha instance.
  /// - [isbn]: The ISBN to fetch the thumbnail from OpenLibrary if local fetch fails
  ///
  ///
  /// Returns a [ThumbnailResult] containing the image and its source if found,
  /// otherwise returns null.
  static Future<ThumbnailResult?> fetchThumbnail(
    String biblionumber,
    String isbn,
  ) async {
    final local = await fetchThumbnailLocal(biblionumber);
    if (local != null) {
      return ThumbnailResult(local, sourceLocal);
    }

    if (isbn.isNotEmpty) {
      final openLibrary = await fetchThumbnailOpenLibrary(isbn);
      if (openLibrary != null) {
        return ThumbnailResult(openLibrary, sourceOpenLibrary);
      }
    }

    return null;
  }

  /// Fetches an image from the server using the provided [biblionumber].
  ///
  /// Parameters:
  /// - [biblionumber]: The biblionumber to fetch the thumbnail from the local Koha instance.
  ///
  /// Returns an [Image] widget if the image is found and valid, otherwise returns null.
  static Future<Image?> fetchThumbnailLocal(String biblionumber) async {
    final dio = _createDio();

    try {
      final response = await dio.get(
        '$_baseUrl/cgi-bin/koha/opac-image.pl?thumbnail=1&biblionumber=$biblionumber',
      );
      if (response.headers.value('content-type') != null &&
          response.headers
              .value('content-type')!
              .toLowerCase()
              .contains('image/png') &&
          response.statusCode == 200) {
        final bytes = response.data;
        return Image.memory(bytes, fit: BoxFit.fitHeight);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    } finally {
      dio.close();
    }
  }

  /// Fetches an image from OpenLibrary using the provided [isbn].
  ///
  /// Parameters:
  /// - [isbn]: The ISBN to fetch the thumbnail from OpenLibrary.
  ///
  /// Returns an [Image] widget if the image is found and valid, otherwise returns null.
  static Future<Image?> fetchThumbnailOpenLibrary(String isbn) async {
    final dio = _createDio();

    try {
      final response = await dio.get('$_openLibraryBaseUrl/b/isbn/$isbn-M.jpg');
      if (response.headers.value('content-type') != null &&
          response.headers
              .value('content-type')!
              .toLowerCase()
              .contains('image/jpeg') &&
          response.statusCode == 200) {
        final bytes = response.data;
        return Image.memory(bytes, fit: BoxFit.fitHeight);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    } finally {
      dio.close();
    }
  }
}
