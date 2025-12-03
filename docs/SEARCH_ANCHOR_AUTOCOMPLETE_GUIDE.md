# Hướng Dẫn Implement SearchAnchor Với Autocomplete - Metro Map Screen

## 📋 Tổng Quan Tính Năng

**Flow Logic:**
1. Người dùng nhập ký tự vào search field
2. Gọi API autocomplete (từ Vietmap) với query text
3. Nhận danh sách `List<PlaceDtoResponse>`
4. Hiển thị danh sách gợi ý trong SearchAnchor dùng trường `display`
5. Khi user click vào 1 gợi ý → Gọi API place detail với `ref_id`
6. Nhận lat/lng từ place detail → Vẽ marker trên map

---

## 🏗️ Kiến Trúc Code (Tuân Theo Clean Architecture)

### **Layer Phân Chia:**

```
┌─────────────────────────────────────────────┐
│  UI Layer (metro_map_screen.dart)           │
│  - SearchAnchor widget                      │
│  - Call provider methods                    │
└─────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────┐
│  Provider Layer (metro_map_provider.dart)   │
│  - Quản lý state: searchQuery, suggestions, │
│    selectedPlace, isLoading                 │
│  - Gọi repository methods                   │
└─────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────┐
│  Domain Layer (metro_map_repository.dart)   │
│  - Interface: searchPlaces(), getPlaceDetails()│
└─────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────┐
│  Data Layer (MetroMapRepositoryImpl)         │
│  - Gọi MetroMapService                      │
│  - Chuyển đổi DTO → Entity                  │
└─────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────┐
│  Service Layer (metro_map_service.dart)     │
│  - Retrofit API calls                       │
│  - /api/search/v4 (autocomplete)            │
│  - /api/place/v4 (place details)            │
└─────────────────────────────────────────────┘
```

---

## 📝 Chi Tiết Các Bước Implement

### **BƯỚC 1: Cập Nhật MetroMapProvider**

**Thêm các state properties:**
- `_searchQuery`: String để lưu giá trị search hiện tại
- `_searchSuggestions`: List<PlaceEntity> lưu danh sách gợi ý
- `_isSearching`: bool để show loading indicator khi đang gọi API
- `_selectedPlace`: PlaceEntity? để lưu địa điểm được chọn
- `_selectedPlaceDetails`: PlaceDetailEntity? để lưu chi tiết (lat/lng)

**Thêm các method:**
1. `onSearchChanged(String query)` - Gọi khi user nhập ký tự
   - Nếu query trống → Clear suggestions
   - Nếu query có nội dung → Gọi `repository.searchPlaces()`
   - Update `_searchSuggestions` khi API return
   - Set `_isSearching = false`

2. `onSuggestionSelected(PlaceEntity place)` - Gọi khi user click gợi ý
   - Lưu `_selectedPlace = place`
   - Gọi `repository.getPlaceDetails(place.refId)`
   - Nhận `PlaceDetailEntity` chứa lat/lng
   - Lưu `_selectedPlaceDetails`
   - Gọi `_vietmapController.moveCamera()` để pan map đến vị trí
   - Vẽ marker tại vị trí lat/lng

3. `clearSearch()` - Clear tất cả state liên quan search
   - `_searchQuery = ""`
   - `_searchSuggestions = []`
   - `_selectedPlace = null`
   - `notifyListeners()`

**Pseudo-code Structure:**
```dart
class MetroMapProvider extends ChangeNotifier {
  // ...existing code...
  
  String _searchQuery = "";
  List<PlaceEntity> _searchSuggestions = [];
  bool _isSearching = false;
  PlaceEntity? _selectedPlace;
  PlaceDetailEntity? _selectedPlaceDetails;
  
  // Getters
  String get searchQuery => _searchQuery;
  List<PlaceEntity> get searchSuggestions => _searchSuggestions;
  bool get isSearching => _isSearching;
  PlaceEntity? get selectedPlace => _selectedPlace;
  PlaceDetailEntity? get selectedPlaceDetails => _selectedPlaceDetails;
  
  // Methods
  Future<void> onSearchChanged(String query) async {
    // Xử lý search logic
  }
  
  Future<void> onSuggestionSelected(PlaceEntity place) async {
    // Xử lý click gợi ý logic
  }
  
  void clearSearch() {
    // Clear state
  }
}
```

---

### **BƯỚC 2: Implement SearchAnchor Trong UI**

**Cấu Trúc SearchAnchor:**

```dart
SearchAnchor(
  builder: (context, controller) {
    // Build searchfield input
  },
  suggestionsBuilder: (context, controller) {
    // Build suggestions list
  },
)
```

**Builder (Input Field):**
- Tạo `SearchBar` hoặc `TextField` cho user nhập text
- Lắng nghe `onChanged` event
- Gọi `provider.onSearchChanged(value)` khi user nhập
- Hiển thị loading indicator nếu `provider.isSearching == true`
- Hiển thị icon clear để gọi `provider.clearSearch()`

**SuggestionsBuilder (Danh sách gợi ý):**
- Kiểm tra `provider.searchSuggestions.isEmpty`
  - Nếu trống → Return empty list hoặc "No results" message
- Nếu có suggestions → Map mỗi PlaceEntity thành ListTile
  - Hiển thị `place.display` làm title
  - Hiển thị `place.address` làm subtitle
  - Gọi `provider.onSuggestionSelected(place)` khi click
- Hiển thị max 10 items (hoặc tuỳ ý)

**Pseudo-code:**
```dart
SearchAnchor(
  builder: (context, controller) {
    return SearchBar(
      controller: controller,
      hintText: 'Tìm kiếm địa điểm...',
      onChanged: (value) {
        provider.onSearchChanged(value);
      },
      trailing: [
        if (provider.searchQuery.isNotEmpty)
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () => provider.clearSearch(),
          ),
        if (provider.isSearching)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(),
          ),
      ],
    );
  },
  suggestionsBuilder: (context, controller) {
    if (provider.searchSuggestions.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.all(8),
          child: Text('Không tìm thấy kết quả'),
        ),
      ];
    }
    
    return provider.searchSuggestions
        .take(10)
        .map((place) => ListTile(
          title: Text(place.display),
          subtitle: Text(place.address),
          onTap: () => provider.onSuggestionSelected(place),
        ))
        .toList();
  },
)
```

---

### **BƯỚC 3: Xử Lý Map Marker Sau Khi Select**

**Sau khi user chọn 1 gợi ý:**

1. **Move Camera:**
   - Dùng `_vietmapController.moveCamera()`
   - Update target tới `lat/lng` từ `_selectedPlaceDetails`
   - Set zoom level = 16.0 để highlight

2. **Thêm Marker:**
   - Dùng `_vietmapController.addSymbol()` hoặc annotation
   - Vị trí: lat/lng từ place detail
   - Icon: Custom icon hoặc default pin
   - Title: `_selectedPlace.name`

**Pseudo-code:**
```dart
Future<void> onSuggestionSelected(PlaceEntity place) async {
  _selectedPlace = place;
  _isSearching = true;
  notifyListeners();
  
  try {
    // Gọi API place detail
    _selectedPlaceDetails = await repository.getPlaceDetails(place.refId);
    
    // Move camera
    await _vietmapController!.moveCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_selectedPlaceDetails!.latitude, _selectedPlaceDetails!.longitude),
        16.0,
      ),
    );
    
    // Add marker tại vị trí
    // ... Code vẽ marker
    
  } catch (e) {
    // Handle error
  } finally {
    _isSearching = false;
    notifyListeners();
  }
}
```

---

## 🔄 Luồng Dữ Liệu Chi Tiết

### **Scenario 1: User Nhập Text "Trần"**

```
UI: User types "Trần"
  ↓
SearchAnchor.builder.onChanged("Trần")
  ↓
MetroMapProvider.onSearchChanged("Trần")
  ├─ Set _isSearching = true
  ├─ Notify listeners (UI shows loading)
  ├─ Call repository.searchPlaces(PlaceRequest(text: "Trần"))
  │
  └─ Repository calls MetroMapService.searchPlaces("Trần")
      ├─ Service → GET /api/search/v4?text=Trần&apikey=...
      ├─ API returns List<PlaceDtoResponse> (10 items)
      ├─ DTO → Entity mapping
      │
      └─ Return List<PlaceEntity> to provider
        ├─ Set _searchSuggestions = result
        ├─ Set _isSearching = false
        ├─ Notify listeners
        │
        └─ UI refreshes & shows suggestions in SearchAnchor.suggestionsBuilder
            ├─ Map each PlaceEntity to ListTile
            └─ Display place.display + place.address
```

### **Scenario 2: User Clicks Gợi Ý "197 Đường Trần Anh Tông"**

```
UI: User clicks ListTile
  ↓
SearchAnchor.suggestionsBuilder.ListTile.onTap()
  ↓
MetroMapProvider.onSuggestionSelected(placeEntity)
  ├─ Set _selectedPlace = placeEntity
  ├─ Set _isSearching = true
  ├─ Notify listeners
  │
  └─ Call repository.getPlaceDetails(PlaceDetailsRequest(refid: "auto:RAk..."))
      ├─ Repository calls MetroMapService.getPlaceDetails("auto:RAk...")
      │
      └─ Service → GET /api/place/v4?refid=auto:RAk...&apikey=...
          ├─ API returns PlaceDetailsDtoResponse (chứa lat, lng)
          ├─ DTO → Entity mapping
          │
          └─ Return PlaceDetailEntity to provider
            ├─ Set _selectedPlaceDetails = result
            │
            ├─ Move camera:
            │  └─ _vietmapController.moveCamera(
            │      CameraUpdate.newLatLngZoom(
            │        LatLng(lat, lng), 16.0
            │      )
            │    )
            │
            ├─ Add marker at (lat, lng) with title = place.name
            │
            ├─ Set _isSearching = false
            ├─ Notify listeners
            │
            └─ UI updates:
                ├─ SearchAnchor closes (suggestions list disappears)
                ├─ Map pans to new location
                └─ Marker appears at location
```

---

## 🛠️ API Endpoints Cần Dùng

### **1. Autocomplete Search - `/api/search/v4`**

**Request:**
```
GET /api/search/v4?text=<search_text>&apikey=<api_key>
```

**Response:**
```json
[
  {
    "ref_id": "auto:RAk...",
    "distance": 0,
    "address": "Phường Hòa Khánh,Thành Phố Đà Nẵng",
    "name": "197 Đường Trần Anh Tông",
    "display": "197 Đường Trần Anh Tông Phường Hòa Khánh,Thành Phố Đà Nẵng",
    "boundaries": [...],
    "categories": [],
    "entry_points": []
  },
  ...
]
```

**Mapping to PlaceEntity:**
- `ref_id` → `refId`
- `distance` → `distance`
- `address` → `address`
- `name` → `name`
- `display` → `display` (dùng để hiển thị)
- `boundaries` → `boundaries` (chứa thông tin administrative)

---

### **2. Place Details - `/api/place/v4`**

**Request:**
```
GET /api/place/v4?refid=<ref_id>&apikey=<api_key>
```

**Response (Expected):**
```json
{
  "ref_id": "auto:RAk...",
  "latitude": 10.123456,
  "longitude": 106.789012,
  "address": "...",
  "name": "...",
  ...
}
```

**Mapping to PlaceDetailEntity:**
- `latitude` → `latitude`
- `longitude` → `longitude`
- Các field khác tùy vào yêu cầu

---

## ⚠️ Những Điểm Cần Chú Ý

### **1. Debounce Search Input**
- Tránh gọi API quá nhiều lần khi user đang nhập
- **Giải pháp:** Thêm delay 300ms trước khi gọi API
  - Sử dụng `Timer` hoặc `Future.delayed()`
  - Cancel timer nếu user tiếp tục nhập

**Pseudo-code:**
```dart
Timer? _searchDebounce;

Future<void> onSearchChanged(String query) async {
  _searchQuery = query;
  _searchDebounce?.cancel();
  
  if (query.isEmpty) {
    _searchSuggestions = [];
    notifyListeners();
    return;
  }
  
  _isSearching = true;
  notifyListeners();
  
  _searchDebounce = Timer(Duration(milliseconds: 300), () async {
    // Gọi API sau 300ms
    try {
      final results = await _repository.searchPlaces(PlaceRequest(text: query));
      _searchSuggestions = results;
    } catch (e) {
      // Handle error
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  });
}
```

---

### **2. Error Handling**
- Nếu API return lỗi → Hiển thị error message
- Nếu network error → Show "Không có kết nối mạng"
- Nếu ref_id invalid → Show "Không thể tải thông tin địa điểm"

**Pseudo-code:**
```dart
Future<void> onSearchChanged(String query) async {
  try {
    // ... search logic
  } catch (e) {
    if (e is DioException) {
      _errorMessage = "Lỗi mạng: Vui lòng thử lại";
    } else {
      _errorMessage = "Có lỗi xảy ra";
    }
    notifyListeners();
  }
}
```

---

### **3. Marker Management**
- Clear marker cũ trước khi thêm marker mới
- **Pseudo-code:**
```dart
Future<void> clearMarkers() async {
  // Xoá tất cả symbols trên map
  // _vietmapController.removeSymbol()
}
```

---

### **4. Keyboard & SearchAnchor Behavior**
- Khi user chọn 1 gợi ý → Keyboard tự đóng (SearchAnchor default behavior)
- Suggestions list tự ẩn khi click
- Controller text vẫn giữ giá trị search (tuỳ design: có thể xoá sau khi select)

---

## ✅ Checklist Implementation

- [ ] Thêm 5 properties state vào MetroMapProvider
- [ ] Implement `onSearchChanged()` method với debounce
- [ ] Implement `onSuggestionSelected()` method
- [ ] Implement `clearSearch()` method
- [ ] Replace SearchAnchor placeholder trong UI
- [ ] Implement SearchAnchor.builder (input field)
- [ ] Implement SearchAnchor.suggestionsBuilder (suggestions list)
- [ ] Add marker vẽ logic khi place selected
- [ ] Test: Nhập text → API call → Suggestions show
- [ ] Test: Click suggestion → API detail → Map pan + marker
- [ ] Test: Error handling (network error, invalid refid, etc.)
- [ ] Test: Debounce (không gọi API quá nhiều lần)

---

## 📊 State Management Diagram

```
MetroMapProvider
├─ _searchQuery: String
├─ _searchSuggestions: List<PlaceEntity>
├─ _isSearching: bool
├─ _selectedPlace: PlaceEntity?
├─ _selectedPlaceDetails: PlaceDetailEntity?
├─ _errorMessage: String?
│
├─ onSearchChanged(String) → repository.searchPlaces()
├─ onSuggestionSelected(PlaceEntity) → repository.getPlaceDetails()
├─ clearSearch() → clear all state
│
└─ notifyListeners() ← UI refresh
    ├─ SearchAnchor widget
    ├─ Loading indicator
    ├─ Suggestions list
    └─ Map + Marker
```

---

## 🎯 Kết Luận

**Flow tóm tắt:**
1. **User nhập ký tự** → `onSearchChanged()` → Gọi search API → Hiển thị suggestions
2. **User click suggestion** → `onSuggestionSelected()` → Gọi place detail API → Pan map + vẽ marker
3. **Debounce** được áp dụng để tránh gọi API quá nhiều lần
4. **Error handling** cho network error và invalid data
5. **State management** qua Provider để refresh UI khi data thay đổi

Tất cả tuân theo **Clean Architecture** với layer phân chia rõ ràng: UI → Provider → Repository → Service.

