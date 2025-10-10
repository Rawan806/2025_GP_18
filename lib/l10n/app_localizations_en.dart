// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tagline => 'Where deposits are kept and trusts are returned.';

  @override
  String get signIn => 'Sign in';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get noAccount => 'Don\'t have an account? Sign up';

  @override
  String get reportLost => 'Report a lost item';

  @override
  String get trackReport => 'Track a report';

  @override
  String get lostFormTitle => 'Report Form';

  @override
  String get dateTime => 'Date & time of loss *';

  @override
  String get itemName => 'Lost item name *';

  @override
  String get attachPhotos => 'Attach photos';

  @override
  String get tipText => 'Tip: To help find your item, attach an old photo if available, or search for a similar image online and attach it.';

  @override
  String get extraDesc => 'Additional description (optional)';

  @override
  String get submit => 'Submit';

  @override
  String get account => 'Account';

  @override
  String get contactUs => 'Contact us';

  @override
  String get logout => 'Log out';
}
