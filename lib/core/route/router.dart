import 'package:auto_route/auto_route.dart';
import 'package:vm_first_app/core/route/root_route.dart';
import 'package:vm_first_app/core/route/route_path.dart';
import 'package:vm_first_app/modules/auth/login/login_screen.dart';
import 'package:vm_first_app/modules/auth/register/register_screen.dart';
import 'package:vm_first_app/modules/home/screens/home_screen.dart';
import 'package:vm_first_app/modules/profile/profile_screen.dart';
import 'package:vm_first_app/modules/metro_go/metro_map_screen.dart';
import 'package:vm_first_app/modules/metro_go_navigation/metro_go_navigation_screen.dart';
import 'package:vm_first_app/modules/my_trip_route/my_trip_route_screen.dart';
import 'package:vm_first_app/modules/auth/change_password/change_password_screen.dart';
import 'package:vm_first_app/modules/main/main_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';
import 'package:vm_first_app/domain/domain.dart';
export 'package:auto_route/auto_route.dart';


part 'router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class RootRouter extends RootStackRouter {
  RootRouter() : super();

  @override
  RouteType get defaultRouteType => const RouteType.cupertino();

  RouterConfig<UrlState> appConfig() {
    return config(
      navigatorObservers: () => <NavigatorObserver>[AutoRouteObserver()],
    );
  }

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      initial: true,
      path: RoutePath.kRoot,
      page: RootRoute.page,
      children: [mainRoute, loginRoute],
    ),
    RedirectRoute(path: '*', redirectTo: RoutePath.kRoot),
  ];
}

final mainRoute = AutoRoute(
  // transitionsBuilder: TransitionsBuilders.slideTop,
  path: RoutePath.kMain,
  page: MainRootRoute.page,
  children: [
    AutoRoute(
      // guards: [AuthGuard],
      page: MainRoute.page,
      path: '',
      children: [
        AutoRoute(page: HomeRoute.page),
        AutoRoute(page: ProfileRoute.page),
        AutoRoute(page: MetroMapRoute.page),
      ],
    ),
    AutoRoute(page: ChangePasswordRoute.page),
    AutoRoute(page: MetroGoNavigationRoute.page),
    AutoRoute(page: MyTripRouteRoute.page),
    // AutoRoute(page: ExportCarRoute.page),
    RedirectRoute(path: '*', redirectTo: ''),
  ],
);

@RoutePage(name: 'MainRootRoute')
class MainRootScreen extends AutoRouter {
  const MainRootScreen({super.key});
}

final loginRoute = AutoRoute(
  // transitionsBuilder: TransitionsBuilders.slideTop,
  path: RoutePath.kLogin,
  page: LoginRootRoute.page,
  children: [
    AutoRoute(
      page: LoginRoute.page,
      path: '',
      initial: true,
    ),
    AutoRoute(page: RegisterRoute.page),
    RedirectRoute(path: '*', redirectTo: ''),
  ],
);

@RoutePage(name: 'LoginRootRoute')
class LoginRootScreen extends AutoRouter {
  const LoginRootScreen({super.key});
}

@RoutePage(name: 'StartupRoute')
class StartupScreen extends AutoRouter {
  const StartupScreen({super.key});
}



extension RoutingControllerUtils on RoutingController {
  T? findRouter<T extends RoutingController>({String? routeName}) {
    final router = this;
    if (router is T &&
        (routeName == null || router.routeData.name == routeName)) {
      return router;
    }

    for (var child in router.childControllers) {
      final result = child.findRouter<T>(routeName: routeName);
      if (result != null) {
        return result;
      }
    }

    return null;
  }
}
