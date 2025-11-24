import 'package:demo_login/app/app_provider.dart';
import 'package:demo_login/app/router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import 'package:demo_login/core/core.dart';

import 'package:demo_login/data/data.dart';

final locator = GetIt.instance;

class AppDependencies {
  static Future<AppDependencies> init(
    SharedPreferencesKeyValueStorage storage,
    NativeBridgeImpl nativeBridge,
  ) async {
    final instance = AppDependencies();
    locator.registerSingleton(instance);
    //MISC--------
    locator.registerSingleton(RootRouter());
    if (!locator.isRegistered<NativeBridge>()) {
      locator.registerLazySingleton<NativeBridge>(() => nativeBridge);
    }
    locator.registerLazySingleton(() => const FlutterSecureStorage());
    locator.registerLazySingleton<KeyValueStorage>(() => storage);
    locator.registerLazySingleton(() => LocaleHandler());
    locator.registerLazySingleton(() => AppProvider(locator()));

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

    return instance;
  }
}
