import 'package:auto_route/auto_route.dart';
import 'package:demo_login/modules/main/bottom_navigation_bar.dart';
import 'package:demo_login/modules/main/main_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [Provider.value(value: this)],
      child: AutoTabsRouter(
        routes: MainBottomTab.values.allRoutes(),
        lazyLoad: true,
        homeIndex: 1,
        duration: Duration.zero,
        transitionBuilder: (context, child, anim) => child,
        builder: (context, child) {
          final tabsRouter = AutoTabsRouter.of(context);
          return Scaffold(
            body: child,
            bottomNavigationBar: buildBottomNavigationBar(tabsRouter),
          );
        },
      ),
    );
  }

  Widget buildBottomNavigationBar(TabsRouter tabsRouter) {
    return VBottomNavigationBar(
      onTap: (index) {
        tabsRouter.setActiveIndex(index);
      },
      items: MainBottomTab.values.toList().allItems(),
      currentIndex: tabsRouter.activeIndex,
    );
  }
}
