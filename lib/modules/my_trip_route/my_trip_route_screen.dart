import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/core/route/router.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:vm_first_app/domain/domain.dart';
import 'package:vm_first_app/modules/my_trip_route/my_trip_route_provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
//import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
@RoutePage()
class MyTripRouteScreen extends StatelessWidget {
  final String? tripName;

  const MyTripRouteScreen({super.key, this.tripName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final provider = MyTripRouteProvider(locator<AppProvider>());
        if (tripName != null && tripName!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.loadTripMarkers(tripName!);
            if(context.mounted && provider.isMapReady) {
              debugPrint('im here with mouted context');
              showTopSnackBar(
                Overlay.of(context),
                MySnackBar.info(
                  message:
                  "Trip: ${TripNameParser.getTripName(tripName!)} is loaded",
                ),
                snackBarPosition: SnackBarPosition.bottom,
              );
            }
          });

        }

        return provider;
      },
      child: const _MyTripRouteView(),
    );
  }
}

class _MyTripRouteView extends StatefulWidget {
  const _MyTripRouteView();

  @override
  State<_MyTripRouteView> createState() => _MyTripRouteViewState();
}

class _MyTripRouteViewState extends State<_MyTripRouteView> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MyTripRouteProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Map Widget
          _VietmapWidget(
            onMapCreated: provider.onMapCreated,
            onMapFullyRendered: provider.onMapFullyRendered,
            onMapLongClick: (latLng) async {
              await provider.onMapLongClick(latLng);
              // Show bottom sheet after reverse data is loaded
              if (context.mounted && provider.isReverseDrawn && provider.reverseEntity != null) {
                _showLocationDetailBottomSheet(context, provider);
              }
            },
            onSymbolTapped: (symbol) {
              provider.onSymbolTapped(symbol);
              // Show metro station bottom sheet if a metro station was tapped
              if (provider.selectedMetroStationIndex != null) {
                _showMetroStationBottomSheet(context, provider, provider.selectedMetroStationIndex!);
              }
            },
          ),

          // Loading indicator while map is not fully rendered
          if (!provider.isMapFullyRendered)
            Container(
              color: Colors.white.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading map...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Selected Location Marker (from search)
          if (provider.isMapReady && provider.isMapFullyRendered && provider.isOnSelectedLocation && provider.selectedPlaceLatLng != null)

            StaticMarkerLayer(
              key: const ValueKey('selectedLocation'),
              mapController: provider.vietmapController,
              markers: [
                StaticMarker(
                  width: 50,
                  height: 50,
                  bearing: 0,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                  latLng: provider.selectedPlaceLatLng!,
                ),
              ],
            ),

          // Long Pressed Location Markers - hiển thị tất cả các điểm đã click
          if (provider.isMapReady && provider.isMapFullyRendered && provider.allLongPressedLocations.isNotEmpty)
            StaticMarkerLayer(
              key: ValueKey('longPressed_${provider.allLongPressedLocations.length}'),
              mapController: provider.vietmapController,
              markers: provider.allLongPressedLocations.asMap().entries.map((entry) {
                final index = entry.key;
                final location = entry.value;
                // Guard: kiểm tra index hợp lệ trước khi truy cập
                if (index >= provider.allLongPressedEntities.length) {
                  return StaticMarker(
                    width: 50,
                    height: 50,
                    bearing: 0,
                    child: const Icon(Icons.location_on, color: Colors.grey, size: 25),
                    latLng: location,
                  );
                }
                final entity = provider.allLongPressedEntities[index];
                final isCurrentSelected = provider.longPressedLocation != null &&
                    location.latitude == provider.longPressedLocation!.latitude &&
                    location.longitude == provider.longPressedLocation!.longitude;
                final isInTrip = provider.isLocationInTrip(location);

                return StaticMarker(
                  width: isCurrentSelected ? 200 : 50,
                  height: isCurrentSelected ? 100 : 50,
                  bearing: 0,
                  child: GestureDetector(
                    onTap: () {
                      provider.selectMarkerAtIndex(index);
                      _showLocationDetailBottomSheet(context, provider);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tooltip - chỉ hiển thị khi marker đang được chọn
                        if (isCurrentSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primaryLight, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              entity.display,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        // Pin marker icon
                        Container(
                          decoration: isCurrentSelected
                              ? BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryLight.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                )
                              : null,
                          child: Icon(
                            isInTrip ? Icons.add_location_alt_rounded : Icons.location_on,
                            color: isInTrip
                                ? AppColors.info
                                : (isCurrentSelected ? AppColors.primaryLight : Colors.grey),
                            size: isCurrentSelected ? 30 : 25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  latLng: location,
                );
              }).toList(),
            ),

          // User Location Layer
          if (provider.isMapReady && provider.isMapFullyRendered && provider.isOnMyLocation)
            UserLocationLayer(
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
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              ignorePointer: true,
            ),


          // Metro stations info panel
          Positioned(
            top: 130,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.train, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              TripNameParser.getTripName(provider.currentTripName ?? ''),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _TripsMenuAnchor(
                              provider: provider,
                              onTripSelected: (tripName) async {
                                // Don't reload if clicking on the same trip
                                if (provider.currentTripName == tripName) {
                                  debugPrint('Im in same tripName');
                                  return;
                                }
                                // Check if current trip has unsaved changes
                                // Only show dialog if:
                                // 1. Has waypoints (hasMarkersToSave)
                                // 2. Has a current trip name
                                // 3. NOT viewing a saved trip (means creating/editing new trip)
                                if (provider.hasMarkersToSave &&
                                    provider.currentTripName != null &&
                                    provider.currentTripName!.isNotEmpty &&
                                    !provider.isViewingSavedTrip) {
                                  // Current trip has unsaved changes, ask user
                                  debugPrint('Unsaved trip detected. Showing confirm dialog.');
                                  final shouldProceed = await _showConfirmSwitchTripDialog(context, provider, tripName);
                                  if (!shouldProceed) {
                                    // User cancelled, don't switch trip
                                    return;
                                  }
                                }

                                // Proceed to load the selected trip
                                await provider.loadTripMarkers(tripName);
                                await provider.currentRoute(tripName);
                                // No need to call tripSelected - currentTripName is already set in loadTripMarkers
                                if (context.mounted && provider.isMapFullyRendered) {
                                  showTopSnackBar(
                                    Overlay.of(context),
                                    MySnackBar.info(
                                      message:
                                      "Trip: ${TripNameParser.getTripName(tripName)} is loaded",
                                    ),
                                    snackBarPosition: SnackBarPosition.bottom,
                                  );
                                }
                              },
                              onDeleteTrip: (tripName) => _showDeleteTripDialog(context, provider, tripName),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                              tooltip: 'Create your strip',
                              onPressed: () async {
                                if (provider.hasMarkersToSave && provider.isPlaceAdded && provider.mustSaveBeforeSwitchNewTrip == false) {
                                  final shouldProceed = await _showConfirmSwitchTripDialog(context, provider, provider.currentTripName!);
                                  if (!shouldProceed) {
                                    return;
                                  }
                                }
                                _showCreateTripDialog(context, provider);},
                            ),
                          ],
                        ),
                      ],
                    ),

                    if (provider.isRouteToStationDrawn && provider.nearestStationName != null) ...[
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.directions, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Ways to: ${provider.nearestStationName}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.straighten, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${provider.routeDistance?.toStringAsFixed(2) ?? '-'} km',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${provider.routeDuration?.toStringAsFixed(0) ?? '-'} phút',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],

                  ],
                ),
              ),
            ),
          ),


          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(16),
                child: TypeAheadField<PlaceEntity>(
                  controller: provider.searchController,
                  focusNode: FocusNode(),
                  itemBuilder: (BuildContext context, value) {
                    return ListTile(
                      leading: const Icon(Icons.location_on),
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


        ],
      ),
      floatingActionButton: Stack(
        children: <Widget>[
          // My Location Button
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              heroTag: 'myLocation',
              mini: true,
              onPressed: () async {
                await provider.moveToMyLocation();
                // Show suggestion dialog after getting location
                if (context.mounted && provider.nearestStationName != null) {
                  _showNearestStationDialog(context, provider);
                }
              },
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),

          // Show All Metro Stations Button
          Positioned(
            bottom: 50,
            right: 0.0,
            child: FloatingActionButton(
              heroTag: 'showAll',
              mini: true,
              tooltip: 'Hiển thị tất cả nhà ga',
              onPressed: provider.showAllMetroStations,
              child: const Icon(Icons.zoom_out_map, color: AppColors.primary),
            ),
          ),

          // Clear Long Pressed Location
          if (provider.isOnLongPressedLocation)
            Positioned(
              bottom: 100,
              right: 0.0,
              child: FloatingActionButton(
                heroTag: 'clearPin',
                mini: true,
                tooltip: 'Xóa điểm đã chọn',
                onPressed: provider.clearLongPressedLocation,
                backgroundColor: Colors.red.shade100,
                child: const Icon(Icons.clear, color: Colors.red),
              ),
            ),

          // Clear Route to Station Button
          if (provider.isRouteToStationDrawn)
            Positioned(
              bottom: 150,
              right: 0.0,
              child: FloatingActionButton(
                heroTag: 'clearRoute',
                mini: true,
                tooltip: 'Xóa đường đi đến ga',
                onPressed: provider.clearRouteToStation,
                backgroundColor: Colors.orange.shade100,
                child: const Icon(Icons.directions_off, color: Colors.orange),
              ),
            ),

          // Save Trip Button - only show when user has added markers by long press
          if (provider.hasMarkersToSave && provider.isPlaceAdded)
            Positioned(
              bottom: 200,
              right: 0.0,
              child: FloatingActionButton(
                heroTag: 'saveTrip',
                mini: true,
                tooltip: 'Save this trip',
                onPressed: () {
                  provider.mustSavedBeforeStartNewTrip();
                  _showSaveTripDialog(context, provider);},
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.save, color: Colors.green),
              ),
            ),


        ],
      ),
    );
  }


  void _showDeleteTripDialog(BuildContext context, MyTripRouteProvider provider, String tripName) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Delete trip',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có chắc chắn muốn xóa chuyến đi "${TripNameParser.getTripName(tripName)}"?',
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await provider.deleteTripByName(tripName);
                if (context.mounted) {
                  showTopSnackBar(
                    Overlay.of(context),
                    MySnackBar.error(
                      message:
                      'Trip: ${TripNameParser.getTripName(tripName)} is delete'
                    ),
                    snackBarPosition: SnackBarPosition.bottom,
                  );
                }
              },
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('Xóa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLocationDetailBottomSheet(BuildContext context, MyTripRouteProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.white12,
      builder: (bottomSheetContext) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: Consumer<MyTripRouteProvider>(
            builder: (consumerContext, providerValue, child) {
              return DraggableScrollableSheet(
                initialChildSize: 0.3,
                minChildSize: 0.25,
                maxChildSize: 0.5,
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

                        // Location display info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.primaryLight,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  providerValue.reverseEntity?.display ?? 'Địa điểm không xác định',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(),

                        // Action buttons - Row 1: Chỉ đường (full width)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                Navigator.of(bottomSheetContext).pop();
                                // Get route and navigate to MetroGoNavigationScreen
                                await providerValue.getRouteToLongPressedLocation();
                                if (context.mounted &&
                                    providerValue.routeToLongPressedLocation != null &&
                                    providerValue.currentPlaceLatLng != null &&
                                    providerValue.longPressedLocation != null &&
                                    providerValue.allLongPressedLocations.isNotEmpty) {
                                  context.router.push(
                                    MetroGoNavigationRoute(
                                      currentLocation: LatLng(
                                        providerValue.currentPlaceLatLng!.latitude,
                                        providerValue.currentPlaceLatLng!.longitude,
                                      ),
                                      listLocations: providerValue.allLongPressedLocations,
                                      route: providerValue.routeToLongPressedLocation!,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.directions, color: Colors.white, size: 20),
                              label: const Text(
                                'Go now',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Action buttons - Row 2: Thêm hành trình + Bỏ hành trình
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              // Thêm hành trình button
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: providerValue.longPressedLocation != null &&
                                            providerValue.isLocationInTrip(providerValue.longPressedLocation!)
                                        ? Colors.grey
                                        : AppColors.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: providerValue.longPressedLocation != null &&
                                          providerValue.isLocationInTrip(providerValue.longPressedLocation!)
                                      ? null
                                      : () {
                                          providerValue.addToTrip();
                                          Navigator.of(bottomSheetContext).pop();
                                          showTopSnackBar(
                                            Overlay.of(context),
                                            MySnackBar.info(
                                              message:
                                              "Add to my trip",
                                            ),
                                            snackBarPosition: SnackBarPosition.bottom,
                                          );
                                        },
                                  icon: Icon(
                                    Icons.add_location_alt,
                                    color: providerValue.longPressedLocation != null &&
                                            providerValue.isLocationInTrip(providerValue.longPressedLocation!)
                                        ? Colors.white54
                                        : Colors.white,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Add new place',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: providerValue.longPressedLocation != null &&
                                              providerValue.isLocationInTrip(providerValue.longPressedLocation!)
                                          ? Colors.white54
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Bỏ hành trình button
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: providerValue.longPressedLocation != null &&
                                            providerValue.isLocationInTrip(providerValue.longPressedLocation!)
                                        ? Colors.red
                                        : Colors.grey,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: providerValue.longPressedLocation != null &&
                                          providerValue.isLocationInTrip(providerValue.longPressedLocation!)
                                      ? () {
                                          providerValue.removeFromTrip();
                                          Navigator.of(bottomSheetContext).pop();
                                          showTopSnackBar(
                                            Overlay.of(context),
                                            MySnackBar.info(
                                              message:
                                              "Remove from trip",
                                            ),
                                            snackBarPosition: SnackBarPosition.bottom,
                                          );
                                        }
                                      : null,
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    color: providerValue.longPressedLocation != null &&
                                            providerValue.isLocationInTrip(providerValue.longPressedLocation!)
                                        ? Colors.white
                                        : Colors.white54,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Remove this place',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: providerValue.longPressedLocation != null &&
                                              providerValue.isLocationInTrip(providerValue.longPressedLocation!)
                                          ? Colors.white
                                          : Colors.white54,
                                    ),
                                  ),
                                ),
                              ),

                            ],
                          ),
                        ),

                        // Close button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(bottomSheetContext).pop();
                              },
                              child: const Text(
                                'Close',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
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

  void _showMetroStationBottomSheet(BuildContext context, MyTripRouteProvider provider, int stationIndex) {
    // Guard: kiểm tra stationIndex hợp lệ (0-13 cho 14 nhà ga)
    if (stationIndex < 0 || stationIndex >= provider.metroStationNames.length) {
      debugPrint('Invalid stationIndex: $stationIndex. Valid range: 0-${provider.metroStationNames.length - 1}');
      return;
    }
    final stationName = provider.metroStationNames[stationIndex];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.white12,
      builder: (bottomSheetContext) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: Consumer<MyTripRouteProvider>(
            builder: (consumerContext, providerValue, child) {
              return DraggableScrollableSheet(
                initialChildSize: 0.25,
                minChildSize: 0.15,
                maxChildSize: 0.4,
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

                        // Metro station info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade700,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.train,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ga Metro $stationName',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tuyến Metro số 1 (Bến Thành - Suối Tiên)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(),

                        // Action button - Chỉ đường
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                Navigator.of(bottomSheetContext).pop();
                                // Get route to metro station
                                await providerValue.getRouteToSelectedMetroStation();
                                if (context.mounted &&
                                    providerValue.routeToLongPressedLocation != null &&
                                    providerValue.currentPlaceLatLng != null &&
                                    providerValue.allLongPressedLocations.isNotEmpty) {
                                  context.router.push(
                                    MetroGoNavigationRoute(
                                      currentLocation: LatLng(
                                        providerValue.currentPlaceLatLng!.latitude,
                                        providerValue.currentPlaceLatLng!.longitude,
                                      ),
                                      listLocations: providerValue.allLongPressedLocations,
                                      route: providerValue.routeToLongPressedLocation!,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.directions, color: Colors.white, size: 20),
                              label: const Text(
                                'Chỉ đường đến ga',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Close button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                providerValue.clearSelectedMetroStation();
                                Navigator.of(bottomSheetContext).pop();
                              },
                              child: const Text(
                                'Đóng',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
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
    ).whenComplete(() {
      // Clear selected metro station when bottom sheet is dismissed
      provider.clearSelectedMetroStation();
    });
  }

  void _showCreateTripDialog(BuildContext context, MyTripRouteProvider provider) {
    final TextEditingController tripNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.add_location_alt, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Create your trip',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tripNameController,
                decoration: InputDecoration(
                  labelText: 'Tên chuyến đi',
                  hintText: 'Nhập tên chuyến đi...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.edit),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(

              onPressed: () {
                final tripName = tripNameController.text.trim();
                if (tripName.isNotEmpty) {
                  provider.createNewTrip(tripName);
                  Navigator.of(dialogContext).pop();
                  showTopSnackBar(
                    Overlay.of(context),
                    MySnackBar.success(
                      message:
                      'Trip: $tripName is created',
                    ),
                    snackBarPosition: SnackBarPosition.bottom,
                  );
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSaveTripDialog(BuildContext context, MyTripRouteProvider provider) {
    final TextEditingController tripNameController = TextEditingController(
      text: TripNameParser.getTripName(provider.currentTripName ?? ''),
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.save, color: Colors.green),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Save my trip',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tripNameController,
                decoration: InputDecoration(
                  labelText: 'Trip Name',
                  hintText: 'Enter your new journey...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.edit),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Text(
                'Trip has ${provider.allLongPressedLocations.length} arrival points',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final tripName = tripNameController.text.trim();
                if (tripName.isNotEmpty) {
                  await provider.storageMyTrip(tripName);
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    showTopSnackBar(
                      Overlay.of(context),
                      MySnackBar.info(
                        message:
                        "Saved: ${TripNameParser.getTripName(tripName)}",
                      ),
                      snackBarPosition: SnackBarPosition.bottom,
                    );
                  }
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Lưu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show confirm dialog when user tries to switch to a new trip without saving current one
  /// Returns true if user wants to proceed (either saved or discarded), false if cancelled
  Future<bool> _showConfirmSwitchTripDialog(
    BuildContext context,
    MyTripRouteProvider provider,
    String newTripName,
  ) async {
    final TextEditingController tripNameController = TextEditingController(
      text: TripNameParser.getTripName(provider.currentTripName ?? ''),
    );

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Unsaved Trip',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You have unsaved changes in your current trip. What would you like to do?',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tripNameController,
                decoration: InputDecoration(
                  labelText: 'Trip Name (to save)',
                  hintText: 'Enter trip name...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Current trip has ${provider.allLongPressedLocations.length} arrival points',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            // Cancel button - stay on current trip
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop('cancel');
              },
              child: const Text('Cancel'),
            ),
            // Discard button - clear data and switch
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop('discard');
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Discard'),
            ),
            // Save button - save and switch
            ElevatedButton.icon(
              onPressed: () async {
                final tripName = tripNameController.text.trim();
                if (tripName.isNotEmpty) {
                  await provider.storageMyTrip(tripName);
                  provider.mustSavedBeforeStartNewTrip();
                  Navigator.of(dialogContext).pop('saved');
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (result == 'cancel') {
      return false; // User cancelled, don't switch
    } else if (result == 'discard') {
      // User chose to discard - clear all unsaved data
      await provider.clearUnsavedTripData();
      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          MySnackBar.info(
            message: "Discarded unsaved trip data",
          ),
          snackBarPosition: SnackBarPosition.bottom,
        );
      }
      return true; // Proceed to switch
    } else if (result == 'saved') {
      // User saved the trip
      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          MySnackBar.info(
            message: "Saved: ${tripNameController.text.trim()}",
          ),
          snackBarPosition: SnackBarPosition.bottom,
        );
      }
      // Don't clear data here - let loadTripMarkers handle clearing when loading the new trip
      return true; // Proceed to switch
    }

    return false; // Default: don't switch
  }

  void _showNearestStationDialog(BuildContext context, MyTripRouteProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.train, color: AppColors.primaryLight),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ga Metro gần nhất',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.nearestStationName ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.straighten, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Khoảng cách: ${provider.distanceToNearestStation?.toStringAsFixed(2) ?? '-'} km',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Bạn có muốn xem đường đi đến ga metro này không?',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Đóng'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                provider.drawRouteToNearestStation();
              },
              icon: const Icon(Icons.directions),
              label: const Text('Xem đường đi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}


class _TripsMenuAnchor extends StatefulWidget {
  final MyTripRouteProvider provider;
  final Function(String tripName) onTripSelected;
  final Function(String tripName) onDeleteTrip;

  const _TripsMenuAnchor({
    required this.provider,
    required this.onTripSelected,
    required this.onDeleteTrip,
  });

  @override
  State<_TripsMenuAnchor> createState() => _TripsMenuAnchorState();
}

class _TripsMenuAnchorState extends State<_TripsMenuAnchor> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    return Consumer<MyTripRouteProvider>(
      builder: (context, provider, child) {
        return MenuAnchor(
          controller: _menuController,
          alignmentOffset: const Offset(-45, 0), // Điều chỉnh vị trí menu: x < 0 left, y > 0 down
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.white),
            surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
            elevation: WidgetStatePropertyAll(8),
            shadowColor: WidgetStatePropertyAll(Colors.black26),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
          ),
          menuChildren: _buildMenuChildren(context, provider),
          onOpen: () {
            // Tự động load dữ liệu khi menu mở
            if (!provider.hasFetchedTrips) {
              provider.loadSavedTripNames();
            }
          },
          builder: (BuildContext context, MenuController controller, Widget? child) {
            return IconButton(
              icon: provider.isLoadingSavedTrips
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.format_list_bulleted_add, color: AppColors.primary),
              tooltip: 'Danh sách chuyến đi',
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            );
          },
        );
      },
    );
  }

  List<Widget> _buildMenuChildren(BuildContext context, MyTripRouteProvider provider) {
    // Loading state
    if (provider.isLoadingSavedTrips) {
      return [
        Container(
          width: 220,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Đang tải...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    // Error state
    if (provider.loadTripsError != null) {
      return [
        Container(
          width: 260,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.loadTripsError!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    _menuController.close();
                    provider.loadSavedTripNames();
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _menuController.open();
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Thử lại'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    // Empty state
    if (provider.savedTripNames.isEmpty) {
      return [
        Container(
          width: 260,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_open_outlined,
                  color: Colors.grey.shade400,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa có chuyến đi nào',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hãy thêm điểm đến và lưu chuyến đi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    // Header
    final List<Widget> items = [
      Container(
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.bookmark_outline, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Your trip',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
      Divider(height: 1, color: Colors.grey.shade200),
    ];

    // Trip items
    for (final tripName in provider.savedTripNames) {
      // Check if this trip is currently selected
      final isSelected = provider.currentTripName == tripName;

      items.add(
        InkWell(
          onTap: () {
            _menuController.close();
            widget.onTripSelected(tripName);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              // Always have border to keep consistent sizing, just change visibility via color
              border: Border.all(
                color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.transparent, // Transparent border for unselected
                width: 1,
              ),
            ),
            width: 150,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    isSelected ? Icons.route : Icons.route_outlined,
                    color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    TripNameParser.getTripName(tripName),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _menuController.close();
                      widget.onDeleteTrip(tripName);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.clear,
                        color: Colors.red.shade400,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return items;
  }
}


class _VietmapWidget extends StatefulWidget {
  final Function(VietmapController) onMapCreated;
  final Function(LatLng) onMapLongClick;
  final Function(Symbol)? onSymbolTapped;
  final VoidCallback? onMapFullyRendered;

  const _VietmapWidget({
    required this.onMapCreated,
    required this.onMapLongClick,
    this.onSymbolTapped,
    this.onMapFullyRendered,
  });

  @override
  State<_VietmapWidget> createState() => _VietmapWidgetState();
}

class _VietmapWidgetState extends State<_VietmapWidget> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        VietmapGL(
          styleString:
              'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=${dotenv.env['VM_API_KEY']}',
          initialCameraPosition: const CameraPosition(
            // Initial position centered on metro line
            target: LatLng(10.780000, 106.720000),
            zoom: 12.0,
          ),
          onMapCreated: (controller) {
            widget.onMapCreated(controller);
          },
          onMapFirstRenderedCallback: () {
            // Called when map is fully rendered for the first time
            widget.onMapFullyRendered?.call();
          },
          onMapLongClick: (point, coordinates) {
            widget.onMapLongClick(coordinates);
          },
          trackCameraPosition: true,
          myLocationEnabled: true,
          myLocationTrackingMode: MyLocationTrackingMode.none,
          myLocationRenderMode: MyLocationRenderMode.normal,
          compassEnabled: true,
          rotateGesturesEnabled: true,
        ),
      ],
    );
  }
}

