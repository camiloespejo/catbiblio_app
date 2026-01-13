//import 'package:catbiblio_app/models/item_location.dart';

class BiblioItem {
  static const int statusAvailable = 0;
  static const int statusBorrowed = 1;
  static const int statusNotForLoan = 2;

  String? itemTypeId;
  String? itemType;
  String holdingLibraryId;
  String holdingLibrary;
  String homeLibraryId;
  String homeLibrary;
  String? collectionCode;
  String? collection;
  String? callNumber;
  String? callNumberSort;
  String? copyNumber;
  int? notForLoanStatus;
  String? checkedOutDate;
  bool borrowedStatus; // Not in json, calculated based on checkedOutDate
  int overAllStatus; // Not in json, to be calculated later
  /*
  ItemLocation
  location; // Used for geographical location - not in json: to be calculated later
  */

  BiblioItem({
    this.itemTypeId,
    this.itemType,
    required this.holdingLibraryId,
    required this.holdingLibrary,
    required this.homeLibraryId,
    required this.homeLibrary,
    this.collectionCode,
    this.collection,
    this.callNumber,
    this.callNumberSort,
    this.copyNumber,
    this.notForLoanStatus,
    this.checkedOutDate,
    this.borrowedStatus = false,
    this.overAllStatus = statusNotForLoan,
  });
  /* : overAllStatus = notForLoanStatus != statusAvailable
           ? statusNotForLoan
           : (checkedOutDate != null ? statusBorrowed : statusAvailable); */
  /*: location =
           location ??
           ItemLocation(floor: '', room: '', shelf: '', shelfSide: '');*/

  static int _getOverallStatus(int? notForLoanStatus, String? checkedOutDate) {
    if (notForLoanStatus != statusAvailable) {
      return statusNotForLoan;
    } else if (checkedOutDate != null) {
      return statusBorrowed;
    } else {
      return statusAvailable;
    }
  }

  factory BiblioItem.fromJson(Map<String, dynamic> json) {
    final checkedOutDate = json['checked_out_date'] as String?;
    final notForLoanStatus = json['not_for_loan_status'] ?? 0;
    return BiblioItem(
      itemTypeId: json['item_type_id'] ?? 'N/D',
      itemType: json['item_type'] ?? 'N/D',
      holdingLibraryId: json['holding_library_id'],
      holdingLibrary: json['holding_library'],
      homeLibraryId: json['home_library_id'],
      homeLibrary: json['home_library'],
      collectionCode: json['collection_code'] ?? 'N/D',
      collection: json['collection'] ?? 'N/D',
      callNumber: json['callnumber'] ?? 'N/D',
      callNumberSort: json['call_number_sort'] ?? 'N/D',
      copyNumber: json['copy_number'] ?? 'N/D',
      notForLoanStatus: notForLoanStatus,
      checkedOutDate: checkedOutDate,
      borrowedStatus: checkedOutDate != null,
      overAllStatus: _getOverallStatus(notForLoanStatus, checkedOutDate),
    );
  }

  @override
  String toString() {
    return 'BiblioItem(itemTypeId: $itemTypeId, itemType: $itemType, holdingLibraryId: $holdingLibraryId, holdingLibrary: $holdingLibrary, homeLibraryId: $homeLibraryId, homeLibrary: $homeLibrary, collectionCode: $collectionCode, collection: $collection, callNumber: $callNumber, callNumberSort: $callNumberSort, copyNumber: $copyNumber, notForLoanStatus: $notForLoanStatus, checkedOutDate: $checkedOutDate, borrowedStatus: $borrowedStatus, overAllStatus: $overAllStatus)';
  }
}
