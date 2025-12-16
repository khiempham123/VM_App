# Testing Guide: Trip Management Features

## Preparation
1. Build và run app trên simulator/device
2. Navigate đến My Trip Route screen
3. Ensure có ít nhất 2-3 saved trips trong storage

---

## Test 1: Polyline Display Fix

### Objective
Verify rằng polyline được hiển thị đúng khi load saved trip, không có GNU artifact.

### Steps
1. Open "Your trip" dropdown menu
2. Chọn một saved trip
3. Observe polyline trên map

### Expected Results
✅ Polyline hiển thị đúng route từ điểm đầu đến điểm cuối
✅ KHÔNG có đường lạc/artifact ở cuối route
✅ Màu sắc của polyline hiển thị đúng
✅ Route path mượt mà, không có điểm lạ

### Debug
- Check console logs: `Extracted polyline:` và `Extracted color:`
- Polyline string không nên chứa `_color_` prefix

---

## Test 2: Trip Selection Visual Indicator

### Objective
Verify visual indicator cho trip được chọn.

### Steps
1. Open "Your trip" dropdown
2. Note: trip hiện tại được chọn (nếu có)
3. Observe styling của các trips trong list

### Expected Results

#### Selected Trip:
✅ Background color: Light blue/teal tint
✅ Border: Visible border với primary color
✅ Icon: Filled route icon (solid)
✅ Text: Bold (semi-bold) với primary color

#### Unselected Trips:
✅ Background: White
✅ No border
✅ Icon: Outlined route icon
✅ Text: Normal weight với black color

### Visual Comparison
```
Selected:    [🗺️ Trip 1]  <- Highlighted
Unselected:   🗺  Trip 2
Unselected:   🗺  Trip 3
```

---

## Test 3: Auto-Deselect via Long Press

### Objective
Verify saved trip tự động deselect khi user long press để thêm waypoint mới.

### Steps
1. Load một saved trip (e.g., "Trip 1")
2. Wait for polyline to display
3. Note the polyline color và position
4. Long press on map tại một location mới
5. Observe bottom sheet xuất hiện
6. Click "Add to Trip" button

### Expected Results
✅ **Before long press**: Saved trip polyline visible trên map
✅ **After long press**: Saved trip polyline disappears
✅ **After add to trip**: New waypoint marker xuất hiện
✅ **Current trip name**: Reset hoặc becomes new trip
✅ **Trip dropdown**: Selected trip indicator không còn

### Console Logs
```
Deselecting saved trip: trip_{Trip 1}_...
```

---

## Test 4: Auto-Deselect via Search Place

### Objective
Verify saved trip deselect khi thêm place từ search.

### Steps
1. Load một saved trip
2. Use search bar để tìm một địa điểm
3. Select địa điểm từ suggestions
4. Map moves to location
5. Long press tại location đó
6. Click "Add to Trip"

### Expected Results
✅ Saved trip polyline disappears sau khi add to trip
✅ New job started với new color
✅ Original saved trip không bị modify

---

## Test 5: Create New Trip

### Objective
Verify creating new trip resets viewing state.

### Steps
1. Load một saved trip
2. Click "Create New Trip" button (if exists) or navigate to create trip
3. Enter new trip name
4. Add waypoints
5. Save trip

### Expected Results
✅ Flag `_isViewingSavedTrip` = false
✅ Có thể tạo trip mới mà không ảnh hưởng saved trip
✅ New trip có color khác với saved trip

---

## Test 6: Data Integrity Check

### Objective
Verify saved trips không bị overwrite khi tạo job mới.

### Steps
1. Load "Trip A" (có 3 waypoints)
2. Note số waypoints và route
3. Long press để add waypoint mới
4. Add waypoint to trip
5. Save as "Trip B"
6. Load lại "Trip A"

### Expected Results
✅ "Trip A" vẫn có đúng 3 waypoints ban đầu
✅ "Trip A" route không thay đổi
✅ "Trip B" được tạo mới với 4 waypoints
✅ Cả 2 trips tồn tại độc lập

---

## Test 7: Multiple Operations

### Objective
Test multiple operations liên tiếp.

### Steps
1. Load "Trip 1"
2. Long press → deselect
3. Add 2 waypoints
4. Save as "Trip 2"
5. Load "Trip 2"
6. Delete "Trip 2"
7. Create new trip "Trip 3"
8. Add 3 waypoints
9. Save

### Expected Results
✅ Mỗi operation hoạt động đúng
✅ No crashes or errors
✅ State management consistent
✅ Visual indicators update correctly

---

## Test 8: Edge Cases

### Test 8A: Empty Trips List
- Start với no saved trips
- Create first trip
- Expected: Works normally

### Test 8B: Rapid Selection Changes
- Quickly switch between different saved trips
- Expected: Each trip loads correctly với correct polyline

### Test 8C: Delete Current Trip
- Load a trip
- Delete that trip
- Expected: Trip deselect, polyline removed, no errors

### Test 8D: Long Press Without Adding
- Load saved trip
- Long press on map
- Close bottom sheet without adding
- Expected: Saved trip remains selected (không deselect nếu không add)

**Note**: Hiện tại implementation deselect ngay khi long press. Nếu muốn chỉ deselect khi user confirm add, cần adjust logic.

---

## Common Issues & Solutions

### Issue 1: Polyline vẫn có artifact
**Solution**: Check `_drawRouteForTripLoaded` method, verify substring logic

### Issue 2: Visual indicator không update
**Solution**: Verify `provider.currentTripName` được set đúng, check notifyListeners()

### Issue 3: Saved trip bị overwrite
**Solution**: Check `_isViewingSavedTrip` flag, verify `_deselectSavedTrip()` được gọi

### Issue 4: Multiple polylines trên map
**Solution**: Check polyline cleanup trong `_deselectSavedTrip()`

---

## Performance Check

Monitor these metrics:
- [ ] Map rendering smooth (no lag)
- [ ] Trip loading time < 1 second
- [ ] Polyline draw time < 500ms
- [ ] No memory leaks khi switch trips nhiều lần
- [ ] Console không có excessive debug logs

---

## Acceptance Criteria

### All Tests Must Pass
- ✅ Polyline displays correctly without artifacts
- ✅ Visual indicator shows selected trip
- ✅ Auto-deselect works on long press
- ✅ Auto-deselect works on add to trip
- ✅ Saved trips data integrity maintained
- ✅ No crashes or errors
- ✅ Smooth user experience

### Optional Enhancements
- [ ] Add confirmation dialog before deselect
- [ ] Add undo functionality
- [ ] Add animation for transitions
- [ ] Add toast notifications

---

## Report Issues

If any test fails, document:
1. Test number và name
2. Steps to reproduce
3. Expected vs actual result
4. Screenshots/screen recording
5. Console logs
6. Device/simulator info

---

## Sign-off

Tester: ___________________
Date: ___________________
Status: [ ] Pass [ ] Fail
Notes: ___________________

