import 'package:catbiblio_app/models/book_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookPreview model fromJson factory', () {
    const jsonBookPreview = {
      'full_title': 'Test Book',
      'biblionumber': '12345',
      'author': 'John Doe',
      //'place': 'New York', // changed in each unit test
      // 'publishercode': 'Test Publisher', // changed in each unit test
      // 'copyrightdate': 2020, // changed in each unit test
      'libraries_count': 2,
      'total_results': 6,
    };

    test(
      'fromJson creates a valid BookPreview instance with all publishing details',
      () {
        final json = {
          ...jsonBookPreview,
          'place': 'New York',
          'publishercode': 'Test Publisher',
          'copyrightdate': 2020,
        };

        const expectedPublishingDetails = 'New York Test Publisher 2020';

        final actualBookPreview = BookPreview.fromJson(json);
        final actualPublishingDetails = actualBookPreview.publishingDetails;

        expect(actualBookPreview, isA<BookPreview>());
        expect(actualPublishingDetails, expectedPublishingDetails);
      },
    );

    test(
      'fromJson creates a valid BookPreview instance: only publishing place',
      () {
        final json = {
          ...jsonBookPreview,
          'place': 'New York',
          'publishercode': null,
          'copyrightdate': null,
        };

        const expectedPublishingDetails = 'New York';

        final actualBookPreview = BookPreview.fromJson(json);
        final actualPublishingDetails = actualBookPreview.publishingDetails;

        expect(actualBookPreview, isA<BookPreview>());
        expect(actualPublishingDetails, expectedPublishingDetails);
      },
    );

    test(
      'fromJson creates a valid BookPreview instance: only publisher code',
      () {
        final json = {
          ...jsonBookPreview,
          'place': null,
          'publishercode': 'Publisher Test',
          'copyrightdate': null,
        };

        const expectedPublishingDetails = 'Publisher Test';

        final actualBookPreview = BookPreview.fromJson(json);
        final actualPublishingDetails = actualBookPreview.publishingDetails;

        expect(actualBookPreview, isA<BookPreview>());
        expect(actualPublishingDetails, expectedPublishingDetails);
      },
    );

    test(
      'fromJson creates a valid BookPreview instance: only copyrightdate',
      () {
        final json = {
          ...jsonBookPreview,
          'place': null,
          'publishercode': null,
          'copyrightdate': 2020,
        };

        const expectedPublishingDetails = '2020';

        final actualBookPreview = BookPreview.fromJson(json);
        final actualPublishingDetails = actualBookPreview.publishingDetails;

        expect(actualBookPreview, isA<BookPreview>());
        expect(actualPublishingDetails, expectedPublishingDetails);
      },
    );

    test(
      'fromJson creates a valid BookPreview instance: only publishing place and copyrightdate',
      () {
        final json = {
          ...jsonBookPreview,
          'place': 'New York',
          'publishercode': null,
          'copyrightdate': 2020,
        };

        const expectedPublishingDetails = 'New York 2020';

        final actualBookPreview = BookPreview.fromJson(json);
        final actualPublishingDetails = actualBookPreview.publishingDetails;

        expect(actualBookPreview, isA<BookPreview>());
        expect(actualPublishingDetails, expectedPublishingDetails);
      },
    );

    test(
      'fromJson creates a valid BookPreview instance: empty publisshing fields',
      () {
        final json = {
          ...jsonBookPreview,
          'place': null,
          'publishercode': null,
          'copyrightdate': null,
        };

        const expectedPublishingDetails = '';

        final actualBookPreview = BookPreview.fromJson(json);
        final actualPublishingDetails = actualBookPreview.publishingDetails;

        expect(actualBookPreview, isA<BookPreview>());
        expect(actualPublishingDetails, expectedPublishingDetails);
      },
    );
  });

  group('BookPreview model toString method', () {
    test('toString returns a valid string representation', () {
      final bookPreview = BookPreview(
        title: 'Test Book',
        author: 'John Doe',
        coverUrl: 'http://example.com/cover.jpg',
        biblioNumber: '12345',
        publishingDetails: 'New York Test Publisher 2020',
        totalRecords: 2,
        locatedInLibraries: 6,
        isbn: '978-3-16-148410-0',
        normalizedIsbn: '9783161484100',
      );

      expect(
        bookPreview.toString(),
        'BookPreview(title: Test Book, author: John Doe, coverUrl: http://example.com/cover.jpg, biblioNumber: 12345, publishingDetails: New York Test Publisher 2020, locatedInLibraries: 6, totalRecords: 2, isbn: 978-3-16-148410-0, normalizedIsbn: 9783161484100)',
      );
    });
  });
}
