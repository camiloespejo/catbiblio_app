import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;

import 'package:catbiblio_app/l10n/app_localizations.dart';
import 'package:catbiblio_app/models/book_preview.dart';
import 'package:catbiblio_app/models/controllers_data.dart';
import 'package:catbiblio_app/models/global_provider.dart';
import 'package:catbiblio_app/models/query_params.dart';
import 'package:catbiblio_app/models/web_query_params.dart';
import 'package:catbiblio_app/services/search.dart';
import 'package:catbiblio_app/services/item_types.dart';
import 'package:catbiblio_app/services/libraries.dart';
import 'package:catbiblio_app/ui/views/book_view.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'colors.dart';

part '../controllers/search_controller.dart';

const Color _primaryColor = CustomColors.primaryColor;

class SearchView extends StatefulWidget {
  final ControllersData? controllersData;
  final WebQueryParams? webQueryParams;

  const SearchView({super.key, this.controllersData, this.webQueryParams});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends SearchController {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: IconButton(
          icon: kIsWeb
              ? const Image(
                image: AssetImage('assets/images/head-icon-medium.png'),
                height: 40)
              : const Image(
                  image: AssetImage('assets/images/head-icon.png'),
                  height: 40,
                ),
          onPressed: () {
            if (kIsWeb) {
              context.go('/');
            }
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            );
          },
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Top controls
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.of(context).size.width < screenSizeLimit
                            ? MediaQuery.of(context).size.width
                            : (MediaQuery.of(context).size.width / 3) * 2,
                      ),
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return DropdownItemType(
                                itemTypeController: _itemTypeController,
                                itemTypeEntries:
                                    widget.controllersData?.itemTypeEntries ?? _itemTypeEntries,
                                maxWidth: constraints.maxWidth,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return DropdownLibraries(
                                libraryController: _librariesController,
                                libraryEntries:
                                    widget.controllersData?.libraryEntries ?? _libraryEntries,
                                widget: widget,
                                maxWidth: constraints.maxWidth,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return DropdownFilter(
                                filterController: _filterController,
                                filterEntries: _filterEntries,
                                widget: widget,
                                maxWidth: constraints.maxWidth,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFieldSearchWidget(
                            searchController: _searchController,
                            onSubmitted: onSubmitAction,
                            clearSearchController: clearSearchController,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    PaginationButtonRow(
                      paginationBehavior: paginationBehavior,
                      setLowerLimit: setLowerLimit,
                      setUpperLimit: setUpperLimit,
                      totalPages: totalPages,
                      currentPage: currentPage,
                      setMiddleSpace: setMiddleSpace,
                      scrollController: _scrollController,
                    ),
                    const SizedBox(height: 8),
                    if (isInitialRequestLoading)
                      const Center(child: LinearProgressIndicator()),
                    if (isError)
                      Text(
                        AppLocalizations.of(context)!.errorOccurred,
                        textAlign: TextAlign.center,
                      ),
                    if (books.isEmpty &&
                        !isInitialRequestLoading &&
                        !isError &&
                        !isPageLoading)
                      Text(
                        AppLocalizations.of(context)!.noResults,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    else if (!isInitialRequestLoading &&
                        !isError &&
                        !isPageLoading)
                      Text(
                        '$totalRecords ${AppLocalizations.of(context)!.totalResults}',
                        textAlign: TextAlign.center,
                      ),
                    const Divider(color: Colors.grey),
                    if (isPageLoading)
                      const Center(child: LinearProgressIndicator()),
                  ],
                ),
              ),
            ),

            BookList(
              books: books,
              isPageLoading: isPageLoading,
              isInitialRequestLoading: isInitialRequestLoading,
            ),

            // Bottom pagination
            if (!isPageLoading && books.length > 5)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: PaginationButtonRow(
                    paginationBehavior: paginationBehavior,
                    setLowerLimit: setLowerLimit,
                    setUpperLimit: setUpperLimit,
                    totalPages: totalPages,
                    currentPage: currentPage,
                    setMiddleSpace: setMiddleSpace,
                    scrollController: _scrollController,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// PaginationButtonRow widget
/// It displays a row of pagination buttons for navigating through pages.
/// The [paginationBehavior] function is called when a button is pressed.
/// The [setLowerLimit] and [setUpperLimit] functions set the limits for pagination.
/// The [totalPages] and [currentPage] parameters indicate the total number of pages and the current page.
/// The [setMiddleSpace] parameter is used to determine the middle space for pagination.
class PaginationButtonRow extends StatelessWidget {
  const PaginationButtonRow({
    super.key,
    required paginationBehavior,
    required setLowerLimit,
    required setUpperLimit,
    required totalPages,
    required currentPage,
    required setMiddleSpace,
    required ScrollController scrollController,
  }) : _paginationBehavior = paginationBehavior,
       _setLowerLimit = setLowerLimit,
       _setUpperLimit = setUpperLimit,
       _totalPages = totalPages,
       _currentPage = currentPage,
       _setMiddleSpace = setMiddleSpace,
       _scrollController = scrollController;
  final Function(int) _paginationBehavior;
  final int _setLowerLimit;
  final int _setUpperLimit;
  final int _totalPages;
  final int _currentPage;
  final int _setMiddleSpace;
  final ScrollController _scrollController;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 2.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (
              int i = _setLowerLimit;
              i <= _setUpperLimit && i <= _totalPages && _totalPages > 1;
              i++
            )
              OutlinedButton(
                onPressed: () {
                  _paginationBehavior(i);
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                style: i == _currentPage
                    ? OutlinedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      )
                    : OutlinedButton.styleFrom(
                        foregroundColor: _primaryColor,
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                child: i == _setUpperLimit
                    ? const Icon(Icons.arrow_forward)
                    : i == _setLowerLimit && i > _setMiddleSpace
                    ? const Icon(Icons.arrow_back)
                    : Text('$i'),
              ),
          ],
        ),
      ),
    );
  }
}

/// BookList widget
/// It displays a list of books with their details.
/// It handles loading states and errors.
/// The [books] parameter is a list of [BookPreview] objects.
/// The [isPageLoading] and [isInitialRequestLoading] parameters indicate the loading state
class BookList extends StatelessWidget {
  const BookList({
    super.key,
    required this.books,
    required this.isPageLoading,
    required this.isInitialRequestLoading,
  });

  final List<BookPreview> books;
  final bool isPageLoading;
  final bool isInitialRequestLoading;

  static final String _baseUrl =
      dotenv.env['KOHA_BASE_URL'] ?? 'https://catbiblio.uv.mx';

  @override
  Widget build(BuildContext context) {
    if (isPageLoading || isInitialRequestLoading) {
      return SliverList.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Column(
            children: [
              Skeletonizer(
                enabled: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 120,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '---------------------------------',
                              style: const TextStyle(fontSize: 25),
                            ),
                            Text(
                              '---------------------------',
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              '-------------------------------',
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              '---------------------',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: Colors.grey),
            ],
          );
        },
      );
    }

    return SliverList.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Column(
          children: [
            InkWell(
              onTap: () {
                if (kIsWeb) {
                  context.go('/book-details/${book.biblioNumber}');
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookView(biblioNumber: book.biblioNumber),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        SizedBox(
                          width: 60,
                          height: 90,
                          child: Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.book,
                                size: 36,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        CachedNetworkImage(
                          imageUrl: book.coverUrl,
                          imageBuilder: (context, imageProvider) => Image(
                            image: imageProvider,
                            width: 60,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                          // This shows if the URL fails to load (404, wrong content-type, etc.)
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 90,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.book,
                              size: 36,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        CachedNetworkImage(
                          imageUrl:
                              "$_baseUrl/cgi-bin/koha/opac-image.pl?thumbnail=1&biblionumber=${book.biblioNumber}",
                          imageBuilder: (context, imageProvider) => Image(
                            image: imageProvider,
                            width: 60,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                          // This shows if the URL fails to load (404, wrong content-type, etc.)
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 90,
                            color: Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          if (book.author.isNotEmpty)
                            Wrap(
                              children: [
                                Text(
                                  '${AppLocalizations.of(context)!.byAuthor}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(book.author),
                              ],
                            ),
                          if (book.publishingDetails.isNotEmpty)
                            Wrap(
                              children: [
                                Text(
                                  '${AppLocalizations.of(context)!.publishingDetails}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(book.publishingDetails),
                              ],
                            ),
                          if (book.locatedInLibraries > 0)
                            Text(
                              '${AppLocalizations.of(context)!.availability} ${book.locatedInLibraries} ${book.locatedInLibraries == 1 ? AppLocalizations.of(context)!.library.toLowerCase() : AppLocalizations.of(context)!.libraries.toLowerCase()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: Colors.grey),
          ],
        );
      },
    );
  }
}

/// TextField for search input
/// It allows users to enter search queries.
/// The [onSubmitted] callback is triggered when the user submits the search.
class TextFieldSearchWidget extends StatelessWidget {
  const TextFieldSearchWidget({
    super.key,
    required TextEditingController searchController,
    required Function(String) onSubmitted,
    required VoidCallback clearSearchController,
  }) : _searchController = searchController,
       _onSubmitted = onSubmitted,
       _clearSearchController = clearSearchController;

  final TextEditingController _searchController;
  final Function(String) _onSubmitted;
  final VoidCallback _clearSearchController;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchController,
      onSubmitted: (value) => _onSubmitted(value),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search, color: _primaryColor),
        suffixIcon: IconButton(
          icon: Icon(Icons.clear),
          onPressed: () => _clearSearchController(),
        ),
        labelText: AppLocalizations.of(context)!.search,
        border: OutlineInputBorder(),
      ),
    );
  }
}

/// Dropdown for selecting libraries
/// It allows users to filter search results by library.
/// It uses a [TextEditingController] to manage the selected library.
/// The dropdown entries are provided as a list of [DropdownMenuEntry<String>].
class DropdownLibraries extends StatelessWidget {
  const DropdownLibraries({
    super.key,
    required this.libraryEntries,
    required this.widget,
    required double maxWidth,
    required TextEditingController libraryController,
  }) : _maxWidth = maxWidth,
       _libraryController = libraryController;

  final List<DropdownMenuEntry<String>> libraryEntries;
  final SearchView widget;
  final double _maxWidth;
  final TextEditingController _libraryController;

  @override
  Widget build(BuildContext context) {
    final queryParams = context.watch<QueryParams>();
    return DropdownMenu(
      controller: _libraryController,
      label: Text(AppLocalizations.of(context)!.library),
      leadingIcon: const Icon(Icons.location_city, color: _primaryColor),
      initialSelection: queryParams.library,
      dropdownMenuEntries: [
        DropdownMenuEntry(
          value: 'all',
          label: AppLocalizations.of(context)!.allLibraries,
        ),
        ...libraryEntries,
      ],
      menuHeight: 300,
      onSelected: (value) => queryParams.library = value!,
      width: _maxWidth,
    );
  }
}

/// Dropdown for selecting filters
/// It allows users to filter search results by specific criteria.
/// It uses a [TextEditingController] to manage the selected filter.
/// The dropdown entries are provided as a list of [DropdownMenuEntry<String>].
class DropdownFilter extends StatelessWidget {
  const DropdownFilter({
    super.key,
    required TextEditingController filterController,
    required List<DropdownMenuEntry<String>> filterEntries,
    required this.widget,
    required double maxWidth,
  }) : _filterController = filterController,
       _filterEntries = filterEntries,
       _maxWidth = maxWidth;

  final TextEditingController _filterController;
  final List<DropdownMenuEntry<String>> _filterEntries;
  final SearchView widget;
  final double _maxWidth;

  @override
  Widget build(BuildContext context) {
    final queryParams = context.watch<QueryParams>();
    return DropdownMenu(
      controller: _filterController,
      label: Text(AppLocalizations.of(context)!.searchBy),
      leadingIcon: const Icon(Icons.filter_list, color: _primaryColor),
      dropdownMenuEntries: _filterEntries,
      onSelected: (value) => queryParams.searchBy = value!,
      enableFilter: false,
      initialSelection: queryParams.searchBy,
      requestFocusOnTap: false,
      width: _maxWidth,
    );
  }
}

/// Dropdown for selecting item types
/// It allows users to filter search results by item type.
/// It uses a [TextEditingController] to manage the selected item type.
/// The dropdown entries are provided as a list of [DropdownMenuEntry<String>].
class DropdownItemType extends StatelessWidget {
  const DropdownItemType({
    super.key,
    required TextEditingController itemTypeController,
    required List<DropdownMenuEntry<String>> itemTypeEntries,
    required double maxWidth,
  }) : _itemTypeController = itemTypeController,
       _itemTypeEntries = itemTypeEntries,
       _maxWidth = maxWidth;

  final TextEditingController _itemTypeController;
  final List<DropdownMenuEntry<String>> _itemTypeEntries;
  final double _maxWidth;

  @override
  Widget build(BuildContext context) {
    final queryParams = context.watch<QueryParams>();
    return DropdownMenu(
      controller: _itemTypeController,
      label: Text(AppLocalizations.of(context)!.itemType),
      enableSearch: true,
      menuHeight: 300,
      leadingIcon: const Icon(Icons.category, color: _primaryColor),
      dropdownMenuEntries: [
        DropdownMenuEntry(
          value: 'all',
          label: AppLocalizations.of(context)!.allItemTypes,
        ),
        ..._itemTypeEntries,
      ],
      initialSelection: queryParams.itemType,
      onSelected: (value) => queryParams.itemType = value!,
      width: _maxWidth,
    );
  }
}
