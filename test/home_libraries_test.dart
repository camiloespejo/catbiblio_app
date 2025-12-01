import 'dart:collection';

import 'package:catbiblio_app/services/home_libraries.dart';
import 'package:test/test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUpAll(() async {
    await dotenv.load();
  });

  group('HomeLibraries requests', () {
    test('getHomeLibraries returns a map of library codes to names', () async {
      final libraries = await HomeLibraries.getHomeLibrariesHashMap();

      expect(libraries, isA<HashMap<String, String>>());
    });
  });
}
