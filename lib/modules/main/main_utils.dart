import 'package:vm_first_app/core/route/router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum MainBottomTab { kHome, kMetroGo, kAccount }

extension ListMainBottomTabExt on List<MainBottomTab> {
  List<PageRouteInfo<dynamic>> allRoutes() {
    return map((e) {
      switch (e) {
        case MainBottomTab.kHome:
          return const HomeRoute();
        case MainBottomTab.kMetroGo:
          return const MetroMapRoute();
        case MainBottomTab.kAccount:
          return const ProfileRoute();
      }
    }).cast<PageRouteInfo<dynamic>>().toList();
  }

  List<BottomNavigationBarItem> allItems() {
    return map((e) {
      switch (e) {
        case MainBottomTab.kHome:
          return BottomNavigationBarItem(
            icon: const Icon(Icons.home, size: 25),
            activeIcon: const Icon(Icons.home_filled, size: 25),
            label: "home_tab".tr(),
          );
        case MainBottomTab.kMetroGo:
          return BottomNavigationBarItem(
            icon: const Icon(Icons.train, size: 25),
            activeIcon: const Icon(Icons.train, size: 25),
            label: "metro_tab".tr(),
          );
        case MainBottomTab.kAccount:
          return BottomNavigationBarItem(
            icon: const Icon(Icons.people, size: 25),
            activeIcon: const Icon(Icons.people_alt_rounded, size: 25),
            label: "profile_tab".tr(),
          );
      }
    }).toList();
  }
}
