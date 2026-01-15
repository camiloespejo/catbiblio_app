part of '../views/libraries_view.dart';

abstract class LibrariesController extends State<LibrariesView> {
  final List<String> regionsList = regions.values.toList();
  final int screenSizeLimit = 800;

  late Future<List<Library>> librariesFuture;

  /// A future that yields an ordered list of region -> libraries entries.
  /// Only regions that have at least one library are included. Libraries
  /// whose `region` is empty or not present in `regionsList` are grouped
  /// under the "Sin región" entry (the value for key `0` in `regions`).
  late Future<List<MapEntry<String, List<Library>>>> groupedEntriesFuture;

  @override
  void initState() {
    super.initState();
    _initializeLibraries();
  }

  /// Initialize or reload libraries data
  void _initializeLibraries() {
    librariesFuture = LibrariesService.getLibraries();
    groupedEntriesFuture = librariesFuture.then(_groupLibrariesByRegion);
  }

  /// Groups libraries by region and returns ordered entries
  List<MapEntry<String, List<Library>>> _groupLibrariesByRegion(
    List<Library> libraries,
  ) {
    final groups = _initializeRegionGroups();
    final noRegionLibraries = _categorizeLibraries(libraries, groups);
    _addUnknownLibrariesToNoRegionGroup(groups, noRegionLibraries);
    return _buildOrderedEntries(groups);
  }

  /// Initialize empty groups for each known region
  Map<String, List<Library>> _initializeRegionGroups() {
    return {for (var regionEntry in regionsList) regionEntry: <Library>[]};
  }

  /// Categorize libraries into their respective region groups
  /// Returns list of libraries with unknown or empty regions
  List<Library> _categorizeLibraries(
    List<Library> libraries,
    Map<String, List<Library>> groups,
  ) {
    final List<Library> noRegionLibraries = [];

    for (var library in libraries) {
      if (library.region.isNotEmpty && groups.containsKey(library.region)) {
        groups[library.region]!.add(library);
      } else {
        noRegionLibraries.add(library);
      }
    }

    return noRegionLibraries;
  }

  /// Add libraries with unknown/empty regions to the 'Sin región' group
  void _addUnknownLibrariesToNoRegionGroup(
    Map<String, List<Library>> groups,
    List<Library> unknownLibraries,
  ) {
    if (unknownLibraries.isEmpty) return;

    final String noRegionLabel = regions[0]!;
    if (!groups.containsKey(noRegionLabel)) {
      groups[noRegionLabel] = <Library>[];
    }
    groups[noRegionLabel]!.addAll(unknownLibraries);
  }

  /// Build ordered entries, only including regions with at least one library
  List<MapEntry<String, List<Library>>> _buildOrderedEntries(
    Map<String, List<Library>> groups,
  ) {
    final List<MapEntry<String, List<Library>>> entries = [];

    // Add regions in order from regionsList
    for (var regionEntry in regionsList) {
      final list = groups[regionEntry];
      if (list != null && list.isNotEmpty) {
        entries.add(MapEntry(regionEntry, list));
      }
    }

    // Ensure 'Sin región' appears if it has libraries and wasn't in regionsList
    _ensureNoRegionEntryIfNeeded(groups, entries);

    return entries;
  }

  /// Add 'Sin región' entry if it has libraries but wasn't already added
  void _ensureNoRegionEntryIfNeeded(
    Map<String, List<Library>> groups,
    List<MapEntry<String, List<Library>>> entries,
  ) {
    final String noRegionLabel = regions[0]!;

    if (groups.containsKey(noRegionLabel) &&
        groups[noRegionLabel]!.isNotEmpty) {
      final alreadyExists = entries.any((e) => e.key == noRegionLabel);
      if (!alreadyExists) {
        entries.add(MapEntry(noRegionLabel, groups[noRegionLabel]!));
      }
    }
  }

  /// Reload the libraries by reassigning the future and triggering a rebuild.
  void reloadLibraries() {
    setState(() {
      _initializeLibraries();
    });
  }

  /// Opens a URL in the default external application.
  /// If the URL cannot be opened, shows a SnackBar with an error message.
  ///
  /// Parameters:
  /// - [url]: The URL to open as a string.
  Future<void> openLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace: $url')),
        );
      }
    }
  }
}
