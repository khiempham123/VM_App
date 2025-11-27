import 'package:vm_first_app/app/app_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vm_first_app/domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:vm_first_app/core/core.dart';
class MetroMapProvider extends ChangeNotifier {
  final AppProvider _appProvider;
  VietmapController? _vietmapController;
  VietmapController get vietmapController => _vietmapController!;


  bool _hasLocationPermission = false;
  bool get hasLocationPermission => _hasLocationPermission;

  bool _isRequestingPermission = false;
  bool get isRequestingPermission => _isRequestingPermission;

  bool _isOnMyLocation = false;
  bool get isOnMyLocation => _isOnMyLocation;

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
    }
    return;
  }
}