//import 'package:flutter/foundation.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:vm_first_app/data/data.dart';
import 'package:vm_first_app/domain/domain.dart';

void registerServices() {
  locator.registerLazySingleton(
    () => AuthService(locator<HttpClient>().dio),
  );
}

void registerRepositories() {
  //init in locator
  try {
    locator.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(locator(), locator()),
    );
  } catch (e) {
    rethrow;
  }
}

void metroMapServices()
{
  locator.registerLazySingleton<MetroMapService>(
    () => MetroMapService(locator<MapClient>().dio),
  );

  locator.registerLazySingleton<RouteService>(
    () => RouteService(locator<MapClient>().dio),
  );
}

void metroMapRepositories() {
  locator.registerLazySingleton<MetroMapRepository>(
    () => MetroMapRepositoryImpl(locator(), locator(), locator<MapClient>().dio),
  );

  locator.registerLazySingleton<RouteRepository>(
    () => RouteRepositoryImpl(locator()),
  );
}