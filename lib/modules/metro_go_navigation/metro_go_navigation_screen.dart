import 'package:provider/provider.dart';
import 'package:vm_first_app/core/route/router.dart';
import 'package:vm_first_app/modules/metro_go_navigation/metro_go_navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';
import 'package:vm_first_app/core/core.dart';

@RoutePage()
class MetroGoNavigationScreen extends StatelessWidget {
  final LatLng currentLocation;
  final LatLng selectedLocation;

  const MetroGoNavigationScreen({
    super.key,
    required this.currentLocation,
    required this.selectedLocation,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MetroGoNavigationProvider(
        currentLocation: currentLocation,
        selectedLocation: selectedLocation,
      ),
      child: const _MetroGoNavigationView(),
    );
  }
}

class _MetroGoNavigationView extends StatelessWidget {
  const _MetroGoNavigationView();

  BuildContext? get context => null;


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetroGoNavigationProvider>();

    return Scaffold(
      body:  Stack(
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
                // Show bottom sheet after route is built
                if(provider.isRouteBuilt) {
                  showModalBottomSheet(
                  context: this.context ?? context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  barrierColor: Colors.white12,
                  builder: (context) {
                    return DraggableScrollableSheet(
                      initialChildSize: 0.2,
                      minChildSize: 0.2,
                      maxChildSize: 0.9,
                      builder: (context, scrollController) {
                        return Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Bo góc trên
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)
                            ],
                          ),
                          child: Column(
                            children: [
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

                              // 2. Tiêu đề (Cố định, không bị mờ)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18.0),
                                        ),
                                      ),
                                      onPressed: () {
                                        provider.startNavigation();
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
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18.0),
                                        ),
                                      ),
                                      onPressed: () {
                                        provider.clearRoute();
                                        context.pop();
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
                                  ],
                                ),
                              ),
                              const Divider(),

                              // 3. Nội dung cuộn với hiệu ứng FADE OUT bên trên
                              Expanded(
                                child: ShaderMask(
                                  // Tạo Gradient từ trong suốt -> màu đục
                                  shaderCallback: (Rect bounds) {
                                    return const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent, // Màu trên cùng (trong suốt)
                                        Colors.white,       // Bắt đầu hiện rõ
                                        Colors.white,       // Hiện rõ
                                      ],
                                      // Các điểm dừng: 0% -> 5% là mờ dần, sau 5% là rõ
                                      stops: [0.0, 0.05, 1.0],
                                    ).createShader(bounds);
                                  },
                                  blendMode: BlendMode.dstIn, // Chế độ hòa trộn quan trọng
                                  child: ListView.builder(
                                    controller: scrollController, // Kết nối scroll với DraggableSheet
                                    itemCount: 20,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        leading: const Icon(Icons.turn_right),
                                        title: Text("Turn right onto Street $index"),
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
                );
                }

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
              child: BannerInstructionView(
                routeProgressEvent: provider.routeProgressEvent,
                instructionIcon: provider.instructionImage,
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
                onStopNavigationCallback: provider.onStopNavigation,
                routeProgressEvent: provider.routeProgressEvent,
              ),
            ),

            // Buttons are now shown in bottom sheet

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

