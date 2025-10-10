// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get tagline => 'حيث تُصان الودائع وتُرد الأمانات.';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get login => 'دخول';

  @override
  String get noAccount => 'ليس لديك حساب؟ سجل الآن';

  @override
  String get reportLost => 'الإبلاغ عن مفقود';

  @override
  String get trackReport => 'متابعة بلاغ';

  @override
  String get lostFormTitle => 'نموذج الإبلاغ';

  @override
  String get dateTime => 'تاريخ ووقت الفقدان *';

  @override
  String get itemName => 'اسم الغرض المفقود *';

  @override
  String get attachPhotos => 'إرفاق صور للغرض';

  @override
  String get tipText => 'ملاحظة: للمساعدة في العثور على الغرض المفقود، يُفضّل إرفاق صورة قديمة إن وُجدت، أو البحث عن صورة مشابهة من الإنترنت وإرفاقها.';

  @override
  String get extraDesc => 'وصف إضافي (اختياري)';

  @override
  String get submit => 'إرسال البلاغ';

  @override
  String get account => 'الحساب';

  @override
  String get contactUs => 'تواصل معنا';

  @override
  String get logout => 'تسجيل خروج';
}
