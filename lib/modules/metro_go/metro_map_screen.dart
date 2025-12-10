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
                      //provider.onRouteSelected();
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
          Positioned(
            bottom: 50,
            right: 0.0,
            child: FloatingActionButton(
              mini: true,
              tooltip: 'Starting Navigation',
              onPressed: (provider.currentPlaceLatLng != null &&
                         provider.selectedPlaceLatLng != null &&
                         provider.listLocations.isNotEmpty &&
                         provider.routeEntity != null)
                  ? () => context.pushRoute(MetroGoNavigationRoute(
                      currentLocation: provider.currentPlaceLatLng!,
                      listLocations: provider.listLocations,
                      route: provider.routeEntity!))
                  : null,
              backgroundColor: (provider.currentPlaceLatLng != null &&
                                provider.selectedPlaceLatLng != null &&
                                provider.listLocations.isNotEmpty &&
                                provider.routeEntity != null)
                  ? null
                  : Colors.grey,
              child: Icon(
                Icons.near_me_outlined,
                color: (provider.currentPlaceLatLng != null &&
                       provider.selectedPlaceLatLng != null &&
                       provider.listLocations.isNotEmpty &&
                       provider.routeEntity != null)
                    ? AppColors.primary
                    : Colors.white,
              ),
            ),
          ),
          Positioned(
            top: 140,
            right: 0.0,
            child: _SavedTripsMenuAnchor(provider: provider),
          )
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

class _SavedTripsMenuAnchor extends StatefulWidget {
  const _SavedTripsMenuAnchor({
    required this.provider,
  });

  final MetroMapProvider provider;

  @override
  State<_SavedTripsMenuAnchor> createState() => _SavedTripsMenuAnchorState();
}

class _SavedTripsMenuAnchorState extends State<_SavedTripsMenuAnchor> {
  final GlobalKey _buttonKey = GlobalKey();
  bool _isLoading = false;

  Future<void> _showTripsMenu() async {
    setState(() => _isLoading = true);

    // Load danh sách chuyến đi
    await widget.provider.loadAllTrip();

    setState(() => _isLoading = false);

    if (!mounted) return;

    // Lấy vị trí của button
    final RenderBox button = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final Offset buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);

    // Tính vị trí menu hiển thị phía trên button
    final RelativeRect position = RelativeRect.fromLTRB(
      buttonPosition.dx,
      buttonPosition.dy + 10,
      overlay.size.width - buttonPosition.dx - button.size.width,
      overlay.size.height - buttonPosition.dy,
    );

    final selectedTrip = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 8,
      items: _buildMenuItems(),
    );

    if (selectedTrip != null && mounted) {
      context.router.push(MyTripRouteRoute(tripName: selectedTrip));
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    final tripNames = widget.provider.savedTripNames;

    // Empty state
    if (tripNames.isEmpty) {
      return [
        PopupMenuItem<String>(
          enabled: false,
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.bookmark_outline, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'My trip',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.create_outlined, color: AppColors.primary),
                iconSize: 18,
                onPressed: () => context.router.push(MyTripRouteRoute()),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          enabled: false,
          child: Container(
            width: 200,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_open_outlined, color: Colors.grey.shade400, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Chưa có chuyến đi nào',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hãy tạo chuyến đi mới',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    // Header
    final List<PopupMenuEntry<String>> items = [
      PopupMenuItem<String>(
        enabled: false,
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.bookmark_outline, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'My trip',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.create_outlined, color: AppColors.primary),
              iconSize: 18,
              onPressed: () => context.router.push(MyTripRouteRoute()),
            ),
          ],
        ),
      ),
      const PopupMenuDivider(height: 1),
    ];

    // Trip items
    for (final tripName in tripNames) {
      items.add(
        PopupMenuItem<String>(
          value: tripName,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.route_outlined, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  TripNameParser.getTripName(tripName),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      key: _buttonKey,
      mini: true,
      tooltip: 'My trip routes',
      onPressed: _isLoading ? null : _showTripsMenu,
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          : const Icon(Icons.person_pin_circle_outlined, color: AppColors.primary),
    );
  }
}