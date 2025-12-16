# Fix: Trip Replacement Issue When Saving and Switching

## Issue Description

When following this flow:
1. Load a saved trip
2. Create a new trip
3. Add routes to the trip
4. Switch to another saved trip (triggers confirm dialog)
5. Choose "Save and switch" in the dialog

**Expected Behavior:**
- Current trip should be saved and added to the trips menu
- Selected trip should be loaded and displayed
- Both trips should exist in the menu

**Actual Behavior (Before Fix):**
- The selected trip was replaced by the saved trip
- The saved trip was not properly added to the trip menu anchor
- Data was being cleared at the wrong time

## Root Cause Analysis

### Problem 1: Clearing Data After Saving
In `_showConfirmSwitchTripDialog`, when the user chose "Save":

```dart
} else if (result == 'saved') {
  // User saved the trip
  if (context.mounted) {
    showTopSnackBar(...);
  }
  await provider.clearUnsavedTripData();  // ❌ WRONG!
  return true; // Proceed to switch
}
```

The issue was that `clearUnsavedTripData()` was called immediately after saving, which:
1. Reset `_currentTripName = null`
2. Cleared all markers and polylines
3. Removed all trip data

This happened **before** the new trip was loaded, causing the saved trip data to be lost.

### Problem 2: storageMyTrip Not Awaited
The `storageMyTrip` method was declared as `void` but used `async/await` internally:

```dart
void storageMyTrip(String tripName) async {  // ❌ Should be Future<void>
  // ... async operations
  await _routeRepository.setMyRouteTrip(...);
  await loadSavedTripNames();
}
```

This meant:
- Calls to `storageMyTrip` couldn't be awaited
- The dialog could close before the trip was fully saved
- The trip list might not be updated when the UI needed it

### Problem 3: Incorrect Code Flow in Save Button
In the confirm dialog's save button:

```dart
onPressed: () async {
  final tripName = tripNameController.text.trim();
  if (tripName.isNotEmpty) {
    provider.storageMyTrip(tripName);  // Not awaited
    Navigator.of(dialogContext).pop('saved');
  }
  provider.mustSavedBeforeStartNewTrip();  // ❌ Called even if tripName is empty
}
```

Issues:
- `storageMyTrip` wasn't awaited
- `mustSavedBeforeStartNewTrip()` was called outside the if block
- Dialog closed before save operation completed

## Solution

### Fix 1: Remove Premature Data Clearing
```dart
} else if (result == 'saved') {
  // User saved the trip
  if (context.mounted) {
    showTopSnackBar(...);
  }
  // Don't clear data here - let loadTripMarkers handle clearing when loading the new trip
  return true; // Proceed to switch
}
```

**Why this works:**
- The saved trip data remains intact until the new trip is loaded
- `loadTripMarkers()` naturally clears and replaces data when loading the selected trip
- The saved trip is already added to the menu by `loadSavedTripNames()` in `storageMyTrip`

### Fix 2: Change storageMyTrip to Return Future<void>
In `my_trip_route_provider.dart`:

```dart
Future<void> storageMyTrip(String tripName) async {  // ✅ Now properly typed
  if (_allLongPressedEntities.isEmpty) return;

  final refIdList = _allLongPressedEntities.map((e) => e.refId).join('_');
  final newKey = 'trip_{$tripName}_${refIdList}_encodedPolyline_${_encodedPolyline}_color_$_currentRouteColor';
  
  // ... save logic ...
  
  await _routeRepository.setMyRouteTrip(_allLongPressedEntities, newKey);
  _currentTripName = newKey;
  _isViewingSavedTrip = true;
  await loadSavedTripNames();  // Refresh trip list
  notifyListeners();
}
```

### Fix 3: Properly Await storageMyTrip Calls

**In the confirm switch dialog:**
```dart
onPressed: () async {
  final tripName = tripNameController.text.trim();
  if (tripName.isNotEmpty) {
    await provider.storageMyTrip(tripName);  // ✅ Now awaited
    provider.mustSavedBeforeStartNewTrip();
    Navigator.of(dialogContext).pop('saved');
  }
}
```

**In the regular save dialog:**
```dart
onPressed: () async {
  final tripName = tripNameController.text.trim();
  if (tripName.isNotEmpty) {
    await provider.storageMyTrip(tripName);  // ✅ Now awaited
    if (context.mounted) {
      Navigator.of(dialogContext).pop();
      showTopSnackBar(...);
    }
  }
}
```

## Flow After Fix

1. User selects a different trip from menu
2. If current trip has unsaved changes, show confirm dialog
3. User chooses "Save and switch":
   - Save current trip (adds to menu via `loadSavedTripNames()`)
   - Close dialog and return `true`
   - `onTripSelected` continues and calls `loadTripMarkers(selectedTripName)`
   - `loadTripMarkers` clears old data and loads the selected trip
   - Both trips now exist in the menu

## Files Modified

1. `/lib/modules/my_trip_route/my_trip_route_screen.dart`
   - Removed `clearUnsavedTripData()` call after saving
   - Added `await` to `storageMyTrip()` calls
   - Fixed save button logic flow

2. `/lib/modules/my_trip_route/my_trip_route_provider.dart`
   - Changed `void storageMyTrip(...)` to `Future<void> storageMyTrip(...)`

## Testing Recommendations

1. **Test Save and Switch Flow:**
   - Create a new trip with waypoints
   - Click on another saved trip
   - Choose "Save and switch"
   - Verify both trips appear in menu
   - Verify selected trip is loaded correctly

2. **Test Save Without Switch:**
   - Create a new trip with waypoints
   - Save using the save button
   - Verify trip appears in menu
   - Verify current trip remains displayed

3. **Test Discard Flow:**
   - Create a new trip with waypoints
   - Click on another saved trip
   - Choose "Discard"
   - Verify unsaved data is cleared
   - Verify selected trip loads correctly

4. **Test Empty Trip Name:**
   - Try to save with empty trip name
   - Verify dialog doesn't close
   - Verify no errors occur

## Related Issues

This fix also addresses potential race conditions where:
- UI updates before data is saved
- Trip list is accessed before refresh completes
- Multiple async operations compete for state updates

