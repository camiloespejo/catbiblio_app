import 'dart:async';

import 'package:catbiblio_app/l10n/app_localizations.dart';
import 'package:catbiblio_app/models/controllers_data.dart';
import 'package:catbiblio_app/models/global_provider.dart';
import 'package:catbiblio_app/models/image_model.dart';
import 'package:catbiblio_app/models/library.dart';
import 'package:catbiblio_app/models/query_params.dart';
import 'package:catbiblio_app/services/book_selections.dart';
import 'package:catbiblio_app/services/item_types.dart';
import 'package:catbiblio_app/services/libraries.dart';
import 'package:catbiblio_app/services/library_services.dart';
import 'package:catbiblio_app/ui/views/book_view.dart';
import 'package:catbiblio_app/ui/views/search_view.dart';
import 'package:catbiblio_app/ui/views/libraries_view.dart';
import 'colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:url_launcher/url_launcher.dart';

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
        title: const Image(
          image: AssetImage('assets/images/head.png'),
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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  ItemTypes(
                    screenSizeLimit: screenSizeLimit,
                    itemTypeController: _itemTypeController,
                    itemTypeEntriesPlusAll: itemTypeEntriesPlusAll,
                  ),
                  Libraries(
                    screenSizeLimit: screenSizeLimit,
                    libraryController: _libraryController,
                    libraryEntriesPlusAll: libraryEntriesPlusAll,
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
                        maxWidth: MediaQuery.of(context).size.width <
                                screenSizeLimit
                            ? MediaQuery.of(context).size.width
                            : (MediaQuery.of(context).size.width / 3) * 2,
                      ),
                      child: TextFieldSearchWidget(
                        searchController: _searchController,
                        onSubmitted: (value) => onSubmitAction(),
                        clearSearchController: clearSearchController,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                            child: IgnorePointer(
                              ignoring: kIsWeb,
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
                                        biblioNumber:
                                            bookSelection.biblionumber,
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
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                  FutureBuilder(
                    future: _librariesServicesFuture,
                    builder: (context, asyncSnapshot) {
                      if (asyncSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (asyncSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      _librariesServices = asyncSnapshot.data ?? {};
                      _startServicesCarouselTimer();

                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height / 2,
                        ),
                        child: IgnorePointer(
                          ignoring: kIsWeb,
                          child: CarouselView.weighted(
                            flexWeights: [1, 4, 1],
                            elevation: 2.0,
                            scrollDirection: Axis.horizontal,
                            itemSnapping: true,
                            controller: _servicesCarouselController,
                            enableSplash: false,
                            children:
                                _librariesServices[selectedLibraryServices]
                                    ?.map((libraryService) {
                                      return HeroLayoutCard(
                                        fit: BoxFit.fitWidth,
                                        imageModel: ImageModel(
                                          libraryService.name,
                                          libraryService.imageUrl,
                                        ),
                                      );
                                    })
                                    .toList() ??
                                [],
                          ),
                        ),
                      );
                    },
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
            child: CachedNetworkImage(
              imageUrl: imageModel.url,
              fit: fit,
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
              ),
            ),
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
        DrawerHeader(child: Image.asset('assets/images/head.png')),
        ListTile(
          leading: const Icon(Icons.map, color: _primaryColor),
          title: Text(AppLocalizations.of(context)!.libraryDirectory),
          enabled: !isLibrariesLoading,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LibrariesView(libraries: librariesFuture),
            ),
          ),
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
