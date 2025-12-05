import 'dart:async' show TimeoutException;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, kDebugMode;
import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:readmore/readmore.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:catbiblio_app/l10n/app_localizations.dart';
import 'package:catbiblio_app/models/biblio_item.dart';
import 'package:catbiblio_app/models/biblios_details.dart';
import 'package:catbiblio_app/models/finder_params.dart';
import 'package:catbiblio_app/services/biblios_items.dart';
import 'package:catbiblio_app/services/book_finder_libraries.dart';
import 'package:catbiblio_app/services/images.dart';
import 'package:catbiblio_app/services/biblios_details.dart';
import 'package:catbiblio_app/ui/views/finder_view.dart';
import 'package:catbiblio_app/ui/views/marc_view.dart';

import 'colors.dart';

part '../controllers/book_controller.dart';

const Color _primaryColor = CustomColors.primaryColor;

class BookView extends StatefulWidget {
  final String biblioNumber;
  const BookView({super.key, required this.biblioNumber});

  @override
  State<BookView> createState() => _BookViewState();
}

class _BookViewState extends BookController {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: kIsWeb
            ? TextButton(
                onPressed: () {
                  context.go('/');
                },
                child: Image(
                  image: const AssetImage('assets/images/head-medium.png'),
                  height: 40,
                ),
              )
            : Text(AppLocalizations.of(context)!.detailsTitle),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                    maxWidth:
                        MediaQuery.of(context).size.width < screenSizeLimit
                        ? MediaQuery.of(context).size.width
                        : (MediaQuery.of(context).size.width / 3) * 2,
                  ),
                  child: Column(
                    children: [
                      if (isErrorLoadingDetails)
                        Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.errorLoadingBookDetails,
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Skeletonizer(
                              enabled: isLoadingDetails,
                              child: Container(
                                color: _primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 24.0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isLoadingDetails)
                                      SizedBox(
                                        width: 120,
                                        height: 160,
                                        child: Container(
                                          color: Colors.white24,
                                          child: const Center(
                                            child: Icon(
                                              Icons.image,
                                              size: 48,
                                              color: Colors.white60,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      FutureBuilder<ThumbnailResult?>(
                                        future: ImageService.fetchThumbnail(
                                          widget.biblioNumber,
                                          bibliosDetails.isbn,
                                        ),
                                        builder: (context, snapshot) {
                                          // Error or no image found: show placeholder
                                          if (snapshot.hasError ||
                                              snapshot.data == null) {
                                            hasImage = false;
                                            return Hero(
                                              tag: 'biblioImage',
                                              child: SizedBox(
                                                width: 120,
                                                height: 160,
                                                child: Container(
                                                  color: Colors.white24,
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.book,
                                                      size: 36,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                          // We have an image and know its source now
                                          hasImage = true;
                                          final source = snapshot.data!.source;
                                          final imageWidget =
                                              snapshot.data!.image;

                                          return GestureDetector(
                                            onTap: () {
                                              if (source ==
                                                  ImageService.sourceLocal) {
                                                _showImageDialog(
                                                  context,
                                                  'biblioImage',
                                                  '$_baseUrl/cgi-bin/koha/opac-image.pl?biblionumber=${widget.biblioNumber}',
                                                );
                                              } else {
                                                _showImageDialog(
                                                  context,
                                                  'biblioImage',
                                                  '$_openLibraryBaseUrl/b/isbn/${bibliosDetails.isbn}-L.jpg',
                                                );
                                              }
                                            },
                                            child: Hero(
                                              tag: 'biblioImage',
                                              child: Column(
                                                children: [
                                                  SizedBox(
                                                    width: 120,
                                                    height: 160,
                                                    child: imageWidget,
                                                  ),
                                                  SizedBox(
                                                    width: 120,
                                                    child: Text(
                                                      source ==
                                                              ImageService
                                                                  .sourceLocal
                                                          ? AppLocalizations.of(
                                                              context,
                                                            )!.localCoverIMGAlt
                                                          : AppLocalizations.of(
                                                              context,
                                                            )!.openLibraryCoverIMGAlt,
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    const SizedBox(width: 16.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SelectionArea(
                                            child: Text(
                                              isLoadingDetails
                                                  ? mockTitle
                                                  : bibliosDetails.title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 16.0,
                                left: 16.0,
                                right: 16.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Skeletonizer(
                                        enabled: isLoadingDetails,
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.bibliographicDetails,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8.0,
                                          right: 8.0,
                                        ),
                                        child: SelectionArea(
                                          child: BibliographicDetails(
                                            bibliosDetails: bibliosDetails,
                                            languageMap: languageMap,
                                            isLoadingDetails: isLoadingDetails,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          bottom: 16.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            Skeletonizer(
                              enabled:
                                  isLoadingDetails || isErrorLoadingDetails,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      if (kIsWeb) {
                                        context.go(
                                          '/marc/${widget.biblioNumber}',
                                        );
                                        return;
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MarcView(
                                            biblioNumber: widget.biblioNumber,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.library_books),
                                    label: const Text('MARC'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      showShareDialog(
                                        context,
                                        bibliosDetails.title,
                                        widget.biblioNumber,
                                      );
                                    },
                                    icon: const Icon(Icons.share),
                                    label: Text(
                                      AppLocalizations.of(context)!.share,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),

                            if (isErrorLoadingBiblioItems)
                              Center(
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.error,
                                      color: Colors.red,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text('Error loading item copies'),
                                  ],
                                ),
                              )
                            else if (biblioItems.isEmpty && !isLoadingDetails)
                              Center(
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.info,
                                      color: _primaryColor,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.noCopiesFound,
                                    ),
                                  ],
                                ),
                              )
                            else
                              Column(
                                children: [
                                  Skeletonizer(
                                    enabled: isLoadingBiblioItems,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '${AppLocalizations.of(context)!.copies}: ${biblioItems.length}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Skeletonizer(
                                    enabled: isLoadingBiblioItems,
                                    child: KeysLegend(),
                                  ),

                                  ListViewLibrariesWidget(
                                    finderlibraries: _finderLibraries,
                                    holdingLibraries: holdingLibraries,
                                    groupedItems: groupedItems,
                                    navigateToFinderView: navigateToFinderView,
                                    isLoadingBiblioItems: isLoadingBiblioItems,
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to display the legend for item status icons
class KeysLegend extends StatelessWidget {
  const KeysLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pin_drop,
                color: CustomColors.customRed,
                size: 20.0,
              ),
              const SizedBox(width: 4.0),
              Text(
                AppLocalizations.of(context)!.legendFinder,
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20.0),
              const SizedBox(width: 4.0),
              Text(
                AppLocalizations.of(context)!.legendAvailable,
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.watch_later, color: Colors.orange, size: 20.0),
              const SizedBox(width: 4.0),
              Text(
                AppLocalizations.of(context)!.legendBorrowed,
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.lock, color: Colors.red, size: 20.0),
              const SizedBox(width: 4.0),
              Text(
                AppLocalizations.of(context)!.legendNotForBorrow,
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget to display a list of libraries and their bibliographic items
/// It shows an expandable list of libraries with their items.
/// Each item shows its details and a button to navigate to the finder view if applicable.
class ListViewLibrariesWidget extends StatelessWidget {
  const ListViewLibrariesWidget({
    super.key,
    required this.holdingLibraries,
    required this.groupedItems,
    required this.navigateToFinderView,
    required this.isLoadingBiblioItems,
    required this.finderlibraries,
  });

  final List<String> holdingLibraries;
  final Map<String, List<BiblioItem>> groupedItems;
  final Set<String> finderlibraries;
  final Function(
    String callNumber,
    String collection,
    String collectionCode,
    String holdingLibrary,
    String libraryCode,
  )
  navigateToFinderView;
  final bool isLoadingBiblioItems;

  @override
  Widget build(BuildContext context) {
    if (isLoadingBiblioItems) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3, // Show 3 placeholder items
        itemBuilder: (context, index) {
          return Skeletonizer.zone(
            child: Card(
              child: ListTile(
                title: Bone.text(words: 4),
                trailing: Bone.icon(),
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: holdingLibraries.length,
      itemBuilder: (context, index) {
        final item = holdingLibraries[index];
        final libraryCode = groupedItems[item]!.first.holdingLibraryId;
        final isFinderEnabled = finderlibraries.contains(libraryCode);

        return Card(
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          color: isFinderEnabled
              ? CustomColors.secondaryColor.withAlpha(255)
              : null,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              collapsedIconColor: isFinderEnabled ? Colors.white : null,
              iconColor: isFinderEnabled ? Colors.white : null,
              tilePadding: const EdgeInsets.symmetric(horizontal: 8.0),
              dense: true,
              childrenPadding: const EdgeInsets.only(bottom: 8.0),
              title: Text(
                '$item (${groupedItems[item]!.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isFinderEnabled ? Colors.white : null,
                ),
              ),
              children: groupedItems[item]!.map((biblioItem) {
                return Card(
                  child: ExpansionTile(
                    collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${AppLocalizations.of(context)!.classification}:\n${biblioItem.callNumber}',
                          ),
                        ),
                        finderlibraries.contains(biblioItem.holdingLibraryId) &&
                                biblioItem.homeLibraryId ==
                                    biblioItem.holdingLibraryId &&
                                biblioItem.overAllStatus ==
                                    BiblioItem.statusAvailable
                            ? IconButton(
                                onPressed: () => navigateToFinderView(
                                  biblioItem.callNumber ?? 'N/D',
                                  biblioItem.collection ?? 'N/D',
                                  biblioItem.collectionCode ?? 'N/D',
                                  biblioItem.holdingLibrary,
                                  biblioItem.holdingLibraryId,
                                ),
                                icon: const Icon(
                                  Icons.pin_drop,
                                  color: CustomColors.customRed,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                    leading: Icon(
                      biblioItem.overAllStatus == BiblioItem.statusBorrowed
                          ? Icons.watch_later
                          : biblioItem.overAllStatus ==
                                BiblioItem.statusNotForLoan
                          ? Icons.lock
                          : Icons.check_circle,
                      color:
                          biblioItem.overAllStatus == BiblioItem.statusBorrowed
                          ? Colors.orange
                          : biblioItem.overAllStatus ==
                                BiblioItem.statusNotForLoan
                          ? Colors.red
                          : Colors.green,
                    ),
                    childrenPadding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      bottom: 8.0,
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.itemType}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(biblioItem.itemType ?? 'N/D'),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.holdingLibrary}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(biblioItem.holdingLibrary),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.collection}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(biblioItem.collection ?? 'N/D'),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.classification}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(biblioItem.callNumber ?? 'N/D'),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.copyNumber}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(biblioItem.copyNumber ?? 'N/D'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Widget to display bibliographic details
/// It shows various details like author, editor, description, ISBN, language, etc.
/// Includes mock data for loading state.
class BibliographicDetails extends StatelessWidget {
  const BibliographicDetails({
    super.key,
    required this.bibliosDetails,
    required this.languageMap,
    required this.isLoadingDetails,
  });

  final BibliosDetails bibliosDetails;
  final Map<String, String> languageMap;
  final bool isLoadingDetails;

  @override
  Widget build(BuildContext context) {
    if (isLoadingDetails) {
      bibliosDetails.author = mockAuthor;
      bibliosDetails.editor = mockEditor;
      bibliosDetails.description = mockDescription;
      bibliosDetails.isbn = mockIsbn;
      bibliosDetails.language = mockLanguage;
      bibliosDetails.originalLanguage = mockOriginalLanguage;
      bibliosDetails.subject = mockSubject;
      bibliosDetails.collaborators = mockCollaborators;
      bibliosDetails.summary = mockSummary;
      bibliosDetails.cdd = mockCdd;
      bibliosDetails.loc = mockLoc;
    }

    return Skeletonizer(
      enabled: isLoadingDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bibliosDetails.author.isNotEmpty)
            SingleBiblioDetailWrap(
              label: AppLocalizations.of(context)!.author,
              value: bibliosDetails.author,
            ),
          if (bibliosDetails.editor.isNotEmpty)
            SingleBiblioDetailWrap(
              label: AppLocalizations.of(context)!.editor,
              value: bibliosDetails.editor,
            ),
          if (bibliosDetails.edition.isNotEmpty)
            SingleBiblioDetailWrap(
              label: AppLocalizations.of(context)!.edition,
              value: bibliosDetails.edition,
            ),
          if (bibliosDetails.description.isNotEmpty)
            SingleBiblioDetailWrap(
              label: AppLocalizations.of(context)!.description,
              value: bibliosDetails.description,
            ),
          if (bibliosDetails.isbn.isNotEmpty)
            SingleBiblioDetailWrap(label: 'ISBN', value: bibliosDetails.isbn),
          if (bibliosDetails.language.isNotEmpty)
            SingleBiblioDetailWrap(
              label: AppLocalizations.of(context)!.language,
              value:
                  languageMap[bibliosDetails.language] ??
                  bibliosDetails.language,
            ),
          if (bibliosDetails.originalLanguage.isNotEmpty)
            SingleBiblioDetailWrap(
              label: AppLocalizations.of(context)!.originalLanguage,
              value:
                  languageMap[bibliosDetails.originalLanguage] ??
                  bibliosDetails.originalLanguage,
            ),
          if (bibliosDetails.subject.isNotEmpty)
            SingleBiblioDetailWrap(
              label: AppLocalizations.of(context)!.subject,
              value: bibliosDetails.subject,
            ),
          if (bibliosDetails.collaborators.isNotEmpty)
            SingleBiblioDetailWrap(
              label: AppLocalizations.of(context)!.collaborators,
              value: bibliosDetails.collaborators,
            ),
          if (bibliosDetails.summary.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.summary,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    // fontSize: 16,
                  ),
                ),
                ReadMoreText(
                  bibliosDetails.summary,
                  trimLines: 4,
                  colorClickableText: Colors.blue,
                  trimMode: TrimMode.Line,
                  trimCollapsedText:
                      '... ${AppLocalizations.of(context)!.readMore}',
                  trimExpandedText:
                      ' ${AppLocalizations.of(context)!.showLess}',
                  // style: const TextStyle(fontSize: 14),
                ),
                // Text(bibliosDetails.summary),
              ],
            ),
          if (bibliosDetails.cdd.isNotEmpty)
            SingleBiblioDetailWrap(label: 'CDD', value: bibliosDetails.cdd),
          if (bibliosDetails.loc.isNotEmpty)
            SingleBiblioDetailWrap(label: 'LOC', value: bibliosDetails.loc),
          if (bibliosDetails.otherClassification.isNotEmpty)
            SingleBiblioDetailWrap(
              label: AppLocalizations.of(context)!.otherClassification,
              value: bibliosDetails.otherClassification,
            ),
          if (bibliosDetails.lawClassification.isNotEmpty)
            SingleBiblioDetailWrap(
              label: AppLocalizations.of(context)!.lawClassification,
              value: bibliosDetails.lawClassification,
            ),
        ],
      ),
    );
  }

  final mockAuthor = 'John Doe';
  final mockEditor = 'Jane Editor';
  final mockDescription = 'Brief description of the work.';
  final mockIsbn = 'ISBN 000-0-00-000000-0';
  final mockLanguage = 'eng';
  final mockOriginalLanguage = 'fre';
  final mockSubject = 'Sample subject, keywords';
  final mockCollaborators = 'A. Collaborator; B. Collaborator';
  final mockSummary =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus non felis eu justo '
      'viverra pulvinar. Curabitur ac orci a lorem posuere tincidunt. Integer vitae dui nec ';
  final mockCdd = '000';
  final mockLoc = 'QA76.XX XX XXX';
}

/// Widget to display a single bibliographic detail with label and value
class SingleBiblioDetailWrap extends StatelessWidget {
  const SingleBiblioDetailWrap({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }
}

/// Dialog to display an image
/// It uses a [Hero] widget for smooth transitions.
/// The [tag] is used to identify the image in the hero animation.
/// The [imageUrl] is the URL of the image to be displayed.
/// The dialog is displayed when the user taps on the image.
class ImageDialog extends StatelessWidget {
  const ImageDialog({required this.tag, required this.imageUrl, super.key});

  final String tag;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.all(16.0),

      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Hero(
          tag: tag,
          child: InteractiveViewer(child: Image.network(imageUrl, scale: 1.2)),
        ),
      ),
    );
  }
}
