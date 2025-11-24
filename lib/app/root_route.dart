import 'package:demo_login/app/app_provider.dart';
import 'package:demo_login/app/router.dart';
import 'package:demo_login/core/core.dart';
import 'package:flutter/material.dart';

@RoutePage()
class RootPage extends StatelessWidget implements AutoRouteWrapper {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = locator<AppProvider>();
    return StreamBuilder<bool>(
      stream: provider.isLoggedIn,
      builder: (context, snapshot) {
        return AutoRouter.declarative(
          routes: (_) {
            return [
              if (snapshot.data == true)
                const MainRootRoute()
              else
                const LoginRootRoute(),
            ];
          },
        );
      },
    );
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return this;
    // return Stack(children: [const PermissionSupport(), this]);
  }
}
