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
