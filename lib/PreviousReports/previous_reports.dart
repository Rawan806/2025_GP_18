import 'package:flutter/material.dart';
import '../l10n/app_localizations_helper.dart';

class PreviousReportsPage extends StatelessWidget {
  const PreviousReportsPage({super.key});

 final Color mainGreen = const Color(0xFF243E36);
 final Color beigeColor = const Color(0xFFC3BFB0);

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    final isArabic = currentLocale.languageCode == 'ar';
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: beigeColor,
        appBar: AppBar(
          backgroundColor: mainGreen, 
          elevation: 0,
          centerTitle: true,
          title: Text(
            AppLocalizations.translate('previousReports', currentLocale.languageCode),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        body: Center(
          child: Text(
            AppLocalizations.translate('noPreviousReports', currentLocale.languageCode),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black38,
            ),
          ),
        ),
      ),
    );
  }
}
