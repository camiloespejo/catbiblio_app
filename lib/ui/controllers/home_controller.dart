part of '../views/home_view.dart';

/// controller for home view
abstract class HomeController extends State<HomeView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchFilterController = TextEditingController();
  final TextEditingController _libraryController = TextEditingController();
  final TextEditingController _libraryServicesController =
      TextEditingController();
  final TextEditingController _itemTypeController = TextEditingController();
  late Future<List<Library>> _librariesFuture;
  final CarouselController _booksCarouselController = CarouselController();
  final CarouselController _servicesCarouselController = CarouselController();
  VoidCallback? _booksControllerListener;
  VoidCallback? _servicesControllerListener;
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

  late Future<List<BookSelection>> _bookSelectionsFuture;

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
    _librariesFuture = Future.value([]);
    _bookSelectionsFuture = BookSelectionsService.getBookSelections();
    fetchData();
    _attachCarouselListeners();
  }

  /// fetches necessary data for home view
  Future<void> fetchData() async {
    try {
      fetchItemTypes();
      // Fetch libraries first (needed for services dropdown)
      await fetchLibraries();

      // Build dropdown after library services are loaded
      buildLibraryServicesDropdown();
    } catch (e) {
      _log('Error in fetchData: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFilterController.dispose();
    _libraryController.dispose();
    _libraryServicesController.dispose();
    _itemTypeController.dispose();
    if (_booksControllerListener != null) {
      _booksCarouselController.removeListener(_booksControllerListener!);
    }
    if (_servicesControllerListener != null) {
      _servicesCarouselController.removeListener(_servicesControllerListener!);
    }
    _booksCarouselController.dispose();
    _servicesCarouselController.dispose();
    _booksCarouselTimer.cancel();
    _servicesCarouselTimer.cancel();
    super.dispose();
  }

  void _attachCarouselListeners() {
    _booksControllerListener = () {
      if (!_booksCarouselController.hasClients) return;
      final ScrollPosition pos = _booksCarouselController.positions.first;
      final double pixels = pos.pixels;
      final double viewport = pos.viewportDimension;
      if (viewport == 0 || _bookSelections.isEmpty) return;

      final bool narrow = MediaQuery.of(context).size.width < 600;
      final List<int> weights = narrow ? <int>[1, 3, 1] : <int>[1, 1, 1, 1, 1];
      final double fraction = weights.first / weights.reduce((a, b) => a + b);

      final double actual =
          (pixels.clamp(0.0, double.infinity)) / (viewport * fraction);
      final double round = actual.roundToDouble();
      final double item = (actual - round).abs() < 1e-6 ? round : actual;
      int newIndex = item.round().toInt();
      newIndex = newIndex.clamp(0, _bookSelections.length - 1);

      if (newIndex != _currentBookIndex) {
        setState(() {
          _currentBookIndex = newIndex;
        });
        if (_isBooksTimerStarted) {
          _booksCarouselTimer.cancel();
          _isBooksTimerStarted = false;
          _startBooksCarouselTimer();
        }
      }
    };
    _booksCarouselController.addListener(_booksControllerListener!);

    _servicesControllerListener = () {
      if (!_servicesCarouselController.hasClients) return;
      final ScrollPosition pos = _servicesCarouselController.positions.first;
      final double pixels = pos.pixels;
      final double viewport = pos.viewportDimension;
      final currentList = _librariesServices[selectedLibraryServices];
      if (viewport == 0 || currentList == null || currentList.isEmpty) return;

      final List<int> weights = <int>[1, 4, 1];
      final double fraction = weights.first / weights.reduce((a, b) => a + b);

      final double actual =
          (pixels.clamp(0.0, double.infinity)) / (viewport * fraction);
      final double round = actual.roundToDouble();
      final double item = (actual - round).abs() < 1e-6 ? round : actual;
      int newIndex = item.round().toInt();
      newIndex = newIndex.clamp(0, currentList.length - 1);

      if (newIndex != _currentServiceIndex) {
        setState(() {
          _currentServiceIndex = newIndex;
        });
        if (_isServicesTimerStarted) {
          _servicesCarouselTimer.cancel();
          _isServicesTimerStarted = false;
          _startServicesCarouselTimer();
        }
      }
    };
    _servicesCarouselController.addListener(_servicesControllerListener!);
  }

  void clearText() {
    _searchController.clear();
  }

  /// changes app locale when selected on menu
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

    WebQueryParams webQueryParams = WebQueryParams(
      searchQuery: queryParams.searchQuery,
      itemType: queryParams.itemType,
      library: queryParams.library,
      filter: queryParams.searchBy,
    );

    navigateToSearchView(controllersData, webQueryParams);
  }

  /// builds query parameters and navigates to search view
  void navigateToSearchView(
    ControllersData controllersData,
    WebQueryParams webQueryParams,
  ) {
    if (kIsWeb) {
      context.go(
        '/search'
        '?searchQuery=${Uri.encodeComponent(webQueryParams.searchQuery ?? '')}'
        '&library=${Uri.encodeComponent(webQueryParams.library ?? '')}'
        '&itemType=${Uri.encodeComponent(webQueryParams.itemType ?? '')}'
        '&filter=${Uri.encodeComponent(webQueryParams.filter ?? '')}',
      );
      return;
    }
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
      _log('Error fetching libraries: $e');
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
      _log('Error fetching item types: $e');
      if (mounted) {
        setState(() {
          isItemTypesLoading = false;
        });
      }
    }
  }

  /// starts the books carousel timer
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

  /// starts the services carousel timer
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
  void buildLibraryServicesDropdown() async {
    _librariesServices = await LibraryServices.getLibraryCodeServicesMap();
    _enabledHomeLibrariesEntries = _libraryEntries
        .where((entry) => _librariesServices.containsKey(entry.value))
        .toList();
    _libraryServicesController.text =
        'Unidad de Servicios Bibliotecarios y de Información Xalapa';
    _startServicesCarouselTimer();

    setState(() {
      isLibraryServicesLoading = false;
      isLibraryServicesError = _librariesServices.isEmpty;
    });
  }

  void onSelectLibraryService(String value) {
    setState(() {
      selectedLibraryServices = value;
    });
  }
}

/// Logs messages to the console if in debug mode
void _log(String? message) {
  if (kDebugMode) {
    debugPrint('home_controller log: $message');
  }
}
