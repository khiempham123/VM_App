// import 'package:flutter/material.dart';
// import 'package:vm_first_app/modules/main/screens/main_screen.dart';
// import 'package:vm_first_app/modules/auth/screens/login.screen.dart';
// class AppRouter {
//   // Private constructor to prevent instantiation
//   AppRouter._();
//
//   // Route names
//   static const String main = '/';
//   static const String login = '/login';
//
//   // Route generator
//   static Route<dynamic> generateRoute(RouteSettings settings) {
//     switch (settings.name) {
//       case main:
//         return MaterialPageRoute(
//           builder: (_) => const MainScreen(),
//         );
//       // Add more routes here
//       default:
//         return MaterialPageRoute(
//           builder: (_) => Scaffold(
//             body: Center(
//               child: Text('No route defined for ${settings.name}'),
//             ),
//           ),
//         );
//     }
//   }
//
//   // Navigation helpers
//   static void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
//     Navigator.pushNamed(context, routeName, arguments: arguments);
//   }
//
//   static void navigateToAndRemoveUntil(BuildContext context, String routeName) {
//     Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
//   }
//
//   static void goBack(BuildContext context) {
//     Navigator.pop(context);
//   }
// }
//
