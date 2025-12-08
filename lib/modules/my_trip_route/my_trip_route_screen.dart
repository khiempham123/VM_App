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

@RoutePage()
class MyTripRouteScreen extends StatelessWidget {
  const MyTripRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyTripRouteProvider(locator<AppProvider>()),
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
            onMapLongClick: (latLng) async {
              await provider.onMapLongClick(latLng);
              // Show bottom sheet after reverse data is loaded
              if (context.mounted && provider.isReverseDrawn && provider.reverseEntity != null) {
                _showLocationDetailBottomSheet(context, provider);
              }
            },
          ),

          // Search Bar


          // Selected Location Marker (from search)
          if (provider.isMapReady && provider.isOnSelectedLocation && provider.selectedPlaceLatLng != null)
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
          if (provider.isMapReady && provider.allLongPressedLocations.isNotEmpty)
            StaticMarkerLayer(
              key: ValueKey('longPressed_${provider.allLongPressedLocations.length}'),
              mapController: provider.vietmapController,
              markers: provider.allLongPressedLocations.asMap().entries.map((entry) {
                final index = entry.key;
                final location = entry.value;
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
                            isInTrip ? Icons.flag : Icons.location_on,
                            color: isInTrip
                                ? Colors.orange
                                : (isCurrentSelected ? AppColors.primaryLight : Colors.grey),
                            size: isCurrentSelected ? 40 : 32,
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
          if (provider.isMapReady && provider.isOnMyLocation)
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

          // Metro Stations Markers with Tooltip
          if (provider.isMapReady)
            StaticMarkerLayer(
              key: ValueKey('metroStations_${provider.selectedMetroStationIndex}'),
              mapController: provider.vietmapController,
              markers: provider.metroStations.asMap().entries.map((entry) {
                final index = entry.key;
                final station = entry.value;
                final stationName = provider.metroStationNames[index];
                final isSelected = provider.selectedMetroStationIndex == index;

                return StaticMarker(
                  width: isSelected ? 150 : 40,
                  height: isSelected ? 80 : 40,
                  bearing: 0,
                  child: GestureDetector(
                    onTap: () {
                      provider.selectMetroStation(index);
                      _showMetroStationBottomSheet(context, provider, index);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tooltip - chỉ hiển thị khi ga metro đang được chọn
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              stationName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        // Metro station icon
                        Container(
                          width: isSelected ? 32 : 24,
                          height: isSelected ? 32 : 24,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.shade700 : AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.train,
                              color: Colors.white,
                              size: isSelected ? 18 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  latLng: station,
                );
              }).toList(),
            ),

          // Metro stations info panel
          Positioned(
            top: 130,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                            // Create new trip button
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                              tooltip: 'Tạo chuyến đi mới',
                              onPressed: () => _showCreateTripDialog(context, provider),
                            ),
                            // Saved trips menu button - wrapped with IconButton for better state handling
                            IconButton(
                              icon: const Icon(Icons.format_list_bulleted_add, color: AppColors.primary),
                              tooltip: 'Danh sách chuyến đi',
                              onPressed: () async {
                                // Load data first
                                await provider.loadSavedTripNames();

                                if (!context.mounted) return;

                                // Show popup menu after data is loaded
                                final RenderBox button = context.findRenderObject() as RenderBox;
                                final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
                                final RelativeRect position = RelativeRect.fromRect(
                                  Rect.fromPoints(
                                    button.localToGlobal(Offset.zero, ancestor: overlay),
                                    button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                                  ),
                                  Offset.zero & overlay.size,
                                );

                                final selectedTrip = await showMenu<String>(
                                  context: context,
                                  position: position,
                                  items: _buildTripMenuItems(provider),
                                );

                                if (selectedTrip != null && context.mounted) {
                                  await provider.loadTripMarkers(selectedTrip);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Trip: ${TripNameParser.getTripName(selectedTrip)} is loaded'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Show route info when route to station is drawn
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(24),
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
          if (provider.hasMarkersToSave)
            Positioned(
              bottom: 200,
              right: 0.0,
              child: FloatingActionButton(
                heroTag: 'saveTrip',
                mini: true,
                tooltip: 'Lưu chuyến đi',
                onPressed: () => _showSaveTripDialog(context, provider),
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.save, color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildTripMenuItems(MyTripRouteProvider provider) {
    // Error state
    if (provider.loadTripsError != null) {
      return [
        PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.loadTripsError!,
                  style: const TextStyle(color: Colors.red),
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
        const PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: [
              Icon(Icons.folder_open, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chưa có chuyến đi nào được lưu.\nHãy thêm điểm đến và lưu chuyến đi.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    // Has saved trips - with long press to delete
    return provider.savedTripNames.map((tripName) {
      return PopupMenuItem<String>(
        value: tripName,
        child: Row(
          children: [
            const Icon(Icons.map, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(TripNameParser.getTripName(tripName))),
            // Delete button
            GestureDetector(
              onTap: () {
                // Close popup first, then show delete dialog
                Navigator.of(context).pop();
                _showDeleteTripDialog(context, provider, tripName);
              },
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.delete_outline, color: Colors.red, size: 20),
              ),
            ),
          ],
        ),
      );
    }).toList();
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
                  'Xóa chuyến đi',
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
              const SizedBox(height: 8),
              const Text(
                'Hành động này không thể hoàn tác.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await provider.deleteTripByName(tripName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa chuyến đi: ${TripNameParser.getTripName(tripName)}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
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
                                'Chỉ đường',
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
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Đã thêm vào hành trình'),
                                              duration: Duration(seconds: 1),
                                            ),
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
                                    'Thêm',
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
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Đã bỏ khỏi hành trình'),
                                              duration: Duration(seconds: 1),
                                            ),
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
                                    'Bỏ',
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
    );
  }

  void _showMetroStationBottomSheet(BuildContext context, MyTripRouteProvider provider, int stationIndex) {
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
                  'Tạo chuyến đi mới',
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
              const SizedBox(height: 12),
              const Text(
                'Sau khi tạo, bạn có thể thêm các điểm đến bằng cách nhấn giữ trên bản đồ.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final tripName = tripNameController.text.trim();
                if (tripName.isNotEmpty) {
                  provider.createNewTrip(tripName);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã tạo chuyến đi: $tripName'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Tạo'),
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
    // TripNameParser.getTripName handles both:
    // - Simple trip name: "My Trip" -> "My Trip"
    // - Full key format: "trip_{My Trip}_refId1_refId2" -> "My Trip"
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
                  'Lưu chuyến đi',
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
              const SizedBox(height: 12),
              Text(
                'Chuyến đi có ${provider.allLongPressedLocations.length} điểm đến',
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
                  provider.storageMyTrip(tripName);
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Saved: ${TripNameParser.getTripName(tripName)}'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
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
              Icon(Icons.train, color: Colors.blue),
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



class _VietmapWidget extends StatefulWidget {
  final Function(VietmapController) onMapCreated;
  final Function(LatLng) onMapLongClick;

  const _VietmapWidget({
    required this.onMapCreated,
    required this.onMapLongClick,
  });

  @override
  State<_VietmapWidget> createState() => _VietmapWidgetState();
}

class _VietmapWidgetState extends State<_VietmapWidget> {
  @override
  Widget build(BuildContext context) {
    return VietmapGL(
      styleString:
          'https://maps.vietmap.vn/maps/styles/tm/style.json?apikey=${dotenv.env['VM_API_KEY']}',
      initialCameraPosition: const CameraPosition(
        // Initial position centered on metro line
        target: LatLng(10.780000, 106.720000),
        zoom: 12.0,
      ),
      onMapCreated: widget.onMapCreated,
      onMapLongClick: (point, coordinates) {
        widget.onMapLongClick(coordinates);
      },
      trackCameraPosition: true,
      myLocationEnabled: true,
      myLocationTrackingMode: MyLocationTrackingMode.none,
      myLocationRenderMode: MyLocationRenderMode.normal,
      compassEnabled: true,
      rotateGesturesEnabled: true,
    );
  }
}

