import 'dart:io';

import 'package:vm_first_app/core/widgets/localization_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vm_first_app/core/core.dart';

import 'package:vm_first_app/data/data.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class LocaleHandler extends Disposable {
  static const String storageKey = "vf_access_locale";
  final _storage = locator<KeyValueStorage>();
  final currentLocale = BehaviorSubject<String?>.seeded(null);

  Locale? _locale;
  Locale get locale {
    if (_locale != null) {
      return _locale!;
    }

    return Platform.localeName.startsWith("vi")
        ? kVietnamLocale
        : kEnglishLocale;
  }

  Future load() async {
    final initLocale =
        await _storage.getString(storageKey) ?? kVietnamLocale.localeString;
    _locale ??= LocaleX.fromLocaleString(initLocale);
    currentLocale.add(initLocale);
  }

  void changeLocale(BuildContext context, Locale locale) {
    context.setLocale(locale);
    _locale ??= locale;
    _storage.setString(storageKey, locale.localeString);
    currentLocale.add(locale.localeString);
  }

  @override
  void dispose() {
    currentLocale.close();
  }
}

extension LocaleX on Locale {
  String get localeString => toStringWithSeparator(separator: "-");
  static Locale fromLocaleString(String localeString) =>
      localeString.toLocale(separator: "-");

  String get displayName => switch (this) {
    kVietnamLocale => "VIE",
    kEnglishLocale => "ENG",
    _ => "Unknown",
  };
}
