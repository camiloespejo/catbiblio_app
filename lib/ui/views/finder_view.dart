import 'package:catbiblio_app/l10n/app_localizations.dart';
import 'package:catbiblio_app/models/book_location.dart';
import 'package:catbiblio_app/models/finder_params.dart';
import 'package:catbiblio_app/services/images.dart';
import 'package:catbiblio_app/services/locations.dart';
import 'package:catbiblio_app/ui/views/search_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

part '../controllers/finder_controller.dart';

class FinderView extends StatefulWidget {
  final FinderParams params;
  const FinderView({super.key, required this.params});

  @override
  State<FinderView> createState() => _FinderViewState();
}

class _FinderViewState extends FinderController {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.finderTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < screenSizeLimit) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    TitleSection(widget: widget, bookLocation: bookLocation),
                    MapSection(widget: widget, bookLocation: bookLocation),
                  ],
                ),
              );
            } else {
              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width < screenSizeLimit
                          ? MediaQuery.of(context).size.width
                          : (MediaQuery.of(context).size.width / 4) * 3.5,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TitleSection(
                            widget: widget,
                            bookLocation: bookLocation,
                          ),
                        ),
                        Expanded(
                          child: MapSection(
                            widget: widget,
                            bookLocation: bookLocation,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class MapSection extends StatelessWidget {
  const MapSection({
    super.key,
    required this.widget,
    required this.bookLocation,
  });

  final FinderView widget;
  final BookLocation bookLocation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 0.0,
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InteractiveViewer(
            scaleEnabled: kIsWeb ? false : true,
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4,
            child: Image.asset('assets/images/croquis1.png'),
          ),
        ],
      ),
    );
  }
}

class TitleSection extends StatelessWidget {
  const TitleSection({
    super.key,
    required this.widget,
    required this.bookLocation,
  });

  final FinderView widget;
  final BookLocation bookLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: primaryUVColor,
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<Image?>(
                future: ImageService.fetchThumbnailLocal(
                  widget.params.biblioNumber,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError || snapshot.data == null) {
                    return const SizedBox.shrink();
                  } else {
                    return Row(
                      children: [
                        SizedBox(width: 120, child: snapshot.data!),
                        const SizedBox(width: 16.0),
                      ],
                    );
                  }
                },
              ),
              Expanded(
                child: Text(
                  '${widget.params.title}\n\n${AppLocalizations.of(context)!.classification}:\n${widget.params.classification}',
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

        Padding(
          padding: EdgeInsetsGeometry.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 8.0),
              Align(
                alignment: AlignmentGeometry.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.location,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Wrap(
                children: [
                  Icon(
                    Icons.location_city,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    widget.params.holdingLibrary,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          Text(
                            AppLocalizations.of(context)!.level,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            bookLocation.level,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(),

                    Expanded(
                      child: Column(
                        children: [
                          Icon(
                            Icons.meeting_room,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          Text(
                            AppLocalizations.of(context)!.room,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            bookLocation.room,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(),

                    Expanded(
                      child: Column(
                        children: [
                          Icon(
                            Icons.library_books,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          Text(
                            AppLocalizations.of(context)!.collection,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.params.collection,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
