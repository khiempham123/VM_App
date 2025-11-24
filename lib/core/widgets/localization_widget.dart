import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

const kVietnamLocale = Locale("vi", "VN");
const kEnglishLocale = Locale("en", "US");
const kSupportLocales = [kVietnamLocale, kEnglishLocale];

class LocalizationWidget extends StatelessWidget {
  final Widget child;
  const LocalizationWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: kSupportLocales,
      fallbackLocale: kVietnamLocale,
      startLocale: kVietnamLocale,
      useFallbackTranslations: true,
      path: 'resources/langs',
      useOnlyLangCode: true,
      saveLocale: true,
      child: child,
    );
  }
}
