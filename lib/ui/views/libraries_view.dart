import 'package:catbiblio_app/services/libraries.dart' show LibrariesService;
import 'package:flutter/material.dart';

import 'package:catbiblio_app/l10n/app_localizations.dart';
import 'package:catbiblio_app/models/library.dart';
import 'package:catbiblio_app/models/region.dart';

import 'package:url_launcher/url_launcher.dart';

part '../controllers/libraries_controller.dart';

class LibrariesView extends StatefulWidget {
  const LibrariesView({super.key});

  @override
  State<LibrariesView> createState() => _LibrariesViewState();
}

class _LibrariesViewState extends LibrariesController {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.libraryDirectory),
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
                  child: FutureBuilder<List<Library>>(
                    future: LibrariesService.getLibraries(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.couldNotFetchLibraries,
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            AppLocalizations.of(context)!.noLibrariesFound,
                          ),
                        );
                      } else {
                        final libraries = snapshot.data!;
                        return Column(
                          children: regionsList.map((item) {
                            return Card(
                              color: Colors.grey[100],
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  collapsedShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  title: Text(
                                    item,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  children: libraries
                                      .where((lib) => lib.region == item)
                                      .map((library) {
                                        return ListTile(
                                          title: Text(library.name),
                                          subtitle: Text(
                                            '${library.city}, ${library.state}',
                                          ),
                                          trailing: library.url.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.link),
                                                  color: Colors.blue,
                                                  onPressed: () =>
                                                      openLink(library.url),
                                                )
                                              : null,
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: Text(library.name),
                                                  content: LibraryDialogBody(
                                                    library: library,
                                                    context: context,
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(),
                                                      child: Text(
                                                        AppLocalizations.of(
                                                          context,
                                                        )!.close,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        );
                                      })
                                      .toList(),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }
                    },
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

/// Widget to display the body of the library details dialog.
/// It shows various fields of the library
/// such as area, address, postal code, city, state, country, email, and URL,
/// only if they are not empty.
/// This widget is used in the buildLibraryDialog method of LibrariesController.
class LibraryDialogBody extends StatelessWidget {
  final Library library;
  final BuildContext context;

  const LibraryDialogBody({
    super.key,
    required this.library,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (library.area.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: Chip(label: Text(library.area)),
            ),
          ),
        if (library.address.isNotEmpty)
          LibraryField(
            fieldName: AppLocalizations.of(context)!.address,
            value: library.address,
          ),
        if (library.postalCode.isNotEmpty)
          LibraryField(
            fieldName: AppLocalizations.of(context)!.postalCode,
            value: library.postalCode,
          ),
        if (library.city.isNotEmpty)
          LibraryField(
            fieldName: AppLocalizations.of(context)!.city,
            value: library.city,
          ),
        if (library.state.isNotEmpty)
          LibraryField(
            fieldName: AppLocalizations.of(context)!.state,
            value: library.state,
          ),
        if (library.country.isNotEmpty)
          LibraryField(
            fieldName: AppLocalizations.of(context)!.country,
            value: library.country,
          ),
        if (library.email.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              children: [
                Text(
                  '${AppLocalizations.of(context)!.email}: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () async {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: library.email,
                    );
                    await launchUrl(emailLaunchUri);
                  },
                  child: Text(
                    library.email,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (library.url.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(top: 8.0),
              child: Chip(
                label: GestureDetector(
                  onTap: () => launchUrl(Uri.parse(library.url)),
                  child: Text(
                    library.url,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget to display a field in the library details dialog
/// with the field name in bold followed by its value.
///
/// For example: "Address: 123 Main St"
///
/// This widget is used in the buildLibraryDialog method of LibrariesController.
class LibraryField extends StatelessWidget {
  final String fieldName;
  final String value;

  const LibraryField({super.key, required this.fieldName, required this.value});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        children: [
          Text(
            '$fieldName: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}
