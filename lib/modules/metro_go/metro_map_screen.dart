//import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/core/route/router.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';


//Idea: Try using Vietmap Api to get map and finding place near the metro terminal
//Example: When you go from ThuDuc to BenThanh terminal you can go Ben Thanh Market,...
//Step 1: Get the list of metro terminal
//Step 2: Get the list of place near the metro start terminal
//Step 3: Get the list of place near the end metro
//Step 4: Compare the list of place near the start terminal and the list of place near the end metro
//Step 5: Get the list of place that is in both list
//Step 6: Show the list of place to suggets user if user open the app with location permission
@RoutePage()
class MetroMapScreen extends StatelessWidget {
  const MetroMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metro Go'),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Go with Metro'),
      )
    );
  }
}