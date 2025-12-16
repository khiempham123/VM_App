# Trip Deselection Callback Mechanism

## Vấn đề (Problem)
Khi user đang xem một saved trip và bắt đầu tạo job mới (thêm waypoint mới), các waypoint mới sẽ được thêm vào trip đã lưu, gây ra việc đè lên trip gốc. Chúng ta cần một cơ chế để tự động bỏ chọn saved trip khi user bắt đầu tạo job mới.

## Giải pháp (Solution)
Implement một callback mechanism để tự động deselect saved trip khi user thực hiện các action tạo job mới:
- Long press trên map để thêm waypoint
- Add location vào trip từ bottom sheet

## Implementation

### 1. Tracking State
Thêm flag để track xem đang xem saved trip hay không:

```dart
// Flag to track if currently viewing a saved trip
bool _isViewingSavedTrip = false;
bool get isViewingSavedTrip => _isViewingSavedTrip;
```

### 2. Deselect Method
Tạo method private để deselect saved trip:

```dart
/// Deselect saved trip and prepare for new job
Future<void> _deselectSavedTrip() async {
  debugPrint('Deselecting saved trip: $_currentTripName');
  
  // Remove the polyline of the saved trip
  if (_currentTripRouteLine != null && _vietmapController != null) {
    try {
      await _vietmapController!.removePolyline(_currentTripRouteLine!);
      _currentTripRouteLine = null;
    } catch (e) {
      debugPrint('Error removing saved trip polyline: $e');
    }
  }
  
  // Clear trip data
  _allLongPressedLocations.clear();
  _allLongPressedEntities.clear();
  _tripWaypoints.clear();
  _tripWaypointEntities.clear();
  
  // Reset trip state
  _currentTripName = null;
  _isViewingSavedTrip = false;
  _originalKey = '';
  _originalTripWaypointEntities.clear();
  
  // Generate new color for new trip
  _currentRouteColor = RandomColor.getColorObject(Options()).toHex(includeAlpha: true);
  
  notifyListeners();
}
```

### 3. Trigger Points
Gọi `_deselectSavedTrip()` tại các điểm trigger:

#### a. On Map Long Click
```dart
Future<void> onMapLongClick(LatLng latLng) async {
  // If viewing a saved trip, deselect it when starting a new job
  if (_isViewingSavedTrip) {
    await _deselectSavedTrip();
  }
  
  // ...existing code to add waypoint...
}
```

#### b. Add To Trip
```dart
void addToTrip() async {
  // If viewing a saved trip, deselect it when adding new waypoint
  if (_isViewingSavedTrip) {
    await _deselectSavedTrip();
  }
  
  // ...existing code to add to trip...
}
```

### 4. State Management
Update flag `_isViewingSavedTrip` tại các điểm phù hợp:

#### Load Saved Trip
```dart
Future<void> loadTripMarkers(String tripName) async {
  _currentTripName = tripName;
  _isViewingSavedTrip = true; // Mark as viewing saved trip
  // ...existing code...
}
```

#### Create New Trip
```dart
Future<void> createNewTrip(String tripName) async {
  _currentTripName = tripName;
  _isViewingSavedTrip = false; // Not viewing saved trip
  // ...existing code...
}
```

#### Save Trip
```dart
void storageMyTrip(String tripName) async {
  // ...existing code...
  _isViewingSavedTrip = false; // After saving, not viewing anymore
  // ...existing code...
}
```

#### Delete Trip
```dart
Future<void> deleteTripByName(String tripName) async {
  // ...existing code...
  if(_currentTripName == tripName) {
    _isViewingSavedTrip = false; // Not viewing anymore
  }
  // ...existing code...
}
```

#### Clear All Trip
```dart
void clearAllTrip() {
  // ...existing code...
  _isViewingSavedTrip = false;
  // ...existing code...
}
```

## Flow Diagram

```
User loads saved trip
    ↓
_isViewingSavedTrip = true
    ↓
Trip displayed on map with polyline
    ↓
User long presses on map OR clicks "Add to Trip"
    ↓
Check: _isViewingSavedTrip == true?
    ↓ YES
Call _deselectSavedTrip()
    ↓
- Remove polyline
- Clear all trip data
- Reset _currentTripName
- Set _isViewingSavedTrip = false
- Generate new color
    ↓
Continue with adding new waypoint
    ↓
New job created (doesn't overwrite saved trip)
```

## Benefits

1. **Data Protection**: Saved trips không bị overwrite khi user tạo job mới
2. **Clear UX**: User thấy rõ ràng khi trip được deselect (polyline disappears)
3. **Automatic**: Không cần user manually clear trip trước khi tạo job mới
4. **Consistent**: Áp dụng đồng nhất cho mọi action thêm waypoint

## Testing Scenarios

### Scenario 1: Long Press After Loading Trip
1. Load một saved trip
2. Long press trên map tại một vị trí mới
3. **Expected**: Saved trip polyline biến mất, trip được deselect, waypoint mới được thêm vào job mới

### Scenario 2: Add To Trip After Loading Trip
1. Load một saved trip
2. Long press tại vị trí và click "Add to Trip"
3. **Expected**: Saved trip deselect, location được thêm vào job mới

### Scenario 3: Multiple Waypoints After Deselect
1. Load saved trip → deselect bằng long press
2. Add thêm nhiều waypoints
3. Save với tên mới
4. **Expected**: Saved trip gốc không bị thay đổi, trip mới được tạo

### Scenario 4: Create New Trip
1. Load saved trip
2. Click "Create New Trip" button
3. **Expected**: Flag reset, có thể tạo trip mới

## Files Changed
- `/lib/modules/my_trip_route/my_trip_route_provider.dart`
  - Added `_isViewingSavedTrip` flag
  - Added `_deselectSavedTrip()` method
  - Updated `onMapLongClick()` to check flag
  - Updated `addToTrip()` to check flag
  - Updated `loadTripMarkers()` to set flag
  - Updated `createNewTrip()` to reset flag
  - Updated `storageMyTrip()` to reset flag
  - Updated `deleteTripByName()` to reset flag
  - Updated `clearAllTrip()` to reset flag

## Notes
- Method `_deselectSavedTrip()` là private (bắt đầu với `_`) vì chỉ dùng nội bộ trong provider
- Callback mechanism tự động, không cần manual intervention từ UI
- Polyline removal là async để đảm bảo map controller ready
- New color được generate để phân biệt job mới với saved trip

