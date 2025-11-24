import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/app/router.dart';
import 'package:vm_first_app/core/core.dart';
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

        // Show loading while waiting for initial auth state
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isLoggedIn = snapshot.data == true;

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
    //return Stack(children: [const PermissionSupport(), this]);
  }
}
