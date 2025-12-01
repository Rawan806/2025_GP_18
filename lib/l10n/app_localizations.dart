import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Where deposits are kept and trusts are returned.'**
  String get tagline;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccount;

  /// No description provided for @reportLost.
  ///
  /// In en, this message translates to:
  /// **'Report a lost item'**
  String get reportLost;

  /// No description provided for @trackReport.
  ///
  /// In en, this message translates to:
  /// **'Track a report'**
  String get trackReport;

  /// No description provided for @lostFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Form'**
  String get lostFormTitle;

  /// No description provided for @dateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & time of loss *'**
  String get dateTime;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Lost item name *'**
  String get itemName;

  /// No description provided for @attachPhotos.
  ///
  /// In en, this message translates to:
  /// **'Attach photos'**
  String get attachPhotos;

  /// No description provided for @tipText.
  ///
  /// In en, this message translates to:
  /// **'Tip: To help find your item, attach an old photo if available, or search for a similar image online and attach it.'**
  String get tipText;

  /// No description provided for @extraDesc.
  ///
  /// In en, this message translates to:
  /// **'Additional description (optional)'**
  String get extraDesc;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @staffLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff Login'**
  String get staffLoginTitle;

  /// No description provided for @staffId.
  ///
  /// In en, this message translates to:
  /// **'Staff ID'**
  String get staffId;

  /// No description provided for @enterStaffId.
  ///
  /// In en, this message translates to:
  /// **'Please enter staff ID'**
  String get enterStaffId;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get enterPassword;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @staffHome.
  ///
  /// In en, this message translates to:
  /// **'Staff Home'**
  String get staffHome;

  /// No description provided for @matchReport.
  ///
  /// In en, this message translates to:
  /// **'Match Report'**
  String get matchReport;

  /// No description provided for @searchReports.
  ///
  /// In en, this message translates to:
  /// **'Search Reports'**
  String get searchReports;

  /// No description provided for @latestReports.
  ///
  /// In en, this message translates to:
  /// **'Latest Reports'**
  String get latestReports;

  /// No description provided for @reportNumber.
  ///
  /// In en, this message translates to:
  /// **'Report Number'**
  String get reportNumber;

  /// No description provided for @lostItem.
  ///
  /// In en, this message translates to:
  /// **'Lost Item'**
  String get lostItem;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @registerFoundItem.
  ///
  /// In en, this message translates to:
  /// **'Register Found Item'**
  String get registerFoundItem;

  /// No description provided for @rerunAI.
  ///
  /// In en, this message translates to:
  /// **'Re-run AI'**
  String get rerunAI;

  /// No description provided for @noImageSelected.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get noImageSelected;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @suggestedTypes.
  ///
  /// In en, this message translates to:
  /// **'Suggested types:'**
  String get suggestedTypes;

  /// No description provided for @suggestedColor.
  ///
  /// In en, this message translates to:
  /// **'Suggested color:'**
  String get suggestedColor;

  /// No description provided for @itemType.
  ///
  /// In en, this message translates to:
  /// **'Item type (e.g., wallet, phone)'**
  String get itemType;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description / distinctive marks'**
  String get description;

  /// No description provided for @foundLocation.
  ///
  /// In en, this message translates to:
  /// **'Found location (area/desk)'**
  String get foundLocation;

  /// No description provided for @storageLocation.
  ///
  /// In en, this message translates to:
  /// **'Storage location (office shelf/bin)'**
  String get storageLocation;

  /// No description provided for @foundTime.
  ///
  /// In en, this message translates to:
  /// **'Found time'**
  String get foundTime;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @pleaseAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Please add a photo'**
  String get pleaseAddPhoto;

  /// No description provided for @typeColorLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Type/Color/Location are required'**
  String get typeColorLocationRequired;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get savedSuccessfully;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// No description provided for @reportDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Details'**
  String get reportDetailsTitle;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @reportLocation.
  ///
  /// In en, this message translates to:
  /// **'Report Location'**
  String get reportLocation;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated At'**
  String get updatedAt;

  /// No description provided for @reportStatus.
  ///
  /// In en, this message translates to:
  /// **'Report Status'**
  String get reportStatus;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// No description provided for @matched.
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get matched;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @requestAdditionalEvidence.
  ///
  /// In en, this message translates to:
  /// **'Request Additional Evidence'**
  String get requestAdditionalEvidence;

  /// No description provided for @staffNotesInternal.
  ///
  /// In en, this message translates to:
  /// **'Staff Notes (Internal)'**
  String get staffNotesInternal;

  /// No description provided for @writeNotesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write any internal notes about the report...'**
  String get writeNotesPlaceholder;

  /// No description provided for @saveNotes.
  ///
  /// In en, this message translates to:
  /// **'Save Notes'**
  String get saveNotes;

  /// No description provided for @confirmDeliveryWithPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delivery with PIN'**
  String get confirmDeliveryWithPin;

  /// No description provided for @searchByNameOrNumber.
  ///
  /// In en, this message translates to:
  /// **'Search by name or report number'**
  String get searchByNameOrNumber;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @preliminaryMatch.
  ///
  /// In en, this message translates to:
  /// **'Preliminary Match'**
  String get preliminaryMatch;

  /// No description provided for @noMatchingResults.
  ///
  /// In en, this message translates to:
  /// **'No matching results.'**
  String get noMatchingResults;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
