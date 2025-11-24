part of '../views/home_view.dart';

/// controller for home view
abstract class HomeController extends State<HomeView> {
  late TextEditingController _searchController;
  late TextEditingController _searchFilterController;
  late TextEditingController _libraryController;
  late TextEditingController _libraryServicesController;
  late TextEditingController _itemTypeController;
  late Future<List<Library>> _librariesFuture;
  final CarouselController _booksCarouselController = CarouselController();
  final CarouselController _servicesCarouselController = CarouselController();
  late List<DropdownMenuEntry<String>> _libraryEntries = [];
  late List<DropdownMenuEntry<String>> _itemTypeEntries = [];
  late List<DropdownMenuEntry<String>> _enabledHomeLibrariesEntries = [];
  late Map<String, List<LibraryService>> _librariesServices = {};
  late List<BookSelection> _bookSelections = [];
  String selectedLibraryServices = 'USBI-X';
  bool isItemTypesLoading = true;
  bool isLibrariesLoading = true;
  bool isLibraryServicesLoading = true;
  bool isBookSelectionsLoading = true;
  bool isLibraryServicesError = false;
  bool isBookSelectionsError = false;
  final int screenSizeLimit = 800;
  String currentBookName = '';
  String currentBiblionumber = '';

  // late Future<List<ItemType>> _futureItemTypes;
  late Future<List<BookSelection>> _bookSelectionsFuture;
  late Future<Map<String, List<LibraryService>>> _librariesServicesFuture;

  late Timer _booksCarouselTimer;
  late Timer _servicesCarouselTimer;
  int _currentBookIndex = 0;
  int _currentServiceIndex = 0;
  bool _isBooksTimerStarted = false;
  bool _isServicesTimerStarted = false;

  List<DropdownMenuEntry<String>> get _filterEntries {
    return [
      DropdownMenuEntry(
        value: 'title',
        label: AppLocalizations.of(context)!.titleEntry,
      ),
      DropdownMenuEntry(
        value: 'author',
        label: AppLocalizations.of(context)!.authorEntry,
      ),
      DropdownMenuEntry(
        value: 'subject',
        label: AppLocalizations.of(context)!.subjectEntry,
      ),
      DropdownMenuEntry(
        value: 'general',
        label: AppLocalizations.of(context)!.generalEntry,
      ),
      DropdownMenuEntry(
        value: 'isbn',
        label: AppLocalizations.of(context)!.isbnEntry,
      ),
      DropdownMenuEntry(
        value: 'issn',
        label: AppLocalizations.of(context)!.issnEntry,
      ),
    ];
  }

  @override
  initState() {
    super.initState();
    _searchFilterController = TextEditingController();
    _libraryController = TextEditingController();
    _searchController = TextEditingController();
    _itemTypeController = TextEditingController();
    _libraryServicesController = TextEditingController();
    _librariesFuture = Future.value([]);

    _bookSelectionsFuture = BookSelectionsService.getBookSelections();
    _librariesServicesFuture = LibraryServices.getLibraryCodeServicesMap();
    fetchData();
  }

  /// fetches necessary data for home view
  ///
  /// Optimized to run independent operations in parallel
  Future<void> fetchData() async {
    try {
      fetchItemTypes();
      // Fetch libraries first (needed for services dropdown)
      await fetchLibraries();

      // Build dropdown after library services are loaded
      buildLibraryServicesDropdown();
    } catch (e) {
      debugPrint('Error in fetchData: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFilterController.dispose();
    _libraryController.dispose();
    _libraryServicesController.dispose();
    _itemTypeController.dispose();
    _libraryServicesController.dispose();
    _booksCarouselController.dispose();
    _servicesCarouselController.dispose();
    _booksCarouselTimer.cancel();
    _servicesCarouselTimer.cancel();
    super.dispose();
  }

  void clearText() {
    _searchController.clear();
  }

  void changeLocale(Locale locale) {
    widget.onLocaleChange(locale);
    // Clear cached filter entries to rebuild with new locale
    setState(() {
      _searchFilterController.clear();
      _itemTypeController.clear();
      _libraryController.clear();
    });
  }

  /// handles search action submission
  void onSubmitAction() {
    if (_searchController.text.isEmpty ||
        _searchController.text.trim().isEmpty ||
        _searchController.text.trim().length < 2) {
      return;
    }

    ControllersData controllersData = ControllersData(
      libraryEntries: _libraryEntries,
      itemTypeEntries: _itemTypeEntries,
      filterEntries: _filterEntries,
    );
    // Set query parameters provider values
    final queryParams = Provider.of<QueryParams>(context, listen: false);
    queryParams.startRecord = 1;
    queryParams.searchQuery = _searchController.text;

    navigateToSearchView(controllersData);
  }

  /// builds query parameters and navigates to search view
  void navigateToSearchView(ControllersData controllersData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchView(controllersData: controllersData),
      ),
    );
  }

  void clearSearchController() {
    _searchController.clear();
  }

  /// opens external link in browser
  Future<void> openExternalLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.couldNotLaunchExternalLink} $url',
            ),
          ),
        );
      }
    }
  }

  /// fetches available libraries
  Future<void> fetchLibraries() async {
    try {
      final libraries = await LibrariesService.getLibraries();

      if (mounted) {
        final libraryEntries = libraries.map((library) {
          return DropdownMenuEntry(
            value: library.libraryId,
            label: library.name,
          );
        }).toList();

        final globalProvider = Provider.of<GlobalProvider>(
          context,
          listen: false,
        );
        globalProvider.setGlobalLibraryEntries(libraryEntries);

        setState(() {
          isLibrariesLoading = false;
          _librariesFuture = Future.value(libraries);
          _libraryEntries = libraryEntries;
        });
      }
    } catch (e) {
      debugPrint('Error fetching libraries: $e');
      if (mounted) {
        setState(() {
          isLibrariesLoading = false;
        });
      }
    }
  }

  /// fetches item types
  Future<void> fetchItemTypes() async {
    try {
      final itemTypes = await ItemTypesService.getItemTypes();

      if (mounted) {
        final itemTypeEntries = itemTypes.map((itemType) {
          return DropdownMenuEntry(
            value: itemType.itemTypeId,
            label: itemType.description,
          );
        }).toList();

        final globalProvider = Provider.of<GlobalProvider>(
          context,
          listen: false,
        );
        globalProvider.setGlobalItemTypeEntries(itemTypeEntries);

        setState(() {
          isItemTypesLoading = false;
          _itemTypeEntries = itemTypeEntries;
        });
      }
    } catch (e) {
      debugPrint('Error fetching item types: $e');
      if (mounted) {
        setState(() {
          isItemTypesLoading = false;
        });
      }
    }
  }

  void _startBooksCarouselTimer() {
    if (_isBooksTimerStarted) return;

    // Safety check that data is available
    if (_bookSelections.isEmpty) {
      _isBooksTimerStarted = true;
      return;
    }

    _booksCarouselTimer = Timer.periodic(const Duration(seconds: 4), (
      Timer timer,
    ) {
      if (!mounted) return;

      _currentBookIndex++;
      final listLength = _bookSelections.length;

      // Logic to determine when to reset the index
      if (MediaQuery.of(context).size.width < 600) {
        if (_currentBookIndex >= listLength) {
          _currentBookIndex = 0;
        }
      } else {
        // Assuming 5 items are visible (1:1:1:1:1 flex) on wider screen, so reset earlier
        if (_currentBookIndex >= listLength - 4) {
          _currentBookIndex = 0;
        }
      }

      _booksCarouselController.animateToItem(
        _currentBookIndex,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
    _isBooksTimerStarted = true;
  }

  void _startServicesCarouselTimer() {
    if (_isServicesTimerStarted) return;

    final serviceList = _librariesServices[selectedLibraryServices];
    // Safety check that data is available
    if (serviceList == null || serviceList.isEmpty) {
      _isServicesTimerStarted = true;
      return;
    }

    _servicesCarouselTimer = Timer.periodic(const Duration(seconds: 6), (
      Timer timer,
    ) {
      if (!mounted) return;

      final currentList = _librariesServices[selectedLibraryServices];
      if (currentList == null || currentList.isEmpty) return;

      _currentServiceIndex = _currentServiceIndex + 1;

      if (_currentServiceIndex >= currentList.length) {
        _currentServiceIndex = 0;
      }

      _servicesCarouselController.animateToItem(
        _currentServiceIndex,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
    _isServicesTimerStarted = true;
  }

  /// builds the library services dropdown based on previously fetched libraries
  void buildLibraryServicesDropdown() {
    _enabledHomeLibrariesEntries = _libraryEntries
        .where((entry) => _librariesServices.containsKey(entry.value))
        .toList();
    _libraryServicesController.text =
        'Unidad de Servicios Bibliotecarios y de Información Xalapa';
  }

  void onSelectLibraryService(String value) {
    selectedLibraryServices = value;
  }
}
