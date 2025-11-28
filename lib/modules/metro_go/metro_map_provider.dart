import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:vm_first_app/core/core.dart';
class MetroMapProvider extends ChangeNotifier {
  final AppProvider _appProvider;
  VietmapController? _vietmapController;
  VietmapController get vietmapController => _vietmapController!;

  final searchController = TextEditingController();

  // bool _hasLocationPermission = false;
  // bool get hasLocationPermission => _hasLocationPermission;
  //
  // bool _isRequestingPermission = false;
  // bool get isRequestingPermission => _isRequestingPermission;

  bool _isOnMyLocation = false;
  bool get isOnMyLocation => _isOnMyLocation;
  late final MetroMapRepository _metroMapRepository;

  List<PlaceEntity> _searchSuggestions = [];
  List<PlaceEntity> get searchSuggestions => _searchSuggestions;
  PlaceDetailEntity? _selectedPlace;
  PlaceDetailEntity? get selectedPlace => _selectedPlace;

  bool _isLoading = false;
  bool get isLoading => _isLoading;


  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  MetroMapProvider(this._appProvider);


  void onMapCreated(VietmapController controller) {
    _vietmapController = controller;
    notifyListeners();
  }

  Future<void> moveToMyLocation() async {
    if (_vietmapController == null) {
      return;
    }


    try {
      await _vietmapController!.moveCamera(
        CameraUpdate.newLatLngZoom(
          await _vietmapController!.requestMyLocationLatLng() ??
              const LatLng(11.8903231, 106.654551),
          16.0,
        ),
      );
      _isOnMyLocation = true;
      notifyListeners();
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> onSearchChanged(String query) async {
    final request = PlaceRequest(text: query);
    final suggestions = await _metroMapRepository.searchPlaces(request);
    _searchSuggestions = suggestions;
    notifyListeners();
  }

  Future<void> onSuggestionSelected(PlaceEntity place) async {
    final request = PlaceDetailsRequest(refid: place.refId);
    final details = await _metroMapRepository.getPlaceDetails(request);
    _selectedPlace = details;
    notifyListeners();
  }
}