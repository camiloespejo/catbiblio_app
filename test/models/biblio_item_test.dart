import 'package:catbiblio_app/models/biblio_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BiblioItem model fromJson factory', () {
    final jsonItem = {
      "bookable": 0,
      "item_id": 1047254,
      "barcode": "VBR020064542",
      "materials_notes": "athum",
      "holding_library_id": "USBI-V",
      // "checked_out_date":
      //     null, // changed to test different statuses in each unit test
      "permanent_location": "Donaciones 2025",
      "item_type_id": "CONSULTA",
      "acquisition_source": "168",
      "call_number_source": "lcc",
      "item_type": "Libros de referencia",
      "localuse": 2,
      "call_number_sort": "PN6728 B36 K36  02002",
      "home_library":
          "Unidad de Servicios Bibliotecarios y de Información Veracruz",
      "last_checkout_date": null,
      "withdrawn": 0,
      "public_notes": "CCOMU",
      "collection": "Narrativa gráfica",
      "holding_library":
          "Unidad de Servicios Bibliotecarios y de Información Veracruz",
      // "not_for_loan_status":
      //     1, // changed to test different statuses in each unit test
      "copy_number": "1",
      "biblio_id": 383061,
      "callnumber": "PN6728.B36 K36 2002",
      "collection_code": "COMICS",
      "home_library_id": "USBI-V",
      "location": "Donaciones 2025",
    };

    test(
      'fromJson creates a valid BiblioItem instance: not for loan item ',
      () {
        final json = {
          ...jsonItem,
          'not_for_loan_status': 1,
          'checked_out_date': null,
        };

        final biblioItemNotForLoan = BiblioItem.fromJson(json);
        const expectedNotForLoanStatus = BiblioItem.statusNotForLoan;

        expect(biblioItemNotForLoan.overAllStatus, expectedNotForLoanStatus);
      },
    );

    test('fromJson creates a valid BiblioItem instance: borrowed item ', () {
      final json = {
        ...jsonItem,
        'not_for_loan_status': 0,
        'checked_out_date': "2023-10-01",
      };

      final biblioItemBorrowed = BiblioItem.fromJson(json);
      const expectedBorrowedStatus = BiblioItem.statusBorrowed;

      expect(biblioItemBorrowed.overAllStatus, expectedBorrowedStatus);
    });

    test('fromJson creates a valid BiblioItem instance: available item ', () {
      final json = {
        ...jsonItem,
        'not_for_loan_status': 0,
        'checked_out_date': null,
      };

      final biblioItemAvailable = BiblioItem.fromJson(json);
      const expectedAvailableStatus = BiblioItem.statusAvailable;

      expect(biblioItemAvailable.overAllStatus, expectedAvailableStatus);
    });

    test('fromJson handles missing optional fields gracefully', () {
      final json = {
        "holding_library_id": "USBI-V",
        "holding_library":
            "Unidad de Servicios Bibliotecarios y de Información Veracruz",
        "home_library_id": "USBI-V",
        "home_library":
            "Unidad de Servicios Bibliotecarios y de Información Veracruz",
      };

      final biblioItem = BiblioItem.fromJson(json);

      expect(biblioItem.itemTypeId, 'N/D');
      expect(biblioItem.itemType, 'N/D');
      expect(biblioItem.collectionCode, 'N/D');
      expect(biblioItem.collection, 'N/D');
      expect(biblioItem.callNumber, 'N/D');
      expect(biblioItem.callNumberSort, 'N/D');
      expect(biblioItem.copyNumber, 'N/D');
      expect(biblioItem.notForLoanStatus, 0);
      expect(biblioItem.checkedOutDate, isNull);
      expect(biblioItem.borrowedStatus, isFalse);
      expect(biblioItem.overAllStatus, BiblioItem.statusAvailable);
    });
  });
}
