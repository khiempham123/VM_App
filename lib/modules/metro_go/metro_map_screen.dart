import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/core/route/router.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:vm_first_app/domain/domain.dart';
import 'package:vm_first_app/modules/metro_go/metro_map_provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

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

class _MetroMapView extends StatefulWidget {
  const _MetroMapView();

  @override
  State<_MetroMapView> createState() => _MetroMapViewState();
}

class _MetroMapViewState extends State<_MetroMapView> {



  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MetroMapProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body:
      Stack(
        children: [
          _VietmapWidget(onMapCreated: provider.onMapCreated),
          SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  elevation: 10,
                  borderRadius: BorderRadius.circular(24),
                  child: TypeAheadField<PlaceEntity>(
                    controller: provider.searchController,
                    focusNode: FocusNode(),
                    itemBuilder: (BuildContext context, value) {
                      return ListTile(
                        title: Text(value.display),
                      );
                    },
                    onSelected: (value) {
                      provider.searchController.text = value.display;
                      provider.onSuggestionSelected(value);
                    },
                    suggestionsCallback: (String search) {
                      return provider.onSearchChanged(search);
                    },
                    hideOnEmpty: true,
                    loadingBuilder: (BuildContext context) {
                      return const Center(
                          child: CircularProgressIndicator(),
                      );
                    },
                    debounceDuration: const Duration(milliseconds: 1000),
                  ),
                ),
              ),
            ),
          provider.isOnSelectedLocation ? StaticMarkerLayer(
            mapController: provider.vietmapController,
            markers: [
              StaticMarker(
                  width: 50,
                  height: 50,
                  bearing: 0,
                  child: Material(
                    borderRadius: BorderRadius.circular(40),
                    elevation: 10,
                    child: SizedBox(
                        width: 50,
                        height: 50,
                        child:Icon(Icons.location_pin, color: Colors.red, size: 30,)),
                  ),
                  latLng: provider.selectedPlaceLatLng!),
            ],
          ) : const SizedBox.shrink(),
          provider.isOnMyLocation ? UserLocationLayer(
            mapController: provider.vietmapController,
            locationIcon: const Icon(
              Icons.circle,
              color: Colors.blue,
              size: 30,
            ),
            bearingIcon: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white),
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
          // Simple route drawing button (VietmapGL + Polyline)
          Positioned(
            bottom: 50,
            right: 0.0,
            child: FloatingActionButton(
              mini: true,
              tooltip: 'Vẽ route đơn giản',
              onPressed: () {
                provider.onRouteSelected();
              },
              child: const Icon(Icons.assistant_direction, color: AppColors.primary),
            ),
          ),

          // Navigation route button (NavigationView with callbacks)
          Positioned(
            bottom: 100,
            right: 0.0,
            child: FloatingActionButton(
              mini: true,
              tooltip: 'Starting Navigation',
              onPressed: (provider.currentPlaceLatLng != null &&
                         provider.selectedPlaceLatLng != null)
                  ? () => context.pushRoute(MetroGoNavigationRoute(currentLocation: provider.currentPlaceLatLng!, selectedLocation: provider.selectedPlaceLatLng!))
                  : null,
              backgroundColor: (provider.currentPlaceLatLng != null &&
                                provider.selectedPlaceLatLng != null)
                  ? null
                  : Colors.grey,
              child: Icon(
                Icons.near_me_outlined,
                color: (provider.currentPlaceLatLng != null &&
                       provider.selectedPlaceLatLng != null)
                    ? AppColors.primary
                    : Colors.white,
              ),
            ),
          ),

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