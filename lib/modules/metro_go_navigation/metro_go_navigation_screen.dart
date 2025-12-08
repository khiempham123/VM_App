import 'package:provider/provider.dart';
import 'package:vm_first_app/core/route/router.dart';
import 'package:vm_first_app/domain/domain.dart';
import 'package:vm_first_app/modules/metro_go_navigation/metro_go_navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';
import 'package:vm_first_app/core/core.dart';


final Map<String, IconData> someMap = {
  "": Icons.straight_outlined,
  "TIẾP TỤC": Icons.straight_outlined,
  "RẼ TRÁI": Icons.turn_left_outlined,
  "RẼ PHẢI": Icons.turn_right_outlined,
  "ĐẾN ĐÍCH": Icons.stop_circle_outlined
};
@RoutePage()
class MetroGoNavigationScreen extends StatelessWidget {
  final LatLng currentLocation;
  final List<LatLng> listLocations;
  final RouteEntity route;
  const MetroGoNavigationScreen({
    super.key,
    required this.currentLocation,
    required this.listLocations,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MetroGoNavigationProvider(
        currentLocation: currentLocation,
        listLocations: listLocations,
        route: route,
      ),
      child: const _MetroGoNavigationView(),
    );
  }
}

class _MetroGoNavigationView extends StatelessWidget {
  const _MetroGoNavigationView();


  /// Show route preview bottom sheet after route is built
  void _showRoutePreviewBottomSheet(
    BuildContext context,
    MetroGoNavigationProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.white12,
      builder: (bottomSheetContext) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: Consumer<MetroGoNavigationProvider>(
            builder: (consumerContext, providerValue, child) {
              return DraggableScrollableSheet(
                initialChildSize: 0.2,
                minChildSize: 0.2,
                maxChildSize: 0.9,
                builder: (sheetContext, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)
                      ],
                    ),
                    child: Column(
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        // Waypoints info header
                        if (providerValue.totalWaypoints > 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.route, color: Colors.blue, size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Hành trình: ${providerValue.totalWaypoints} điểm đến',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Action buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                    ),
                                  ),
                                  onPressed: () {
                                    // Use providerValue from Consumer to ensure state access
                                    providerValue.startNavigation();
                                    // Close bottom sheet after starting navigation
                                    Navigator.of(bottomSheetContext).pop();
                                  },
                                  icon: const Icon(Icons.navigation, color: Colors.white),
                                  label: const Text(
                                    'Go now',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                    ),
                                  ),
                                  onPressed: () {
                                    // Use providerValue from Consumer to ensure state access
                                    providerValue.clearRoute();
                                    // Close bottom sheet
                                    Navigator.of(bottomSheetContext).pop();
                                    context.router.pop();
                                  },
                                  icon: const Icon(Icons.clear, color: Colors.white),
                                  label: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),

                        // Route instructions list with fade effect
                        Expanded(
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.white,
                                  Colors.white,
                                ],
                                stops: [0.0, 0.05, 1.0],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.dstIn,
                            child: ListView.builder(
                              controller: scrollController,
                              itemCount: providerValue.route.paths[0].instructions.length,
                              itemBuilder: (context, index) {
                                final instructionText = providerValue.route.paths[0].instructions[index].text;
                                final words = instructionText.split(' ');
                                final mapKey = words.length >= 2
                                    ? '${words[0]} ${words[1]}'.toUpperCase()
                                    : words.isNotEmpty ? words[0].toUpperCase() : '';
                                debugPrint(mapKey);
                                return ListTile(
                                  leading: Icon(someMap[mapKey] ?? Icons.straight_outlined),
                                  title: Text(instructionText),
                                  subtitle: const Text("100m"),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetroGoNavigationProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // NavigationView
          NavigationView(
            mapOptions: provider.navigationOption,

            onMapCreated: (controller) {
              provider.onNavigationControllerCreated(controller);
            },

            onMapRendered: () {
              provider.onMapRendered();
            },

            onRouteBuilt: (route) {
              provider.onRouteBuilt(route);
              debugPrint('${provider.isNavigating}');
              // Show bottom sheet after route is built using the correct context
              if (provider.isRouteBuilt && !provider.isNavigating) {
                // Use addPostFrameCallback to ensure the widget tree is stable
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showRoutePreviewBottomSheet(context, provider);
                });
              }
              debugPrint('Im here: ${provider.routeProgressEvent}');

            },

              onRouteBuildFailed: (error) {
                provider.onRouteBuildFailed(error);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Không thể tìm tuyến đường')),
                );
              },

              onMapMove: () => provider.showRecenterButton(),

              onRouteProgressChange: (RouteProgressEvent event) {
                provider.onRouteProgressChange(event);
                provider.setInstructionImage(event.currentModifier, event.currentModifierType);
              },

              onArrival: () {
                provider.onArrival();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Container(
                      height: 100,
                      color: Colors.green,
                      child: const Center(
                        child: Text(
                          'Bạn đã tới đích',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },

              onNewRouteSelected: (route) {
                debugPrint('New route selected: ${route.toString()}');
              },
            ),

            // Banner Instruction View
            Positioned(
              top: MediaQuery.of(context).viewPadding.top,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  BannerInstructionView(
                    routeProgressEvent: provider.routeProgressEvent,
                    instructionIcon: provider.instructionImage,
                  ),
                  // Waypoint progress indicator (only show when navigating with multiple waypoints)
                  if (provider.isNavigating && provider.totalWaypoints > 1)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            provider.isAtFinalDestination ? Icons.flag : Icons.pin_drop,
                            color: provider.isAtFinalDestination ? Colors.green : Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            provider.isAtFinalDestination
                                ? 'Điểm đến cuối cùng'
                                : 'Điểm ${provider.currentWaypointIndex + 1}/${provider.totalWaypoints}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (provider.hasMoreWaypoints) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Còn ${provider.remainingWaypoints} điểm',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Action View
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomActionView(
                recenterButton: provider.recenterButton,
                controller: provider.navigationController,
                onOverviewCallback: provider.showRecenterButton,
                onStopNavigationCallback: () {
                  provider.onStopNavigation();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showRoutePreviewBottomSheet(context, provider);
                  });
                },
                routeProgressEvent: provider.routeProgressEvent,
              ),
            ),


        // Loading overlay
            if (provider.isInitializingNavigation)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Đang khởi tạo điều hướng...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

          ],
        ),
    );
  }
}

