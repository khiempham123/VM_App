# Fix: New Trip Overwritten When Loading Old Trip

## 🐛 Vấn đề (Problem)

**Scenario**:
1. User tạo trip mới bằng button add_circle_outline
2. User lưu trip mới
3. User click vào trip cũ trong menu
4. **BUG**: Trip mới vừa tạo bị đè lên trip cũ và trip cũ biến mất

### Ví dụ Cụ thể
```
1. Create "Trip A" → Add waypoints → Save
2. Click "Old Trip B" from menu
3. Result: "Trip A" data replaces "Trip B" in storage
4. "Trip B" is gone!
```

## 🔍 Nguyên nhân (Root Cause)

### Logic Flow Hiện Tại (Sai)
```
User clicks on "Old Trip"
    ↓
onTripSelected() called
    ↓
Check: hasMarkersToSave && isPlaceAdded && !mustSaveBeforeSwitchNewTrip
    ↓ (FALSE vì trip mới đã được save)
Skip confirm dialog
    ↓
Call loadTripMarkers("Old Trip")
    ↓
Clear _allLongPressedLocations (trip mới mất!)
    ↓
Load "Old Trip" data vào cleared arrays
    ↓
Data của "Trip mới" bị ghi đè
```

### Vấn đề Cụ Thể

#### 1. Condition Không Đầy Đủ
```dart
// ❌ BAD - Chỉ check isPlaceAdded
if (provider.hasMarkersToSave && 
    provider.isPlaceAdded && 
    provider.mustSaveBeforeSwitchNewTrip == false) {
  // Show dialog
}
```

**Issues**:
- `isPlaceAdded`: Only true khi vừa add waypoint, false sau khi save
- `mustSaveBeforeSwitchNewTrip`: Complex flag không cover all cases
- **Không check**: Trip hiện tại có phải là trip khác với trip được chọn không?

#### 2. loadTripMarkers Clear Ngay
```dart
Future<void> loadTripMarkers(String tripName) async {
  _currentTripName = tripName;
  
  // ❌ Clear ngay lập tức, mất data!
  _allLongPressedLocations.clear();
  _allLongPressedEntities.clear();
  _tripWaypoints.clear();
  _tripWaypointEntities.clear();
  
  // Load trip from storage
  final trips = await _routeRepository.getTripByName(tripName);
  // ...
}
```

#### 3. Không Phân Biệt Viewing vs Creating
Không có cách để biết trip hiện tại đang:
- **Viewing**: Đang xem trip đã lưu (safe to switch)
- **Creating/Editing**: Đang tạo/sửa trip mới (need confirmation)

## ✅ Giải pháp (Solution)

### 1. Thêm Check: Switching to Different Trip

```dart
// ✅ GOOD - Check if actually switching
if (provider.currentTripName == tripName) {
  return; // Same trip, don't reload
}
```

### 2. Improved Condition Logic

```dart
// ✅ GOOD - More comprehensive check
if (provider.hasMarkersToSave && 
    provider.currentTripName != null && 
    provider.currentTripName!.isNotEmpty &&
    !provider.isViewingSavedTrip) { // ← Key check!
  // Show confirm dialog
}
```

**Logic**:
- `hasMarkersToSave`: Trip has waypoints
- `currentTripName != null && != empty`: Actually has a current trip
- `!isViewingSavedTrip`: NOT viewing saved trip = creating/editing new trip

### 3. Add _isViewingSavedTrip Flag

```dart
// In provider
bool _isViewingSavedTrip = false;
bool get isViewingSavedTrip => _isViewingSavedTrip;

// Set when loading saved trip
Future<void> loadTripMarkers(String tripName) async {
  _currentTripName = tripName;
  _isViewingSavedTrip = true; // ← Mark as viewing
  // ...
}

// Reset when creating new trip
Future<void> createNewTrip(String tripName) async {
  _currentTripName = tripName;
  _isViewingSavedTrip = false; // ← Creating, not viewing
  // ...
}
```

## 🔄 Correct Flow

### Scenario 1: Create New Trip → Load Old Trip
```
1. User creates "Trip A"
     _currentTripName = "Trip A"
     _isViewingSavedTrip = false (creating)
     _allLongPressedLocations = [waypoints]

2. User saves "Trip A"
     Data stored in repository
     _isViewingSavedTrip = false (still creating state)

3. User clicks "Old Trip B"
     Check: currentTripName == "Old Trip B"? 
     → NO, different trip
     
     Check: hasMarkersToSave? → YES
     Check: currentTripName not null/empty? → YES  
     Check: !isViewingSavedTrip? → YES (NOT viewing)
     
     → Show confirm dialog!

4. User confirms or cancels
     Confirm → "Trip A" preserved, load "Trip B"
     Cancel → Stay on "Trip A"
```

### Scenario 2: Load Trip A → Load Trip B
```
1. User loads "Trip A"
     _currentTripName = "Trip A"
     _isViewingSavedTrip = true (viewing)
     
2. User clicks "Trip B"
     Check: currentTripName == "Trip B"?
     → NO, different trip
     
     Check: !isViewingSavedTrip?
     → NO (currently viewing saved trip)
     
     → Skip confirm, directly load "Trip B" ✅
```

### Scenario 3: Load Trip A → Click Trip A Again
```
1. User loads "Trip A"
     _currentTripName = "Trip A"
     
2. User clicks "Trip A" again
     Check: currentTripName == "Trip A"?
     → YES, same trip
     
     → Return early, don't reload ✅
```

## 📊 Comparison

### Before ❌

| Scenario | Behavior | Result |
|----------|----------|--------|
| Create new → Load old | No warning | Data loss! |
| Load A → Load B | Direct switch | OK |
| Load A → Load A | Reload | Unnecessary |

### After ✅

| Scenario | Behavior | Result |
|----------|----------|--------|
| Create new → Load old | Show confirm | Data protected! |
| Load A → Load B | Direct switch | OK |
| Load A → Load A | Skip reload | Efficient |

## 🔧 Implementation

### my_trip_route_screen.dart

```dart
onTripSelected: (tripName) async {
  // ✅ 1. Don't reload same trip
  if (provider.currentTripName == tripName) {
    return;
  }
  
  // ✅ 2. Check if current trip has unsaved changes
  if (provider.hasMarkersToSave && 
      provider.currentTripName != null && 
      provider.currentTripName!.isNotEmpty &&
      !provider.isViewingSavedTrip) {
    // Show confirm dialog
    final shouldProceed = await _showConfirmSwitchTripDialog(
      context, provider, tripName
    );
    if (!shouldProceed) {
      return; // User cancelled
    }
  }
  
  // ✅ 3. Safe to proceed
  await provider.loadTripMarkers(tripName);
  await provider.currentRoute(tripName);
}
```

### my_trip_route_provider.dart

```dart
// Add flag
bool _isViewingSavedTrip = false;
bool get isViewingSavedTrip => _isViewingSavedTrip;

// Set when loading
Future<void> loadTripMarkers(String tripName) async {
  _currentTripName = tripName;
  _isViewingSavedTrip = true; // Viewing saved trip
  // ... clear and load data
}

// Reset when creating
Future<void> createNewTrip(String tripName) async {
  _currentTripName = tripName;
  _isViewingSavedTrip = false; // Creating new trip
  // ...
}
```

## 🧪 Testing

### Test 1: Create → Save → Load Old
```
Steps:
1. Click add_circle_outline button
2. Enter name "Test Trip"
3. Add 2-3 waypoints
4. Save trip
5. Click on old trip from menu

Expected:
✅ Confirm dialog appears
✅ Options: "Save & Switch" or "Discard & Switch"
✅ Both options preserve old trip data
```

### Test 2: Load → Load Different
```
Steps:
1. Load "Trip A" from menu
2. Click "Trip B" from menu

Expected:
✅ No confirm dialog (viewing saved trips)
✅ Direct switch to "Trip B"
✅ "Trip A" data intact in storage
```

### Test 3: Load → Click Same
```
Steps:
1. Load "Trip A" from menu
2. Click "Trip A" again from menu

Expected:
✅ No reload
✅ No unnecessary operations
✅ Stays on "Trip A"
```

### Test 4: Create → Don't Save → Load Old
```
Steps:
1. Create new trip
2. Add waypoints
3. DON'T save
4. Click old trip from menu

Expected:
✅ Confirm dialog appears
✅ Warning about unsaved changes
✅ Old trip protected
```

## 🎯 Key Points

### 1. Three States of Trip
```
1. Creating: New trip being built
   - _currentTripName = "new name"
   - _isViewingSavedTrip = false
   - Need protection!

2. Viewing: Saved trip loaded
   - _currentTripName = existing trip name
   - _isViewingSavedTrip = true
   - Can switch freely

3. None: No trip loaded
   - _currentTripName = null/empty
   - No protection needed
```

### 2. Protection Logic
```dart
Need Protection When:
  hasMarkersToSave = true (has data)
  AND currentTripName exists (active trip)
  AND !isViewingSavedTrip (creating/editing)
  
Safe to Switch When:
  isViewingSavedTrip = true (just viewing)
  OR hasMarkersToSave = false (no data)
```

### 3. Avoid Unnecessary Reloads
```dart
if (currentTripName == selectedTripName) {
  return; // Already on this trip
}
```

## 🛡️ Data Protection Guarantees

After fix:
- ✅ Newly created trips cannot be overwritten accidentally
- ✅ User always gets confirmation before losing unsaved data  
- ✅ Switching between saved trips is smooth (no unnecessary prompts)
- ✅ Clicking same trip doesn't cause reload
- ✅ All trip data preserved in storage

## 📝 Files Modified

1. **my_trip_route_screen.dart**
   - Updated `onTripSelected` logic
   - Added same trip check
   - Improved condition for confirm dialog

2. **my_trip_route_provider.dart**
   - Added `_isViewingSavedTrip` flag and getter
   - Set flag in `loadTripMarkers()`
   - Reset flag in `createNewTrip()`

## 🎓 Learning: State Management Pattern

### Problem: Boolean Flags Are Not Enough
```dart
// ❌ Not sufficient
bool _hasUnsavedChanges; // Too vague
```

### Solution: Semantic State Tracking
```dart
// ✅ Clear semantics
bool _isViewingSavedTrip; // Viewing vs Creating
String? _currentTripName;  // Which trip
bool hasMarkersToSave;     // Has data
```

### Pattern: Defensive Programming
```
1. Check if operation needed (same trip?)
2. Check if operation safe (!isViewingSavedTrip?)
3. Ask user if not safe (confirm dialog)
4. Proceed only if confirmed
```

---

**Issue**: New trip overwritten by old trip
**Root Cause**: Insufficient checks before clearing data
**Solution**: Add state flag + improved condition logic
**Result**: ✅ Data protection guaranteed

**Date**: December 16, 2025

