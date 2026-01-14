import 'package:test/test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:catbiblio_app/models/book_preview.dart';
import 'package:catbiblio_app/models/query_params.dart';
import 'package:catbiblio_app/services/search.dart';
import 'package:catbiblio_app/models/search_result.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUpAll(() async {
    await dotenv.load();
  });

  group('SearchService requests', () {
    debugPrint('Testing SearchService searchBooks method');
    // general search tests
    test('test searchBooks: general search and branch', () async {
      final queryParams = QueryParams(
        library: 'USBI-X',
        searchBy: 'general',
        searchQuery: 'harry potter',
      );

      final response = await SearchService.searchBooks(queryParams);
      //debugPrint("Response: ${response.toString()}");

      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });
    test('test searchBooks: general search and no branch', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'general',
        searchQuery: 'harry potter',
      );

      final response = await SearchService.searchBooks(queryParams);
      //debugPrint(" Response: $response");

      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    // title search tests
    test('test searchBooks: title and branch', () async {
      final queryParams = QueryParams(
        library: 'USBI-X',
        searchBy: 'title',
        searchQuery: 'sistemas operativos',
      );

      final response = await SearchService.searchBooks(queryParams);
      //debugPrint("Response: ${response.toString()}");

      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    test('test searchBooks: title and no branch', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'title',
        searchQuery: 'sistemas operativos',
      );

      final response = await SearchService.searchBooks(queryParams);
      //debugPrint(" Response: $response");

      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    // author search tests
    test('test searchBooks: author and branch', () async {
      final queryParams = QueryParams(
        library: 'USBI-X',
        searchBy: 'author',
        searchQuery: 'frank herbert',
      );

      final response = await SearchService.searchBooks(queryParams);
      //debugPrint("Response: $response");

      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    test('test searchBooks: author and no branch', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'author',
        searchQuery: 'frank herbert',
      );

      final response = await SearchService.searchBooks(queryParams);
      //debugPrint("Response: $response");

      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    test('test searchBooks: subject and no branch', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'subject',
        searchQuery: 'ciencia ficcion',
      );

      final response = await SearchService.searchBooks(queryParams);
      //debugPrint("Response: $response");

      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    test('test searchBooks: subject and branch', () async {
      final queryParams = QueryParams(
        library: 'USBI-X',
        searchBy: 'subject',
        searchQuery: 'ciencia ficcion',
      );

      final response = await SearchService.searchBooks(queryParams);
      //debugPrint("Response: $response");

      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    test('test searchBooks: empty query', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'title',
        searchQuery: '',
      );

      final response = await SearchService.searchBooks(queryParams);
      //debugPrint("Response: $response");

      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.books.isEmpty, true);
      expect(response.totalRecords, 0);
    });

    // ISBN search tests
    test('test searchBooks: ISBN search', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'isbn',
        searchQuery: '9780123456789',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    test('test searchBooks: ISBN with branch', () async {
      final queryParams = QueryParams(
        library: 'USBI-V',
        searchBy: 'isbn',
        searchQuery: '9780123456789',
      );

      final response = await SearchService.searchBooks(queryParams);

      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    // ISSN search tests
    test('test searchBooks: ISSN search', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'issn',
        searchQuery: '1234-5678',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    test('test searchBooks: ISSN with branch', () async {
      final queryParams = QueryParams(
        library: 'USBI-V',
        searchBy: 'issn',
        searchQuery: '1234-5678',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    // Different branch tests
    test('test searchBooks: title with USBI-V branch', () async {
      final queryParams = QueryParams(
        library: 'USBI-V',
        searchBy: 'title',
        searchQuery: 'programacion',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    // Special characters and encoding tests
    test('test searchBooks: title with special characters', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'title',
        searchQuery: 'programación básica',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    test('test searchBooks: author with special characters', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'author',
        searchQuery: 'josé martínez',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    // Multiple word searches
    test('test searchBooks: multi-word title search', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'title',
        searchQuery: 'introduction to computer science',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    test('test searchBooks: multi-word author search', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'author',
        searchQuery: 'garcia marquez',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    // Edge case tests
    test('test searchBooks: single character search', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'title',
        searchQuery: 'a',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    test('test searchBooks: very long search query', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'title',
        searchQuery:
            'this is a very long search query that might test the limits of the search system and how it handles extensive input',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    // Whitespace handling tests
    test('test searchBooks: query with leading/trailing spaces', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'title',
        searchQuery: '  programming  ',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    test('test searchBooks: query with multiple spaces', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'title',
        searchQuery: 'computer    science',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    // Case sensitivity tests
    test('test searchBooks: uppercase query', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'title',
        searchQuery: 'PROGRAMMING',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    test('test searchBooks: mixed case query', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'author',
        searchQuery: 'Frank Herbert',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    // Numeric queries
    test('test searchBooks: numeric title search', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'title',
        searchQuery: '2024',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    // Response validation tests
    test('test searchBooks: validate response structure', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'title',
        searchQuery: 'test',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());

      // If response is not empty, check structure
      if (response.books.isNotEmpty) {
        final firstBook = response.books.first;
        expect(firstBook.title, isA<String>());
        expect(firstBook.author, isA<String>());
        expect(firstBook.coverUrl, isA<String>());
        expect(firstBook.biblioNumber, isA<String>());
        expect(firstBook.publishingDetails, isA<String>());
      }
    });

    // Error handling tests (these might need to be mocked)
    test('test searchBooks: null search query handling', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'title',
        searchQuery: '',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.books.isEmpty, true);
      expect(response.totalRecords, 0);
    });

    // Different search combinations
    test('test searchBooks: subject with different branch', () async {
      final queryParams = QueryParams(
        library: 'USBI-V',
        searchBy: 'subject',
        searchQuery: 'matematicas',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    test('test searchBooks: author with accents', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'author',
        searchQuery: 'garcía márquez',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    // Performance/load tests (basic)
    test('test searchBooks: common search term', () async {
      final queryParams = QueryParams(
        library: 'all',
        searchBy: 'title',
        searchQuery: 'el',
      );

      final response = await SearchService.searchBooks(queryParams);
      expect(response, isA<SearchResult>());
      expect(response.books, isA<List<BookPreview>>());
      expect(response.totalRecords, isA<int>());
    });

    // Test with different valid search types
    test('test searchBooks: verify all search types work', () async {
      final searchTypes = [
        'title',
        'author',
        'subject',
        'general',
        'isbn',
        'issn',
      ];
      final searchQueries = [
        'test',
        'author test',
        'subject test',
        'general test',
        '1234567890',
        '1234-5678',
      ];

      for (int i = 0; i < searchTypes.length; i++) {
        final queryParams = QueryParams(
          library: 'all',
          searchBy: searchTypes[i],
          searchQuery: searchQueries[i],
        );
        final response = await SearchService.searchBooks(queryParams);
        expect(
          response.books,
          isA<List<BookPreview>>(),
          reason: 'Failed for search type: ${searchTypes[i]}',
        );
      }
    });
  });
  group('SearchService helper methods', () {
    debugPrint('Testing SearchService helper methods');
    test('test buildQueryParameters general filter and branch', () {
      final params = QueryParams(
        library: 'USBI-X',
        searchBy: 'general',
        searchQuery: 'sistemas operativos',
      );

      final expectedParams = {'q': 'sistemas operativos', 'branch': 'USBI-X'};

      final queryParameters = SearchService.buildQueryParameters(params);

      expect(queryParameters, equals(expectedParams));
    });
    test('test buildQueryParameters general filter and no branch', () {
      final params = QueryParams(
        library: 'all',
        searchBy: 'general',
        searchQuery: 'sistemas operativos',
      );

      final expectedParams = {'q': 'sistemas operativos'};

      final queryParameters = SearchService.buildQueryParameters(params);

      expect(queryParameters, equals(expectedParams));
    });
    test('test buildQueryParameters title and branch', () {
      final params = QueryParams(
        library: 'USBI-X',
        searchBy: 'title',
        searchQuery: 'sistemas operativos',
      );

      final expectedParams = {
        'title': 'sistemas operativos',
        'branch': 'USBI-X',
      };

      final queryParameters = SearchService.buildQueryParameters(params);

      expect(queryParameters, equals(expectedParams));
    });

    test('test buildQueryParameters with all libraries', () {
      final params = QueryParams(
        library: 'all',
        searchBy: 'author',
        searchQuery: 'frank herbert',
      );

      final expectedParams = {'author': 'frank herbert'};

      final queryParameters = SearchService.buildQueryParameters(params);

      expect(queryParameters, equals(expectedParams));
    });

    test('test buildQueryParameters with empty search query', () {
      final params = QueryParams(
        library: 'all',
        searchBy: 'title',
        searchQuery: '',
      );

      final expectedParams = {};

      final queryParameters = SearchService.buildQueryParameters(params);

      expect(queryParameters, equals(expectedParams));
    });

    test('test buildQueryParameters completely empty', () {
      final params = QueryParams(library: '', searchBy: '', searchQuery: '');

      final expectedParams = {};

      final queryParameters = SearchService.buildQueryParameters(params);

      expect(queryParameters, equals(expectedParams));
    });

    test('test buildQueryParameters with startRecord', () {
      final params = QueryParams(
        library: 'USBI-X',
        searchBy: 'title',
        searchQuery: 'sistemas operativos',
        startRecord: 5,
      );

      final expectedParams = {
        'title': 'sistemas operativos',
        'branch': 'USBI-X',
        'offset': 5,
      };

      final queryParameters = SearchService.buildQueryParameters(params);

      expect(queryParameters, equals(expectedParams));
    });

    test('test buildQueryParameters with large startRecord', () {
      final params = QueryParams(
        library: 'USBI-X',
        searchBy: 'title',
        searchQuery: 'sistemas operativos',
        startRecord: 100,
      );

      final expectedParams = {
        'title': 'sistemas operativos',
        'branch': 'USBI-X',
        'offset': 100,
      };

      final queryParameters = SearchService.buildQueryParameters(params);

      expect(queryParameters, equals(expectedParams));
    });

    test('test buildQueryParameters with negative startRecord', () {
      final params = QueryParams(
        library: 'USBI-X',
        searchBy: 'title',
        searchQuery: 'sistemas operativos',
        startRecord: -10,
      );

      final expectedParams = {
        'title': 'sistemas operativos',
        'branch': 'USBI-X',
      };

      final queryParameters = SearchService.buildQueryParameters(params);

      expect(queryParameters, equals(expectedParams));
    });
  });
}
