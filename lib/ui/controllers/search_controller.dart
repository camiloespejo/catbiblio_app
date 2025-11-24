part of '../views/search_view.dart';

abstract class SearchController extends State<SearchView> {
  final TextEditingController _filterController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _itemTypeController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  late List<BookPreview> books = [];
  late final List<DropdownMenuEntry<String>> _filterEntries;
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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _filterEntries = widget.controllersData.filterEntries;
    final queryParams = Provider.of<QueryParams>(context, listen: false);
    _searchController.text = queryParams.searchQuery;
    setMiddleSpace = setUpperLimit - 2;

    loadSearch();
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
}
