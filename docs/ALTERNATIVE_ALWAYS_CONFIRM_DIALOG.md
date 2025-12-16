# Alternative Solution: Always Show Confirm Dialog

Nếu user muốn dialog xuất hiện **MỌI LÚC** khi switch trips (kể cả saved trips), thay đổi condition như sau:

## In my_trip_route_screen.dart

```dart
onTripSelected: (tripName) async {
  // Don't reload if clicking on the same trip
  if (provider.currentTripName == tripName) {
    return;
  }
  
  // ✅ OPTION B: Show dialog whenever switching trips with data
  if (provider.hasMarkersToSave &&
      provider.currentTripName != null &&
      provider.currentTripName!.isNotEmpty) {
    // Always ask when switching away from a trip with data
    debugPrint('Switching trips. Showing confirm dialog.');
    final shouldProceed = await _showConfirmSwitchTripDialog(context, provider, tripName);
    if (!shouldProceed) {
      return;
    }
  }
  
  // Proceed to load the selected trip
  await provider.loadTripMarkers(tripName);
  await provider.currentRoute(tripName);
}
```

**Key Change**: Remove `!provider.isViewingSavedTrip` check
→ Dialog shows for ANY switch if current trip has data

## Comparison

| Condition | Option A (Smart) | Option B (Always) |
|-----------|------------------|-------------------|
| `hasMarkersToSave` | ✓ | ✓ |
| `currentTripName != null` | ✓ | ✓ |
| `currentTripName != empty` | ✓ | ✓ |
| `!isViewingSavedTrip` | ✓ | ✗ (removed) |

## Behavior Difference

| Scenario | Option A | Option B |
|----------|----------|----------|
| Unsaved → Load | Dialog | Dialog |
| Saved → Load | No dialog | Dialog |
| Create → Save → Load | No dialog | Dialog |

Choose Option B if you want maximum data protection!

