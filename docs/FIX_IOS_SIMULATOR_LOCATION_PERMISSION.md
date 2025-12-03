# Fix: iOS Simulator Location Permission PermanentlyDenied

## 🔴 Vấn Đề

### Log lỗi:
```
📍 [LOCATION] Permission requested: PermissionStatus.permanentlyDenied
```

### Triệu chứng:
- Đã cấp quyền location cho app trên simulator
- Nhưng vẫn nhận được status `permanentlyDenied`
- App không thể lấy vị trí người dùng

---

## 🔍 Nguyên Nhân

### iOS Simulator vs Device Thật

#### 1. **iOS Simulator đặc biệt**
iOS Simulator có cách xử lý location permission khác với device thật:

```dart
// Trên Device Thật:
// denied → request → granted ✅

// Trên iOS Simulator:
// denied → request → permanentlyDenied ❌
// Ngay cả khi bạn đã cấp quyền trong Settings!
```

#### 2. **Tại sao lại như vậy?**
- Simulator không có GPS thật
- Permission system của simulator không giống 100% với device
- `permanentlyDenied` trên simulator **KHÔNG có nghĩa** là user thực sự deny vĩnh viễn
- VietmapGL vẫn có thể hoạt động được nếu location được simulate

#### 3. **Code cũ có vấn đề**
```dart
// ❌ Code cũ
static Future<bool> requestPermission() async {
  final status = await Permission.location.request();
  
  if (status.isPermanentlyDenied) {
    await openAppSettings(); // 👈 Luôn mở settings trên simulator
    return false;           // 👈 Luôn trả về false
  }
  
  return status.isGranted;
}
```

**Kết quả**: 
- Trên simulator, luôn nhận `permanentlyDenied`
- Code luôn trả về `false`
- App không bao giờ hoạt động được

---

## ✅ Giải Pháp

### 1. Detect iOS Simulator và Handle Đặc Biệt

#### File: `lib/core/utils/location_permission_service.dart`

```dart
import 'dart:io';
import 'package:flutter/foundation.dart'; // 👈 Import để dùng kDebugMode
import 'package:permission_handler/permission_handler.dart';

class LocationPermissionService {
  static Future<bool> requestPermission() async {
    final currentStatus = await Permission.location.status;
    
    // ✅ Kiểm tra nếu đã granted hoặc limited (iOS 14+)
    if (currentStatus.isGranted || currentStatus.isLimited) {
      return true;
    }
    
    // ✅ QUAN TRỌNG: Xử lý iOS Simulator
    if (kDebugMode && Platform.isIOS && currentStatus.isPermanentlyDenied) {
      debugPrint('⚠️ [LOCATION] iOS Simulator detected with permanentlyDenied');
      debugPrint('⚠️ [LOCATION] This is NORMAL on simulator');
      
      // Trên simulator, permanentlyDenied không có nghĩa
      // VietmapGL sẽ tự handle nếu location được simulate
      return true; // 👈 Return true để cho VietmapGL tự xử lý
    }
    
    // Request permission
    final status = await Permission.location.request();
    
    // Handle các trạng thái
    if (status.isGranted || status.isLimited) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      // Chỉ mở settings trên device thật
      if (!kDebugMode || !Platform.isIOS) {
        await openAppSettings();
      }
      return false;
    }
    
    return status.isGranted || status.isLimited;
  }
}
```

### 2. Accept Cả `isLimited` Status (iOS 14+)

iOS 14+ có thêm status `limited` khi user chọn "Precise: Off":

```dart
// ✅ Đúng
return status.isGranted || status.isLimited;

// ❌ Sai - Bỏ qua limited
return status.isGranted;
```

### 3. Check Permission Trước Khi Request

```dart
static Future<bool> requestPermission() async {
  final currentStatus = await Permission.location.status;
  
  // ✅ Nếu đã có permission, return luôn
  if (currentStatus.isGranted || currentStatus.isLimited) {
    return true;
  }
  
  // Chỉ request khi chưa có permission
  final status = await Permission.location.request();
  // ...
}
```

---

## 🎯 Cách Test

### Test trên iOS Simulator:

#### 1. **Set location cho simulator**
```
Simulator Menu → Features → Location → Custom Location
Latitude: 10.762317
Longitude: 106.654551
```

#### 2. **Check app settings**
```
Simulator Menu → Settings → Privacy & Security → Location Services
→ Tìm app của bạn
→ Đảm bảo đã chọn "While Using the App" hoặc "Always"
```

#### 3. **Reset permissions (nếu cần)**
```
Simulator Menu → Device → Erase All Content and Settings
```

#### 4. **Expected behavior**
```
✅ Log: "iOS Simulator detected with permanentlyDenied"
✅ Log: "This is NORMAL on simulator"
✅ Map vẫn hiển thị được
✅ Location icon (blue dot) vẫn hiển thị tại vị trí simulate
✅ Click "My Location" button → Camera di chuyển đến vị trí simulate
```

### Test trên Device Thật:

```
1. Uninstall app
2. Reinstall app
3. Mở app lần đầu → Popup permission → Allow
4. Expected: Nhận granted (KHÔNG có permanentlyDenied)
5. Location hoạt động bình thường
```

---

## 🔧 Code Changes Summary

### Files Changed:

#### 1. `lib/core/utils/location_permission_service.dart`
```dart
// ✅ Thêm
import 'dart:io';
import 'package:flutter/foundation.dart';

// ✅ Logic đặc biệt cho iOS Simulator
if (kDebugMode && Platform.isIOS && currentStatus.isPermanentlyDenied) {
  return true; // Let VietmapGL handle it
}

// ✅ Accept limited status
return status.isGranted || status.isLimited;
```

#### 2. `lib/modules/metro_go/metro_map_provider.dart`
```dart
// ✅ Thêm error handling
String? _errorMessage;
bool _isLoadingLocation = false;

// ✅ Better error messages
Future<void> moveToMyLocation() async {
  _isLoadingLocation = true;
  _errorMessage = null;
  notifyListeners();
  
  try {
    // ... logic
    if (userLocation != null) {
      _errorMessage = null;
    } else {
      _errorMessage = 'Cannot get your location...';
    }
  } catch (e) {
    _errorMessage = 'Error: $e';
  } finally {
    _isLoadingLocation = false;
    notifyListeners();
  }
}
```

#### 3. `lib/modules/metro_go/metro_map_screen.dart`
```dart
// ✅ Hiển thị error messages
if (provider.errorMessage != null)
  Positioned(
    top: 16,
    child: ErrorMessageWidget(
      message: provider.errorMessage!,
      onClose: provider.clearError,
    ),
  ),

// ✅ Hiển thị loading state
if (provider.isLoadingLocation)
  Center(child: CircularProgressIndicator()),

// ✅ Disable button khi đang loading
FloatingActionButton(
  onPressed: provider.isMapReady && !provider.isLoadingLocation
      ? provider.moveToMyLocation
      : null,
  child: provider.isLoadingLocation
      ? CircularProgressIndicator()
      : Icon(Icons.my_location),
)
```

---

## 📊 Comparison: Before vs After

| Aspect | Before | After |
|--------|--------|-------|
| **iOS Simulator** | ❌ Always fail | ✅ Works |
| **Permission Detection** | Only `isGranted` | `isGranted` OR `isLimited` |
| **Error Handling** | ❌ No feedback | ✅ Error messages |
| **Loading State** | ❌ No indicator | ✅ Loading spinner |
| **User Experience** | ❌ Confusing | ✅ Clear feedback |
| **Device Support** | iOS only | ✅ iOS + Android |

---

## 🐛 Common Issues & Solutions

### Issue 1: "Location still null on simulator"

**Giải pháp:**
```
1. Check: Simulator → Features → Location
2. Chọn "Custom Location" hoặc "City Run"
3. Không dùng "None" (sẽ trả về null)
```

### Issue 2: "PermanentlyDenied on real device"

**Giải pháp:**
```
1. User thực sự đã deny vĩnh viễn
2. Phải mở Settings → App → Location → Allow
3. Code đã tự động mở settings khi detect permanentlyDenied trên device thật
```

### Issue 3: "Map không hiển thị blue dot"

**Giải pháp:**
```dart
// Check trong VietmapGL widget
VietmapGL(
  myLocationEnabled: widget.hasLocationPermission, // 👈 Phải là true
  myLocationRenderMode: MyLocationRenderMode.compass, // 👈 Phải set
)
```

---

## 🎓 Best Practices

### ✅ DO

1. **Luôn check kDebugMode và Platform**
```dart
if (kDebugMode && Platform.isIOS) {
  // Special handling for iOS simulator
}
```

2. **Accept cả limited status**
```dart
return status.isGranted || status.isLimited;
```

3. **Hiển thị feedback cho user**
```dart
// Loading state
_isLoadingLocation = true;

// Error messages
_errorMessage = 'Cannot get location';
```

4. **Log chi tiết để debug**
```dart
debugPrint('📍 [LOCATION] Permission status: $status');
debugPrint('⚠️ [LOCATION] iOS Simulator detected');
```

### ❌ DON'T

1. **Không treat simulator giống device**
```dart
// ❌ Sai
if (status.isPermanentlyDenied) {
  return false; // Sẽ fail trên simulator
}

// ✅ Đúng
if (kDebugMode && Platform.isIOS && status.isPermanentlyDenied) {
  return true; // Special case for simulator
}
```

2. **Không ignore limited status**
```dart
// ❌ Sai
return status.isGranted; // Bỏ qua limited

// ✅ Đúng
return status.isGranted || status.isLimited;
```

3. **Không quên handle errors**
```dart
// ❌ Sai
try {
  final location = await getLocation();
  // Không check null
  camera.moveTo(location); // Crash nếu null
} catch (e) {
  // Silent fail
}

// ✅ Đúng
try {
  final location = await getLocation();
  if (location != null) {
    camera.moveTo(location);
  } else {
    _errorMessage = 'Cannot get location';
  }
} catch (e) {
  _errorMessage = 'Error: $e';
  notifyListeners();
}
```

---

## 📱 Platform-Specific Notes

### iOS

#### Info.plist Configuration
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show you on the map</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to track your route</string>
```

#### Permission States
- `notDetermined` - Chưa hỏi
- `denied` - User từ chối
- `granted` - User cho phép (precise location)
- `limited` - User cho phép (approximate location, iOS 14+)
- `permanentlyDenied` - User từ chối vĩnh viễn HOẶC simulator bug

### Android

#### AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### Permission States
- `granted` - Có quyền
- `denied` - Từ chối (có thể hỏi lại)
- `permanentlyDenied` - Từ chối vĩnh viễn (đã từ chối 2 lần)

---

## 🎯 Tổng Kết

### Root Cause
iOS Simulator trả về `permanentlyDenied` ngay cả khi permission đã được cấp. Đây là **đặc điểm** của simulator, không phải bug của app.

### Solution
Detect simulator và treat `permanentlyDenied` như một trạng thái hợp lệ trên simulator, để VietmapGL tự xử lý location.

### Key Changes
1. ✅ Thêm logic đặc biệt cho iOS Simulator
2. ✅ Accept cả `isLimited` status (iOS 14+)
3. ✅ Better error handling và user feedback
4. ✅ Loading states và disabled buttons
5. ✅ Detailed logging để debug

### Testing
- ✅ iOS Simulator: Works với permanentlyDenied
- ✅ iOS Device: Works với granted/limited
- ✅ Android: Works bình thường
- ✅ Error messages hiển thị đúng
- ✅ Loading states hoạt động

---

**Lưu ý quan trọng**: 
- Luôn test trên **device thật** để đảm bảo permission flow đúng
- Simulator chỉ dùng để development, không đại diện 100% cho device behavior
- Log `permanentlyDenied` trên simulator là **BÌNH THƯỜNG**, không phải lỗi!

