import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/app/router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
//import 'package:flutter/foundation.dart';

import 'package:vm_first_app/core/core.dart';

import 'package:vm_first_app/data/data.dart';

final locator = GetIt.instance;

class AppDependencies {
  static Future<AppDependencies> init(
    SharedPreferencesKeyValueStorage storage,
  ) async {

    final instance = AppDependencies();
    locator.registerSingleton(instance);

    //MISC--------
    locator.registerSingleton(RootRouter());

    locator.registerLazySingleton(() => const FlutterSecureStorage());

    locator.registerLazySingleton<KeyValueStorage>(() => storage);

    locator.registerLazySingleton(() => LocaleHandler());

    locator.registerLazySingleton(
      () => HttpClient(
        dio: HttpClient.createDio(
          localeStr: locator<LocaleHandler>().locale.languageCode,
        ),
        onForceLogout: () {
          // locator<AuthHandler>().logout();
        },
        storage: locator(),
        interceptors: [
          // DioFirebasePerformanceInterceptor()
        ],
      ),
    );

    locator.registerLazySingleton(
      () => AuthRequestInterceptor(httpClient: locator(), storage: locator()),
    );

    //API---------
    registerServices();

    registerRepositories();

    // Register AppProvider after all dependencies are set up
    locator.registerLazySingleton(() => AppProvider(locator()));

    return instance;
  }
}
