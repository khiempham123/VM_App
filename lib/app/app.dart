import 'package:vm_first_app/app/router.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:vm_first_app/core/widgets/auto_hide_keyboard.dart';
import 'package:vm_first_app/app/app_provider.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: locator<AppProvider>(),
      child: AutoHideKeyboard(
        child: MaterialApp.router(
          title: 'VM First App',
          debugShowCheckedModeBanner: false,
          routerConfig: locator<RootRouter>().appConfig(),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.lightTheme(),
          builder: (context, child) {
            return child ?? const SizedBox();
          },
        ),
      ),
    );
  }
}
