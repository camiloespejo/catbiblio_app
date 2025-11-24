import 'package:flutter/foundation.dart';

class QueryParams extends ChangeNotifier {
  String _library;
  String _searchBy;
  String _searchQuery;
  int _startRecord;
  String _itemType;

  QueryParams({
    String library = 'all',
    String searchBy = 'title',
    String searchQuery = '',
    int startRecord = 1,
    String itemType = 'all',
  }) : _library = library,
       _searchBy = searchBy,
       _searchQuery = searchQuery,
       _startRecord = startRecord,
       _itemType = itemType;

  // Getters
  String get library => _library;
  String get searchBy => _searchBy;
  String get searchQuery => _searchQuery;
  int get startRecord => _startRecord;
  String get itemType => _itemType;

  // Setters that notify listeners when values change
  set library(String value) {
    if (_library != value) {
      _library = value;
      notifyListeners();
    }
  }

  set searchBy(String value) {
    if (_searchBy != value) {
      _searchBy = value;
      notifyListeners();
    }
  }

  set searchQuery(String value) {
    if (_searchQuery != value) {
      _searchQuery = value;
      notifyListeners();
    }
  }

  set startRecord(int value) {
    if (_startRecord != value) {
      _startRecord = value;
      notifyListeners();
    }
  }

  set itemType(String value) {
    if (_itemType != value) {
      _itemType = value;
      notifyListeners();
    }
  }

  @override
  String toString() {
    return 'QueryParams(library: $_library, searchBy: $_searchBy, searchQuery: $_searchQuery, startRecord: $_startRecord, itemType: $_itemType)';
  }

  void reset() {
    _library = 'all';
    _searchBy = 'title';
    _searchQuery = '';
    _startRecord = 1;
    _itemType = 'all';
    notifyListeners();
  }
}
