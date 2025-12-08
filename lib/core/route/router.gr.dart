// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'router.dart';

/// generated route for
/// [ChangePasswordScreen]
class ChangePasswordRoute extends PageRouteInfo<void> {
  const ChangePasswordRoute({List<PageRouteInfo>? children})
    : super(ChangePasswordRoute.name, initialChildren: children);

  static const String name = 'ChangePasswordRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ChangePasswordScreen();
    },
  );
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomeScreen();
    },
  );
}

/// generated route for
/// [LoginRootScreen]
class LoginRootRoute extends PageRouteInfo<void> {
  const LoginRootRoute({List<PageRouteInfo>? children})
    : super(LoginRootRoute.name, initialChildren: children);

  static const String name = 'LoginRootRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginRootScreen();
    },
  );
}

/// generated route for
/// [LoginScreen]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginScreen();
    },
  );
}

/// generated route for
/// [MainRootScreen]
class MainRootRoute extends PageRouteInfo<void> {
  const MainRootRoute({List<PageRouteInfo>? children})
    : super(MainRootRoute.name, initialChildren: children);

  static const String name = 'MainRootRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MainRootScreen();
    },
  );
}

/// generated route for
/// [MainScreen]
class MainRoute extends PageRouteInfo<void> {
  const MainRoute({List<PageRouteInfo>? children})
    : super(MainRoute.name, initialChildren: children);

  static const String name = 'MainRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MainScreen();
    },
  );
}

/// generated route for
/// [MetroGoNavigationScreen]
class MetroGoNavigationRoute extends PageRouteInfo<MetroGoNavigationRouteArgs> {
  MetroGoNavigationRoute({
    Key? key,
    required LatLng currentLocation,
    required List<LatLng> listLocations,
    required RouteEntity route,
    List<PageRouteInfo>? children,
  }) : super(
         MetroGoNavigationRoute.name,
         args: MetroGoNavigationRouteArgs(
           key: key,
           currentLocation: currentLocation,
           listLocations: listLocations,
           route: route,
         ),
         initialChildren: children,
       );

  static const String name = 'MetroGoNavigationRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MetroGoNavigationRouteArgs>();
      return MetroGoNavigationScreen(
        key: args.key,
        currentLocation: args.currentLocation,
        listLocations: args.listLocations,
        route: args.route,
      );
    },
  );
}

class MetroGoNavigationRouteArgs {
  const MetroGoNavigationRouteArgs({
    this.key,
    required this.currentLocation,
    required this.listLocations,
    required this.route,
  });

  final Key? key;

  final LatLng currentLocation;

  final List<LatLng> listLocations;

  final RouteEntity route;

  @override
  String toString() {
    return 'MetroGoNavigationRouteArgs{key: $key, currentLocation: $currentLocation, listLocations: $listLocations, route: $route}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MetroGoNavigationRouteArgs) return false;
    return key == other.key &&
        currentLocation == other.currentLocation &&
        const ListEquality<LatLng>().equals(
          listLocations,
          other.listLocations,
        ) &&
        route == other.route;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      currentLocation.hashCode ^
      const ListEquality<LatLng>().hash(listLocations) ^
      route.hashCode;
}

/// generated route for
/// [MetroMapScreen]
class MetroMapRoute extends PageRouteInfo<void> {
  const MetroMapRoute({List<PageRouteInfo>? children})
    : super(MetroMapRoute.name, initialChildren: children);

  static const String name = 'MetroMapRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MetroMapScreen();
    },
  );
}

/// generated route for
/// [MyTripRouteScreen]
class MyTripRouteRoute extends PageRouteInfo<void> {
  const MyTripRouteRoute({List<PageRouteInfo>? children})
    : super(MyTripRouteRoute.name, initialChildren: children);

  static const String name = 'MyTripRouteRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MyTripRouteScreen();
    },
  );
}

/// generated route for
/// [ProfileScreen]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfileScreen();
    },
  );
}

/// generated route for
/// [RegisterScreen]
class RegisterRoute extends PageRouteInfo<void> {
  const RegisterRoute({List<PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RegisterScreen();
    },
  );
}

/// generated route for
/// [RootPage]
class RootRoute extends PageRouteInfo<void> {
  const RootRoute({List<PageRouteInfo>? children})
    : super(RootRoute.name, initialChildren: children);

  static const String name = 'RootRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return WrappedRoute(child: const RootPage());
    },
  );
}

/// generated route for
/// [StartupScreen]
class StartupRoute extends PageRouteInfo<void> {
  const StartupRoute({List<PageRouteInfo>? children})
    : super(StartupRoute.name, initialChildren: children);

  static const String name = 'StartupRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const StartupScreen();
    },
  );
}
