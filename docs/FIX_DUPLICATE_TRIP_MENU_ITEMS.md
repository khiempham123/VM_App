# Fix: Duplicate Trip Menu Items Issue

## Issue Description (Vietnamese)
Khi có 3 items trong menu anchor, tạo 1 new trip → add routes → save → switch sang 1 trong 3 items cũ, thì số lượng items trong menu bây giờ là 4 thay vì 3.

## Issue Description (English)
When there are 3 items in the trip menu, if the user:
1. Creates a new trip
2. Adds routes to it
3. Saves the trip
4. Switches to one of the 3 existing trips

The menu shows 4 items instead of properly managing the trip count. The issue was related to improper tracking of the original trip key.

## Root Cause Analysis

### Problem: _originalKey Not Being Cleared

When loading a saved trip, `_originalKey` and `_originalTripWaypointEntities` are set to track the original state:

```dart
// In loadTripMarkers()
_originalTripWaypointEntities = trips;
_originalKey = tripName;
```

However, when creating a new trip or clearing data, these variables were **NOT** being reset. This caused issues in `storageMyTrip`:

```dart
Future<void> storageMyTrip(String tripName) async {
  final newKey = 'trip_{$tripName}_${refIdList}_...';
  
  // This check would use stale _originalKey from a previously loaded trip!
  if(_originalKey != newKey && _originalTripWaypointEntities != _allLongPressedEntities) {
    _routeRepository.deleteTripByName(_originalKey);  // ❌ Might delete wrong trip
  }
  
  await _routeRepository.setMyRouteTrip(_allLongPressedEntities, newKey);
  // ...
}
```

### Problematic Scenario

**Before Fix:**
1. User loads Trip A → `_originalKey = "trip_{A}_..."`
2. User creates new trip → `clearAllTrip()` is called
   - Clears waypoints and locations
   - **But `_originalKey` still = "trip_{A}_..."**
3. User adds waypoints to new trip
4. User saves as "My New Trip" → creates `newKey = "trip_{My New Trip}_..."`
5. Check condition:
   - `_originalKey != newKey` → `"trip_{A}_..." != "trip_{My New Trip}_..."` → **TRUE**
   - `_originalTripWaypointEntities != _allLongPressedEntities` → **TRUE** (different waypoints)
6. → **Calls `deleteTripByName("trip_{A}_...")` → DELETES TRIP A!**
7. → Saves "My New Trip"
8. Result: Menu has original trips minus A, plus new trip

Depending on timing and conditions, this could lead to:
- Unexpected deletion of previously loaded trips
- Confusion about which trip is which
- Duplicate or missing trips in the menu

## Solution

### Fix 1: Clear _originalKey in clearAllTrip()

```dart
void clearAllTrip() {
  _tripWaypoints.clear();
  _tripWaypointEntities.clear();
  _allLongPressedEntities.clear();
  _allLongPressedLocations.clear();
  // Clear original trip tracking to prevent incorrect deletions
  _originalKey = '';  // ✅ Added
  _originalTripWaypointEntities.clear();  // ✅ Added
  if(_currentTripRouteLine != null) {
    _vietmapController?.removePolyline(_currentTripRouteLine!);
    notifyListeners();
  }
  notifyListeners();
}
```

### Fix 2: Clear _originalKey in clearUnsavedTripData()

```dart
Future<void> clearUnsavedTripData() async {
  // ... existing clear logic ...
  
  // Reset current trip name
  _currentTripName = null;
  _isOnMyLocation = false;
  // Clear original trip tracking
  _originalKey = '';  // ✅ Added
  _originalTripWaypointEntities.clear();  // ✅ Added
  notifyListeners();
  debugPrint('Cleared all unsaved trip data');
}
```

## How It Works Now

**After Fix:**
1. User loads Trip A → `_originalKey = "trip_{A}_..."`
2. User creates new trip → `clearAllTrip()` is called
   - Clears waypoints and locations
   - **Now also clears `_originalKey = ''`** ✅
   - **Clears `_originalTripWaypointEntities`** ✅
3. User adds waypoints to new trip
4. User saves as "My New Trip" → creates `newKey = "trip_{My New Trip}_..."`
5. Check condition:
   - `_originalKey != newKey` → `'' != 'trip_{My New Trip}_...'` → **TRUE**
   - `_originalTripWaypointEntities != _allLongPressedEntities` → `[] != [waypoints]` → **TRUE**
6. → Calls `deleteTripByName('')` → **Does nothing** (empty key) ✅
7. → Saves "My New Trip"
8. Result: Menu correctly shows original 3 trips + new trip = 4 trips

When switching to Trip B:
- `loadTripMarkers(B)` loads Trip B correctly
- Menu shows: A, B, C, My New Trip (4 items as expected)

## Related Fixes from Previous Session

This fix builds upon previous fixes:

1. **Changed `storageMyTrip` from `void` to `Future<void>`**
   - Allows proper awaiting of save operations
   - Ensures trip list is refreshed before UI updates

2. **Removed premature `clearUnsavedTripData()` call after saving**
   - Previously cleared data immediately after save
   - Now lets `loadTripMarkers()` handle clearing when loading new trip
   - Prevents saved trip from being lost before switch

3. **Fixed save button logic in confirm dialog**
   - Added `await` to `storageMyTrip()` call
   - Moved `mustSavedBeforeStartNewTrip()` inside the save condition
   - Ensures dialog only closes after save completes

## Files Modified

1. `/lib/modules/my_trip_route/my_trip_route_provider.dart`
   - Modified `clearAllTrip()` to clear `_originalKey` and `_originalTripWaypointEntities`
   - Modified `clearUnsavedTripData()` to clear `_originalKey` and `_originalTripWaypointEntities`
   - Changed `storageMyTrip()` return type from `void` to `Future<void>` (from previous fix)

2. `/lib/modules/my_trip_route/my_trip_route_screen.dart` (from previous fixes)
   - Removed `clearUnsavedTripData()` after save in switch dialog
   - Added `await` to `storageMyTrip()` calls
   - Fixed save button logic

## Testing Scenarios

### Scenario 1: Create New Trip with Existing Trips
1. Have 3 existing trips (A, B, C) in menu
2. Click "Create new trip" button
3. Add waypoints
4. Click on Trip B (triggers confirm dialog)
5. Choose "Save and switch", name it "Trip D"
6. **Expected:** Menu shows A, B, C, D (4 items)
7. **Expected:** Trip D is saved and added to menu
8. **Expected:** Trip B is loaded and displayed
9. **Expected:** No trips are deleted

### Scenario 2: Create New Trip After Loading One
1. Have 3 existing trips (A, B, C) in menu
2. Load Trip A (click on it)
3. Click "Create new trip" button
4. Add waypoints
5. Click on Trip B (triggers confirm dialog)
6. Choose "Save and switch", name it "Trip D"
7. **Expected:** Menu shows A, B, C, D (4 items)
8. **Expected:** Trip A is NOT deleted
9. **Expected:** Trip D is saved correctly
10. **Expected:** Trip B is loaded

### Scenario 3: Discard New Trip
1. Have 3 existing trips
2. Create new trip and add waypoints
3. Click on existing trip
4. Choose "Discard"
5. **Expected:** Menu still shows 3 trips (no new trip added)
6. **Expected:** Selected trip loads correctly

### Scenario 4: Update Existing Trip
1. Load Trip A
2. Add more waypoints
3. Save (without changing name)
4. **Expected:** Trip A is updated (old key deleted, new key saved)
5. **Expected:** Menu still shows same number of trips
6. **Expected:** Trip A shows updated waypoints when loaded again

## Technical Notes

### About _originalKey and _originalTripWaypointEntities

These variables track the original state when a trip is loaded from storage:

- **Purpose:** Detect when a trip has been modified and needs to update/delete the old key
- **Set in:** `loadTripMarkers()` when loading a saved trip
- **Should be cleared when:**
  - Creating a new trip
  - Discarding unsaved changes
  - Switching to a different trip (before loading)

### Trip Key Format

Trips are stored with a composite key:
```
trip_{TripName}_{refId1_refId2_...}_encodedPolyline_{polyline}_color_{color}
```

This means:
- Same trip name + different waypoints = different key
- Updating waypoints creates a new key
- Old key should be deleted to avoid duplicates

### Deletion Logic

The deletion logic in `storageMyTrip`:
```dart
if(_originalKey != newKey && _originalTripWaypointEntities != _allLongPressedEntities) {
  _routeRepository.deleteTripByName(_originalKey);
}
```

This ensures:
- Old key is only deleted if creating a new key (rename or waypoint change)
- Empty `_originalKey` won't delete anything
- Prevents accidental deletion of unrelated trips

