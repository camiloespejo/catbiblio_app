part of '../views/search_view.dart';

abstract class SearchController extends State<SearchView> {
  final TextEditingController _filterController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _itemTypeController = TextEditingController();
  final TextEditingController _librariesController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<BookPreview> books = [];
  static const int initialUpperLimit = 8;
  int currentPage = 1;
  int totalPages = 0;
  int setUpperLimit = initialUpperLimit;
  int setMiddleSpace = 0;
  int setLowerLimit = 1;
  int totalRecords = 0;
  bool isInitialRequestLoading = false;
  bool isPageLoading = false;
  bool isError = false;
  final int screenSizeLimit = 800;

  bool isItemTypesLoading = true;
  bool isLibrariesLoading = true;
  List<DropdownMenuEntry<String>> _itemTypeEntries = [];
  List<DropdownMenuEntry<String>> _libraryEntries = [];
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
  void initState() {
    super.initState();
    setMiddleSpace = setUpperLimit - 2;

    loadSearch();

    if (kIsWeb) {
      _searchController.value = TextEditingValue(
        text: widget.webQueryParams?.searchQuery ?? '',
      );
      _itemTypeController.value = TextEditingValue(
        text: widget.webQueryParams?.itemType ?? 'all',
      );
      _librariesController.value = TextEditingValue(
        text: widget.webQueryParams?.library ?? 'all',
      );
      _filterController.value = TextEditingValue(
        text: widget.webQueryParams?.filter ?? 'title',
      );

      fetchItemTypes();
      fetchLibraries();
      return;
    }

    final queryParams = Provider.of<QueryParams>(context, listen: false);
    _searchController.text = queryParams.searchQuery;
  }

  void loadSearch() {
    isInitialRequestLoading = true;
    isError = false;
    final queryParams = Provider.of<QueryParams>(context, listen: false);
    SearchService.searchBooks(queryParams)
        .then((result) {
          if (!mounted) return;
          setState(() {
            books = result.books;
            totalRecords = result.totalRecords;
            totalPages = (totalRecords / 10).ceil();
            isInitialRequestLoading = false;
          });
        })
        .catchError((error) {
          if (!mounted) return;
          setState(() {
            isInitialRequestLoading = false;
            isError = true;
          });
        });
  }

  void clearSearchController() {
    _searchController.clear();
  }

  @override
  void dispose() {
    _filterController.dispose();
    _scrollController.dispose();
    _itemTypeController.dispose();
    _librariesController.dispose();
    _searchController.dispose();

    super.dispose();
  }

  void clearText() {
    _searchController.clear();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void onSubmitAction(String searchQuery) {
    if (searchQuery.isEmpty) return;
    final queryParams = Provider.of<QueryParams>(context, listen: false);
    setState(() {
      queryParams.searchQuery = searchQuery;
      books.clear();
      totalRecords = 0;
      currentPage = 1;
      setUpperLimit = initialUpperLimit;
      setLowerLimit = 1;
      totalPages = 0;
      updatePageResults();
    });
  }

  void updatePageResults() {
    final queryParams = Provider.of<QueryParams>(context, listen: false);
    queryParams.startRecord = (currentPage - 1) * 10;

    setState(() {
      isPageLoading = true;
    });
    SearchService.searchBooks(queryParams)
        .then((result) {
          setState(() {
            books = result.books;
            totalRecords = result.totalRecords;
            totalPages = (totalRecords / 10).ceil();
            isInitialRequestLoading = false;
            isError = false;
            isPageLoading = false;
          });
        })
        .catchError((error) {
          setState(() {
            isInitialRequestLoading = false;
            isError = true;
            isPageLoading = false;
          });
        });
  }

  void paginationBehavior(int selectedIndex) {
    if (isPageLoading || currentPage == selectedIndex) return;

    /// This allows for pagination to continue forward.
    if (currentPage + 1 == setUpperLimit && selectedIndex == setUpperLimit) {
      setState(() {
        setUpperLimit += setMiddleSpace;
        setLowerLimit += setMiddleSpace;
        currentPage++;
        updatePageResults();
      });
      return;
    }

    /// This allows for pagination to continue backwards.
    if (currentPage - 1 == setLowerLimit &&
        selectedIndex == setLowerLimit &&
        currentPage > (setUpperLimit - setLowerLimit)) {
      setState(() {
        setUpperLimit -= setMiddleSpace;
        setLowerLimit -= setMiddleSpace;
        currentPage--;
        updatePageResults();
      });
      return;
    }

    /// This allows for pagination to continue forward one page.
    if (selectedIndex == setUpperLimit) {
      setState(() {
        currentPage++;
        updatePageResults();
      });
      return;
    }

    /// This allows for pagination to continue backwards one page.
    if (selectedIndex == setLowerLimit &&
        currentPage > (setUpperLimit - setLowerLimit)) {
      setState(() {
        currentPage--;
        updatePageResults();
      });
      return;
    }

    /// This allows for pagination to jump to a specific page.
    setState(() {
      currentPage = selectedIndex;
      updatePageResults();
    });
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
}

void _log(String? message) {
  if (kDebugMode) {
    debugPrint('search_controller log: $message');
  }
}
