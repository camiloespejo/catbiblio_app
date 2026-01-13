import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// home view top bar title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Filter by dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Search by'**
  String get searchBy;

  /// Library selection dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// Search field hint
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Our selections section title
  ///
  /// In en, this message translates to:
  /// **'Our Selections'**
  String get ourSelections;

  /// News section title
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get news;

  /// Search history section title
  ///
  /// In en, this message translates to:
  /// **'Search History'**
  String get searchHistory;

  /// Language selection hint
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Library directory section title
  ///
  /// In en, this message translates to:
  /// **'Library Directory'**
  String get libraryDirectory;

  /// Electronic resources section title
  ///
  /// In en, this message translates to:
  /// **'Electronic Resources'**
  String get electronicResources;

  /// Frequently asked questions section title
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// Privacy notice section title
  ///
  /// In en, this message translates to:
  /// **'Privacy Notice'**
  String get privacyNotice;

  /// Search results view top bar title
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchTitle;

  /// Title entry in search by dropdown
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleEntry;

  /// Author entry in search by dropdown
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get authorEntry;

  /// Subject entry in search by dropdown
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subjectEntry;

  /// General entry in search by dropdown
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalEntry;

  /// ISBN entry in search by dropdown
  ///
  /// In en, this message translates to:
  /// **'ISBN'**
  String get isbnEntry;

  /// ISSN entry in search by dropdown
  ///
  /// In en, this message translates to:
  /// **'ISSN'**
  String get issnEntry;

  /// By author label in book preview
  ///
  /// In en, this message translates to:
  /// **'By'**
  String get byAuthor;

  /// Publishing details label in book preview
  ///
  /// In en, this message translates to:
  /// **'Publishing details'**
  String get publishingDetails;

  /// Availability label in book preview
  ///
  /// In en, this message translates to:
  /// **'Available in'**
  String get availability;

  /// All libraries entry in library selection dropdown
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allLibraries;

  /// Details title in book view
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsTitle;

  /// Snackbar message shown when the language is changed to English
  ///
  /// In en, this message translates to:
  /// **'Language changed to English'**
  String get languageChanged;

  /// Label for total number of search results
  ///
  /// In en, this message translates to:
  /// **'results'**
  String get totalResults;

  /// Message shown when no search results are found
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// Message shown when an error occurs during data fetching
  ///
  /// In en, this message translates to:
  /// **'An error occurred while fetching data. Please try again.'**
  String get errorOccurred;

  /// Message shown when there is an error loading the libraries
  ///
  /// In en, this message translates to:
  /// **'Error loading libraries'**
  String get errorLoadingLibraries;

  /// Label for the original language of a book
  ///
  /// In en, this message translates to:
  /// **'Original Language'**
  String get originalLanguage;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Spanish language option
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// French language option
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// German language option
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// Japanese language option
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get japanese;

  /// Italian language option
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get italian;

  /// Portuguese language option
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get portuguese;

  /// Russian language option
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// Chinese language option
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// Label for the subject of a book
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// Label for the collaborators of a book
  ///
  /// In en, this message translates to:
  /// **'Collaborators'**
  String get collaborators;

  /// Label for the summary of a book
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// Button text to expand the summary
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get readMore;

  /// Button text to collapse the summary
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// Editor label in book preview
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editor;

  /// Edition label in book preview
  ///
  /// In en, this message translates to:
  /// **'Edition'**
  String get edition;

  /// Description label in book preview
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Other Classification label in book preview
  ///
  /// In en, this message translates to:
  /// **'Other Classification'**
  String get otherClassification;

  /// Law Classification label in book preview
  ///
  /// In en, this message translates to:
  /// **'Law Classification'**
  String get lawClassification;

  /// Bibliographic Details title in book view
  ///
  /// In en, this message translates to:
  /// **'Bibliographic Details'**
  String get bibliographicDetails;

  /// Author label in book preview
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// Copies label in book preview
  ///
  /// In en, this message translates to:
  /// **'Copies'**
  String get copies;

  /// Message shown when no copies are found for a book
  ///
  /// In en, this message translates to:
  /// **'No copies found'**
  String get noCopiesFound;

  /// Classification label in book preview
  ///
  /// In en, this message translates to:
  /// **'Classification'**
  String get classification;

  /// Share button label in book view
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Email button label in book view
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Title for the share via dialog
  ///
  /// In en, this message translates to:
  /// **'Share via...'**
  String get shareVia;

  /// Cancel button label in share via dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Snackbar message shown when an external link could not be launched
  ///
  /// In en, this message translates to:
  /// **'Could not launch external link.'**
  String get couldNotLaunchExternalLink;

  /// Snackbar message shown when WhatsApp is not installed
  ///
  /// In en, this message translates to:
  /// **'WhatsApp is not installed.'**
  String get couldNotLaunchWhatsApp;

  /// Snackbar message shown when no email client is found
  ///
  /// In en, this message translates to:
  /// **'Could not find an email client.'**
  String get couldNotFindEmailClient;

  /// Label for the type of item in book preview
  ///
  /// In en, this message translates to:
  /// **'Item type'**
  String get itemType;

  /// Label for the holding library in book preview
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get holdingLibrary;

  /// Label for the collection in book preview
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get collection;

  /// Label for the copy number in book preview
  ///
  /// In en, this message translates to:
  /// **'Copy number'**
  String get copyNumber;

  /// Label for the region in library details
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// Label for the address in library details
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Label for the postal code in library details
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get postalCode;

  /// Label for the city in library details
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// Label for the state in library details
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// Label for the country in library details
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// Label for the library name in library details
  ///
  /// In en, this message translates to:
  /// **'Library name'**
  String get libraryName;

  /// Label for the area in library details
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// Label for the homepage in library details
  ///
  /// In en, this message translates to:
  /// **'Homepage'**
  String get homepage;

  /// Close button label in library details dialog
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// MARC view title in book view
  ///
  /// In en, this message translates to:
  /// **'MARC View'**
  String get marcView;

  /// Message shown when there is an error loading the MARC data
  ///
  /// In en, this message translates to:
  /// **'Error loading MARC data'**
  String get errorLoadingMarc;

  /// Message shown when no MARC data is available for a book
  ///
  /// In en, this message translates to:
  /// **'No MARC data available'**
  String get noMarcDataAvailable;

  /// Libraries label in book preview
  ///
  /// In en, this message translates to:
  /// **'Libraries'**
  String get libraries;

  /// Message shown when libraries could not be fetched for the directory
  ///
  /// In en, this message translates to:
  /// **'Could not fetch libraries, check your internet connection, or try again later.'**
  String get couldNotFetchLibraries;

  /// Message shown when no libraries are found for the directory
  ///
  /// In en, this message translates to:
  /// **'No libraries found'**
  String get noLibrariesFound;

  /// Title for the finder view
  ///
  /// In en, this message translates to:
  /// **'Finder'**
  String get finderTitle;

  /// Label for the location section in the finder view
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// All item types entry in item type selection dropdown
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allItemTypes;

  /// Label for the room in book preview
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get room;

  /// Label for the level in book preview
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// Message shown when there is an error loading the book details
  ///
  /// In en, this message translates to:
  /// **'Error loading book details'**
  String get errorLoadingBookDetails;

  /// Title for the search section in home view
  ///
  /// In en, this message translates to:
  /// **'Search in UV Library Catalog'**
  String get searchSectionTitle;

  /// Library services section title
  ///
  /// In en, this message translates to:
  /// **'Library Services'**
  String get libraryServices;

  /// Book selections section title
  ///
  /// In en, this message translates to:
  /// **'Selections'**
  String get bookSelections;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Message shown when book selections could not be loaded
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load book selections, check your internet connection, or try again later.'**
  String get couldntLoadBookSelections;

  /// Message shown when home libraries services could not be loaded
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load libraries services, check your internet connection, or try again later.'**
  String get couldntLoadHomeLibrariesServices;

  /// Alt text for book cover images fetched from Open Library
  ///
  /// In en, this message translates to:
  /// **'Book cover from Open Library'**
  String get openLibraryCoverIMGAlt;

  /// Alt text for book cover images fetched from Local Library
  ///
  /// In en, this message translates to:
  /// **'Local book cover image'**
  String get localCoverIMGAlt;

  /// Status label indicating that a book copy is available
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get legendAvailable;

  /// Status label indicating that a book copy is borrowed
  ///
  /// In en, this message translates to:
  /// **'Borrowed'**
  String get legendBorrowed;

  /// Status label indicating that a book copy is located using the finder
  ///
  /// In en, this message translates to:
  /// **'Finder'**
  String get legendFinder;

  /// Status label indicating that a book copy is not for borrowing
  ///
  /// In en, this message translates to:
  /// **'Not for borrow'**
  String get legendNotForBorrow;

  /// Message shown when there is a timeout while loading data
  ///
  /// In en, this message translates to:
  /// **'Timeout while loading data, please check your internet connection and try again.'**
  String get timeoutLoading;

  /// Message shown when there is an error loading the library services
  ///
  /// In en, this message translates to:
  /// **'Error loading library services'**
  String get errorLoadingLibraryServices;

  /// Message shown when there is an error loading the item copies
  ///
  /// In en, this message translates to:
  /// **'Error loading item copies'**
  String get errorLoadingItemCopies;

  /// Title for the legend section in book view
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get legendTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
