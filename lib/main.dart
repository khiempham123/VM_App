import 'package:vm_first_app/app/app.dart';
import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/core/widgets/localization_widget.dart';
import 'package:vm_first_app/data/data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


import 'package:vm_first_app/core/core.dart';

void main() async {
  //init
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  final kvStorage = SharedPreferencesKeyValueStorage.newInstance();

  await AppDependencies.init(kvStorage);

  // Restore auth session if exists
  await locator<AppProvider>().restore();

  await dotenv.load(
    fileName: "assets/.env",
  );
  runApp(const LocalizationWidget(child: MyApp()));
}

