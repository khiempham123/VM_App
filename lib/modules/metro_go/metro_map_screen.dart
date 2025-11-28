import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/core/route/router.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:vm_first_app/modules/metro_go/metro_map_provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

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
    return ChangeNotifierProvider(
      create: (context) => MetroMapProvider(locator<AppProvider>()),
      child: const _MetroMapView(),
    );
  }
}

class _MetroMapView extends StatelessWidget {
  const _MetroMapView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetroMapProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(
          backgroundColor: AppColors.background,
        ),
      ),
      body:
      Stack(
        children: [
          TypeAheadField(

          ),
          _VietmapWidget(onMapCreated: provider.onMapCreated),
          provider.isOnMyLocation ? UserLocationLayer(
            mapController: provider.vietmapController,
            locationIcon: const Icon(
              Icons.circle,
              color: Colors.blue,
              size: 50,
            ),
            bearingIcon: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white),
              child: const Icon(
                Icons.arrow_upward,
                color: Colors.red,
                size: 15,
              ),
            ),
            ignorePointer: true,
          ) : const SizedBox.shrink(),
        ],
      ),
      floatingActionButton: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              mini: true,
              onPressed: provider.moveToMyLocation ,
              child: const Icon(Icons.location_pin, color: AppColors.primary,),
            ),
          ),
          Positioned(
            bottom: 50,
            right: 0.0,
            child: FloatingActionButton(
            mini: true,
            onPressed: () {},
            child: const Icon(Icons.assistant_direction, color: AppColors.primary,),
          ),)

        ],
      ),
    );
  }
}

class _VietmapWidget extends StatefulWidget {
  final Function(VietmapController) onMapCreated;

  const _VietmapWidget({
    required this.onMapCreated,
  });

  @override
  State<_VietmapWidget> createState() => _VietmapWidgetState();
}

class _VietmapWidgetState extends State<_VietmapWidget> {
  @override
  Widget build(BuildContext context) {
    return VietmapGL(
      // Các config cơ bản
      styleString:
      'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=${dotenv.env['VM_API_KEY']}',
      initialCameraPosition: const CameraPosition(
        target: LatLng(10.762317, 106.654551),
        zoom: 14.0,
      ),

      onMapCreated: widget.onMapCreated,

      trackCameraPosition: true,
      myLocationEnabled: true,
      myLocationTrackingMode: MyLocationTrackingMode.trackingCompass,
      myLocationRenderMode: MyLocationRenderMode.compass,
      compassEnabled: true,
      rotateGesturesEnabled: true,
    );
  }
}