# Clean Architecture Code Rules for Copilot Chat


## Layer Responsibilities
- `core/`: Utilities, config, constants, shared widgets. Reusable across all layers.
- `domain/`: Contains only pure Dart code. Entities, use cases, and repository interfaces.
- `data/`: Implementation logic. DTOs, local database, Retrofit services, and repository implementations.
- `modules/`: Presentation/UI. Feature-based folders, each with screens and state providers.


## Naming Conventions
- Abstract classes: `AuthRepository` → File: `auth_repository.dart`
- Implementations: `AuthRepositoryImpl` → File: `auth_repository_impl.dart`
- DTOs: `UserDto`, `WeatherDto` → Must implement `.fromJson()`, `.toEntity()`
- UseCases: `LoginUser`, `FetchWeatherForecast` → File: `login_user.dart`, `fetch_weather_forecast.dart`
- UI (modules/):
- Screens: `login_screen.dart`, `weather_screen.dart`
- State: `auth_provider.dart`, `weather_provider.dart`


## Import Rules
- `domain/` must not import from `data/` or `modules/`
- `data/` can import from `domain/` only
- `modules/` can import from `domain/`, never from `data/`
- `core/` is accessible to all layers


## DTO and Service Guidelines
- Place Retrofit interfaces in `data/services/`
- Generated service implementations must stay in the same folder with `.g.dart`
- Group DTOs under `dto/` with subfolders by feature and `base_dto/` for common types
- DTOs must extend `freezed` where applicable and provide mapping to domain entities via extension methods


## Best Practices
- Interfaces and implementations in separate files
- Entities are shared only between domain and UI
- DTOs never leak into domain or UI
- Favor dependency injection for wiring layers
- One class per file, keep files short and single-responsibility