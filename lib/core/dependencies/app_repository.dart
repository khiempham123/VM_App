import 'package:demo_login/core/core.dart';
import 'package:demo_login/data/data.dart';
import 'package:demo_login/domain/domain.dart';

void registerServices() {
  // locator.registerLazySingleton(
  //   instanceName: "weather_service_base",
  //       () => WeatherService.base(locator()),
  // );
}

void registerRepositories() {
  //init in locator
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(locator(), locator()),
  );
}
