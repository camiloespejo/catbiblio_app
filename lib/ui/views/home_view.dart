import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint;
import 'package:flutter/material.dart';

import 'package:catbiblio_app/l10n/app_localizations.dart';
import 'package:catbiblio_app/models/controllers_data.dart';
import 'package:catbiblio_app/models/global_provider.dart';
import 'package:catbiblio_app/models/image_model.dart';
import 'package:catbiblio_app/models/library.dart';
import 'package:catbiblio_app/models/query_params.dart';
import 'package:catbiblio_app/models/web_query_params.dart';
import 'package:catbiblio_app/services/book_selections.dart';
import 'package:catbiblio_app/services/item_types.dart';
import 'package:catbiblio_app/services/libraries.dart';
import 'package:catbiblio_app/services/library_services.dart';
import 'package:catbiblio_app/ui/views/book_view.dart';
import 'package:catbiblio_app/ui/views/search_view.dart';
import 'package:catbiblio_app/ui/views/libraries_view.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

import 'colors.dart';

part '../controllers/home_controller.dart';

const Color _primaryColor = CustomColors.primaryColor;
const Color _secondaryColor = CustomColors.secondaryColor;

class HomeView extends StatefulWidget {
  final Function(Locale locale) onLocaleChange;

  const HomeView({super.key, required this.onLocaleChange});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends HomeController {
  static final String _baseUrl =
      dotenv.env['KOHA_BASE_URL'] ?? 'https://catbiblio.uv.mx';

  @override
  Widget build(BuildContext context) {
    // Pre-calculate dropdown entries to avoid repeated calculations
    final libraryEntriesPlusAll = [
      DropdownMenuEntry(
        value: 'all',
        label: AppLocalizations.of(context)!.allLibraries,
      ),
      ..._libraryEntries,
    ];
    final itemTypeEntriesPlusAll = [
      DropdownMenuEntry(
        value: 'all',
        label: AppLocalizations.of(context)!.allItemTypes,
      ),
      ..._itemTypeEntries,
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Image(
          image: kIsWeb
              ? AssetImage('assets/images/head-medium.png')
              : AssetImage('assets/images/head.png'),
          height: 40,
        ),
      ),
      drawer: AppNavigationDrawer(
        onLocaleChange: widget.onLocaleChange,
        openLink: openExternalLink,
        isLibrariesLoading: isLibrariesLoading,
        librariesFuture: _librariesFuture,
      ),
      drawerEnableOpenDragGesture: true,
      body: SafeArea(
        /// Search filters section
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Skeletonizer(
                    enabled: isItemTypesLoading,
                    child: ItemTypes(
                      screenSizeLimit: screenSizeLimit,
                      itemTypeController: _itemTypeController,
                      itemTypeEntriesPlusAll: itemTypeEntriesPlusAll,
                    ),
                  ),
                  Skeletonizer(
                    enabled: isLibrariesLoading,
                    child: Libraries(
                      screenSizeLimit: screenSizeLimit,
                      libraryController: _libraryController,
                      libraryEntriesPlusAll: libraryEntriesPlusAll,
                    ),
                  ),
                  Filters(
                    screenSizeLimit: screenSizeLimit,
                    filterController: _searchFilterController,
                    filterEntries: _filterEntries,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      left: 16.0,
                      right: 16.0,
                      bottom: 16.0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.of(context).size.width < screenSizeLimit
                            ? MediaQuery.of(context).size.width
                            : (MediaQuery.of(context).size.width / 3) * 2,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFieldSearchWidget(
                              searchController: _searchController,
                              onSubmitted: (value) => onSubmitAction(),
                              clearSearchController: clearSearchController,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 20,
                              ),
                              minimumSize: const Size(48, 20),
                            ),
                            onPressed: () => onSubmitAction(),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                if (MediaQuery.of(context).size.width >
                                    screenSizeLimit)
                                  Row(
                                    children: [
                                      const SizedBox(width: 4),
                                      Text(
                                        AppLocalizations.of(context)!.search,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// BookSelections Carousel
            /// It displays a carousel of book selections.
            /// Using future builder to load book selections asynchronously.
            /// The carousel is displayed only if there are book selections available.
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(color: _primaryColor),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.bookSelections,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16.0),
                      FutureBuilder(
                        future: _bookSelectionsFuture,
                        builder: (context, asyncSnapshot) {
                          if (asyncSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            );
                          } else if (asyncSnapshot.hasError) {
                            return Center(
                              child: Text(
                                'error',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }

                          _bookSelections = asyncSnapshot.data ?? [];
                          _startBooksCarouselTimer();

                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height / 2,
                            ),
                            child: CarouselView.weighted(
                              flexWeights:
                                  MediaQuery.of(context).size.width < 600
                                  ? const [1, 3, 1]
                                  : const [1, 1, 1, 1, 1],
                              scrollDirection: Axis.horizontal,
                              itemSnapping: true,
                              elevation: 2.0,
                              controller: _booksCarouselController,
                              enableSplash: true,
                              backgroundColor: _primaryColor,
                              onTap: (index) {
                                final bookSelection = _bookSelections[index];
                                if (kIsWeb) {
                                  context.go(
                                    '/book-details/${bookSelection.biblionumber}',
                                  );
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookView(
                                      biblioNumber: bookSelection.biblionumber,
                                    ),
                                  ),
                                );
                              },
                              children: _bookSelections.map((bookSelection) {
                                return HeroLayoutCard(
                                  fit: BoxFit.fitHeight,
                                  imageModel: ImageModel(
                                    bookSelection.name,
                                    '$_baseUrl/cgi-bin/koha/opac-image.pl?biblionumber=${bookSelection.biblionumber}',
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                      // button icon with icon arrow left
                      SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8.0,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_currentBookIndex == 0) return;

                              _booksCarouselController.animateToItem(
                                _currentBookIndex - 1,
                                // duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              setState(() {
                                _currentBookIndex--;
                              });
                            },
                            label: const Icon(Icons.arrow_left, size: 32),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (MediaQuery.of(context).size.width < 600) {
                                if (_currentBookIndex >= _bookSelections.length) {
                                  return;
                                }
                              } else {
                                if (_currentBookIndex >= _bookSelections.length - 4 - 1) {
                                  return;
                                }
                              }

                              _booksCarouselController.animateToItem(
                                _currentBookIndex + 1,
                                // duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              setState(() {
                                _currentBookIndex++;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _primaryColor,
                            ),
                            label: const Icon(Icons.arrow_right, size: 32),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// Libraries Services Carousel
            /// It displays a carousel of library services.
            /// Using future builder to load library services asynchronously.
            /// The carousel is displayed only if there are library services available.
            /// It will default to USBI-X
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: 16.0),
                  Center(
                    child: Text(
                      AppLocalizations.of(context)!.libraryServices,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Center(
                    child: DropdownLibrariesServicesWidget(
                      libraryServicesController: _libraryServicesController,
                      enabledHomeLibrariesEntries: _enabledHomeLibrariesEntries,
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                      onSelected: onSelectLibraryService,
                    ),
                  ),

                  if (isLibraryServicesLoading)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _primaryColor,
                        ),
                      ),
                    )
                  else if (isLibraryServicesError)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.errorLoadingLibraryServices,
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height / 2,
                      ),
                      child: CarouselView.weighted(
                        flexWeights: [1, 4, 1],
                        elevation: 2.0,
                        scrollDirection: Axis.horizontal,
                        itemSnapping: true,
                        controller: _servicesCarouselController,
                        enableSplash: false,
                        children:
                            _librariesServices[selectedLibraryServices]?.map((
                              libraryService,
                            ) {
                              return HeroLayoutCard(
                                fit: BoxFit.fitWidth,
                                imageModel: ImageModel(
                                  libraryService.name,
                                  libraryService.imageUrl,
                                ),
                              );
                            }).toList() ??
                            [],
                      ),
                    ),
                  SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8.0,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_currentServiceIndex == 0) return;

                          _servicesCarouselController.animateToItem(
                            _currentServiceIndex - 1,
                            // duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          setState(() {
                            _currentServiceIndex--;
                          });
                        },
                        label: const Icon(Icons.arrow_left, size: 32),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_currentServiceIndex >=
                              (_librariesServices[selectedLibraryServices]
                                          ?.length ??
                                      1) -
                                  1) {
                            return;
                          }
                          _servicesCarouselController.animateToItem(
                            _currentServiceIndex + 1,
                            // duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          setState(() {
                            _currentServiceIndex++;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        label: const Icon(Icons.arrow_right, size: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ItemTypes widget
/// It displays a dropdown menu for selecting item types.
/// The [screenSizeLimit] parameter is used to set the maximum width of the dropdown.
class ItemTypes extends StatelessWidget {
  const ItemTypes({
    super.key,
    required this.screenSizeLimit,
    required TextEditingController itemTypeController,
    required this.itemTypeEntriesPlusAll,
  }) : _itemTypeController = itemTypeController;

  final int screenSizeLimit;
  final TextEditingController _itemTypeController;
  final List<DropdownMenuEntry<String>> itemTypeEntriesPlusAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        left: 16.0,
        right: 16.0,
        bottom: 8.0,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width < screenSizeLimit
              ? MediaQuery.of(context).size.width
              : (MediaQuery.of(context).size.width / 3) * 2,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return DropdownItemTypesWidget(
              itemTypeController: _itemTypeController,
              itemTypeEntries: itemTypeEntriesPlusAll,
              maxWidth: constraints.maxWidth,
            );
          },
        ),
      ),
    );
  }
}

class Libraries extends StatelessWidget {
  const Libraries({
    super.key,
    required this.screenSizeLimit,
    required TextEditingController libraryController,
    required this.libraryEntriesPlusAll,
  }) : _libraryController = libraryController;

  final int screenSizeLimit;
  final TextEditingController _libraryController;
  final List<DropdownMenuEntry<String>> libraryEntriesPlusAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        left: 16.0,
        right: 16.0,
        bottom: 8.0,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width < screenSizeLimit
              ? MediaQuery.of(context).size.width
              : (MediaQuery.of(context).size.width / 3) * 2,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return DropdownLibrariesWidget(
              libraryController: _libraryController,
              libraryEntries: libraryEntriesPlusAll,
              maxWidth: constraints.maxWidth,
            );
          },
        ),
      ),
    );
  }
}

class Filters extends StatelessWidget {
  const Filters({
    super.key,
    required this.screenSizeLimit,
    required TextEditingController filterController,
    required this.filterEntries,
  }) : _searchFilterController = filterController;

  final int screenSizeLimit;
  final TextEditingController _searchFilterController;
  final List<DropdownMenuEntry<String>> filterEntries;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        left: 16.0,
        right: 16.0,
        bottom: 8.0,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width < screenSizeLimit
              ? MediaQuery.of(context).size.width
              : (MediaQuery.of(context).size.width / 3) * 2,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return DropdownFilters(
              searchFilterController: _searchFilterController,
              filterEntries: filterEntries,
              maxWidth: constraints.maxWidth,
            );
          },
        ),
      ),
    );
  }
}

/// HeroLayoutCard widget
/// It displays a card with an image and title.
/// The image is loaded from a URL and the title is displayed at the bottom of the card
/// Used for both carousels book selections and library services.
class HeroLayoutCard extends StatelessWidget {
  const HeroLayoutCard({
    super.key,
    required this.imageModel,
    required this.fit,
  });

  final BoxFit fit;
  final ImageModel imageModel;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return Stack(
      alignment: AlignmentDirectional.bottomStart,
      children: <Widget>[
        ClipRect(
          child: OverflowBox(
            maxWidth: width * 2,
            minWidth: width,
            child: Image.network(imageModel.url, loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_secondaryColor),
                ),
              );
            }, errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                width: double.infinity,
                height: double.infinity,
                child: Icon(
                  Icons.broken_image,
                  size: 64,
                  color: Colors.grey[600],
                ),
              );
            }, fit: fit),
          ),
        ),
        Container(
          width: double.infinity,
          color: _secondaryColor.withAlpha(200),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  imageModel.title,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// AppNavigationDrawer widget
/// It provides a navigation drawer with various options for the user.
class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({
    super.key,
    required this.onLocaleChange,
    required this.openLink,
    required this.isLibrariesLoading,
    required this.librariesFuture,
  });

  final ValueChanged<Locale> onLocaleChange;
  final Future<void> Function(String url) openLink;
  final bool isLibrariesLoading;
  final Future<List<Library>> librariesFuture;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      children: [
        DrawerHeader(
          child: kIsWeb
              ? Image.asset('assets/images/head-medium.png')
              : Image.asset('assets/images/head.png'),
        ),
        ListTile(
          leading: const Icon(Icons.map, color: _primaryColor),
          title: Text(AppLocalizations.of(context)!.libraryDirectory),
          enabled: !isLibrariesLoading,
          onTap: () {
            if (kIsWeb) {
              context.go('/directory');
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LibrariesView()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.computer, color: _primaryColor),
          title: Text(AppLocalizations.of(context)!.electronicResources),
          trailing: Transform.scale(
            scale: 0.8,
            child: const Icon(Icons.open_in_new),
          ),
          onTap: () => openLink('https://www.uv.mx/dgbuv/#descubridor'),
        ),
        ListTile(
          leading: const Icon(Icons.help, color: _primaryColor),
          title: Text(AppLocalizations.of(context)!.faq),
          trailing: Transform.scale(
            scale: 0.8,
            child: const Icon(Icons.open_in_new),
          ),
          onTap: () =>
              openLink('https://www.uv.mx/dgbuv/preguntas-frecuentes/'),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip, color: _primaryColor),
          title: Text(AppLocalizations.of(context)!.privacyNotice),
          trailing: Transform.scale(
            scale: 0.8,
            child: const Icon(Icons.open_in_new),
          ),
          onTap: () => openLink(
            'https://catbiblio.uv.mx/avisos/aviso-privacidad-integral-sib.pdf',
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.language, color: _primaryColor),
          title: Text(AppLocalizations.of(context)!.language),
          onTap: () {
            onLocaleChange(
              AppLocalizations.of(context)!.localeName == 'es'
                  ? const Locale('en')
                  : const Locale('es'),
            );
            Navigator.pop(context);
            Future.delayed(Duration.zero, () {
              if (context.mounted) {
                SnackBar snackBar = SnackBar(
                  content: Text(AppLocalizations.of(context)!.languageChanged),
                  duration: const Duration(seconds: 2),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.info, color: _primaryColor),
          title: Text(AppLocalizations.of(context)!.about),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'Catálogo Bibliotecario UV',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2025 Sistema Integral Bibliotecario UV',
            );
          },
        ),
      ],
    );
  }
}

/// DropdownLibrariesServicesWidget
/// It allows users to select a library service from a dropdown menu.
/// This widget information depends on the libraries list previously loaded.
/// This cannot be used before the libraries are loaded.
class DropdownLibrariesServicesWidget extends StatelessWidget {
  const DropdownLibrariesServicesWidget({
    super.key,
    required this.libraryServicesController,
    required this.enabledHomeLibrariesEntries,
    required this.maxWidth,
    required this.onSelected,
  });

  final TextEditingController libraryServicesController;
  final List<DropdownMenuEntry<String>> enabledHomeLibrariesEntries;
  final double maxWidth;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu(
      onSelected: (value) => onSelected(value!),
      width: maxWidth,
      controller: libraryServicesController,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
      dropdownMenuEntries: enabledHomeLibrariesEntries,
      enableSearch: false,
      enableFilter: false,
      requestFocusOnTap: false,
    );
  }
}

/// DropdownFilters widget
/// It allows users to select a filter for search results.
class DropdownFilters extends StatelessWidget {
  const DropdownFilters({
    super.key,
    required this.searchFilterController,
    required this.filterEntries,
    required this.maxWidth,
  });

  final TextEditingController searchFilterController;
  final List<DropdownMenuEntry<String>> filterEntries;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final queryParams = context.watch<QueryParams>();
    return DropdownMenu(
      controller: searchFilterController,
      label: Text(AppLocalizations.of(context)!.searchBy),
      leadingIcon: const Icon(Icons.filter_list, color: _primaryColor),
      dropdownMenuEntries: filterEntries,
      initialSelection: queryParams.searchBy,
      onSelected: (value) => queryParams.searchBy = value!,
      width: maxWidth,
      enableFilter: false,
      requestFocusOnTap: false,
    );
  }
}

/// SearchView widget
/// It allows users to search for items in the catalog based on the previous filters.
class TextFieldSearchWidget extends StatelessWidget {
  const TextFieldSearchWidget({
    super.key,
    required this.searchController,
    required this.onSubmitted,
    required this.clearSearchController,
  });

  final TextEditingController searchController;
  final Function(String) onSubmitted;
  final VoidCallback clearSearchController;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: searchController,
      onSubmitted: (value) => onSubmitted(value),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, color: _primaryColor),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => clearSearchController(),
        ),
        labelText: AppLocalizations.of(context)!.search,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

/// DropdownLibrariesWidget
/// It allows users to select a library for filtering search results.
class DropdownLibrariesWidget extends StatelessWidget {
  const DropdownLibrariesWidget({
    super.key,
    required this.libraryController,
    required this.libraryEntries,
    required this.maxWidth,
  });

  final TextEditingController libraryController;
  final List<DropdownMenuEntry<String>> libraryEntries;
  final double maxWidth;
  @override
  Widget build(BuildContext context) {
    final queryParams = context.watch<QueryParams>();
    return DropdownMenu(
      controller: libraryController,
      label: Text(AppLocalizations.of(context)!.library),
      enableSearch: true,
      menuHeight: 300,
      leadingIcon: const Icon(Icons.location_city, color: _primaryColor),
      initialSelection: queryParams.library,
      width: maxWidth,
      dropdownMenuEntries: libraryEntries,
      onSelected: (value) {
        queryParams.library = value!;
      },
    );
  }
}

/// DropdownItemTypesWidget
/// It allows users to select an item type for filtering search results.
class DropdownItemTypesWidget extends StatelessWidget {
  const DropdownItemTypesWidget({
    super.key,
    required this.itemTypeController,
    required this.itemTypeEntries,
    required this.maxWidth,
  });

  final TextEditingController itemTypeController;
  final List<DropdownMenuEntry<String>> itemTypeEntries;
  final double maxWidth;
  @override
  Widget build(BuildContext context) {
    final queryParams = context.watch<QueryParams>();
    return DropdownMenu(
      controller: itemTypeController,
      label: Text(AppLocalizations.of(context)!.itemType),
      enableSearch: true,
      menuHeight: 300,
      leadingIcon: const Icon(Icons.category, color: _primaryColor),
      initialSelection: queryParams.itemType,
      dropdownMenuEntries: itemTypeEntries,
      width: maxWidth,
      onSelected: (value) {
        queryParams.itemType = value!;
      },
    );
  }
}
